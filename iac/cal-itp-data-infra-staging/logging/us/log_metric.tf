resource "google_logging_metric" "staging_gtfs_rt_bucket_writes_metric" {
  name        = "staging_gtfs_rt_bucket_writes_metric"
  description = "Counts writes to the staging GTFS-RT bucket."
  filter      = <<-FILTER
    resource.type = "gcs_bucket"
    protoPayload.methodName = "storage.objects.create"
    protoPayload.resourceName = "projects/_/buckets/calitp-staging-gtfs-rt-raw-v2"
  FILTER
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}
