resource "google_compute_managed_ssl_certificate" "calitp" {
  name = "calitp-certificate"

  managed {
    domains = [
      "dbt-docs.dds.dot.ca.gov.",
      "gtfs.dds.dot.ca.gov.",
      "reports.dds.dot.ca.gov.",
      "analysis.dds.dot.ca.gov.",
    ]
  }
}

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

resource "google_compute_backend_bucket" "calitp-reports" {
  name        = "calitp-reports-backend-bucket"
  bucket_name = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-reports_name
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

resource "google_compute_backend_bucket" "calitp-analysis" {
  name        = "calitp-analysis-backend-bucket"
  bucket_name = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-analysis_name
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

resource "google_compute_url_map" "calitp-https" {
  name            = "calitp-https-load-balancer"
  default_service = google_compute_backend_bucket.calitp-dbt-docs.id

  host_rule {
    path_matcher = "gtfs"
    hosts        = ["gtfs.dds.dot.ca.gov"]
  }

  host_rule {
    path_matcher = "dbt-docs"
    hosts        = ["dbt-docs.dds.dot.ca.gov"]
  }

  host_rule {
    path_matcher = "reports"
    hosts        = ["reports.dds.dot.ca.gov"]
  }

  host_rule {
    path_matcher = "analysis"
    hosts        = ["analysis.dds.dot.ca.gov"]
  }

  path_matcher {
    name            = "gtfs"
    default_service = google_compute_backend_bucket.calitp-gtfs.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.calitp-gtfs.id
    }
  }

  path_matcher {
    name            = "dbt-docs"
    default_service = google_compute_backend_bucket.calitp-dbt-docs.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.calitp-dbt-docs.id
    }
  }

  path_matcher {
    name            = "reports"
    default_service = google_compute_backend_bucket.calitp-reports.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.calitp-reports.id
    }
  }

  path_matcher {
    name            = "analysis"
    default_service = google_compute_backend_bucket.calitp-analysis.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.calitp-analysis.id
    }
  }
}

resource "google_compute_target_https_proxy" "calitp-https" {
  name             = "calitp-https-proxy"
  url_map          = google_compute_url_map.calitp-https.id
  ssl_certificates = [google_compute_managed_ssl_certificate.calitp.id]
}

resource "google_compute_global_forwarding_rule" "calitp-https" {
  name        = "calitp-https-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = 443
  target      = google_compute_target_https_proxy.calitp-https.id
  ip_address  = data.terraform_remote_state.networks.outputs.google_compute_network_static-load-balancer-address_id
}

resource "google_compute_url_map" "calitp-http" {
  name = "calitp-http-load-balancer"

  default_url_redirect {
    strip_query    = false
    https_redirect = true
  }
}

resource "google_compute_target_http_proxy" "calitp-http" {
  name    = "calitp-http-proxy"
  url_map = google_compute_url_map.calitp-http.self_link
}

resource "google_compute_global_forwarding_rule" "calitp-http" {
  name        = "calitp-http-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = 80
  target      = google_compute_target_http_proxy.calitp-http.self_link
  ip_address  = data.terraform_remote_state.networks.outputs.google_compute_network_static-load-balancer-address_id
}
