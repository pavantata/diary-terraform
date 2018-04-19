import boto3
import os
import uuid

def lambda_handler(event, context):
    
    recordId = str(uuid.uuid4())
    user = event["user"]
    time = event["time"]
    text = event["text"]

    print('Generating new DynamoDB record, with ID: ' + recordId)
    print('Input Text: ' + text)
    print('Selected user: ' + user)
    print('Selected time: ' + time)
    
    #Creating new record in DynamoDB table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DB_TABLE_NAME'])
    table.put_item(
        Item={
            'id' : recordId,
            'user': user,
            'time': time,
            'text' : text
        }
    )
    
    return recordId

# add environment variables - DB_TABLE_NAME=posts

# python 2.7

