from __future__ import print_function
import json
import os
import base64
import boto3


def handler_kinesis(event, context):
    """
    Receive a batch of events from Kinesis and insert as-is into our DynamoDB table if invoked asynchronously,
    otherwise perform an asynchronous invocation of this Lambda and immediately return
    """
    
    if not 'async' in event:
        for record in event['Records']:
            invoke_self_async(record, context)
        return "Invoking asyncronously"

    process_record(event)


def invoke_self_async(event, context):
    """
    This function invoke the lambda function asyncronously for each single record received.
    """
    event['async'] = True
    called_function = context.invoked_function_arn
    boto3.client('lambda').invoke(
        FunctionName=called_function,
        InvocationType='Event',
        Payload=bytes(json.dumps(event), "UTF-8")
    )


def process_record(record):
    """
    This function receives the record and decide if the target is a S3 bucket or a DynamoDB table.
    """
    
    data =json.loads(base64.b64decode(record['kinesis']['data']))
    
    if data['type'] == "archive":
        
        keylist = data.keys()
        
        object_body = ""
        object_row = ""

        for key in sorted(keylist):
            object_body = object_body + "{},".format(key)
            object_row = object_row + "{},".format(data[key])

        object_body = object_body[:-1]
        object_row = object_row[:-1]
        object_data = "{}\n{}".format(object_body, object_row)
        
        # Create a new object with the event data.
        boto3.client('s3').put_object(Body=bytes(object_data, "UTF-8"), Bucket=os.environ["s3_bucket"], Key="{}.csv".format(record['eventID']))
       