data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_disk" "mpc1_data_disk_01" {
  project = var.project_id
  zone    = var.disk_zone
  name    = "mpc1-data-disk-01"
}

data "google_compute_disk" "mpc2_data_disk_01" {
  project = var.project_id
  zone    = var.disk_zone
  name    = "mpc2-data-disk-01"
}

data "google_compute_disk" "mpc2_logs_disk_01" {
  project = var.project_id
  zone    = var.disk_zone
  name    = "mpc2-logs-disk-01"
}

resource "google_compute_resource_policy" "daily_snapshot_policy" {
  count   = var.create_snapshot_policy ? 1 : 0
  project = var.project_id
  name    = "${var.project_name}-daily-snapshot-policy"
  region  = var.policy_region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        start_time_in_hours = "03:00"
        duration_days       = 7
      }
    }
    retention_policy {
      max_retention_days = 7
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

data "google_compute_image" "mpc_vm_images" {
  for_each = var.vm_names_to_lookup

  project = var.project_id
  name    = "${each.key}-migrated-disk"
}

data "google_compute_image" "jumpbox_image" {
  project = var.project_id
  name    = "jumpbox-base-image"
}
