include {
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

output "network_name" {
  description = "The name of the created VPC network."
  value       = google_compute_network.vpc_network.name
}

output "network_self_link" {
  description = "The self_link of the created VPC network."
  value       = google_compute_network.vpc_network.self_link
}

output "subnet_name" {
  description = "The name of the created subnetwork."
  value       = google_compute_subnetwork.vpc_subnet.name
}

output "subnet_self_link" {
  description = "The self_link of the created subnetwork."
  value       = google_compute_subnetwork.vpc_subnet.self_link
}

output "subnet_ip_cidr_range" {
  description = "The IP CIDR range of the created subnetwork."
  value       = google_compute_subnetwork.vpc_subnet.ip_cidr_range
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
    network_name = "prod-network"
}
