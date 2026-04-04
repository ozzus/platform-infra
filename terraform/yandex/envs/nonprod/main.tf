terraform {
  required_version = ">= 1.8.0"
}

module "platform" {
  source = "../../modules/platform"

  project_name         = "diasoft-platform"
  environment          = "nonprod"
  app_environments     = ["dev", "stage"]
  vpc_cidr             = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.10.0/24", "10.20.11.0/24"]
  private_subnet_cidrs = ["10.20.20.0/24", "10.20.21.0/24"]
  availability_zones   = ["ru-central1-a", "ru-central1-b"]
}
