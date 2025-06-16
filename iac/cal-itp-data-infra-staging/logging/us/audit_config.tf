resource "google_bigquery_dataset" "audit" {
  dataset_id                 = "audit"
  location                   = "us-west2"
  project                    = "cal-itp-data-infra-staging"
  delete_contents_on_destroy = true
}

resource "google_logging_project_sink" "audit" {
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

resource "google_bigquery_dataset_iam_binding" "audit" {
  project    = "cal-itp-data-infra-staging"
  dataset_id = google_bigquery_dataset.audit.dataset_id
  role       = "roles/bigquery.dataEditor"
  members = [
    google_logging_project_sink.audit.writer_identity,
  ]
  depends_on = [google_bigquery_dataset.audit]
}
