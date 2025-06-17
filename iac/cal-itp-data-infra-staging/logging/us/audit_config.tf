resource "google_bigquery_dataset" "audit" {
  project                    = "cal-itp-data-infra-staging"
  location                   = "us-west2"
  dataset_id                 = "audit"
  delete_contents_on_destroy = true
}

resource "google_logging_project_sink" "audit" {
  project     = "cal-itp-data-infra-staging"
  name        = "bigquery-sink"
  destination = "bigquery.googleapis.com/projects/cal-itp-data-infra-staging/datasets/${google_bigquery_dataset.audit.dataset_id}"
  filter      = <<-EOT
  protoPayload.metadata."@type"="type.googleapis.com/google.cloud.audit.BigQueryAuditMetadata"
  EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
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
