from __future__ import print_function
import json
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
    print(base64.b64decode(record['kinesis']['data']))