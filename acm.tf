# acm.tf

# Configure a second provider for the us-east-1 region, which is required for API Gateway certificates.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Find the Route 53 hosted zone for your main domain.
data "aws_route53_zone" "primary" {
  name = var.root_domain_name
}

# Create the ACM certificate for your subdomain (e.g., api.yourdomain.com)
resource "aws_acm_certificate" "api_cert" {
  # This resource must be created in us-east-1
  provider = aws.us_east_1

  domain_name       = "${var.subdomain}.${var.root_domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create the DNS record required to validate the certificate.
# Terraform will automatically add this to your Route 53 hosted zone.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.zone_id
}

# This resource tells Terraform to wait until the certificate has been successfully validated by AWS.
resource "aws_acm_certificate_validation" "api_cert_validation" {
  # This resource must be created in us-east-1
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
