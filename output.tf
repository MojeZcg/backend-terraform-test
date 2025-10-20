output "public_ip" {
  value = aws_instance.app_instance.public_ip
}

output "db_endpoint" {
  value     = aws_db_instance.app_db.address
  sensitive = true
}

output "bucket_name" {
  value = aws_s3_bucket.internal_bucket.id
}

output "eip_address" {
  value = aws_eip.app_eip.public_ip
}
