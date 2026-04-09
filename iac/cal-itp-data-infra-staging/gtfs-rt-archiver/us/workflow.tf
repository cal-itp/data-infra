resource "google_pubsub_topic" "gtfs-rt-archiver-staging-heartbeat" {
  name    = "gtfs-rt-archiver-staging-heartbeat"
  project = "cal-itp-data-infra-staging"
}

resource "google_eventarc_trigger" "gtfs-rt-archiver-staging-heartbeat" {
  name     = "gtfs-rt-archiver-staging-heartbeat"
  location = "us-west2"
  project  = "cal-itp-data-infra-staging"

  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  destination {
    workflow = google_workflows_workflow.gtfs-rt-archiver-staging-heartbeat.id
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.gtfs-rt-archiver-staging-heartbeat.id
    }
  }
}

resource "google_workflows_workflow" "gtfs-rt-archiver-staging-heartbeat" {
  name            = "gtfs-rt-archiver-staging-heartbeat"
  description     = "GTFS-RT Archiver Heartbeat"
  region          = "us-west2"
  project         = "cal-itp-data-infra-staging"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email
  source_contents = templatefile("${local.source_path}/heartbeat.yaml", {})

  call_log_level          = "LOG_ALL_CALLS"
  execution_history_level = "EXECUTION_HISTORY_DETAILED"

  user_env_vars = {
    "GTFS_RT_ARCHIVER__TOPIC" = google_pubsub_topic.gtfs-rt-archiver-staging.id
  }
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver-staging-heartbeat" {
  name        = "gtfs-rt-archiver-staging-heartbeat"
  description = "GTFS-RT Archiver Heartbeat"
  region      = "us-west2"
  project     = "cal-itp-data-infra-staging"
  schedule    = "* * * * *"
  time_zone   = "America/Los_Angeles"

  pubsub_target {
    topic_name = google_pubsub_topic.gtfs-rt-archiver-staging-heartbeat.id
    data       = base64encode(jsonencode({ limit = null }))
  }
}
