# Root Terraform configuration.
# For class-31 standalone exercises use this file with the local backend below.
# For multi-environment production use, see terraform/environments/{dev,production}/
# which use the module pattern and S3 remote backend introduced in class-32.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── S3 remote backend (class-32+) ─────────────────────────────
  # Prerequisites (create once, before terraform init):
  #   aws s3api create-bucket --bucket jcc-terraform-state --region us-east-1
  #   aws s3api put-bucket-versioning --bucket jcc-terraform-state \
  #     --versioning-configuration Status=Enabled
  #   aws dynamodb create-table --table-name jcc-terraform-locks \
  #     --attribute-definitions AttributeName=LockID,AttributeType=S \
  #     --key-schema AttributeName=LockID,KeyType=HASH \
  #     --billing-mode PAY_PER_REQUEST
  #
  # Then uncomment and run: terraform init -reconfigure
  #
  # backend "s3" {
  #   bucket         = "jcc-terraform-state"
  #   key            = "root/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "jcc-terraform-locks"
  #   encrypt        = true
  # }

  # Local backend — class-31 only. Remove before using in a team.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.app_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
