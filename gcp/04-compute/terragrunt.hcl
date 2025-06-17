include {
  path = find_in_parent_folders()
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

data "google_project" "project" {
  project_id = var.project_id
}
EOF
}


dependency "network" {
  config_path = "../02-network"
}

dependency "storage" {
  config_path = "../03-storage"
}