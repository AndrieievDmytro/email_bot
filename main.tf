# main.tf

provider "aws" {
  region = var.aws_region
}

# Used to create unique names for resources
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Archive the email sender lambda function code
data "archive_file" "lambda_zip" {
  type                    = "zip"
  source_content          = file("lambda_function.py")
  source_content_filename = "lambda_function.py"
  output_path             = "${path.module}/lambda_function.zip"
}

# Archive the identity verifier lambda function code
data "archive_file" "verifier_zip" {
  type                    = "zip"
  source_content          = file("verify_identity_function.py")
  source_content_filename = "verify_identity_function.py"
  output_path             = "${path.module}/verify_identity_function.zip"
}
