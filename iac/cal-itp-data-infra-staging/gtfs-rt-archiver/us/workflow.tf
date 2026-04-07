resource "google_pubsub_topic" "gtfs-rt-archiver" {
  name    = "gtfs-rt-archiver"
  project = "cal-itp-data-infra-staging"
}

resource "google_pubsub_topic" "gtfs-rt-archiver-heartbeat" {
  name    = "gtfs-rt-archiver-heartbeat"
  project = "cal-itp-data-infra-staging"
}

resource "google_eventarc_trigger" "gtfs-rt-archiver-heartbeat" {
  name     = "gtfs-rt-archiver-heartbeat"
  location = "us-west2"
  project  = "cal-itp-data-infra-staging"

  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  destination {
    workflow = google_workflows_workflow.gtfs-rt-archiver-heartbeat.id
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.gtfs-rt-archiver-heartbeat.id
    }
  }
}

resource "google_workflows_workflow" "gtfs-rt-archiver-heartbeat" {
  name            = "gtfs-rt-archiver-heartbeat"
  region          = "us-west2"
  project         = "cal-itp-data-infra-staging"
  description     = "GTFS-RT Archiver"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email
  source_contents = templatefile("${local.source_path}/gtfs-rt-archiver-heartbeat.yaml", {})

  call_log_level          = "LOG_ALL_CALLS"
  execution_history_level = "EXECUTION_HISTORY_DETAILED"

  user_env_vars = {
    "GTFS_RT_ARCHIVER__TOPIC" = google_pubsub_topic.gtfs-rt-archiver.id
  }
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver-heartbeat" {
  project     = "cal-itp-data-infra-staging"
  name        = "gtfs-rt-archiver-heartbeat"
  description = "GTFS-RT Archiver heartbeat"
  schedule    = "* * * * *"
  time_zone   = "America/Los_Angeles"
  region      = "us-west2"

  pubsub_target {
    topic_name = google_pubsub_topic.gtfs-rt-archiver-heartbeat.id
    data       = base64encode(jsonencode({ limit = null }))
  }
}
