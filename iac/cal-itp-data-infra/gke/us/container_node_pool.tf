resource "google_container_node_pool" "tfer--data-infra-apps_apps-v2" {
  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = "2"
    min_node_count       = "1"
    total_max_node_count = "0"
    total_min_node_count = "0"
  }

  cluster            = google_container_cluster.tfer--data-infra-apps.name
  initial_node_count = "1"
  location           = "us-west1"

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  max_pods_per_node = "110"
  name              = "apps-v2"

  network_config {
    create_pod_range     = "false"
    enable_private_nodes = "false"
    pod_ipv4_cidr_block  = "10.96.0.0/14"
    pod_range            = "gke-data-infra-apps-pods-0fe1e974"
  }

  node_config {
    disk_size_gb    = "100"
    disk_type       = "pd-standard"
    image_type      = "COS_CONTAINERD"
    local_ssd_count = "0"
    logging_variant = "DEFAULT"
    machine_type    = "n1-standard-4"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes    = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible     = "false"
    service_account = "default"

    shielded_instance_config {
      enable_integrity_monitoring = "true"
      enable_secure_boot          = "false"
    }

    spot = "false"
  }

  node_count     = "1"
  node_locations = ["us-west1-a", "us-west1-b", "us-west1-c"]
  project        = "cal-itp-data-infra"

  upgrade_settings {
    max_surge       = "1"
    max_unavailable = "0"
    strategy        = "SURGE"
  }

  version = "1.30.9-gke.1127000"
}

resource "google_container_node_pool" "tfer--data-infra-apps_gtfsrt-v4" {
  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = "2"
    min_node_count       = "1"
    total_max_node_count = "0"
    total_min_node_count = "0"
  }

  cluster            = google_container_cluster.tfer--data-infra-apps.name
  initial_node_count = "1"
  location           = "us-west1"

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  max_pods_per_node = "110"
  name              = "gtfsrt-v4"

  network_config {
    create_pod_range     = "false"
    enable_private_nodes = "false"
    pod_ipv4_cidr_block  = "10.96.0.0/14"
    pod_range            = "gke-data-infra-apps-pods-0fe1e974"
  }

  node_config {
    disk_size_gb = "100"
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"

    labels = {
      resource-domain = "gtfsrtv3"
    }

    local_ssd_count = "0"
    logging_variant = "DEFAULT"
    machine_type    = "c2-standard-4"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes    = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible     = "false"
    service_account = "default"

    shielded_instance_config {
      enable_integrity_monitoring = "true"
      enable_secure_boot          = "false"
    }

    spot = "false"

    taint {
      effect = "NO_SCHEDULE"
      key    = "resource-domain"
      value  = "gtfsrtv3"
    }
  }

  node_count     = "1"
  node_locations = ["us-west1-a", "us-west1-b", "us-west1-c"]
  project        = "cal-itp-data-infra"

  upgrade_settings {
    max_surge       = "1"
    max_unavailable = "0"
    strategy        = "SURGE"
  }

  version = "1.30.9-gke.1127000"
}

resource "google_container_node_pool" "tfer--data-infra-apps_jobs-v1" {
  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = "3"
    min_node_count       = "1"
    total_max_node_count = "0"
    total_min_node_count = "0"
  }

  cluster            = google_container_cluster.tfer--data-infra-apps.name
  initial_node_count = "1"
  location           = "us-west1"

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  max_pods_per_node = "110"
  name              = "jobs-v1"

  network_config {
    create_pod_range     = "false"
    enable_private_nodes = "false"
    pod_ipv4_cidr_block  = "10.96.0.0/14"
    pod_range            = "gke-data-infra-apps-pods-0fe1e974"
  }

  node_config {
    disk_size_gb = "100"
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"

    labels = {
      pod-role = "computetask"
    }

    local_ssd_count = "0"
    logging_variant = "DEFAULT"
    machine_type    = "c2-standard-4"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes    = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible     = "false"
    service_account = "default"

    shielded_instance_config {
      enable_integrity_monitoring = "true"
      enable_secure_boot          = "false"
    }

    spot = "false"

    taint {
      effect = "NO_SCHEDULE"
      key    = "pod-role"
      value  = "computetask"
    }
  }

  node_count     = "1"
  node_locations = ["us-west1-a", "us-west1-b", "us-west1-c"]
  project        = "cal-itp-data-infra"

  upgrade_settings {
    max_surge       = "1"
    max_unavailable = "0"
    strategy        = "SURGE"
  }

  version = "1.30.9-gke.1127000"
}

resource "google_container_node_pool" "tfer--data-infra-apps_jupyterhub-users" {
  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = "0"
    min_node_count       = "0"
    total_max_node_count = "12"
    total_min_node_count = "6"
  }

  cluster            = google_container_cluster.tfer--data-infra-apps.name
  initial_node_count = "2"
  location           = "us-west1"

  management {
    auto_repair  = "true"
    auto_upgrade = "true"
  }

  max_pods_per_node = "110"
  name              = "jupyterhub-users"

  network_config {
    create_pod_range     = "false"
    enable_private_nodes = "false"
    pod_ipv4_cidr_block  = "10.96.0.0/14"
    pod_range            = "gke-data-infra-apps-pods-0fe1e974"
  }

  node_config {
    disk_size_gb = "100"
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"

    labels = {
      "hub.jupyter.org/node-purpose" = "user"
    }

    local_ssd_count = "0"
    logging_variant = "DEFAULT"
    machine_type    = "e2-highmem-2"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes    = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible     = "false"
    service_account = "default"

    shielded_instance_config {
      enable_integrity_monitoring = "true"
      enable_secure_boot          = "false"
    }

    spot = "false"

    taint {
      effect = "NO_SCHEDULE"
      key    = "hub.jupyter.org/dedicated"
      value  = "user"
    }
  }

  node_locations = ["us-west1-a", "us-west1-b", "us-west1-c"]
  project        = "cal-itp-data-infra"

  upgrade_settings {
    max_surge       = "1"
    max_unavailable = "0"
    strategy        = "SURGE"
  }

  version = "1.30.9-gke.1127000"
}
