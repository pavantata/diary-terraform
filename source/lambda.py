import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    
    logger.info('testing2 logging got event{}'.format(event))
    
    #user = event["user"]
    #postId = event["postId"]
    #time = event["time"]
    
    user = event.get('user', None)
    postId = event.get('postId', None)
    time = event.get('time', None)
    
    logger.info('value of user:%s:',user)
    logger.info('value of postId:%s:', postId)
    logger.info('value of time:%s:', time)
    
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DB_TABLE_NAME'])
    
    if not user:
        if postId=="*":
            items = table.scan()
        else:
            items = table.query(
                KeyConditionExpression=Key('id').eq(postId)
            )
    else:
        if not time:
            items = table.query(
                 IndexName='user-time-index',
                 KeyConditionExpression=Key('user').eq(user)
            )
        else:
            items = table.query(
                 IndexName='user-time-index',
                 KeyConditionExpression=Key('user').eq(user) & Key('time').begins_with(time)
            )
    
    return items["Items"]
    
# add these environment variables  - DB_TABLE_NAME=posts

# python version 2.7
