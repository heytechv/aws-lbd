### Base project template for Java + localstack/aws in docker
### Project contains client side
#### - basic sending file to bucket
### and localstack/aws side
#### - handling it using lambda (Java)

<br/>

### How project works
We create bucket `testbucket` (in localstack/aws) which can store files. By sending file to our `testbucket` we activate event which calls our lambda function wrote in Java.
_____________

## Docker/localhost
### 1. Instalujemy AWS CLI (localhost)
Instalujemy `aws cli` na swoim kompie (będziemy komendami się łączyć z aws/localstack na docker).

### 2. docker-compose.yml
Potrzebujemy localstack
```yml
version: "3.8"

services:
 localstack:
  image: localstack/localstack:latest
  ports:
   - "4566:4566"
   - "4569:4569"
   - "4571:4571"
   - "4572:4572"
   - "4574:4574"
   - "8080:8080"
  environment:
   - SERVICES=s3,lambda,serverless,sqs
   - DEBUG=1
   - AWS_DEFAULT_REGION=eu-central-1
   - AWS_ACCESS_KEY_ID=foo
   - AWS_SECRET_ACCESS_KEY=bar
   - EDGE_PORT=4566
   - DOCKER_HOST=unix:///var/run/docker.sock
   - LAMBDA_DOCKER_NETWORK=aws-lbd_default
   - HOSTNAME_EXTERNAL=localstack
   - DATA_DIR=/tmp/localstack
   - LAMBDA_REMOTE_DOCKER=true
  volumes:
   - "./docker_tmp:/tmp/localstack"
   - "/var/run/docker.sock:/var/run/docker.sock"
```
Docker domyślnie tworzy siec, która ma nazwę:<br/>
`katalogpowyzejgdziedocker_default`
<br/>Dlatego:<br/>
`LAMBDA_DOCKER_NETWORK=katalogpowyzejgdziedocker_default`
<br/>Nasz przyszły plik java (który stworzymy niżej) localstack uruchamia w osobnym docker, dlatego musimy temu nowemu kontenerowi pokazać jakie będzie ip localstack:<br/>
`HOSTNAME_EXTERNAL=localstack`

### 3. Run docker
`docker compose up`

## Java (Bucket Event Handler)
### UWAGA! localstack wymaga .zip pliku, w którym znajduje się katalog lib z zależnościami oraz ścieżką z naszą klasą (co i jak jest opisane poniżej).

#### Przydatne linki:
- https://codetinkering.com/localstack-s3-lambda-example-docker/ - odbieranie pliku (jako tako działa ale nie dla localstack bo maven zly)
- https://examples.javacodegeeks.com/software-development/amazon-aws/tutorial-use-aws-lambda-s3-real-time-data-processing/
- https://medium.com/@mengjiannlee/local-deployment-of-aws-lambda-spring-cloud-function-using-sam-local-and-localstack-dc7669110906 - struktura plików w projekcie
- http://whirlysworld.blogspot.com/2016/03/aws-lambda-java-deployment-maven-build.html - LINK KTÓRY ROZWIĄZAŁ WSZYSTKIE PROBLEMY

### 1. Tworzymy nowy projekt maven.

### 2. Tworzymy plik
`main/java/fislottoaws/BucketHandler.java`

