:: https://codetinkering.com/localstack-s3-lambda-example-docker/

aws lambda create-function --endpoint-url http://localhost:4566 --function-name processCsv --runtime java8 --handler fislottoaws.BucketHandler --region eu-central-1 --zip-file fileb://C:\Users\mwlocka\fis_sst_staz_4_aws\lottocode\target\java-basic-1.0-SNAPSHOT-lambda_deployment_package_assembly.zip --role arn:aws:iam::12345:role/ignoreme
