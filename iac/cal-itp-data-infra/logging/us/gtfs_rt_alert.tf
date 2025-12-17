resource "google_monitoring_notification_channel" "email" {
  type         = "email"
  display_name = "GTFS-RT Archivers Email Alert Channel"
  description  = "Send gtfs-rt archivers alerts to email."
  labels = {
    email_address = "dds.app.notify@dot.ca.gov"
  }
}

resource "google_monitoring_alert_policy" "gtfs_rt_bucket_writes_alert" {
  display_name          = "GTFS-RT Bucket Writes Alert"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email.name]
  conditions {
    display_name = "Less than 1500 writes to specific bucket in 15 minutes"
    condition_sql {
      query = <<-QUERY
      SELECT count(*) AS row_count FROM `projects/your-project-id/logs/cloudaudit.googleapis.com%2Fdata_access`
      WHERE resource.type = "gcs_bucket"
      AND protoPayload.methodName = "storage.objects.create"
      AND resource.labels.bucket_name = "calitp-gtfs-rt-raw-v2"
      AND STARTS_WITH(protoPayload.resourceName, "calitp-gtfs-rt-raw-v2/trip_updates/")
      QUERY
      minutes {
        periodicity = 15
      }
      row_count_test {
        comparison = "COMPARISON_LT"
        threshold  = 1500
      }
    }
  }
  documentation {
    content   = "This alert triggers when the number of writes to 'calitp-gtfs-rt-raw-v2/trip_updates' is less than 1500 in 15 minutes."
    mime_type = "text/markdown"
  }
}
