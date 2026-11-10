variable "project_name" {
  description = "Project identifier"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "allowed_ip" {
  description = "Public IP allowed to access PrivateBin"
  type        = string
}

variable "ami_id" {
  description = "AMI ID used by the existing PrivateBin EC2 instance"
  type        = string
}
