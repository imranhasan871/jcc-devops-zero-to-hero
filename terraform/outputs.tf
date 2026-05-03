output "vpc_id" {
  description = "ID of the VPC created for this environment"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the two public subnets (one per AZ)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the two private subnets (one per AZ)"
  value       = aws_subnet.private[*].id
}

output "rds_endpoint" {
  description = "Connection endpoint hostname:port for the RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "Port number for the RDS PostgreSQL instance"
  value       = aws_db_instance.postgres.port
}
