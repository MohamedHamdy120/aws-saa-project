import json
import boto3
import os

SNS_TOPIC_ARN=os.environ["SNS_TOPIC_ARN"]
sns=boto3.client("sns")

def lambda_handler(event, context):
    for record in event["Records"]:
        data=json.loads(record["body"])
        print(data)
        sns.publish(TopicArn=SNS_TOPIC_ARN, Subject=f"New guestbook entry from {data['name']}",Message=f"{data['name']} (id {data['id']}) posted a new entry.")
        
