output "google_compute_firewall_tfer--default-allow-icmp_self_link" {
  value = "${google_compute_firewall.tfer--default-allow-icmp.self_link}"
}

output "google_compute_firewall_tfer--default-allow-internal_self_link" {
  value = "${google_compute_firewall.tfer--default-allow-internal.self_link}"
}

output "google_compute_firewall_tfer--default-allow-rdp_self_link" {
  value = "${google_compute_firewall.tfer--default-allow-rdp.self_link}"
}

output "google_compute_firewall_tfer--default-allow-ssh_self_link" {
  value = "${google_compute_firewall.tfer--default-allow-ssh.self_link}"
}
