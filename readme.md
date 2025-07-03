

```
# Fully Automated AWS Email API with Terraform

This project contains a complete, production-ready Terraform configuration to deploy a serverless email API on AWS. It automatically sets up a custom domain with an SSL certificate, creates Lambda functions for sending templated emails and verifying new recipients, and configures all the necessary security and permissions.

## Features

-   **Fully Automated:** From certificate creation to DNS setup, the entire infrastructure is managed by Terraform. No manual steps in the AWS console are required.
-   **Custom Domain:** Automatically configures a professional API endpoint (e.g., `https://api.yourdomain.com`) using your domain managed in AWS Route 53.
-   **Serverless & Scalable**: Uses AWS Lambda and API Gateway, so you only pay for what you use and it scales automatically.
-   **Template-Driven Emails**: The email sending function uses a template defined directly in the Terraform code, which can be easily modified.
-   **Automated Recipient Verification**: Includes a `/verify-identity` endpoint to programmatically start the SES email verification process for new users, which is essential for deliverability and for using the service while in the SES sandbox.
-   **Secure by Design**: Uses IAM roles with least-privilege permissions for each function and keeps the S3 template bucket private.

## Prerequisites

1.  **Terraform Installed**: [Download Terraform](https://www.terraform.io/downloads.html)
2.  **AWS Account**: An active AWS account.
3.  **AWS CLI Configured**: Your AWS credentials should be configured locally (`aws configure`).
4.  **Domain in Route 53**: Your root domain (e.g., `yourdomain.com`) **must** be managed as a Public Hosted Zone in AWS Route 53. This is required for the automation to work.
5.  **SES Production Access (Recommended)**: For sending emails to any unverified recipient, your SES account must be out of the sandbox. You can request production access from the SES Account Dashboard in the AWS Console.

## Project File Structure

Your project directory should contain the following files:


```

**. ├── main.tf ├── variables.tf ├── iam.tf ├── lambda.tf ├── ses.tf ├── s3.tf ├── acm.tf # New file for certificate management ├── outputs.tf ├── lambda_function.py └── verify_identity_function.py # New file for verification logic**

```

## How to Use

### 1. Configure Variables

Create a `terraform.tfvars` file. This is where you will set your specific domain and email details.

```hcl
# terraform.tfvars

aws_region       = "ca-central-1" # Your preferred AWS region
root_domain_name = "yourdomain.com"
subdomain        = "api" # The subdomain for your API, e.g., api.yourdomain.com
ses_email_from   = "your-verified-sender@yourdomain.com"

```

### 2. Deploy the Infrastructure

1. **Initialize Terraform:** *This command downloads the necessary AWS provider plugins.*
   ```
   terraform init

   ```
2. **Plan the deployment:** *This command shows you everything that will be created without making any changes.*
   ```
   terraform plan

   ```
3. **Apply the changes:** *This command builds all the resources in your AWS account. It may take a few minutes, especially while it waits for the SSL certificate to be validated and issued.*
   ```
   terraform apply

   ```

### 3. Using Your New API

**After the deployment is complete, Terraform will output your** `<span class="selected">custom_api_endpoint</span>`. You can now use this URL to interact with your service.

#### To Verify a New Email Address

**Send a** `<span class="selected">POST</span>` **request to the** `<span class="selected">/verify-identity</span>` **endpoint. The recipient will receive an email from AWS and must click the link inside to complete verification.**

```
curl -X POST \
  '[https://api.yourdomain.com/verify-identity](https://api.yourdomain.com/verify-identity)' \
  -H "Content-Type: application/json" \
  -d '{
    "email": "new.user.to.verify@example.com"
  }'

```

#### To Send a Templated Email

**Send a** `<span class="selected">POST</span>` **request to the** `<span class="selected">/send-email</span>` **endpoint. This will only work if the recipient's address has been verified (or if your account is out of the sandbox).**

```
curl -X POST \
  '[https://api.yourdomain.com/send-email](https://api.yourdomain.com/send-email)' \
  -H "Content-Type: application/json" \
  -d '{
    "to_email": "verified.recipient@example.com",
    "subject": "A Test from Your Custom Domain",
    "template_key": "clientA/welcome_template.html",
    "template_data": {
      "name": "Valuable Client",
      "company": "Your Company Name"
    }
  }'

```

## Cleaning Up

**To completely remove all the resources created by this project from your AWS account, run the following command:**

```
terraform destroy
```
