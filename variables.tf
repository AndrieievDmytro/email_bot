# variables.tf

variable "aws_region" {
  description = "The AWS region to create resources in (e.g., us-east-1, ca-central-1)."
  type        = string
  default     = "us-east-1"
}

variable "root_domain_name" {
  description = "Your main domain name managed in Route 53 (e.g., gravellewoodworking.ca)."
  type        = string
}

variable "subdomain" {
  description = "The subdomain to use for the API (e.g., 'api')."
  type        = string
  default     = "api"
}

variable "function_name" {
  description = "The base name for the Lambda functions."
  type        = string
  default     = "email-service"
}

variable "ses_email_from" {
  description = "The verified email address to send emails from."
  type        = string
}

variable "template_bucket_name" {
  description = "The name of the S3 bucket for email templates. Must be globally unique."
  type        = string
  default     = "" # If empty, a unique name will be generated
}
