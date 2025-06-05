resource "google_container_cluster" "airflow-jobs-staging" {
  name     = "airflow-jobs-staging"
  location = "us-west2"
  project  = "cal-itp-data-infra-staging"

  enable_autopilot = true

  network = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link

  deletion_protection = false
}
