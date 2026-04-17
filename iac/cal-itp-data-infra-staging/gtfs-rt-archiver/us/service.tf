resource "google_pubsub_topic" "gtfs-rt-archiver-staging" {
  name    = "gtfs-rt-archiver-staging"
  project = "cal-itp-data-infra-staging"
}

resource "google_pubsub_subscription" "gtfs-rt-archiver-staging" {
  name  = "gtfs-rt-archiver-staging"
  topic = google_pubsub_topic.gtfs-rt-archiver-staging.id

  ack_deadline_seconds       = 60
  message_retention_duration = "600s"

  expiration_policy {
    ttl = "86400s"
  }
}

resource "google_cloud_run_v2_worker_pool" "gtfs-rt-archiver-staging" {
  name                = "gtfs-rt-archiver-staging"
  location            = "us-west2"
  deletion_protection = false

  instance_splits {
    type    = "INSTANCE_SPLIT_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  template {
    service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

    containers {
      image = "us-west2-docker.pkg.dev/cal-itp-data-infra-staging/ghcr/cal-itp/data-infra/gtfs-rt-archiver-v5:${var.git_sha != null ? var.git_sha : data.external.git.result.sha}"

      env {
        name  = "CALITP_BUCKET__GTFS_RT_RAW"
        value = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-rt-raw-v2_name
      }

      env {
        name  = "GTFS_RT_ARCHIVER__SUBSCRIPTION"
        value = google_pubsub_subscription.gtfs-rt-archiver-staging.id
      }
    }
  }
}
