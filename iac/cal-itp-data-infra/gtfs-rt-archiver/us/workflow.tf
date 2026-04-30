resource "google_pubsub_topic" "gtfs-rt-archiver-heartbeat" {
  name    = "gtfs-rt-archiver-heartbeat"
  project = "cal-itp-data-infra"
}

resource "google_pubsub_topic" "gtfs-rt-archiver-clock" {
  name    = "gtfs-rt-archiver-clock"
  project = "cal-itp-data-infra"
}

resource "google_eventarc_trigger" "gtfs-rt-archiver-clock" {
  name     = "gtfs-rt-archiver-clock"
  location = "us-west2"
  project  = "cal-itp-data-infra"

  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  destination {
    workflow = google_workflows_workflow.gtfs-rt-archiver-clock.id
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.gtfs-rt-archiver-clock.id
    }
  }
}

resource "google_workflows_workflow" "gtfs-rt-archiver-clock" {
  name            = "gtfs-rt-archiver-clock"
  description     = "GTFS-RT Archiver Heartbeat"
  region          = "us-west2"
  project         = "cal-itp-data-infra"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email
  source_contents = templatefile("${local.source_path}/clock.yaml", {})

  call_log_level          = "LOG_ALL_CALLS"
  execution_history_level = "EXECUTION_HISTORY_DETAILED"

  user_env_vars = {
    "CALITP_TOPIC__GTFS_RT_ARCHIVER_HEARTBEAT" = google_pubsub_topic.gtfs-rt-archiver-heartbeat.id
  }
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver-clock" {
  paused      = false
  name        = "gtfs-rt-archiver-clock"
  description = "GTFS-RT Archiver Heartbeat"
  region      = "us-west2"
  project     = "cal-itp-data-infra"
  schedule    = "* * * * *"
  time_zone   = "America/Los_Angeles"

  pubsub_target {
    topic_name = google_pubsub_topic.gtfs-rt-archiver-clock.id
    data       = base64encode(jsonencode({ limit = null }))
  }
}
