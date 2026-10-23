output "vpc_id" {
  value = aws_vpc.main.id
}

output "app_instance_id" {
  value = aws_instance.app.id
}

output "app_public_ip" {
  description = "Instance address. Public traffic should use the load balancer, not this IP."
  value       = aws_eip.app.public_ip
}

output "alb_dns_name" {
  description = "Create CNAME or alias records for the three prod domains to this name."
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  value = aws_lb.app.zone_id
}

output "certificate_arn" {
  description = "Issued wildcard certificate attached to the HTTPS listener."
  value       = data.aws_acm_certificate.app.arn
}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "deploy_document" {
  value = aws_ssm_document.deploy.name
}

output "postgres_endpoint" {
  value = aws_db_instance.postgres.address
}

output "app_env_objects" {
  description = "Private S3 objects containing each backend .env file."
  value       = { for k, o in aws_s3_object.app_env : k => "s3://${o.bucket}/${o.key}" }
}

output "secret_names" {
  value = {
    postgres = aws_secretsmanager_secret.postgres.name
    redis    = aws_secretsmanager_secret.redis.name
    rabbitmq = aws_secretsmanager_secret.rabbitmq.name
  }
}
