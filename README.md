### UWAGA! Kasowac docker_tmp bo farmazony (stare eventy)

Docker (localstack):
1. `docker compose up -d`
2. `docker down`

Komendy aws cli:
1. `aws_cmds/1_bucket_S3_create.bat`
2. `aws_cmds/2_lambda_create.bat`
3. `aws_cmds/3_event_register.bat`
4. `aws_cmds/sqs/1_lambda_sqsFunc_create.bat`
5. `aws_cmds/sqs/2_event_sqsFunc_register.bat`
6. `aws_cmds/4_lambda_invoke.bat`

Lub Terraform:
1. `cd terraform`
2. (`terraform init`)
3. `terraform apply` -> yes
4. `aws_cmds/4_lambda_invoke.bat`


# Zadanie
### Tresc zadania
> Napisać funkcje lambda, która będzie konsumować plik z S3 (CSV), mapowować do formatu JSON i przekazywać na SQS.<br/>
> Co zawiera plik:<br/>
> - plik ma zawierac kupon totka: czyli 6 kolumn liczb w zakresie 1-49 które się nie powtarzaja<br/>
> - plik moze zawierać wiele wierszy (czyli zakładów pojedynczych) na cały kupon<br/>

### Dodalem dependencies do pom.xml (sqs oraz dependency manager)...
Dodajac dependency manager (od aws w tym przypadku) do poszczegolnych np. do `aws-java-sdk-sqs` nie podajemy wersji! 

### Dane wysylane sa na kolejke...
Mozemy je odebrac (sciagac ze stosu pojedynczo) uzywajac *sqs_receive.bat:*
```bat
aws sqs receive-message --queue-url http://localhost:4566/000000000000/MojaKolejka --endpoint-url=http://localhost:4566 --region eu-central-1
```
Java sama tworzy kolejke o zadanej w *Config.java* nazwie.

### Tresc zadania - ciag dalszy
> Odebrac z kolejki

# Receive from SQS (queue) - SqsListener
##### - https://rochisha-jaiswal70.medium.com/using-aws-lambda-with-amazon-simple-queue-service-bb0694257a2b
Dziala dokladnie tak jak BucketHandler. Tworzymy nowa klase (SqsHandler.java), która będzie Handlerem dla zdarzenia "wysłanie wiadomości do kolejki".<br/>
<br/>
Tworzymy naszą nową lambde:

```bat
aws lambda create-function --endpoint-url http://localhost:4566 --function-name sqsListener --runtime java11 --handler fislottoaws.SqsHandler --region eu-central-1 --zip-file fileb://..\target\java-basic-1.0-SNAPSHOT-lambda_deployment_package_assembly.zip --role arn:aws:iam::12345:role/ignoreme
```

Parametry
- `--function-name sqsListener` - nazwa naszej nowej lambdy
- `--handler fislottoaws.SqsHandler` - nasz handler javovy

Następnie rejestrujemy naszą lambde na zdarzenie dla naszej kolejki:
```bat
aws lambda create-event-source-mapping --function-name sqsListener --batch-size 5 --maximum-batching-window-in-seconds 60  --event-source-arn arn:aws:sqs:eu-central-1:000000000000:MojaKolejka --endpoint-url http://localhost:4566
```

Parametry:
- `--function-name sqsListener` - nazwa naszej lambdy
- `--event-source-arn arn:aws:sqs:eu-central-1:000000000000:MojaKolejka` - na końcu MojaKolejka to nazwa mojej kolejki (W tym przykładzie, SQSHelper.java sam tworzy kolejkę o nazwie zdefiniowanej w Config.java)

I teraz dowolne wysłanie czegokolwiek na kolejkę spowoduje wywołanie naszej lambdy :).


