output "SSH_ip" {
  value = aws_eip.app_eip.public_ip
}

output "db_ep" {
  value     = aws_db_instance.app_db.address
  sensitive = true
}

output "bucket" {
  value = aws_s3_bucket.internal_bucket.id
}

output "app_url" {
  value = "http://${aws_eip.app_eip.public_ip}:3000"
}
