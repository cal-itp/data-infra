resource "google_compute_network" "tfer--default" {
  auto_create_subnetworks                   = "true"
  bgp_always_compare_med                    = "false"
  bgp_best_path_selection_mode              = "LEGACY"
  delete_default_routes_on_create           = "false"
  description                               = "Default network for the project"
  enable_ula_internal_ipv6                  = "false"
  mtu                                       = "0"
  name                                      = "default"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  project                                   = "cal-itp-data-infra"
  routing_mode                              = "REGIONAL"
}
