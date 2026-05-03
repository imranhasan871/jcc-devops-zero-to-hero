# Production environment — larger instances, more storage.
# Uses the same modules as dev but with production-appropriate sizing.
# Remote state stored under key "production/terraform.tfstate" — completely
# separate from dev state, so a plan in dev never touches production resources.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = "jcc"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  app_name    = "jcc"
  environment = "production"
  region      = "us-east-1"
  vpc_cidr    = "10.1.0.0/16"   # different CIDR from dev to allow VPC peering if needed
}

module "rds" {
  source                = "../../modules/rds"
  app_name              = "jcc"
  environment           = "production"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  app_security_group_id = "sg-placeholder-replace-with-real-sg"
  db_password           = var.db_password
  instance_class        = "db.t3.medium"   # 2 vCPU, 4GB RAM
  allocated_storage     = 100
}

variable "db_password" {
  type      = string
  sensitive = true
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
