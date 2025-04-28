resource "google_compute_backend_bucket" "calitp-gtfs" {
  name        = "calitp-gtfs-backend-bucket"
  bucket_name = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs_name
  enable_cdn  = true
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 3600
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
    serve_while_stale = 86400
  }
}

resource "google_compute_backend_bucket" "calitp-dbt-docs" {
  name        = "calitp-dbt-docs-backend-bucket"
  bucket_name = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-dbt-docs_name
  enable_cdn  = true
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 3600
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
    serve_while_stale = 86400
  }
}

resource "google_compute_url_map" "default" {
  name            = "http-lb"
  default_service = google_compute_backend_bucket.calitp-gtfs.id

  host_rule {
    path_matcher = "gtfs"
    hosts        = ["gtfs.dds.dot.ca.gov"]
  }

  host_rule {
    path_matcher = "dbt-docs"
    hosts        = ["dbt-docs.dds.dot.ca.gov"]
  }

  path_matcher {
    name            = "gtfs"
    default_service = google_compute_backend_bucket.calitp-gtfs.id
  }

  path_matcher {
    name            = "dbt-docs"
    default_service = google_compute_backend_bucket.calitp-dbt-docs.id
  }
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-lb-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-lb-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = data.terraform_remote_state.networks.outputs.google_compute_network_static-load-balancer-address_id
}
