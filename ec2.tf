data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Existing role in this account; both servers use its instance profile.
data "aws_iam_role" "ec2" {
  name = var.ec2_role_name
}

data "aws_iam_instance_profile" "ec2" {
  name = var.ec2_instance_profile_name
}

resource "aws_security_group" "app" {
  name_prefix = "${local.name}-app-"
  description = "HTTP from the load balancer to Nginx"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from the load balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.public["public_a"].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = data.aws_iam_instance_profile.ec2.name

  user_data = templatefile("${path.module}/templates/app-user-data.sh.tftpl", {
    region             = var.aws_region
    rabbitmq_secret_id = aws_secretsmanager_secret.rabbitmq.name
    redis_secret_id    = aws_secretsmanager_secret.redis.name
    node_version       = var.node_version
    api_domain         = var.api_domain
    rider_domain       = var.rider_domain
    admin_domain       = var.admin_domain
  })

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name}-app"
    Role = "app"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }

  depends_on = [
    aws_iam_role_policy.deploy,
    aws_secretsmanager_secret_version.rabbitmq,
  ]
}

resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id

  tags = {
    Name = "${local.name}-app"
  }
}
