resource "google_cloud_run_v2_service" "metabase-staging" {
  name                 = "metabase-staging"
  location             = "us-west2"
  deletion_protection  = false
  ingress              = "INGRESS_TRAFFIC_ALL"
  invoker_iam_disabled = true

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  scaling {
    min_instance_count = 1
  }

  template {
    service_account = data.terraform_remote_state.iam.outputs.google_service_account_metabase-service-account_email

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.metabase-staging.connection_name]
      }
    }

    containers {
      image = "us-west2-docker.pkg.dev/cal-itp-data-infra-staging/ghcr/cal-itp/data-infra/metabase:staging"

      resources {
        limits = {
          cpu    = "1"
          memory = "2048Mi"
        }
      }

      ports {
        container_port = 3000
      }

      startup_probe {
        timeout_seconds       = 2
        period_seconds        = 5
        failure_threshold     = 10
        initial_delay_seconds = 60

        http_get {
          path = "/"
          port = 3000
        }
      }

      liveness_probe {
        http_get {
          path = "/"
          port = 3000
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "MB_DB_TYPE"
        value = "postgres"
      }

      env {
        name  = "MB_DB_DBNAME"
        value = google_sql_database.metabase-staging.name
      }

      env {
        name  = "MB_DB_HOST"
        value = "127.0.0.1"
      }

      env {
        name  = "MB_DB_USER"
        value = google_sql_user.metabase-staging.name
      }

      env {
        name = "MB_DB_PASS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.metabase-staging-password.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "JAVA_OPTS"
        value = "-Xmx2048m"
      }
    }
  }
}

resource "google_cloud_run_service_iam_binding" "metabase-staging" {
  location = google_cloud_run_v2_service.metabase-staging.location
  service  = google_cloud_run_v2_service.metabase-staging.name
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}

resource "google_compute_region_network_endpoint_group" "metabase-staging" {
  name                  = "metabase-staging"
  network_endpoint_type = "SERVERLESS"
  region                = google_cloud_run_v2_service.metabase-staging.location
  cloud_run {
    service = google_cloud_run_v2_service.metabase-staging.name
  }
}

module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 14.0"

  name    = "metabase-staging"
  project = "cal-itp-data-infra-staging"

  ssl                             = true
  managed_ssl_certificate_domains = [local.domain]
  https_redirect                  = true

  address        = google_compute_global_address.metabase-staging.address
  create_address = false

  backends = {
    metabase = {
      groups = []
      serverless_neg_backends = [
        {
          "region" : "us-west2",
          "type" : "cloud-run",
          "service" : {
            "name" : google_cloud_run_v2_service.metabase-staging.name
          }
        }
      ]

      health_check = {
        request_path = "/"
        protocol     = "HTTP"
        port         = 80
      }

      enable_cdn = false

      iap_config = {
        enable = false
      }

      log_config = {
        enable = false
      }
    }
  }
}
