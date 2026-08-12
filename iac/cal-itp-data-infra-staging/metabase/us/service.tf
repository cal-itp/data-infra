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

      # Metabase runs Liquibase schema migrations on first boot of a new version,
      # and does not serve / until they finish. If the startup probe gives up
      # mid-migration the container is killed while holding the
      # DATABASECHANGELOGLOCK row, and the next boot hangs waiting on a lock
      # nobody holds — recoverable only by clearing it by hand.
      #
      # failure_threshold * period_seconds is capped at 240s by Cloud Run, so
      # 48 * 5 is the most probing time available; with the 60s initial delay
      # that is a 300s budget, matching production. This is a ceiling, not a
      # wait: a healthy container goes Ready on its first successful probe, so
      # normal starts and autoscaling are unaffected.
      startup_probe {
        timeout_seconds       = 2
        period_seconds        = 5
        failure_threshold     = 48
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

      # Required by entrypoint.sh to build the Cloud SQL Unix-socket symlink.
      # Must be set explicitly: the entrypoint's fallback enumerates /cloudsql,
      # but on Cloud Run that directory is not listable even though the socket
      # beneath it is connectable, so the fallback always fails here.
      env {
        name  = "CLOUD_SQL_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.metabase-staging.connection_name
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
        enable      = true
        sample_rate = 1.0
      }

      security_policy = google_compute_security_policy.metabase-staging.self_link
    }
  }
}
