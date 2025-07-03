# lambda_function.py

import os
import boto3
import json
from botocore.exceptions import ClientError

s3 = boto3.client('s3')
ses = boto3.client('ses', region_name=os.environ.get('AWS_REGION'))

def lambda_handler(event, context):
    """
    Lambda function to send an email.
    The function is triggered by API Gateway.
    The POST request body should be a JSON with the following structure:
    {
        "to_email": "recipient@example.com",
        "subject": "Your Subject",
        "template_key": "clientA/welcome_template.html",
        "template_data": {
            "name": "John Doe",
            "company": "ACME Corp"
        }
    }
    """
    print("Received event: " + json.dumps(event, indent=2))

    try:
        # Parse the request body
        body = json.loads(event.get('body', '{}'))
        to_email = body.get('to_email')
        subject = body.get('subject')
        template_key = body.get('template_key')
        template_data = body.get('template_data', {})

        if not all([to_email, subject, template_key]):
            return {
                'statusCode': 400,
                'body': json.dumps('Missing required fields: to_email, subject, or template_key')
            }

        # Get the email template from S3
        template_object = s3.get_object(
            Bucket=os.environ['TEMPLATE_BUCKET'],
            Key=template_key
        )
        html_template = template_object['Body'].read().decode('utf-8')

        # Replace placeholders in the template
        # This is a simple substitution. For more complex logic, consider a templating library.
        html_body = html_template
        for key, value in template_data.items():
            placeholder = f"{{{{{key}}}}}" # Assumes placeholders like {{name}}
            html_body = html_body.replace(placeholder, str(value))

        # Send the email
        response = ses.send_email(
            Destination={
                'ToAddresses': [to_email],
            },
            Message={
                'Body': {
                    'Html': {
                        'Charset': 'UTF-8',
                        'Data': html_body,
                    },
                    'Text': {
                        'Charset': 'UTF-8',
                        'Data': 'This is a fallback text body.', # You can generate a text version too
                    },
                },
                'Subject': {
                    'Charset': 'UTF-8',
                    'Data': subject,
                },
            },
            Source=os.environ['SES_FROM_EMAIL'],
        )

    except ClientError as e:
        print(e.response['Error']['Message'])
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error sending email: {e.response['Error']['Message']}")
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps(f"An unexpected error occurred: {str(e)}")
        }

    print(f"Email sent! Message ID: {response['MessageId']}")
    return {
        'statusCode': 200,
        'body': json.dumps(f"Email sent successfully to {to_email}! Message ID: {response['MessageId']}")
    }
