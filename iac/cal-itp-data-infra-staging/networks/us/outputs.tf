output "google_compute_network_tfer--default_self_link" {
  value = google_compute_network.tfer--default.self_link
}

output "google_compute_network_static-load-balancer-address_id" {
  value = google_compute_global_address.static-load-balancer-address.id
}

output "google_compute_address_enghouse-sftp-address_ip" {
  value = google_compute_address.enghouse-sftp-address.address
}
