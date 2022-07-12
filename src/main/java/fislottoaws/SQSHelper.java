package fislottoaws;

import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.client.builder.AwsClientBuilder;
import com.amazonaws.services.sqs.AmazonSQS;
import com.amazonaws.services.sqs.AmazonSQSClientBuilder;
import com.amazonaws.services.sqs.model.QueueNameExistsException;
import com.amazonaws.services.sqs.model.SendMessageRequest;

// https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/examples-sqs-messages.html
public class SQSHelper {

    public static void send(AmazonSQS sqs, String url, String message) {
        SendMessageRequest sendMessageRequest = new SendMessageRequest()
                .withQueueUrl(url)
                .withMessageBody(message)
                .withDelaySeconds(2);
        sqs.sendMessage(sendMessageRequest);
    }


    public static AmazonSQS prepareSQS() {
        AwsClientBuilder.EndpointConfiguration config = new AwsClientBuilder.EndpointConfiguration(Config.S3_ENDPOINT, Config.AWS_REGION);

        AmazonSQSClientBuilder builder = AmazonSQSClientBuilder.standard();
        builder.withEndpointConfiguration(config);
        builder.withCredentials(new AWSStaticCredentialsProvider(new BasicAWSCredentials("foo", "bar")));
        return builder.build();
    }

    public static String createSQSifNeeded(AmazonSQS sqs, String name) {
        try {
            sqs.createQueue(name);
        } catch (QueueNameExistsException ignore) { }

        return sqs.getQueueUrl(name).getQueueUrl();
    }


}
