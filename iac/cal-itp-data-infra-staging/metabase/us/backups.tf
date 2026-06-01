# Portable GCS export backups for the Metabase Cloud SQL database.
#
# These are pg_dump exports written to GCS, and are independent of the Cloud SQL
# automated backups configured in sql.tf. A daily Cloud Scheduler job invokes a
# Cloud Workflow, which calls the Cloud SQL Admin instances.export API to dump
# the live database to a timestamped .sql.gz object in a dedicated GCS bucket.
#
# The workflow runs as (and the scheduler authenticates as) the metabase-backup
# service account, which is defined in the iam module (iam/us) and consumed here
# via data.terraform_remote_state.iam.
locals {
  backup_source_path = "${path.module}/workflows"
  backup_runner_sa   = data.terraform_remote_state.iam.outputs.google_service_account_metabase-backup_email
}

# Dedicated bucket for portable pg_dump exports. Single-region us-west2 (matches
# the existing prod bucket's single-region setup and co-locates with the staging
# Cloud SQL instance), no lifecycle (retain forever for now; a retention policy
# can be added later).
resource "google_storage_bucket" "metabase-staging-backups" {
  name     = "calitp-backups-metabase-staging"
  project  = "cal-itp-data-infra-staging"
  location = "us-west2"

  storage_class               = "NEARLINE"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
}

# The Cloud SQL instance performs the export using its own service identity, so
# that identity needs write access to the destination bucket.
resource "google_storage_bucket_iam_member" "metabase-staging-backups" {
  bucket = google_storage_bucket.metabase-staging-backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_sql_database_instance.metabase-staging.service_account_email_address}"
}

resource "google_workflows_workflow" "metabase-staging-backup" {
  name            = "metabase-staging-backup"
  description     = "Daily Metabase Cloud SQL -> GCS pg_dump export"
  region          = "us-west2"
  project         = "cal-itp-data-infra-staging"
  service_account = local.backup_runner_sa

  call_log_level          = "LOG_ALL_CALLS"
  execution_history_level = "EXECUTION_HISTORY_DETAILED"

  source_contents = templatefile("${local.backup_source_path}/metabase-backup.yaml", {
    project  = "cal-itp-data-infra-staging"
    instance = google_sql_database_instance.metabase-staging.name
    database = google_sql_database.metabase-staging.name
    bucket   = google_storage_bucket.metabase-staging-backups.name
  })
}

resource "google_cloud_scheduler_job" "metabase-staging-backup" {
  name        = "metabase-staging-backup"
  description = "Daily Metabase Cloud SQL -> GCS pg_dump export"
  region      = "us-west2"
  project     = "cal-itp-data-infra-staging"
  schedule    = "0 4 * * *"
  time_zone   = "America/Los_Angeles"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.metabase-staging-backup.id}/executions"

    oauth_token {
      service_account_email = local.backup_runner_sa
    }
  }
}
