resource "google_compute_route" "tfer--default-route-5698a55f5a20cff3" {
  description      = "Default route to the Internet."
  dest_range       = "0.0.0.0/0"
  name             = "default-route-5698a55f5a20cff3"
  network          = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  next_hop_gateway = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/gateways/default-internet-gateway"
  priority         = "1000"
  project          = "cal-itp-data-infra"
}
