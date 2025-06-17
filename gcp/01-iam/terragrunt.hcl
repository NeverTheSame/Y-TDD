include {
  # не дублирую настройки бэкенда в каждом модуле
  path = find_in_parent_folders()
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "google" {
  project = "${dependency.prod_project.outputs.prod_project_id}"
  region  = "us-west1"
}
EOF
}

generate "variables" {
  path      = "variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "org_id" {
  description = "The organization ID"
  type        = string
}

variable "folder_name" {
  description = "The production folder name"
  type        = list(string)
}

variable "billing_id" {
  description = "The billing ID"
  type        = string
}

variable "prod_project_apis" {
  type = map(string)
}
EOF
}

generate "data_tf" {
  path      = "data.tf"
  if_exists = "overwrite"
  contents  = <<EOF
data "terraform_remote_state" "org_secrets_remote_data" {
  backend = "gcs"

  config = {
    bucket = "infrastructure"
    prefix = "02-org-secrets"
  }
}

data "terraform_remote_state" "production_project_remote_data" {
  backend = "gcs"

  config = {
    bucket = "infrastructure"
    prefix = "prod/01-prod-projects"
  }
}

data "terraform_remote_state" "production_network_remote_data" {
  backend = "gcs"

  config = {
    bucket = "infrastructure"
    prefix = "prod/03-prod-network-firewall"
  }
}
EOF
}

inputs = {
  ssh_user_kirill     = "kirill"
  ssh_user_alex       = "alex"
  nginx_cert_key_path = "nginx_certs/cert.pem"
  nginx_key_path      = "nginx_certs/key.pem"
}

dependency "prod_project" {
  config_path = "../01-prod-projects"
}