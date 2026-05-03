variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment: dev, staging, or production"
  type        = string
}

variable "app_name" {
  description = "Application name prefix used in all resource names"
  type        = string
  default     = "jcc"
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
  # Never put a default here. Always pass via TF_VAR_db_password env var or
  # a secrets manager integration. The sensitive=true flag prevents this value
  # from appearing in plan output or state file diffs.
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "jccadmin"
}
