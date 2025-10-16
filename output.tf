output "public_ip" {
  value = aws_instance.app_instance.public_ip
}

output "db_endpoint" {
  value     = aws_db_instance.app_db.address
  sensitive = true
}
