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

