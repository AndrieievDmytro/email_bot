# verify_identity_function.py

import os
import boto3
import json

# Initialize the SES client
ses = boto3.client('ses', region_name=os.environ.get('AWS_REGION'))

def lambda_handler(event, context):
    """
    Lambda function to start the SES email identity verification process.
    Expects a POST request with a JSON body like:
    {
        "email": "new_user@example.com"
    }
    """
    print("Received event: " + json.dumps(event, indent=2))

    try:
        body = json.loads(event.get('body', '{}'))
        email_to_verify = body.get('email')

        if not email_to_verify:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Error: Missing required field "email".'})
            }

        # This API call tells SES to send a verification email to the user.
        ses.verify_email_identity(
            EmailAddress=email_to_verify
        )

        print(f"Successfully initiated verification for {email_to_verify}")
        return {
            'statusCode': 200,
            'body': json.dumps({'message': f'Verification email sent to {email_to_verify}. Please check the inbox to complete verification.'})
        }

    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'An unexpected error occurred: {str(e)}'})
        }
