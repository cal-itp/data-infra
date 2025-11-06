resource "google_workflows_workflow" "gtfs-rt-archiver" {
  name            = "gtfs-rt-archiver"
  region          = "us-west2"
  project         = "cal-itp-data-infra-staging"
  description     = "GTFS-RT Archiver"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_email
  source_contents = templatefile("${local.workflow_path}/gtfs-rt.yaml",{})
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver" {
  project          = "cal-itp-data-infra-staging"
  name             = "gtfs-rt-archiver"
  description      = "Cloud Scheduler GTFS-RT Archiver"
  schedule         = "*/3 * * * *"
  time_zone        = "America/Los_Angeles"
  attempt_deadline = "320s"
  region           = "us-west2"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.gtfs-rt-archiver.id}/executions"
    body = base64encode(
      jsonencode({
        "argument" : "{}",
        "callLogLevel" : "CALL_LOG_LEVEL_UNSPECIFIED"
      })
    )

    oauth_token {
      service_account_email = data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}
