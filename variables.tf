variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "privatebin"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "assignment"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ip" {
  description = "Public IP allowed to access PrivateBin"
  type        = string
  default     = "182.77.70.94/32"
}