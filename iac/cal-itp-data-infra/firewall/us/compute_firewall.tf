resource "google_compute_firewall" "tfer--default-allow-http" {
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  disabled      = "false"
  name          = "default-allow-http"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "1000"
  project       = "cal-itp-data-infra"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "tfer--default-allow-https" {
  allow {
    ports    = ["443"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  disabled      = "false"
  name          = "default-allow-https"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "1000"
  project       = "cal-itp-data-infra"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

resource "google_compute_firewall" "tfer--default-allow-icmp" {
  allow {
    protocol = "icmp"
  }

  description   = "Allow ICMP from anywhere"
  direction     = "INGRESS"
  disabled      = "false"
  name          = "default-allow-icmp"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "65534"
  project       = "cal-itp-data-infra"
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "tfer--default-allow-internal" {
  allow {
    ports    = ["0-65535"]
    protocol = "tcp"
  }

  allow {
    ports    = ["0-65535"]
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  description   = "Allow internal traffic on the default network"
  direction     = "INGRESS"
  disabled      = "false"
  name          = "default-allow-internal"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "65534"
  project       = "cal-itp-data-infra"
  source_ranges = ["10.128.0.0/9"]
}

resource "google_compute_firewall" "tfer--default-allow-rdp" {
  allow {
    ports    = ["3389"]
    protocol = "tcp"
  }

  description   = "Allow RDP from anywhere"
  direction     = "INGRESS"
  disabled      = "false"
  name          = "default-allow-rdp"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "65534"
  project       = "cal-itp-data-infra"
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "tfer--default-allow-ssh" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  description   = "Allow SSH from anywhere"
  direction     = "INGRESS"
  disabled      = "false"
  name          = "default-allow-ssh"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "65534"
  project       = "cal-itp-data-infra"
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "tfer--gke-data-infra-apps-0fe1e974-all" {
  allow {
    protocol = "ah"
  }

  allow {
    protocol = "esp"
  }

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "sctp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  direction     = "INGRESS"
  disabled      = "false"
  name          = "gke-data-infra-apps-0fe1e974-all"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "1000"
  project       = "cal-itp-data-infra"
  source_ranges = ["10.96.0.0/14"]
  target_tags   = ["gke-data-infra-apps-0fe1e974-node"]
}

resource "google_compute_firewall" "tfer--gke-data-infra-apps-0fe1e974-ssh" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  disabled      = "false"
  name          = "gke-data-infra-apps-0fe1e974-ssh"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "1000"
  project       = "cal-itp-data-infra"
  source_ranges = ["34.127.17.149/32", "34.145.121.153/32", "34.145.4.65/32"]
  target_tags   = ["gke-data-infra-apps-0fe1e974-node"]
}

resource "google_compute_firewall" "tfer--gke-data-infra-apps-0fe1e974-vms" {
  allow {
    ports    = ["1-65535"]
    protocol = "tcp"
  }

  allow {
    ports    = ["1-65535"]
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  direction     = "INGRESS"
  disabled      = "false"
  name          = "gke-data-infra-apps-0fe1e974-vms"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "1000"
  project       = "cal-itp-data-infra"
  source_ranges = ["10.128.0.0/9"]
  target_tags   = ["gke-data-infra-apps-0fe1e974-node"]
}

resource "google_compute_firewall" "tfer--gke-us-west2-calitp-airflow2-pr-171e4e47-gke-0b2083d6-ssh" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  disabled      = "false"
  name          = "gke-us-west2-calitp-airflow2-pr-171e4e47-gke-0b2083d6-ssh"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "1000"
  project       = "cal-itp-data-infra"
  source_ranges = ["34.94.25.3/32"]
  target_tags   = ["gke-us-west2-calitp-airflow2-pr-171e4e47-gke-0b2083d6-node"]
}

resource "google_compute_firewall" "tfer--k8s-ad40eb3afc69e4deeaf43a1ed1393eeb-http-hc" {
  allow {
    ports    = ["32549"]
    protocol = "tcp"
  }

  description   = "{\"kubernetes.io/service-name\":\"ingress-nginx/ingress-nginx-controller\", \"kubernetes.io/service-ip\":\"34.127.51.123\"}"
  direction     = "INGRESS"
  disabled      = "false"
  name          = "k8s-ad40eb3afc69e4deeaf43a1ed1393eeb-http-hc"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "1000"
  project       = "cal-itp-data-infra"
  source_ranges = ["130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"]
  target_tags   = ["gke-data-infra-apps-0fe1e974-node"]
}

resource "google_compute_firewall" "tfer--k8s-e092126e72b02003-node-http-hc" {
  allow {
    ports    = ["10256"]
    protocol = "tcp"
  }

  description   = "{\"kubernetes.io/cluster-id\":\"e092126e72b02003\"}"
  direction     = "INGRESS"
  disabled      = "false"
  name          = "k8s-e092126e72b02003-node-http-hc"
  network       = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority      = "1000"
  project       = "cal-itp-data-infra"
  source_ranges = ["130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"]
  target_tags   = ["gke-data-infra-apps-0fe1e974-node"]
}

resource "google_compute_firewall" "tfer--k8s-fw-a0d3bb39e959b49a1b6015fd2193e30d" {
  allow {
    ports    = ["2200"]
    protocol = "tcp"
  }

  description        = "{\"kubernetes.io/service-name\":\"prod-sftp-ingest-elavon/sftp-internet\", \"kubernetes.io/service-ip\":\"34.145.56.125\"}"
  destination_ranges = ["34.145.56.125"]
  direction          = "INGRESS"
  disabled           = "false"
  name               = "k8s-fw-a0d3bb39e959b49a1b6015fd2193e30d"
  network            = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority           = "1000"
  project            = "cal-itp-data-infra"
  source_ranges      = ["0.0.0.0/0"]
  target_tags        = ["gke-data-infra-apps-0fe1e974-node"]
}

resource "google_compute_firewall" "tfer--k8s-fw-ad40eb3afc69e4deeaf43a1ed1393eeb" {
  allow {
    ports    = ["443", "80"]
    protocol = "tcp"
  }

  description        = "{\"kubernetes.io/service-name\":\"ingress-nginx/ingress-nginx-controller\", \"kubernetes.io/service-ip\":\"34.127.51.123\"}"
  destination_ranges = ["34.127.51.123"]
  direction          = "INGRESS"
  disabled           = "false"
  name               = "k8s-fw-ad40eb3afc69e4deeaf43a1ed1393eeb"
  network            = data.terraform_remote_state.networks.outputs.google_compute_network_tfer--default_self_link
  priority           = "1000"
  project            = "cal-itp-data-infra"
  source_ranges      = ["0.0.0.0/0"]
  target_tags        = ["gke-data-infra-apps-0fe1e974-node"]
}
