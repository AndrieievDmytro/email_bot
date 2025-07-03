# --- Resources for the Email Sender Function ---
resource "aws_lambda_function" "email_sender" {
  function_name    = "${var.function_name}-sender-${random_string.suffix.result}"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
      SES_FROM_EMAIL  = var.ses_email_from
      TEMPLATE_BUCKET = aws_s3_bucket.template_bucket.id
      # The AWS_REGION variable is reserved and has been removed.
    }
  }
  tags = { Name = "EmailSenderLambda" }
}

# --- Resources for the Identity Verifier Function ---
resource "aws_lambda_function" "identity_verifier" {
  function_name    = "${var.function_name}-verifier-${random_string.suffix.result}"
  role             = aws_iam_role.verifier_exec_role.arn
  handler          = "verify_identity_function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.verifier_zip.output_path
  source_code_hash = data.archive_file.verifier_zip.output_base64sha256
  environment {
    variables = {
      # The AWS_REGION variable is reserved and has been removed.
    }
  }
  tags = { Name = "IdentityVerifierLambda" }
}

# --- API Gateway Resources ---
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "${var.function_name}-api-${random_string.suffix.result}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.email_sender.invoke_arn
}

resource "aws_apigatewayv2_integration" "verifier_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.identity_verifier.invoke_arn
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /send-email"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "verifier_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "POST /verify-identity"
  target    = "integrations/${aws_apigatewayv2_integration.verifier_integration.id}"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_sender.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "verifier_api_permission" {
  statement_id  = "AllowAPIGatewayInvokeVerifier"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.identity_verifier.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}


# --- Custom Domain Resources ---

resource "aws_apigatewayv2_domain_name" "api_custom_domain" {
  domain_name = "${var.subdomain}.${var.root_domain_name}"
  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  # Add this depends_on block to wait for the certificate to be ready.
  depends_on = [aws_acm_certificate_validation.api_cert_validation]
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  domain_name = aws_apigatewayv2_domain_name.api_custom_domain.id
  stage       = aws_apigatewayv2_stage.api_stage.id
}

# --- Automated DNS Record for Custom Domain ---

resource "aws_route53_record" "api_dns" {
  name    = aws_apigatewayv2_domain_name.api_custom_domain.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.primary.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api_custom_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_custom_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
