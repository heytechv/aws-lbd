:: https://rochisha-jaiswal70.medium.com/using-aws-lambda-with-amazon-simple-queue-service-bb0694257a2b

aws lambda create-function --endpoint-url http://localhost:4566 --function-name sqsListener --runtime java11 --handler fislottoaws.SqsHandler --region eu-central-1 --zip-file fileb://..\target\java-basic-1.0-SNAPSHOT-lambda_deployment_package_assembly.zip --role arn:aws:iam::12345:role/ignoreme
