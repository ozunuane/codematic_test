output "project" {
  value = var.gcp_project_id
}

output "network" {
  value = google_compute_network.codematic
}



output "name" {
  value = google_compute_network.codematic.name
}

output "private_subnet" {
  value = google_compute_subnetwork.private
}

output "public_subnet" {
  value = google_compute_subnetwork.public
}
output "public_subnet_name" {
  value = google_compute_subnetwork.public.name
}

output "private_subnet_name" {
  value = google_compute_subnetwork.private.name
}


output "nat_ip_address" {
  value = google_compute_address.nat-ip.address
}
