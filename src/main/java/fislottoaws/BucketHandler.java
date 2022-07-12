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

    public final String AWS_REGION = "eu-central-1";
    public final String S3_ENDPOINT = "http://localstack:4566";

    @Override public Void handleRequest(S3Event s3Event, Context context) {

        LambdaLogger logger = context.getLogger();

        String bucket = s3Event.getRecords().get(0).getS3().getBucket().getName();
        String key = s3Event.getRecords().get(0).getS3().getObject().getKey();

        AmazonS3 bucketClient = prepareBucketClient();

        S3Object obj = bucketClient.getObject(new GetObjectRequest(bucket, key));
        try (InputStream stream = obj.getObjectContent()) {

            BufferedReader br = new BufferedReader(new InputStreamReader(stream));
            String line="";
            while ((line=br.readLine())!=null)
                logger.log(line+"\n");


        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return null;
    }

    private AmazonS3 prepareBucketClient() {
        AwsClientBuilder.EndpointConfiguration config = new AwsClientBuilder.EndpointConfiguration(S3_ENDPOINT, AWS_REGION);

        AmazonS3ClientBuilder builder = AmazonS3ClientBuilder.standard();
        builder.withEndpointConfiguration(config);
        builder.withPathStyleAccessEnabled(true);
        builder.withCredentials(new AWSStaticCredentialsProvider(new BasicAWSCredentials("foo", "bar")));
        return builder.build();
    }
}