resource "google_compute_address" "bastion" {
  name    = "${var.app_name}-bastion-public-ip"
  project = var.project
  region  = var.region
}

resource "google_compute_firewall" "bastion_access" {
  name          = "${var.app_name}-bastion-access"
  network       = var.network.self_link
  project       = var.project
  source_ranges = ["0.0.0.0/0"] # Allows traffic from any IP

  allow {
    protocol = "tcp"
    ports    = ["22", "80", ]
  }

  target_tags = ["allow-ssh"]
}
