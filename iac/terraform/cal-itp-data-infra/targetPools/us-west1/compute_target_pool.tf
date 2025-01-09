resource "google_compute_target_pool" "tfer--a0d3bb39e959b49a1b6015fd2193e30d" {
  description      = "{\"kubernetes.io/service-name\":\"prod-sftp-ingest-elavon/sftp-internet\"}"
  failover_ratio   = "0"
  health_checks    = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/httpHealthChecks/k8s-e092126e72b02003-node"]
  instances        = ["us-west1-a/gke-data-infra-apps-apps-v2-2729c0c0-8ms8", "us-west1-a/gke-data-infra-apps-gtfsrt-v4-2a13e092-k2sh", "us-west1-a/gke-data-infra-apps-gtfsrt-v4-2a13e092-qr7i", "us-west1-a/gke-data-infra-apps-jobs-v1-cd18666b-d7vg", "us-west1-a/gke-data-infra-apps-jupyterhub-users-b57e08f4-ldpn", "us-west1-b/gke-data-infra-apps-apps-v2-0dfb61fb-qloc", "us-west1-b/gke-data-infra-apps-gtfsrt-v4-b003cc53-d25a", "us-west1-b/gke-data-infra-apps-jobs-v1-8eec22fb-9fgb", "us-west1-b/gke-data-infra-apps-jupyterhub-users-dddc57ff-2iq0", "us-west1-b/gke-data-infra-apps-jupyterhub-users-dddc57ff-rb5c", "us-west1-c/gke-data-infra-apps-apps-v2-24a4cc95-c6nc", "us-west1-c/gke-data-infra-apps-apps-v2-24a4cc95-r80w", "us-west1-c/gke-data-infra-apps-gtfsrt-v4-7577d4d7-2q5e", "us-west1-c/gke-data-infra-apps-jobs-v1-625ec063-7qyx", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-0ipn", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-58p2", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-f0y0"]
  name             = "a0d3bb39e959b49a1b6015fd2193e30d"
  project          = "cal-itp-data-infra"
  region           = "us-west1"
  session_affinity = "NONE"
}

resource "google_compute_target_pool" "tfer--ad40eb3afc69e4deeaf43a1ed1393eeb" {
  description      = "{\"kubernetes.io/service-name\":\"ingress-nginx/ingress-nginx-controller\"}"
  failover_ratio   = "0"
  health_checks    = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/httpHealthChecks/ad40eb3afc69e4deeaf43a1ed1393eeb"]
  instances        = ["us-west1-a/gke-data-infra-apps-apps-v2-2729c0c0-8ms8", "us-west1-a/gke-data-infra-apps-gtfsrt-v4-2a13e092-k2sh", "us-west1-a/gke-data-infra-apps-gtfsrt-v4-2a13e092-qr7i", "us-west1-a/gke-data-infra-apps-jobs-v1-cd18666b-d7vg", "us-west1-a/gke-data-infra-apps-jupyterhub-users-b57e08f4-ldpn", "us-west1-b/gke-data-infra-apps-apps-v2-0dfb61fb-qloc", "us-west1-b/gke-data-infra-apps-gtfsrt-v4-b003cc53-d25a", "us-west1-b/gke-data-infra-apps-jobs-v1-8eec22fb-9fgb", "us-west1-b/gke-data-infra-apps-jupyterhub-users-dddc57ff-2iq0", "us-west1-b/gke-data-infra-apps-jupyterhub-users-dddc57ff-rb5c", "us-west1-c/gke-data-infra-apps-apps-v2-24a4cc95-c6nc", "us-west1-c/gke-data-infra-apps-apps-v2-24a4cc95-r80w", "us-west1-c/gke-data-infra-apps-gtfsrt-v4-7577d4d7-2q5e", "us-west1-c/gke-data-infra-apps-jobs-v1-625ec063-7qyx", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-0ipn", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-58p2", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-f0y0"]
  name             = "ad40eb3afc69e4deeaf43a1ed1393eeb"
  project          = "cal-itp-data-infra"
  region           = "us-west1"
  session_affinity = "NONE"
}
