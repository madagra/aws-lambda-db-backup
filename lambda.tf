# the S3 bucket where the OpenSearch snapshots
# are going to be stored (daily, incrementally)
resource "aws_s3_bucket" "es_snapshot_repo" {
  bucket = "my-es-snapshot-repo-agk214"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name        = "open_search_backup_bucket"
    Terraform   = "true"
  }

}

# security group for the Lambda function
# which only allows egress connections
resource "aws_security_group" "es_snapshot_sg" {
  name   = "es-snapshot-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "open_search_backup_sg"
    Terraform   = "true"
  }

}

module "lambda" {

  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda-es-snapshot-${var.environment}"
  description   = "OpenSearch domain snapshot backup"
  handler       = "es_snapshot_handler.lambda_handler"
  runtime       = "python3.9"

  attach_policy = true
  policy        = aws_iam_policy.es_snapshot_passrole_policy.arn

  source_path = [
    "${path.module}/lambda/es_snapshot_handler.py",
    {
      pip_requirements = "${path.module}/lambda/requirements.txt"
    }
  ]

  vpc_subnet_ids         = var.vpc_subnets
  vpc_security_group_ids = [aws_security_group.es_snapshot_sg]
  attach_network_policy  = true

  environment_variables = {
    DOMAIN_HOST          = var.es_domain_host
    DOMAIN_REGION        = var.region
    DOMAIN_REPO_NAME     = "my-snapshot-repo"
    DOMAIN_SNAPSHOT_NAME = "my-snapshot"
    DOMAIN_REPO_S3BUCKET = aws_s3_bucket.es_snapshot_repo.id
  }

  tags = {
    Name = "open_search_backup_lambda"
    Terraform   = "true"
  }

}

resource "aws_cloudwatch_event_rule" "cron_schedule" {
  name                = replace("${module.lambda.this_lambda_function_name}-cron_schedule", "/(.{0,64}).*/", "$1")
  description         = "This event will run according to a schedule for Lambda ${module.lambda.this_lambda_function_name}"
  schedule_expression = var.lambda_cron_schedule
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule = aws_cloudwatch_event_rule.cron_schedule.name
  arn  = module.lambda.this_lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.this_lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_schedule.arn
}
