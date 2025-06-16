# resource "google_project_iam_audit_config" "audit" {
#   project = "cal-itp-data-infra-staging"

#   audit_log_config {
#     log_type = "ADMIN_READ"
#   }
# }

resource "google_bigquery_dataset" "audit" {
  dataset_id                 = "audit"
  location                   = "us-west2"
  project                    = "cal-itp-data-infra-staging"
  delete_contents_on_destroy = true
}

resource "google_logging_project_sink" "audit_sink" {
  name        = "bigquery-sink"
  destination = "bigquery.googleapis.com/projects/cal-itp-data-infra-staging/datasets/${google_bigquery_dataset.audit.dataset_id}"
  filter      = <<-EOT
  protoPayload.metadata."@type"="type.googleapis.com/google.cloud.audit.BigQueryAuditMetadata"
  EOT

  unique_writer_identity = true
  project                = "cal-itp-data-infra-staging"

  bigquery_options {
    use_partitioned_tables = true # always true if it is false, logs cant export to the bigquery
  }
}
