resource "google_compute_subnetwork" "tfer--default" {
  ip_cidr_range              = "10.138.0.0/20"
  name                       = "default"
  network                    = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  private_ip_google_access   = "false"
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  project                    = "cal-itp-data-infra-staging"
  purpose                    = "PRIVATE"
  region                     = "us-west1"
  stack_type                 = "IPV4_ONLY"
}
