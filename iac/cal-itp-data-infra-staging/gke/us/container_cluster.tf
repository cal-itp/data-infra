resource "google_container_cluster" "airflow-jobs-staging" {
  name     = "airflow-jobs-staging"
  location = "us-west2"
  project  = "cal-itp-data-infra-staging"

  enable_autopilot    = true
  deletion_protection = false
  network             = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link

  secret_manager_config {
    enabled = true
  }

  workload_identity_config {
    workload_pool = "cal-itp-data-infra-staging.svc.id.goog"
  }
}

resource "google_container_cluster" "sftp-endpoints" {

  name     = "sftp-endpoints"
  location = "us-west2"
  project  = "cal-itp-data-infra-staging"

  enable_autopilot    = true
  deletion_protection = false
  network             = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link

  secret_manager_config {
    enabled = true
  }

  workload_identity_config {
    workload_pool = "cal-itp-data-infra-staging.svc.id.goog"
  }

  node_config {
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  addons_config {
    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }
}
