# RDS module — creates a PostgreSQL instance in private subnets with a
# security group that only accepts connections from the application tier.

resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.environment}-rds-sg"
  description = "PostgreSQL access from app tier only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-${var.environment}-rds-sg" }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.app_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = { Name = "${var.app_name}-${var.environment}-db-subnet-group" }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.app_name}-${var.environment}-postgres"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_encrypted      = true
  db_name                = "jccdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  backup_retention_period = 7
  skip_final_snapshot    = true
  deletion_protection    = false
  tags                   = { Name = "${var.app_name}-${var.environment}-postgres" }
}
