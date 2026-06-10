# Portable GCS export backups for the Metabase Cloud SQL database.
#
# These are pg_dump exports written to GCS, and are independent of the Cloud SQL
# automated backups configured in sql.tf. A daily Cloud Scheduler job invokes a
# Cloud Workflow, which calls the Cloud SQL Admin instances.export API to dump
# the live database to a timestamped .sql.gz object under the exports/ prefix of
# the calitp-backups-metabase bucket.
#
# Unlike staging (which creates a dedicated bucket here), production reuses the
# pre-existing calitp-backups-metabase bucket, which is managed in the gcs/us
# module. The bucket IAM grant that lets the Cloud SQL instance write its dumps
# therefore lives with that bucket in gcs/us (added to its authoritative IAM
# policy), not in this module. Everything else (the runner service account, its
# roles, the workflow, and the scheduler) lives here so it plans and applies
# together.
locals {
  backup_source_path = "${path.module}/workflows"
  backup_runner_sa   = google_service_account.metabase-backup.email
  backup_bucket      = "calitp-backups-metabase"
}

# Identity the Cloud Scheduler job authenticates as and the Cloud Workflow runs
# as. It calls the Cloud SQL Admin instances.export API and triggers the workflow
# execution. Keyless: no JSON key is generated (auth is via GCP identity binding).
resource "google_service_account" "metabase-backup" {
  account_id   = "metabase-backup"
  description  = "Service account for the scheduled Metabase Cloud SQL to GCS export workflow"
  display_name = "metabase-backup"
  project      = "cal-itp-data-infra"
}

resource "google_project_iam_member" "metabase-backup-cloudsql" {
  role    = "roles/cloudsql.editor"
  member  = "serviceAccount:${google_service_account.metabase-backup.email}"
  project = "cal-itp-data-infra"
}

resource "google_workflows_workflow_iam_member" "metabase-backup-invoker" {
  project  = "cal-itp-data-infra"
  location = google_workflows_workflow.metabase-backup.region
  workflow = google_workflows_workflow.metabase-backup.name
  role     = "roles/workflows.invoker"
  member   = "serviceAccount:${google_service_account.metabase-backup.email}"
}

resource "google_workflows_workflow" "metabase-backup" {
  name            = "metabase-backup"
  description     = "Daily Metabase Cloud SQL -> GCS pg_dump export"
  region          = "us-west2"
  project         = "cal-itp-data-infra"
  service_account = local.backup_runner_sa

  call_log_level          = "LOG_ALL_CALLS"
  execution_history_level = "EXECUTION_HISTORY_DETAILED"

  source_contents = templatefile("${local.backup_source_path}/metabase-backup.yaml", {
    project  = "cal-itp-data-infra"
    instance = google_sql_database_instance.metabase.name
    database = google_sql_database.metabase.name
    bucket   = local.backup_bucket
  })
}

resource "google_cloud_scheduler_job" "metabase-backup" {
  name        = "metabase-backup"
  description = "Daily Metabase Cloud SQL -> GCS pg_dump export"
  region      = "us-west2"
  project     = "cal-itp-data-infra"
  schedule    = "0 4 * * *"
  time_zone   = "America/Los_Angeles"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.metabase-backup.id}/executions"

    oauth_token {
      service_account_email = local.backup_runner_sa
    }
  }
}
