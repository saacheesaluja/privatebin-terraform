terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "privatebin-terraform-state-904869824787"
    key          = "privatebin/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}