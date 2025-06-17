remote_state {
  backend = "gcs"
  config = {
    bucket  = "company-tfstate-bucket"
    prefix  = "gcp/${path_relative_to_include()}/terraform.tfstate"
    project = "gcp-project-id"
  }
}

generate "provider" {
  path      = "provider.tf"
  contents = <<EOF
provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file("path/to/service-account-key.json")
}

inputs = {
  project_id = "gcp-project-id"
  region     = "us-west1"
}