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
import com.amazonaws.services.sqs.AmazonSQS;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


public class BucketHandler implements RequestHandler<S3Event, String> {

    @Override public String handleRequest(S3Event s3Event, Context context) {

        // Init logger
        LambdaLogger logger = context.getLogger();

        // Get bucket name and key
        String bucket = s3Event.getRecords().get(0).getS3().getBucket().getName();
        String key = s3Event.getRecords().get(0).getS3().getObject().getKey();

        // Prepare bucket connection?
        AmazonS3 bucketClient = S3BucketHelper.prepareBucketClient();

        // Prepare SQS
        AmazonSQS sqs = SQSHelper.prepareSQS();

        // Get object (file) content from bucket
        S3Object obj = bucketClient.getObject(new GetObjectRequest(bucket, key));

        // Validate numbers
        Pattern pattern = Pattern.compile("^([1-4]\\d|[1-9]),([1-4]\\d|[1-9]),([1-4]\\d|[1-9]),([1-4]\\d|[1-9]),([1-4]\\d|[1-9]),([1-4]\\d|[1-9])$");
        Matcher matcher;

        // Convert file to ArrayList<Kupon>
        List<Kupon> kuponList = new ArrayList<>();

        try (InputStream stream = obj.getObjectContent()) {
            BufferedReader br = new BufferedReader(new InputStreamReader(stream));

            String line;
            while ((line=br.readLine())!=null) {
                matcher = pattern.matcher(line);
                if (matcher.matches()) {
                    kuponList.add(new Kupon(
                            Integer.parseInt(matcher.group(1)),
                            Integer.parseInt(matcher.group(2)),
                            Integer.parseInt(matcher.group(3)),
                            Integer.parseInt(matcher.group(4)),
                            Integer.parseInt(matcher.group(5)),
                            Integer.parseInt(matcher.group(6))
                    ));
                } else {
                    logger.log("[Error] Blad z kuponem: '"+line+"'\n");
                }
            }
        } catch (IOException ioe) { ioe.printStackTrace(); }

        for (Kupon kupon : kuponList)
            logger.log("Kupon: "+kupon.toString()+"\n");

        // Mapper, map ArrayList<Kupon> to JSON string
        ObjectMapper mapper = new ObjectMapper();
//        mapper.enable(SerializationFeature.INDENT_OUTPUT);
        String jsonResult="{}";
        try {
            jsonResult = mapper.writeValueAsString(kuponList);
        } catch (JsonProcessingException e) { e.printStackTrace(); }

        logger.log(jsonResult+"\n");

        // Send to SQS queue
        String sqsMainUrl = SQSHelper.createSQSifNeeded(sqs, Config.SQS_MAIN_NAME);
        SQSHelper.send(sqs, sqsMainUrl, jsonResult);

        return jsonResult;
    }



}