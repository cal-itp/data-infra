resource "google_container_cluster" "data-infra-apps-staging" {
  enable_autopilot = true

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = "true"
    }
  }

  database_encryption {
    state = "DECRYPTED"
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.96.0.0/14"
    services_ipv4_cidr_block = "10.100.0.0/20"
  }

  location = "us-west1"

  logging_service   = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  maintenance_policy {
    recurring_window {
      end_time   = "2023-02-16T14:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU"
      start_time = "2023-02-16T10:00:00Z"
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = "false"
    }
  }

  name               = "data-infra-apps-staging"
  network            = "projects/cal-itp-data-infra-staging/global/networks/default"

  networking_mode = "VPC_NATIVE"
  node_locations  = ["us-west1-a", "us-west1-b", "us-west1-c"]

  private_cluster_config {
    enable_private_endpoint = "false"
    enable_private_nodes    = "false"

    master_global_access_config {
      enabled = "false"
    }
  }

  project = "cal-itp-data-infra-staging"

  release_channel {
    channel = "STABLE"
  }

  service_external_ips_config {
    enabled = "true"
  }

  subnetwork = "projects/cal-itp-data-infra-staging/regions/us-west1/subnetworks/default"
}

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
