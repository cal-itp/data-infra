resource "google_container_cluster" "nginx-staging" {
  name     = "nginx-staging"
  location = "us-west1"
  project  = "cal-itp-data-infra-staging"

  enable_autopilot = true

  network = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link

  deletion_protection = false
}
