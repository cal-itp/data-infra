resource "google_service_account_key" "metabase-staging-key" {
  service_account_id = data.terraform_remote_state.iam.outputs.google_service_account_metabase-service-account_name
}

resource "metabase_database" "bigquery" {
  name = "bigquery"

  bigquery_details = {
    service_account_key      = base64decode(google_service_account_key.metabase-staging-key.private_key)
    project_id               = "cal-itp-data-infra-staging"
    dataset_filters_type     = "inclusion"
    dataset_filters_patterns = "mart_gtfs,mart_gtfs_audit"
  }
}
