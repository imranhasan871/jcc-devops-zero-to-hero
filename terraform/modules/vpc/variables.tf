variable "app_name" {
  description = "Application name prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region — used to derive AZ names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
