resource "google_compute_http_health_check" "tfer--ad40eb3afc69e4deeaf43a1ed1393eeb" {
  check_interval_sec  = "8"
  description         = "{\"kubernetes.io/service-name\":\"ad40eb3afc69e4deeaf43a1ed1393eeb\"}"
  healthy_threshold   = "1"
  name                = "ad40eb3afc69e4deeaf43a1ed1393eeb"
  port                = "32549"
  project             = "cal-itp-data-infra"
  request_path        = "/healthz"
  timeout_sec         = "1"
  unhealthy_threshold = "3"
}

resource "google_compute_http_health_check" "tfer--k8s-e092126e72b02003-node" {
  check_interval_sec  = "8"
  description         = "{\"kubernetes.io/service-name\":\"k8s-e092126e72b02003-node\"}"
  healthy_threshold   = "1"
  name                = "k8s-e092126e72b02003-node"
  port                = "10256"
  project             = "cal-itp-data-infra"
  request_path        = "/healthz"
  timeout_sec         = "1"
  unhealthy_threshold = "3"
}
