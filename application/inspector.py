import boto3
import requests
import os


def lambda_handler(event, context):
    dynamo_table_name = os.environ['DYNAMODB_TABLE_NAME']
    gitlab_access_token_name = os.environ['GITLAB_REPOSITORY_ACCESSTOKEN_NAME']
    gitlab_api_url = os.environ['GITLAB_REPOSITORY_URL']

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

    print("コミット情報をDynamoDBに保存しました。")

    return {
        'statusCode': 200,
        'body': 'コミット情報をDynamoDBに保存しました。'
    }
