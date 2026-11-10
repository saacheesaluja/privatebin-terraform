output "notes_bucket_name" {
  description = "Name of the S3 bucket storing PrivateBin notes"
  value       = aws_s3_bucket.privatebin_notes.bucket
}

output "ec2_instance_id" {
  description = "ID of the PrivateBin EC2 instance"
  value       = aws_instance.privatebin.id
}
