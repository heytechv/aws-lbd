package fislottoaws;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;


public class SqsHandler implements RequestHandler<SQSEvent, Object> {

    // https://rochisha-jaiswal70.medium.com/using-aws-lambda-with-amazon-simple-queue-service-bb0694257a2b


    @Override public String handleRequest(SQSEvent event, Context context) {
        String response ="";

        LambdaLogger logger = context.getLogger();


        for (SQSEvent.SQSMessage msg : event.getRecords()) {

            logger.log("ODERBRANO "+msg.getBody()+"\n");
        }

        return "ok";
    }
}
