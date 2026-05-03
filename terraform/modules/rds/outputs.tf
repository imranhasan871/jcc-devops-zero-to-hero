output "endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "port" {
  description = "RDS port number"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}
