output "bucket_name" {
  value = minio_s3_bucket.cloud_vault_bucket.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.users.name
}
