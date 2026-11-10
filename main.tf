module "privatebin" {
  source = "./modules/privatebin"

  project_name  = var.project_name
  environment   = var.environment
  instance_type = var.instance_type
  allowed_ip    = var.allowed_ip
  ami_id        = "ami-0516089d963059a51"
}