resource "google_pubsub_topic" "gtfs-rt-feed-archiver" {
  name    = "gtfs-rt-feed-archiver"
  project = "cal-itp-data-infra-staging"
}

resource "google_eventarc_trigger" "gtfs-rt-feed-archiver" {
  name     = "gtfs-rt-feed-archiver"
  location = "us-west2"
  project  = "cal-itp-data-infra-staging"

  service_account = data.terraform_remote_state.iam.outputs.google_service_account_workflow-service-account_email

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  destination {
    workflow = google_workflows_workflow.gtfs-rt-feed-archiver.id
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.gtfs-rt-feed-archiver.id
    }
  }
}

resource "google_workflows_workflow" "gtfs-rt-archiver" {
  name            = "gtfs-rt-archiver"
  region          = "us-west2"
  project         = "cal-itp-data-infra-staging"
  description     = "GTFS-RT Archiver"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_workflow-service-account_email
  source_contents = templatefile("${local.workflow_path}/gtfs-rt-archiver.yaml", {})

  call_log_level          = "LOG_ALL_CALLS"
  execution_history_level = "EXECUTION_HISTORY_DETAILED"

  user_env_vars = {
    "GTFS_RT_ARCHIVER__TOPIC" = google_pubsub_topic.gtfs-rt-feed-archiver.id
  }
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver" {
  project          = "cal-itp-data-infra-staging"
  name             = "gtfs-rt-archiver"
  description      = "GTFS-RT Archiver heartbeat"
  schedule         = "* * * * *"
  time_zone        = "America/Los_Angeles"
  attempt_deadline = "5s"
  region           = "us-west2"

  pubsub_target {
    topic_name = google_pubsub_topic.gtfs-rt-feed-archiver.id
    data       = base64encode(jsonencode({ argument = jsonencode({ limit = 1 }) }))
  }
}
