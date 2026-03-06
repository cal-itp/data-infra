resource "google_pubsub_topic" "gtfs-rt-archiver" {
  name    = "gtfs-rt-archiver"
  project = "cal-itp-data-infra-staging"
}

resource "google_cloud_run_v2_service" "gtfs-rt-archiver" {
  name     = "gtfs-rt-archiver"
  location = "us-west2"
  project  = "cal-itp-data-infra-staging"

  template {
    containers {
      name           = "gtfs-rt-archiver"
      image          = "us-west2-docker.pkg.dev/cal-itp-data-infra-staging/ghcr/cal-itp/data-infra/metabase:staging"
      base_image_uri = "us-central1-docker.pkg.dev/serverless-runtimes/google-22/runtimes/python311"
    }
  }

  build_config {
    function_target = "process_cloud_event"
    image_uri                = "us-west2-docker.pkg.dev/cal-itp-data-infra-staging/ghcr/cal-itp/data-infra/metabase:staging"
    base_image               = "us-central1-docker.pkg.dev/serverless-runtimes/google-22/runtimes/python311"
    enable_automatic_updates = true
  }

  service_config {
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver-service-account_email
  }

  event_trigger {
    trigger_region = "us-west2"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.gtfs-rt-archiver.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

resource "google_cloud_run_v2_service_iam_member" "gtfs-rt-archiver" {
  location = google_cloud_run_v2_service.gtfs-rt-archiver.location
  name     = google_cloud_run_v2_service.gtfs-rt-archiver.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
