import boto3
import requests
import os
from datetime import datetime, timedelta, timezone


def lambda_handler(event, context):
    dynamo_table_name = os.environ['DYNAMODB_TABLE_NAME']
    gitlab_access_token_name = os.environ['GITLAB_REPOSITORY_ACCESSTOKEN_NAME']
    gitlab_api_url = os.environ['GITLAB_REPOSITORY_URL']
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(dynamo_table_name)

    ssm = boto3.client('ssm')
    parameter = ssm.get_parameter(Name=gitlab_access_token_name, WithDecryption=True)
    gitlab_access_token = parameter['Parameter']['Value']

    headers = {'Authorization': f'Bearer {gitlab_access_token}'}
    response = requests.get(gitlab_api_url, headers=headers)
    commits = response.json()

    for commit in commits:
        table.put_item(
            Item={
                'commit_id': commit['id'],
                'message': commit['message'],
                'author_name': commit['author_name'],
                'committed_date': commit['committed_date']
            }
        )

    response = table.scan()
    items = response['Items']
    sorted_items = sorted(items, key=lambda x: x['committed_date'], reverse=True)

    if sorted_items:
        latest_item = sorted_items[0]
        latest_commit_date = datetime.strptime(latest_item['committed_date'], '%Y-%m-%dT%H:%M:%S.%f%z')
        current_time = datetime.now(timezone.utc)

        if latest_commit_date.date() < (current_time - timedelta(days=1)).date():
            sns = boto3.client('sns')
            message = f"最新のコミットは {latest_commit_date.strftime('%Y-%m-%d')} に行われました: {latest_item['message']}"
            sns.publish(TopicArn=sns_topic_arn, Message=message)
            print("メールが送信されました。")
    else:
        print("データが見つかりません。")

    print("コミット情報をDynamoDBに保存しました。")

    return {
        'statusCode': 200,
        'body': 'コミット情報をDynamoDBに保存しました。'
    }
