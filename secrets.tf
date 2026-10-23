resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "random_password" "jwt_refresh" {
  length  = 64
  special = false
}

resource "random_password" "internal_service_token" {
  length  = 64
  special = false
}

resource "random_password" "rider_jwt" {
  length  = 64
  special = false
}

resource "random_password" "vendor_jwt" {
  length  = 64
  special = false
}

resource "random_password" "socket_adapter_key" {
  length  = 32
  special = false
}

resource "random_password" "admin_session" {
  length  = 64
  special = false
}

locals {
  postgres_url_base = "postgresql://${var.postgres_master_username}:${random_password.postgres.result}@${aws_db_instance.postgres.address}:5432/${var.postgres_database_name}"
  redis_url         = "redis://:${random_password.redis_auth_token.result}@127.0.0.1:6379"
  rabbitmq_url      = "amqp://drifyv2:${random_password.rabbitmq.result}@127.0.0.1:5672"

  shared_env = {
    jwt_secret             = random_password.jwt.result
    jwt_refresh_secret     = random_password.jwt_refresh.result
    internal_service_token = random_password.internal_service_token.result
    rider_jwt_secret       = random_password.rider_jwt.result
    vendor_jwt_secret      = random_password.vendor_jwt.result
    socket_adapter_key     = random_password.socket_adapter_key.result
    admin_session_secret   = random_password.admin_session.result
    postgres_url_base      = local.postgres_url_base
    postgres_host          = aws_db_instance.postgres.address
    postgres_user          = var.postgres_master_username
    postgres_password      = random_password.postgres.result
    postgres_database      = var.postgres_database_name
    redis_url              = local.redis_url
    rabbitmq_url           = local.rabbitmq_url
    rabbitmq_password      = random_password.rabbitmq.result
    aws_region             = var.aws_region
    api_domain             = var.api_domain
    rider_domain           = var.rider_domain
    admin_domain           = var.admin_domain
  }
}

resource "aws_secretsmanager_secret" "postgres" {
  name                    = "${local.name}/postgres"
  description             = "PostgreSQL master credentials for ${local.name}"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id

  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = 5432
    dbname   = var.postgres_database_name
    username = var.postgres_master_username
    password = random_password.postgres.result
  })
}

resource "aws_secretsmanager_secret" "redis" {
  name                    = "${local.name}/redis"
  description             = "Password for the Redis container on the application server"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id

  secret_string = jsonencode({
    engine   = "redis"
    host     = "127.0.0.1"
    port     = 6379
    password = random_password.redis_auth_token.result
    url      = local.redis_url
  })
}

resource "aws_secretsmanager_secret" "rabbitmq" {
  name                    = "${local.name}/rabbitmq"
  description             = "RabbitMQ credentials for the broker on the application server"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "rabbitmq" {
  secret_id = aws_secretsmanager_secret.rabbitmq.id

  secret_string = jsonencode({
    username = "drifyv2"
    password = random_password.rabbitmq.result
    url      = local.rabbitmq_url
  })
}

# Full .env for each backend. Terraform uploads the infrastructure values once.
# Later edits in S3, including third-party keys, are kept.
resource "aws_s3_object" "app_env" {
  for_each = toset(["customer", "rider", "admin"])

  bucket                 = aws_s3_bucket.artifacts.id
  key                    = "env/${each.key}.env"
  content                = templatefile("${path.module}/templates/${each.key}.env.tftpl", local.shared_env)
  content_type           = "text/plain"
  server_side_encryption = "AES256"

  lifecycle {
    ignore_changes = [content, etag, tags, tags_all]
  }
}
