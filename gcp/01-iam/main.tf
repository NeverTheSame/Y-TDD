resource "google_service_account" "accounts" {
  for_each     = var.service_accounts
  project      = var.project_id
  account_id   = each.key
  display_name = each.value
}

# например дал сервисному аккаунту gke-deployer права на управление образами в GCR
resource "google_project_iam_member" "gke_deployer_permissions" {
  project = var.project_id
  role    = "roles/storage.admin" # можно пушить образы в GCR
  member  = "serviceAccount:${google_service_account.accounts["gke-deployer"].email}"
}

# compute-manager права на просмотр машины для сервисного аккаунта
resource "google_project_iam_member" "compute_viewer_permissions" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.accounts["compute-manager"].email}"
}