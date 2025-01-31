resource "google_compute_subnetwork" "tfer--default" {
  ip_cidr_range            = "10.138.0.0/20"
  name                     = "default"
  network                  = "${data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link}"
  private_ip_google_access = "true"
  project                  = "cal-itp-data-infra"
  purpose                  = "PRIVATE"
  region                   = "us-west1"

  secondary_ip_range {
    ip_cidr_range = "10.100.0.0/20"
    range_name    = "gke-data-infra-apps-services-0fe1e974"
  }

  secondary_ip_range {
    ip_cidr_range = "10.96.0.0/14"
    range_name    = "gke-data-infra-apps-pods-0fe1e974"
  }

  stack_type = "IPV4_ONLY"
}
