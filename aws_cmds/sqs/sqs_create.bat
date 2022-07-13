:: Create SQS queue
:: https://docs.aws.amazon.com/cli/latest/reference/sqs/create-queue.html

aws sqs create-queue --queue-name MojaKolejka --endpoint-url=http://localhost:4566 --region eu-central-1