resource "google_compute_managed_ssl_certificate" "calitp-staging" {
  name = "calitp-staging-certificate-4"

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = [
      "dbt-docs-staging.dds.dot.ca.gov.",
      "reports-staging.dds.dot.ca.gov.",
      "analysis-staging.dds.dot.ca.gov."
    ]
  }
}

resource "google_compute_backend_bucket" "calitp-staging-dbt-docs" {
  name        = "calitp-staging-dbt-docs-backend-bucket"
  bucket_name = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-dbt-docs_name
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

resource "google_compute_backend_bucket" "calitp-reports-staging" {
  name        = "calitp-reports-staging-backend-bucket"
  bucket_name = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-reports-staging_name
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

resource "google_compute_backend_bucket" "calitp-analysis-staging" {
  name        = "calitp-analysis-staging-backend-bucket"
  bucket_name = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-analysis-staging_name
  enable_cdn  = true
  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 300
    default_ttl       = 300
    max_ttl           = 86400
    negative_caching  = true
    serve_while_stale = 86400
  }
}

resource "google_compute_url_map" "calitp-staging-https" {
  name            = "calitp-staging-https-load-balancer"
  default_service = google_compute_backend_bucket.calitp-staging-dbt-docs.id

  host_rule {
    path_matcher = "dbt-docs"
    hosts        = ["dbt-docs-staging.dds.dot.ca.gov"]
  }

  host_rule {
    path_matcher = "reports-staging"
    hosts        = ["reports-staging.dds.dot.ca.gov"]
  }

  host_rule {
    path_matcher = "analysis-staging"
    hosts        = ["analysis-staging.dds.dot.ca.gov"]
  }

  path_matcher {
    name            = "dbt-docs"
    default_service = google_compute_backend_bucket.calitp-staging-dbt-docs.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.calitp-staging-dbt-docs.id
    }
  }

  path_matcher {
    name            = "reports-staging"
    default_service = google_compute_backend_bucket.calitp-reports-staging.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.calitp-reports-staging.id
    }
  }

  path_matcher {
    name            = "analysis-staging"
    default_service = google_compute_backend_bucket.calitp-analysis-staging.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.calitp-analysis-staging.id
    }
  }
}

resource "google_compute_target_https_proxy" "calitp-staging-https" {
  name             = "calitp-staging-https-proxy"
  url_map          = google_compute_url_map.calitp-staging-https.id
  ssl_certificates = [google_compute_managed_ssl_certificate.calitp-staging.id]
}

resource "google_compute_global_forwarding_rule" "calitp-staging-https" {
  name        = "calitp-staging-https-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = 443
  target      = google_compute_target_https_proxy.calitp-staging-https.id
  ip_address  = data.terraform_remote_state.networks.outputs.google_compute_network_static-load-balancer-address_id
}

resource "google_compute_url_map" "calitp-staging-http" {
  name = "calitp-staging-http-load-balancer"

  default_url_redirect {
    strip_query    = false
    https_redirect = true
  }
}

resource "google_compute_target_http_proxy" "calitp-staging-http" {
  name    = "calitp-staging-http-proxy"
  url_map = google_compute_url_map.calitp-staging-http.self_link
}

resource "google_compute_global_forwarding_rule" "calitp-staging-http" {
  name        = "calitp-staging-http-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = 80
  target      = google_compute_target_http_proxy.calitp-staging-http.self_link
  ip_address  = data.terraform_remote_state.networks.outputs.google_compute_network_static-load-balancer-address_id
}
