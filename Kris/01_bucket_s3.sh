#!/bin/bash
# Używanie localstack z AWS CLI: https://lobster1234.github.io/2017/04/05/working-with-localstack-command-line/

# Konfiguracja aws 1x na początku i zapisuje do plików                                                                  # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-settings
#   ~/.aws/config; ~/.aws/credentials
#
# aws configure                                                                                                         # tworzę poświadczenia np wg aws_credentials_mojeInfo.yml
# docker compose up                                                                                                     # uruchamia contener localstack na osobnym terminalu - mogę oglądać logi
# gnome-terminal -- bash -c "(cd ../; docker compose up)"; ./01_bucket_s3.sh                                            # automatycznie uruchamiam dicker i ten skrypt. Działa

#-----------------------------------------------------------------------------------------------------------------------
docker compose ps | grep "^aws-lbd.*running" || {
  echo INFO: Nie uruchomiono jeszcze: Docker localstack, Uruchamiam w nowym oknie z logami...
  gnome-terminal -- bash -c "(cd ../; docker compose up)"; }

shopt -s expand_aliases                                                                                                 # Aliasy nie są rozwijane, gdy powłoka nie jest interaktywna, chyba że expand_aliasesopcja powłoki jest ustawiona przy użyciu shopt(zobacz opis shoptponiżej WBUDOWANE POLECENIA POWŁOKI ): https://stackoverflow.com/questions/24054154/how-do-create-an-alias-in-shell-scripts
alias awss3Local="aws --endpoint-url=http://localhost:4566 --region eu-central-1 s3 "

echo -e "\n--- Włączam debugowanie ---"; set -x

awss3Local ls                                                   # format polecenia
awss3Local mb s3://testbucket01                                 # tworzy bucket o nazwie testbucket01
awss3Local mb s3://testbucket02                                 #                        testbucket02
awss3Local ls                                                   # wynik: testbucket01\ntestbucket02
awss3Local rb s3://testbucket02                                 # usuwa                  testbucket02
awss3Local ls                                                   # wynik: testbucket01\ntestbucket02
awss3Local ls s3://testbucket01
awss3Local cp ../samplefile.txt s3://testbucket01               # kopiuję plik do testbuckert01
awss3Local ls s3://testbucket01
awss3Local rm s3://testbucket01/samplefile.txt                  # usuwam  plik z  testbuckert01
awss3Local ls s3://testbucket01
awss3Local ls