*BucketHandler.java:*
```java
package fislottoaws;


import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.client.builder.AwsClientBuilder;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.GetObjectRequest;
import com.amazonaws.services.s3.model.S3Object;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;


public class BucketHandler implements RequestHandler<S3Event, Void> {

    @Override public Void handleRequest(S3Event s3Event, Context context) {

        LambdaLogger logger = context.getLogger();

        String bucket = s3Event.getRecords().get(0).getS3().getBucket().getName();
        String key = s3Event.getRecords().get(0).getS3().getObject().getKey();

        AmazonS3 s3Client = AmazonS3ClientBuilder.defaultClient();

        S3Object obj = prepareS3().getObject(new GetObjectRequest(bucket, key));
        try (InputStream stream = obj.getObjectContent()) {
            // TODO: Do something with the file contents here

            BufferedReader br = new BufferedReader(new InputStreamReader(stream));
            String line="";
            while ((line=br.readLine())!=null)
                logger.log(line+"\n");


        } catch (IOException ioe) {
            //throw ioe;
            ioe.printStackTrace();
        }

        return null;

    }
    public final String AWS_REGION = "eu-central-1";
    public final String S3_ENDPOINT = "http://localstack:4566";

    private AmazonS3 prepareS3() {
        BasicAWSCredentials credentials = new BasicAWSCredentials("foo", "bar");

        AwsClientBuilder.EndpointConfiguration config =
                new AwsClientBuilder.EndpointConfiguration(S3_ENDPOINT, AWS_REGION);

        AmazonS3ClientBuilder builder = AmazonS3ClientBuilder.standard();
        builder.withEndpointConfiguration(config);
        builder.withPathStyleAccessEnabled(true);
        builder.withCredentials(new AWSStaticCredentialsProvider(credentials));
        return builder.build();
    }
}
```
#### WAŻNE! Wyżej moje dane, wiec uzupełnić `new BasicAWSCredentials(accessKey, secretKey)`, `AWS_REGION` regionem z docker oraz `S3_ENDPOINT` jako `nazwa_dockera:port_dockera`.

### 3. MAVEN - konfiguracja
Tworzymy plik `src/assembly/lambda_deployment_package_assembly.xml`.<br/>
*lambda_deployment_package_assembly.xml:*
```xml
<assembly xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.3"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.3 http://maven.apache.org/xsd/assembly-1.1.3.xsd">
<!-- http://whirlysworld.blogspot.com/2016/03/aws-lambda-java-deployment-maven-build.html -->
    <id>lambda_deployment_package_assembly</id>
    <formats>
        <format>zip</format>
    </formats>
    <includeBaseDirectory>false</includeBaseDirectory>
    <fileSets>
        <fileSet>
            <directory>${project.build.directory}/classes</directory>
            <outputDirectory>/</outputDirectory>
            <includes>
                <include>**/*.class</include>
            </includes>
        </fileSet>
        <fileSet>
            <outputDirectory>extras</outputDirectory>
            <includes>
                <include>readme.md</include>
            </includes>
        </fileSet>
    </fileSets>
    <dependencySets>
        <dependencySet>
            <outputDirectory>lib</outputDirectory>
            <useProjectArtifact>false</useProjectArtifact>
        </dependencySet>
    </dependencySets>
</assembly>
```
Okej, teraz zawartość pliku maven<br/>
*pom.xml:*
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>java-basic</artifactId>
    <packaging>jar</packaging>
    <version>1.0-SNAPSHOT</version>
    <name>java-basic-function</name>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>

    <dependencies>
        <dependency>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-lambda-java-core</artifactId>
            <version>1.2.1</version>
        </dependency>
        <dependency>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
            <version>2.8.6</version>
        </dependency>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-api</artifactId>
            <version>[2.17.1,)</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-core</artifactId>
            <version>[2.17.1,)</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-slf4j18-impl</artifactId>
            <version>[2.17.1,)</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>5.6.0</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <version>5.6.0</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-java-sdk-s3</artifactId>
            <version>1.11.415</version>
        </dependency>
        <dependency>
            <groupId>com.amazonaws</groupId>
            <artifactId>aws-lambda-java-events</artifactId>
            <version>2.2.9</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <!--  Note: mvn clean; mvn package
                -->
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.3.0</version>
                <configuration>
                    <descriptors>
                        <descriptor>src/assembly/lambda_deployment_package_assembly.xml</descriptor>
                    </descriptors>
                </configuration>
                <executions>
                    <execution>
                        <id>lambda_deployment_package_execution</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

### 4. Build
`mvn clean package`

### 5. AWS (create bucket)
*1_bucket_S3_create.bat:*
```bat
:: https://lobster1234.github.io/2017/04/05/working-with-localstack-command-line/

:: Tworzy bucket o nazwie testbucket
aws s3 mb s3://testbucket --endpoint-url=http://localhost:4566 --region eu-central-1
```

