output "bucket_names" {
  description = "Nomes dos buckets S3 por ambiente e camada"
  value       = { for k, v in aws_s3_bucket.data : k => v.id }
}

output "bucket_arns" {
  description = "ARNs dos buckets S3 por ambiente e camada"
  value       = { for k, v in aws_s3_bucket.data : k => v.arn }
}
