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

output "acm_validation_records" {
  description = "Add these CNAMEs at the drify.com DNS host. The HTTPS listener stays pending until ACM sees them."
  value = {
    for dvo in aws_acm_certificate.app.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "runner_instance_id" {
  value = aws_instance.runner.id
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
