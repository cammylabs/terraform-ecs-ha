import json, os
from botocore.vendored import requests
from datetime import datetime, timedelta

SLACK_WEBHOOK = os.environ['SLACK_WEBHOOK']

def send_to_slack(message):
    global SLACK_WEBHOOK

    body = json.dumps({
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": message['text']
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": "*Project:*\n"+message['app_name']
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*Region:*\n"+message['app_region']
                    },
                    {
                        "type": "mrkdwn",
                        "text": "*When:*\n"+message['event_time']
                    }
                ]
            },
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {
                            "type": "plain_text",
                            "emoji": False,
                            "text": "Open CodeDeploy"
                        },
                        "style": "primary",
                        "url": message['url']
                    }
                ]
            }
        ]
    })

    requests.post(url=SLACK_WEBHOOK, json=json.loads(body))


def handler(event, context):
    health_check = True

    message = json.loads(event['Records'][0]['Sns']['Message'])
    sns = json.dumps(event['Records'][0]['Sns'])
    timestamp = json.loads(sns)

    url = ('https://' +
           message['region'] +
           '.console.aws.amazon.com/codesuite/codedeploy/deployments/' +
           message['deploymentId'] +
           '?' + message['region'])

    text = "New message from CodeDeploy:\n*<" + url + "|New Deployment "+message['status']+" >*"

    event_time = datetime.fromisoformat(timestamp['Timestamp'][:-1]) + timedelta(hours=11)

    data = {
        'url': url,
        'text': text,
        'app_name': message['applicationName'],
        'app_region': message['region'],
        'event_time': str(event_time)
    }

    send_to_slack(data)

    if health_check is True:
        return {
            'statusCode': 200,
            'body': json.dumps('OK')}
    else:
        return {
            'statusCode': 500,
            'body': json.dumps('Something unexpected happened')}