# terraform.tfvars

aws_region     = "your_aws_region"
function_name  = "my-email-sender"
root_domain_name = "yourdomain.com"
subdomain        = "api"  # Subdomain for the email API, e.g., api.yourdomain.com
ses_email_from   = "your_verified_sender_email" # Email address verified in SES 