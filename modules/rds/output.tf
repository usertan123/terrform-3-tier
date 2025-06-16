output "rds_username" {
  value     = data.external.rds_credentials.result.username
  sensitive = true
}

output "rds_password" {
  value     = data.external.rds_credentials.result.password
  sensitive = true
}

output "rds_endpoint" {
  value = aws_db_instance.database.endpoint
}