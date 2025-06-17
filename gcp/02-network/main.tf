resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false # подсеть создам отдельно
  routing_mode            = "REGIONAL"
  description             = "Custom VPC network for ${var.project_name} project."
    log_config {
     enable = true
     aggregation_interval = "INTERVAL_5_SEC"
     flow_sampling = 0.5
     metadata = "INCLUDE_ALL_METADATA"
    }
}

resource "google_compute_subnetwork" "vpc_subnet" {
  project       = var.project_id
  name          = var.subnet_name
  ip_cidr_range = var.subnet_ip_cidr_range
  region        = var.region
  network       = google_compute_network.vpc_network.self_link # Reference to the VPC created above
  description   = "Subnet for ${var.project_name} in ${var.region}."

}

resource "google_compute_firewall" "allow_iap_ssh" {
  project     = var.project_id
  name        = "${var.network_name}-allow-iap-ssh"
  network     = google_compute_network.vpc_network.self_link
  description = "Allow IAP for SSH to instances on the VPC network."

  source_ranges = ["35.235.240.0/20"] # IAP's external IP range

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["allow-iap-ssh"]
}

