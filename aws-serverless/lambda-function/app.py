import boto3
import json

print('Loading function')
dynamo = boto3.client('dynamodb')


def respond(err, res=None):
    return {
        'statusCode': '400' if err else '200',
        'body': err.message if err else json.dumps(res),
        'headers': {
            'Content-Type': 'application/json',
        },
    }


def lambda_handler(event, context):
    

    item = dynamo.get_item(
        TableName="AWSServerlessTerraform",
        Key={
            'UserId': {'S': 'test'}
        }
    )
    
    print(item)
