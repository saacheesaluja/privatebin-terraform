output "notes_bucket_name" {
  description = "Name of the S3 bucket storing PrivateBin notes"
  value       = module.privatebin.notes_bucket_name
}

output "ec2_instance_id" {
  description = "ID of the PrivateBin EC2 instance"
  value       = module.privatebin.ec2_instance_id
}

output "ssm_port_forward_command" {
  description = "Command to access PrivateBin locally through Session Manager"
  value       = "aws ssm start-session --target ${module.privatebin.ec2_instance_id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"3344\"],\"localPortNumber\":[\"3344\"]}' --region ${var.aws_region}"
}
