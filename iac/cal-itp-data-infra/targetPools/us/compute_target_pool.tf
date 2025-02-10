resource "google_compute_target_pool" "tfer--a0d3bb39e959b49a1b6015fd2193e30d" {
  description      = "{\"kubernetes.io/service-name\":\"prod-sftp-ingest-elavon/sftp-internet\"}"
  failover_ratio   = "0"
  health_checks    = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/httpHealthChecks/k8s-e092126e72b02003-node"]
  instances        = ["us-west1-a/gke-data-infra-apps-apps-v2-2729c0c0-v3px", "us-west1-a/gke-data-infra-apps-gtfsrt-v4-2a13e092-n53e", "us-west1-a/gke-data-infra-apps-gtfsrt-v4-2a13e092-s9i5", "us-west1-a/gke-data-infra-apps-jobs-v1-cd18666b-ygrz", "us-west1-a/gke-data-infra-apps-jupyterhub-users-b57e08f4-42at", "us-west1-b/gke-data-infra-apps-apps-v2-0dfb61fb-5kvg", "us-west1-b/gke-data-infra-apps-gtfsrt-v4-b003cc53-b7vi", "us-west1-b/gke-data-infra-apps-jobs-v1-8eec22fb-aazx", "us-west1-b/gke-data-infra-apps-jupyterhub-users-dddc57ff-cbrw", "us-west1-b/gke-data-infra-apps-jupyterhub-users-dddc57ff-u7p2", "us-west1-c/gke-data-infra-apps-apps-v2-24a4cc95-bdau", "us-west1-c/gke-data-infra-apps-apps-v2-24a4cc95-xdkc", "us-west1-c/gke-data-infra-apps-gtfsrt-v4-7577d4d7-lz65", "us-west1-c/gke-data-infra-apps-jobs-v1-625ec063-5q8v", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-b03b", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-juyr", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-shcz"]
  name             = "a0d3bb39e959b49a1b6015fd2193e30d"
  project          = "cal-itp-data-infra"
  region           = "us-west1"
  session_affinity = "NONE"
}

resource "google_compute_target_pool" "tfer--ad40eb3afc69e4deeaf43a1ed1393eeb" {
  description      = "{\"kubernetes.io/service-name\":\"ingress-nginx/ingress-nginx-controller\"}"
  failover_ratio   = "0"
  health_checks    = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/httpHealthChecks/ad40eb3afc69e4deeaf43a1ed1393eeb"]
  instances        = ["us-west1-a/gke-data-infra-apps-apps-v2-2729c0c0-v3px", "us-west1-a/gke-data-infra-apps-gtfsrt-v4-2a13e092-n53e", "us-west1-a/gke-data-infra-apps-gtfsrt-v4-2a13e092-s9i5", "us-west1-a/gke-data-infra-apps-jobs-v1-cd18666b-ygrz", "us-west1-a/gke-data-infra-apps-jupyterhub-users-b57e08f4-42at", "us-west1-b/gke-data-infra-apps-apps-v2-0dfb61fb-5kvg", "us-west1-b/gke-data-infra-apps-gtfsrt-v4-b003cc53-b7vi", "us-west1-b/gke-data-infra-apps-jobs-v1-8eec22fb-aazx", "us-west1-b/gke-data-infra-apps-jupyterhub-users-dddc57ff-cbrw", "us-west1-b/gke-data-infra-apps-jupyterhub-users-dddc57ff-u7p2", "us-west1-c/gke-data-infra-apps-apps-v2-24a4cc95-bdau", "us-west1-c/gke-data-infra-apps-apps-v2-24a4cc95-xdkc", "us-west1-c/gke-data-infra-apps-gtfsrt-v4-7577d4d7-lz65", "us-west1-c/gke-data-infra-apps-jobs-v1-625ec063-5q8v", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-b03b", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-juyr", "us-west1-c/gke-data-infra-apps-jupyterhub-users-6aa76dbb-shcz"]
  name             = "ad40eb3afc69e4deeaf43a1ed1393eeb"
  project          = "cal-itp-data-infra"
  region           = "us-west1"
  session_affinity = "NONE"
}