*1a_bucket_S3_list.bat:*
```bat
:: https://lobster1234.github.io/2017/04/05/working-with-localstack-command-line/

aws --endpoint-url=http://localhost:4566 --region eu-central-1 s3 ls
```

### 6. AWS (create lambda)
*2_lambda_create.bat:*
```bat
:: https://codetinkering.com/localstack-s3-lambda-example-docker/

aws lambda create-function --endpoint-url http://localhost:4566 --function-name processCsv --runtime java11 --handler fislottoaws.BucketHandler --region eu-central-1 --zip-file fileb://..\target\java-basic-1.0-SNAPSHOT-lambda_deployment_package_assembly.zip --role arn:aws:iam::12345:role/ignoreme
```
Parametry:<br/>
- `--function-name processCsv` - jak ma się nazywać nasza funkcja na aws(localstack)
- `--runtime java11` - java8/java11
- `--handler fislottoaws.BucketHandler` - klasa handler
- `--zip-file fileb:sciezka_do_naszego_pliku.zip` - wygenerowany zip

Wynikiem wywołania komendy będzie coś w tym stylu:
```json
{
    "FunctionName": "processcsv",
    "FunctionArn": "arn:aws:lambda:eu-central-1:000000000000:function:processcsv",
    "Runtime": "java8",
    "Role": "arn:aws:iam::12345:role/ignoreme",
    "Handler": "lambda.S3EventHandler",
...
}
```

Potrzebne nam tylko `FunctionArn`.<br/><br/>
Tworzymy plik, który będzie służył do zarejestrowania eventu, o nazwie np. *s3hook.json* w np. katalogu głównym (tam gdzie *pom.xml*)
 i dajemy w `LambdaFunctionArn` to co wyżej nam zwróciło oraz eventy, które chcemy obsługiwać.<br/>
*s3hook.json:*
```json
{
  "LambdaFunctionConfigurations": [
    {
      "Id": "1234567890123",
      "LambdaFunctionArn": "arn:aws:lambda:eu-central-1:000000000000:function:processCsv",
      "Events": [
        "s3:ObjectCreated:*"
      ]
    }
  ]
}
```

_______________________________________
(Jako ciekawostka daje plik do usuwania stworzonej wcześniej funkcji *2_lambda_delete.bat:*)
```bat
:: https://codetinkering.com/localstack-s3-lambda-example-docker/

aws lambda delete-function --endpoint-url http://localhost:4566 --function-name processCsv
```

### 7. AWS (register event)
Potrzebujemy plik z podpunktu wyżej, wywołujemy:<br/>
*3_event_register.bat:*
```bat
aws s3api put-bucket-notification-configuration --bucket testbucket --notification-configuration file://../s3hook.json --endpoint-url http://localhost:4566 --region eu-central-1
```
Parametry:
- `--notification-configuration file://../s3hook.json` - tutaj nasz plik z podpunktu wyżej

### 8. AWS (lambda invoke/call)
Super. Mamy wszystko, teraz możemy przetestować nasz event BucketHandler wysyłając plik na server aws/localstack.<br/>
Tworzymy plik np. *samplefile.txt* i wywołujemy:<br/>
*4_lambda_invoke.bat:*
```bat
aws s3 cp ../samplefile.txt s3://testbucket/samplefile.txt --endpoint-url http://localhost:4566 --region eu-central-1
```
Parametry:
- `../samplefile.txt s3://testbucket/samplefile.txt` - ścieżka do naszego pliku lokalnie oraz ścieżka gdzie ma byc (w jakim bucket) na serwerze

### 9. View file using browser (Optional)
`http://localhost:4566/testbucket/samplefile.txt`


# FAQ
1. Mam błąd w docker `java.lang.NoClassDefFoundError` lub `ClassNotFoundException`
> Jak napisałem wyżej w `UWAGA`, localstack nie przyjmuje plików jar, nawet shaded idk czemu, musi byc zip.
Przejrzyj dokumentacje jeszcze raz i skopiuj maven, potem `mvn clean package`