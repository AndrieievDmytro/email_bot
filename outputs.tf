# outputs.tf

output "custom_api_endpoint" {
  description = "The fully configured custom domain URL for your API."
  value       = "https://${var.subdomain}.${var.root_domain_name}"
}

output "default_api_endpoint" {
  description = "The default, randomly generated URL for the API Gateway (can be used for testing)."
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}

output "lambda_function_name" {
  description = "The name of the created Lambda function."
  value       = aws_lambda_function.email_sender.function_name
}

output "template_s3_bucket_name" {
  description = "The name of the S3 bucket for email templates."
  value       = aws_s3_bucket.template_bucket.id
}
