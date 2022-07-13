:: Delete SQS queue
:: https://docs.aws.amazon.com/cli/latest/reference/sqs/delete-queue.html

aws sqs delete-queue --queue-url http://localhost:4566/000000000000/MojaKolejka --endpoint-url=http://localhost:4566 --region eu-central-1