# Dev environment — uses module pattern from class-32.
# Small instance sizes, minimal storage, no deletion protection.
# Remote state: S3 + DynamoDB locking.
# To initialize: terraform init -backend-config=../../backend-dev.hcl
# where backend-dev.hcl contains:
#   bucket         = "jcc-terraform-state"
#   key            = "dev/terraform.tfstate"
#   region         = "us-east-1"
#   dynamodb_table = "jcc-terraform-locks"
#   encrypt        = true

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
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  app_name    = "jcc"
  environment = "dev"
  region      = "us-east-1"
  vpc_cidr    = "10.0.0.0/16"
}

module "rds" {
  source                = "../../modules/rds"
  app_name              = "jcc"
  environment           = "dev"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  app_security_group_id = "sg-placeholder-replace-with-real-sg"
  db_password           = var.db_password
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
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
