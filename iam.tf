data "aws_iam_policy_document" "es_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "es_snapshot_policy" {
  name        = "es_snapshot_policy"
  path        = "/"
  description = "Allow access to S3 bucket and OpenSearch domain"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
      "Action": [
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.es_snapshot_repo.id}"
      ]
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.es_snapshot_repo.id}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "es:ESHttpPut",
      "Resource": "${var.es_domain_arn}/*"
    }    
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "es_snapshot_policy_attach" {
  role       = aws_iam_role.es_snapshot_role.name
  policy_arn = aws_iam_policy.es_snapshot_policy.arn
}

resource "aws_iam_role" "es_snapshot_role" {
  assume_role_policy = data.aws_iam_policy_document.es_role_policy.json
  name               = var.snapshot_role
  tags = {
    Terraform   = "true"
  }
}

resource "aws_iam_policy" "es_snapshot_passrole_policy" {
  name        = "es_snapshot_passrole_policy"
  path        = "/"
  description = "Allow role or user to assume the snapshot role to create ES snapshots"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "${aws_iam_role.es_snapshot_role.arn}"
    }
  ]
}
EOF
}

# the user which will perform the OpenSearch snapshots
data "aws_iam_user" "user" {
  user_name = var.username
}

resource "aws_iam_user_policy_attachment" "attach_user" {
  user       = data.aws_iam_user.user.user_name
  policy_arn = aws_iam_policy.es_snapshot_passrole_policy.arn
}