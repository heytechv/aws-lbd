# https://www.youtube.com/watch?v=XxTcw7UTues&ab_channel=WahlNetwork

# Terraform wykona operacje aws cli (ktore wykonywalem recznie)
# na kompie automatycznie.
# Stworzy bucket, lambdy itp.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.49"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region            = "eu-central-1"
  access_key        = "foo"
  secret_key        = "bar"
  s3_force_path_style = true
  # lokalnie
  profile = "local"
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    sqs    = "http://localhost:4566"  # adres dockera z punktu widzenia mojego kompa (nie pod-dockerow)
    s3     = "http://localhost:4566"
    lambda = "http://localhost:4566"
  }
}

# Create bucket [resource "type" "localname" { ... }]
resource "aws_s3_bucket" "testbucket" {
  bucket = "testbucket"
}

# Create sqs (queue) - mam nadzieje ze if not exists
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queues
resource "aws_sqs_queue" "mojakolejka" {
  name = "MojaKolejka"
}

# ----------------------------------------------------------------------------------------------------------------------
# -- (BucketHandler.java) ----------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------
# Create lambda (BucketHandler.java)
resource "aws_lambda_function" "lambdaBucketProcessCsv" {
  depends_on = [aws_s3_bucket.testbucket]  # co wczesniej ma zostac wykonane

  function_name = "processCsv"
  role          = "arn:aws:iam::12345:role/ignoreme"
  filename      = "../target/java-basic-1.0-SNAPSHOT-lambda_deployment_package_assembly.zip"
  runtime       = "java11"
  handler       = "fislottoaws.BucketHandler"
}

# Attach event to lambda (BucketHandler.java)
resource "aws_s3_bucket_notification" "eventBucketProcessCSV" {
  depends_on = [aws_lambda_function.lambdaBucketProcessCsv]  # co wczesniej ma zostac wykonane

  bucket = aws_s3_bucket.testbucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambdaBucketProcessCsv.arn
    events = [
      "s3:ObjectCreated:*"
    ]
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# -- (SqsHandler.java) -------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------
# Create lambda (SqsHandler.java)
resource "aws_lambda_function" "lambdaSqsListener" {
  depends_on = [aws_s3_bucket.testbucket]

  function_name = "sqsListener"
  role          = "arn:aws:iam::12345:role/ignoreme"
  filename      = "../target/java-basic-1.0-SNAPSHOT-lambda_deployment_package_assembly.zip"
  runtime       = "java11"
  handler       = "fislottoaws.SqsHandler"
}

# Attach event to lambda (SqsHandler.java)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
resource "aws_lambda_event_source_mapping" "eventSqsListener" {
  depends_on = [aws_lambda_function.lambdaSqsListener, aws_sqs_queue.mojakolejka]

  event_source_arn = aws_sqs_queue.mojakolejka.arn
  function_name = aws_lambda_function.lambdaSqsListener.arn
}


# Tego nie, bo terraform to inicjalizacja srodowiska, a nie wywolywanie! (chyba xd)
## Upload file (invoke our event to call the lambda)
## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object
#resource "aws_s3_bucket_object" "kuponCsv" {
#  bucket = aws_s3_bucket.testbucket.bucket
#  key    = "kupon.csv"  # nazwa obiektu w bucket
#  source = "../kupon.csv"
#
#}

