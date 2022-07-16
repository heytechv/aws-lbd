#!/bin/bash
# Używanie localstack z AWS CLI: https://lobster1234.github.io/2017/04/05/working-with-localstack-command-line/

# Konfiguracja aws 1x na początku i zapisuje do plików                                                                  # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-settings
#   ~/.aws/config; ~/.aws/credentials
#
# aws configure                                                                                                         # tworzę poświadczenia np wg aws_credentials_mojeInfo.yml
# docker compose up                                                                                                     # uruchamia contener localstack na osobnym terminalu - mogę oglądać logi
# gnome-terminal -- bash -c "(cd ../; docker compose up)"; ./01_bucket_s3.sh                                            # automatycznie uruchamiam dicker i ten skrypt. Działa

#-----------------------------------------------------------------------------------------------------------------------
source sh/init.sh
#--- helpers ---
echoWithoutDebug() { set +x; echo -e "$@"; set -x; }

##--- usage ---
#usage() {
#  echo "Usage: $0 [functions]:"
#  cat $0 | grep -o "^aws\w*" | sed "s#^${1}#  ${1}#g"; exit
#}

#--- initEnv ---
initEnv() {
 # Alias Definicja, zakres obowiązywania tylko wewnątrz funkcji. Zakres globalny patrz initEnv()
 # shopt -s expand_aliases                                                                                              # aliasy nie są rozwijane, gdy powłoka nie jest interaktywna, chyba że expand_aliasesopcja powłoki jest ustawiona przy użyciu shopt(zobacz opis shoptponiżej WBUDOWANE POLECENIA POWŁOKI ): https://stackoverflow.com/questions/24054154/how-do-create-an-alias-in-shell-scripts
 # alias awsLocal="aws --endpoint-url=http://localhost:4566 --region eu-central-1 "                                     # alias definicja lokalnie

 # Alias Definicja, zakres obowiązywania także na zewnątrz funkcji
  awsLocal() { aws "$@" --endpoint-url http://localhost:4566 --region eu-central-1; } # read -r -t 2 -p "Breakpoint: "; # Alias definiowany wewnątrz funkcji: https://github.com/koalaman/shellcheck/wiki/SC2262

  docker compose ps | grep -q "^aws-lbd.*running" || {
    echo INFO: Nie uruchomiono: Docker Compose localstack, Uruchamiam w nowym oknie z logami...
    gnome-terminal -- bash -c "(cd ../; docker compose up)"; }

  awsLocal s3 ls || { sleep 2; awsLocal s3 ls || { echo "Error: Nie udało się uruchomić Docker Compose localstack"; exit 1; } }

  $parm_debug && { echo -e "\n--- Włączam debugowanie ---"; set -x; }                                                   # debugowanie
}

#--- Robocze -----------------------------------------------------------------------------------------------------------
awsRob01() {
  awsLocal s3 ls                                                   # format polecenia
#  echo "Rob01ddd"
}

#--- functions ---------------------------------------------------------------------------------------------------------
awsBucket() {
  awsLocal s3 ls                                                   # format polecenia
  awsLocal s3 mb s3://testbucket01                                 # tworzy bucket o nazwie testbucket01
  awsLocal s3 mb s3://testbucket02                                 #                        testbucket02
  awsLocal s3 ls                                                   # wynik: testbucket01\ntestbucket02
  awsLocal s3 rb s3://testbucket02                                 # usuwa                  testbucket02
  awsLocal s3 ls                                                   # wynik: testbucket01\ntestbucket02
  awsLocal s3 ls s3://testbucket01
  awsLocal s3 cp helpers/samplefile.txt s3://testbucket01          # kopiuję plik do testbuckert01
  awsLocal s3 ls s3://testbucket01
  awsLocal s3 rm s3://testbucket01/samplefile.txt                  # usuwam  plik z  testbuckert01
  awsLocal s3 ls s3://testbucket01
  awsLocal s3 ls
}

awsLambda() {
  # Doc->Lambda: https://codetinkering.com/localstack-s3-lambda-example-docker/
  #              https://rochisha-jaiswal70.medium.com/using-aws-lambda-with-amazon-simple-queue-service-bb0694257a2b
  awsLocal lambda create-function \
           --function-name processCsv --runtime java11 --handler fislottoaws.BucketHandler \
           --zip-file fileb://../target/java-basic-1.0-SNAPSHOT.jar \
           --role arn:aws:iam::12345:role/ignoreme
  awsLocal lambda delete-function --function-name processCsv

#aws lambda create-function \
#         --function-name sqsListener --runtime java11 --handler fislottoaws.SqsHandler \
#         --zip-file fileb://..\target\java-basic-1.0-SNAPSHOT-lambda_deployment_package_assembly.zip \
#         --role arn:aws:iam::12345:role/ignoreme \
#aws lambda create-event-source-mapping --function-name sqsListener --batch-size 5 --maximum-batching-window-in-seconds 60 --event-source-arn arn:aws:sqs:eu-central-1:000000000000:MojaKolejka
#
}

awsEventRegister() {
  awsLocal s3 mb s3://testbucket
  awsLocal s3api put-bucket-notification-configuration --bucket testbucket --notification-configuration file://../s3hook.json
}

awsLambdaInvoke() {                                                                                                     # Wywoływanie lambda w localstack
  awsLocal s3 cp ../kupon.csv s3://testbucket/kupon.csv
}

awsSqsQueue() {
  # Doc SQS queue:
  #   Create     : https://docs.aws.amazon.com/cli/latest/reference/sqs/create-queue.html
  #   Delete     : https://docs.aws.amazon.com/cli/latest/reference/sqs/delete-queue.html
  #   Send-msg   : https://docs.aws.amazon.com/cli/latest/reference/sqs/send-message.html
  #   Receive-msg: https://docs.aws.amazon.com/cli/latest/reference/sqs/receive-message.html
  awsLocal sqs create-queue    --queue-name MojaKolejka
  awsLocal sqs send-message    --queue-url http://localhost:4566/000000000000/MojaKolejka --message-body "siema"
  awsLocal sqs receive-message --queue-url http://localhost:4566/000000000000/MojaKolejka
  awsLocal sqs delete-queue    --queue-url http://localhost:4566/000000000000/MojaKolejka
}

#------------------------------------------------------------------------------------------------------------------------
awsMichal() {                                                                                                             # Przykład Localstack S3 i Java Lambda w Docker: https://codetinkering.com/localstack-s3-lambda-example-docker/
  awsLocal s3 mb s3://testbucket                                                                                        # Tworzę Bucket (zasobnik) S3 za pomocą LocalStack
  awsLocal lambda create-function \
           --function-name processCsv --runtime java11 --handler fislottoaws.BucketHandler \
           --zip-file fileb://../target/java-basic-1.0-SNAPSHOT-lambda_deployment_package_assembly.zip \
           --role arn:aws:iam::12345:role/ignoreme
                                                                                                                        # Rejestracja zdarzeń Bucket Lambda do S3
  awsLocal s3api put-bucket-notification-configuration \
           --bucket testbucket --notification-configuration file://helpers/s3hook.json

#  read -r -t 2 -p "Breakpoint cp: "
  awsLocal s3 cp helpers/samplefile.txt s3://testbucket/samplefile.txt                                                  # Wywoływanie Lambda w Localstack - to polecenie uruchomi lambdę

  set +x; echo -e "\n--- Czyszczenie środowiska ---"
  awsLocal s3 rm s3://testbucket/samplefile.txt                                                                         # usuwa plik
  awsLocal s3 rb s3://testbucket                                                                                        # usuwa testbucket
  awsLocal lambda delete-function --function-name processCsv                                                            # usuwa funkcję
}

#=======================================================================================================================
initEnv
#awsBucket
#awsLambda
#awsEventRegister
#awsLambdaInvoke
#awsSqsQueue

#awsMichal

echo "--- $toRunFunction ---"; "$toRunFunction"
