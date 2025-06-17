resource "google_compute_instance" "mpc_vms" {
  for_each = var.vm_list # список mpc машин для миграции

  project      = var.project_id
  zone         = "us-west1-a"
  name         = each.key
  machine_type = each.value.machine_type

  boot_disk {
    initialize_params {
      image = data.terraform_remote_state.images.outputs.migrated_image_self_links[each.key]
    }
  }

  network_interface {
    network    = data.terraform_remote_state.network.outputs.vpc_self_link
    subnetwork = data.terraform_remote_state.network.outputs.subnet_self_link
  }
}

resource "google_compute_instance" "jumpbox_vm" {
  project      = var.project_id
  zone         = "us-west1-a"
  name         = "jumpbox"
  machine_type = "e2-mini-2"

  boot_disk {
    initialize_params {
      image = data.terraform_remote_state.images.outputs.jumpbox_image_self_link
    }
  }

  network_interface {
    network    = data.terraform_remote_state.network.outputs.vpc_self_link
    subnetwork = data.terraform_remote_state.network.outputs.subnet_self_link
  }
}

