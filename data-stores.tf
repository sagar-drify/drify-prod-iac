resource "random_password" "postgres" {
  length  = 32
  special = false
}

resource "random_password" "redis_auth_token" {
  length  = 40
  special = false
}

resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.name}-postgres-"
  description = "PostgreSQL access from the application server only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from the application server"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${local.name}-postgres"
  subnet_ids = values(aws_subnet.private)[*].id
}

resource "aws_db_instance" "postgres" {
  identifier                 = "${local.name}-postgres"
  allocated_storage          = 20
  max_allocated_storage      = 100
  storage_type               = "gp3"
  engine                     = "postgres"
  engine_version             = var.postgres_version
  instance_class             = var.postgres_instance_class
  db_name                    = var.postgres_database_name
  username                   = var.postgres_master_username
  password                   = random_password.postgres.result
  port                       = 5432
  db_subnet_group_name       = aws_db_subnet_group.postgres.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  publicly_accessible        = false
  multi_az                   = false
  storage_encrypted          = true
  backup_retention_period    = 7
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${local.name}-postgres-final"
  deletion_protection        = var.deletion_protection
  auto_minor_version_upgrade = true
}
