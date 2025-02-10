resource "google_container_cluster" "tfer--data-infra-apps" {
  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = "true"
    }

    network_policy_config {
      disabled = "false"
    }
  }

  cluster_autoscaling {
    autoscaling_profile = "BALANCED"
    enabled             = "false"
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.96.0.0/14"
    services_ipv4_cidr_block = "10.100.0.0/20"
    stack_type               = "IPV4"
  }

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = "false"
      endpoint               = "gke-0fe1e974c7ae431b8906cfb4b50cc4218cb1-1005246706141.us-west1.gke.goog"
    }
  }

  database_encryption {
    state = "DECRYPTED"
  }

  default_max_pods_per_node                = "110"
  deletion_protection                      = "true"
  enable_cilium_clusterwide_network_policy = "false"
  enable_fqdn_network_policy               = "false"
  enable_intranode_visibility              = "false"
  enable_kubernetes_alpha                  = "false"
  enable_l4_ilb_subsetting                 = "false"
  enable_legacy_abac                       = "false"
  enable_multi_networking                  = "false"
  enable_shielded_nodes                    = "true"
  enable_tpu                               = "false"
  initial_node_count                       = "0"

  location = "us-west1"

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  logging_service = "logging.googleapis.com/kubernetes"

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

  monitoring_config {
    advanced_datapath_observability_config {
      enable_metrics = "false"
      enable_relay   = "false"
    }

    enable_components = ["SYSTEM_COMPONENTS"]
  }

  monitoring_service = "monitoring.googleapis.com/kubernetes"
  name               = "data-infra-apps"
  network            = "projects/cal-itp-data-infra/global/networks/default"

  network_policy {
    enabled  = "true"
    provider = "CALICO"
  }

  networking_mode = "VPC_NATIVE"
  node_locations  = ["us-west1-a", "us-west1-b", "us-west1-c"]

  node_pool_defaults {
    node_config_defaults {
      insecure_kubelet_readonly_port_enabled = "TRUE"
      logging_variant                        = "DEFAULT"
    }
  }

  node_version = "1.30.8-gke.1128001"

  private_cluster_config {
    enable_private_endpoint = "false"
    enable_private_nodes    = "false"

    master_global_access_config {
      enabled = "false"
    }
  }

  project = "cal-itp-data-infra"

  release_channel {
    channel = "STABLE"
  }

  secret_manager_config {
    enabled = "false"
  }

  service_external_ips_config {
    enabled = "true"
  }

  subnetwork = "projects/cal-itp-data-infra/regions/us-west1/subnetworks/default"
}
