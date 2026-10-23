variable "aws_account_id" {
  description = "The only AWS account Terraform may modify."
  type        = string
  default     = "068657603153"
}

variable "aws_region" {
  description = "AWS region. It must offer at least two available AZs."
  type        = string
  default     = "us-west-1"
}

variable "project_name" {
  description = "Short project identifier used in resource names."
  type        = string
  default     = "drify"
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "prod"
}

variable "ec2_role_name" {
  description = "Existing IAM role attached to both servers."
  type        = string
  default     = "ssm-iam-role"
}

variable "ec2_instance_profile_name" {
  description = "Existing instance profile for ec2_role_name."
  type        = string
  default     = "ssm-iam-role"
}

variable "app_instance_type" {
  description = "Runs Nginx, the Node apps, Redis, RabbitMQ, and the GitHub Actions runner."
  type        = string
  default     = "t3.large"
}

variable "node_version" {
  description = "Node.js version on the application server; the customer monorepo needs >= 22.12."
  type        = string
  default     = "22.20.0"
}

variable "api_domain" {
  description = "Public host for the customer api-gateway."
  type        = string
  default     = "prod-api.drify.com"
}

variable "rider_domain" {
  description = "Public host for the rider and merchant backend."
  type        = string
  default     = "prod-rider.drify.com"
}

variable "admin_domain" {
  description = "Public host for the admin backend."
  type        = string
  default     = "prod-admin.drify.com"
}

variable "postgres_instance_class" {
  description = "RDS instance class. Use db.t3.small or db.t3.micro."
  type        = string
  default     = "db.t3.small"

  validation {
    condition     = contains(["db.t3.small", "db.t3.micro"], var.postgres_instance_class)
    error_message = "postgres_instance_class must be db.t3.small or db.t3.micro."
  }
}

variable "postgres_version" {
  description = "PostgreSQL engine version supported by RDS in the chosen region."
  type        = string
  default     = "16.15"
}

variable "postgres_database_name" {
  description = "The one database shared by all three backends."
  type        = string
  default     = "drifyv2"
}

variable "postgres_master_username" {
  type    = string
  default = "drifyadmin"
}

variable "skip_final_snapshot" {
  description = "Set false in persistent environments to require a final RDS snapshot at destroy."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevents accidental RDS deletion."
  type        = bool
  default     = true
}
