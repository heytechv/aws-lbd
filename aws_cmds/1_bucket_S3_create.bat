:: https://lobster1234.github.io/2017/04/05/working-with-localstack-command-line/

:: Tworzy bucket o nazwie testbucket
aws s3 mb s3://testbucket --endpoint-url=http://localhost:4566 --region eu-central-1
