# iam.tf

# Get the current AWS region and account ID to build ARNs dynamically
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


# --- Role and Policy for the Email Sender Function ---

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.function_name}-role-${random_string.suffix.result}"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.function_name}-policy-${random_string.suffix.result}"
  description = "IAM policy for sending emails with SES, accessing templates from S3, and logging."
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = ["ses:SendEmail", "ses:SendTemplatedEmail"],
        Effect   = "Allow",
        Resource = "*" # Using "*" is the most reliable way to ensure SES sending permissions.
      },
      { Action = ["s3:GetObject"], Effect = "Allow", Resource = "${aws_s3_bucket.template_bucket.arn}/*" },
      { Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Effect = "Allow", Resource = "arn:aws:logs:*:*:*" }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


# --- Role and Policy for the Identity Verifier Function ---

resource "aws_iam_role" "verifier_exec_role" {
  name = "${var.function_name}-verifier-role-${random_string.suffix.result}"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_policy" "verifier_policy" {
  name        = "${var.function_name}-verifier-policy-${random_string.suffix.result}"
  description = "IAM policy for initiating SES email identity verification."
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = "ses:VerifyEmailIdentity",
        Effect   = "Allow",
        Resource = "*" # This action requires a wildcard resource
      },
      { Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Effect = "Allow", Resource = "arn:aws:logs:*:*:*" }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "verifier_policy_attach" {
  role       = aws_iam_role.verifier_exec_role.name
  policy_arn = aws_iam_policy.verifier_policy.arn
}
