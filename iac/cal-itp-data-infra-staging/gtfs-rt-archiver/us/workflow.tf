resource "google_workflows_workflow" "gtfs-rt-feed-archiver" {
  name            = "gtfs-rt-feed-archiver"
  region          = "us-west2"
  project         = "cal-itp-data-infra-staging"
  description     = "GTFS-RT Feed Archiver"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_workflow-service-account_email
  source_contents = templatefile("${local.workflow_path}/gtfs-rt-feed-archiver.yaml", {})

  call_log_level          = "LOG_ALL_CALLS"
  execution_history_level = "EXECUTION_HISTORY_DETAILED"

  user_env_vars = {
    "CALITP_BUCKET__GTFS_RT_RAW" = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-rt-raw-v2_name
  }
}

resource "google_cloud_tasks_queue" "gtfs-rt-feed-archiver" {
  name     = "gtfs-rt-feed-archiver-1"
  location = "us-west2"
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
    "GTFS_RT_ARCHIVER__TASK_QUEUE"      = google_cloud_tasks_queue.gtfs-rt-feed-archiver.id,
    "GTFS_RT_ARCHIVER__CHILD_WORKFLOW"  = google_workflows_workflow.gtfs-rt-feed-archiver.name,
    "GTFS_RT_ARCHIVER__SERVICE_ACCOUNT" = data.terraform_remote_state.iam.outputs.google_service_account_workflow-service-account_email,
  }
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver" {
  project          = "cal-itp-data-infra-staging"
  name             = "gtfs-rt-archiver"
  description      = "Cloud Scheduler for the GTFS-RT Archiver"
  schedule         = "*/15 * * * *"
  time_zone        = "America/Los_Angeles"
  attempt_deadline = "60s"
  region           = "us-west2"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.gtfs-rt-archiver.id}/executions"
    body = base64encode(
      jsonencode({
        argument     = jsonencode({ limit = 1 }),
        callLogLevel = "CALL_LOG_LEVEL_UNSPECIFIED"
      })
    )

    oauth_token {
      service_account_email = data.terraform_remote_state.iam.outputs.google_service_account_workflow-service-account_email
    }
  }
}
