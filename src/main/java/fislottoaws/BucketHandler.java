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