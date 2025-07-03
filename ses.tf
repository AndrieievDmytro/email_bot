# ses.tf

# This assumes you have already verified a domain or email address in SES.
# Terraform can manage domain verification, but email verification is a manual process.

resource "aws_ses_email_identity" "email_identity" {
  email = var.ses_email_from
}
