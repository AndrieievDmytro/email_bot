# s3.tf

# Create the S3 bucket
resource "aws_s3_bucket" "template_bucket" {
  bucket = var.template_bucket_name != "" ? var.template_bucket_name : "${var.function_name}-templates-${random_string.suffix.result}"
}

# Configure versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "template_bucket_versioning" {
  bucket = aws_s3_bucket.template_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "template_bucket_pab" {
  bucket = aws_s3_bucket.template_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Upload the email template with content defined directly in the code
resource "aws_s3_object" "example_template" {
  bucket = aws_s3_bucket.template_bucket.id
  key    = "clientA/welcome_template.html" # The path for the template in S3

  # Using a heredoc to define the HTML content in-line
  content = <<-EOT
<!DOCTYPE html>
<html>
<head>
<title>Welcome!</title>
</head>
<body>
  <h1>Hi {{name}}!</h1>
  <p>Welcome to {{company}}. We are excited to have you on board.</p>
</body>
</html>
EOT

  # When using content directly, you also need to set the content type
  content_type = "text/html"

  # The etag should now hash the content string itself to detect changes
  etag = md5(<<-EOT
<!DOCTYPE html>
<html>
<head>
<title>Welcome!</title>
</head>
<body>
  <h1>Hi {{name}}!</h1>
  <p>Welcome to {{company}}. We are excited to have you on board.</p>
</body>
</html>
EOT
)
}
