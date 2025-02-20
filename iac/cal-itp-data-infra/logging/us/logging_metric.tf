resource "google_logging_metric" "tfer--gtfs-rt-url-errors" {
  filter = "logName=\"projects/cal-itp-data-infra/logs/stdout\"\nresource.labels.namespace_name=\"gtfs-rt\"\nseverity=INFO"

  metric_descriptor {
    metric_kind = "DELTA"
    unit        = "1"
    value_type  = "INT64"
  }

  name    = "gtfs-rt-url-errors"
  project = "cal-itp-data-infra"
}
