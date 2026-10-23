resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name}-deploy-artifacts-${var.aws_account_id}"
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  dynamic "rule" {
    for_each = toset(["customer/", "rider/", "admin/"])

    content {
      id     = "expire-${trimsuffix(rule.value, "/")}-builds"
      status = "Enabled"

      filter {
        prefix = rule.value
      }

      expiration {
        days = 30
      }
    }
  }
}

resource "aws_ssm_document" "deploy" {
  name            = "${local.name}-deploy"
  document_type   = "Command"
  document_format = "YAML"

  content = templatefile("${path.module}/templates/deploy-document.yaml.tftpl", {
    region = var.aws_region
    bucket = aws_s3_bucket.artifacts.bucket
  })
}

resource "aws_iam_role_policy" "deploy" {
  name = "${local.name}-deploy"
  role = data.aws_iam_role.ec2.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DeployArtifacts"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Sid      = "ListArtifacts"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.artifacts.arn
      },
      {
        Sid    = "ReadDrifySecrets"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = [
          aws_secretsmanager_secret.rabbitmq.arn,
          aws_secretsmanager_secret.redis.arn,
        ]
      },
      {
        Sid    = "RunDeployDocument"
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:document/${local.name}-deploy",
          "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:instance/*",
        ]
      },
      {
        Sid      = "ReadDeployResult"
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation"]
        Resource = "*"
      },
    ]
  })
}
