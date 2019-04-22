from __future__ import print_function
import json
import base64


def handler_kinesis(event, context):
    
    print(event)
    for record in event['Records']:
        process_record(record)


def process_record(record):
    print(base64.b64decode(record['kinesis']['data']))