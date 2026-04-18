resource "google_pubsub_topic" "gtfs-rt-archiver-staging" {
  name    = "gtfs-rt-archiver-staging"
  project = "cal-itp-data-infra-staging"
}

data "archive_file" "gtfs-rt-archiver" {
  output_path = local.archive_path
  source_dir  = local.source_path
  type        = "zip"

  excludes = [
    "**/.env",
    "**/.env.*",
    "**/tests/**",
    "**/.git/**",
    "**/.gitignore",
    "**/pyproject.toml",
    "**/*.yaml",
    "**/uv.lock",
    "**/README.md",
    "**/Dockerfile",
  ]
}

resource "google_storage_bucket_object" "gtfs-rt-archiver" {
  name   = "gtfs-rt-archiver-${data.archive_file.gtfs-rt-archiver.output_sha512}.zip"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-rt-archiver_name
  source = local.archive_path

  content_type = "application/zip"
  depends_on   = [data.archive_file.gtfs-rt-archiver]

  provisioner "local-exec" {
    when    = create
    command = "rm ${data.archive_file.gtfs-rt-archiver.output_path}"
  }
}

resource "google_cloudfunctions2_function" "gtfs-rt-archiver" {
  name     = "gtfs-rt-archiver"
  location = "us-west2"

  depends_on = [google_storage_bucket_object.gtfs-rt-archiver]

  service_config {
    available_memory = "256M"
    ingress_settings = "ALLOW_INTERNAL_ONLY"

    all_traffic_on_latest_revision = true
    service_account_email          = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

    environment_variables = {
      CALITP_BUCKET__GTFS_RT_RAW = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-rt-raw-v2_name}"
      REQUEST_CONNECT_TIMEOUT    = 5
      REQUEST_READ_TIMEOUT       = 5
    }
  }

  build_config {
    runtime     = "python311"
    entry_point = "process_cloud_event"

    source {
      storage_source {
        bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-rt-archiver_name
        object = "gtfs-rt-archiver-${data.archive_file.gtfs-rt-archiver.output_sha512}.zip"
      }
    }
  }

  event_trigger {
    trigger_region = "us-west2"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.gtfs-rt-archiver-staging.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}
