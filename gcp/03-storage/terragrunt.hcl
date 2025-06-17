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

generate "variables" {
  path      = "variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "project_id" {
  description = "The GCP project ID where the disks exist."
  type        = string
}

variable "disk_zone" {
  description = "The GCP zone where the restored disks are located (e.g., 'us-central1-a'). All disks are assumed to be in the same zone for simplicity."
  type        = string
}

variable "project_name" {
  description = "A generic project name used for naming resources (e.g., 'my-app')."
  type        = string
}

variable "policy_region" {
  description = "The GCP region for the snapshot schedule policy (must contain the disk zone)."
  type        = string
}

variable "create_snapshot_policy" {
  description = "Set to true to create the daily snapshot policy. Useful for toggling resource creation."
  type        = bool
  default     = true
}
EOF
}

generate "outputs" {
  path      = "outputs.tf"
  if_exists = "overwrite"
  contents  = <<EOF
output "mpc1_data_disk_01" {
  description = "The self_link of the restored data disk on mpc1"
  value       = data.google_compute_disk.mpc1_data_disk_01.self_link
}
output "mpc2_data_disk_01" {
  description = "The self_link of the restored data disk on mpc2"
  value       = data.google_compute_disk.mpc2_data_disk_01.self_link
}
output "mpc2_logs_disk_01" {
  description = "The self_link of the restored logs disk on mpc2"
  value       = data.google_compute_disk.mpc2_logs_disk_01.self_link
}
