terraform {
  required_version = ">= 1.8.0"
}

module "platform" {
  source = "../../modules/platform"

  project_name         = "diasoft-platform"
  environment          = "prod"
  app_environments     = ["prod"]
  vpc_cidr             = "10.30.0.0/16"
  public_subnet_cidrs  = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
  private_subnet_cidrs = ["10.30.20.0/24", "10.30.21.0/24", "10.30.22.0/24"]
  availability_zones   = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
}
