resource "google_compute_network" "tfer--default" {
  auto_create_subnetworks         = "true"
  delete_default_routes_on_create = "false"
  description                     = "Default network for the project"
  enable_ula_internal_ipv6        = "false"
  mtu                             = "0"
  name                            = "default"
  project                         = "cal-itp-data-infra"
  routing_mode                    = "REGIONAL"
}
