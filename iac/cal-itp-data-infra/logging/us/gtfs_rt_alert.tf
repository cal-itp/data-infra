# the empty data block is required to inherit the `provider "google"` block from provider.tf
data "google_project" "project" {
}

resource "google_monitoring_notification_channel" "email_dds_notify" {
  project      = data.google_project.project.project_id
  type         = "email"
  display_name = "GTFS-RT Archivers Email Alert Channel - DDS App Notify"
  description  = "Send gtfs-rt archivers alerts to dds.app.notify@dot.ca.gov."
  labels = {
    email_address = "dds.app.notify@dot.ca.gov"
  }
}

# 2. Define the Alerting Policy
resource "google_monitoring_alert_policy" "gtfs_low_write_alert" {
  display_name = "Low Write Activity - GTFS Bucket (15m)"
  project      = data.google_project.project.project_id
  combiner     = "OR"
  severity     = "WARNING" # Options: "WARNING", "ERROR", "CRITICAL"

  conditions {
    display_name = "GCS Write Count < 1500 in 15m (MQL)"

    condition_monitoring_query_language {
      query = <<-EOT
        fetch gcs_bucket
        | metric 'storage.googleapis.com/api/request_count'
        | filter (resource.bucket_name == 'calitp-gtfs-rt-raw-v2')
        | filter (metric.method =~ '.*Write.*|.*Upload.*')
        | align delta(15m)
        | every 15m
        | group_by [], [value_request_count_sum: sum(val())]
        | condition val() < 1500
      EOT

      duration = "0s" # Alert immediately when the 15m window falls below 1500

      trigger {
        count = 1
      }
    }
  }

  # This section handles the lifecycle and "No Data" behavior
  alert_strategy {
    # Keeps incident open for 12 hours if data disappears
    auto_close = "43200s"
  }

  # Attach the email notification channel defined above
  notification_channels = [
    google_monitoring_notification_channel.email_dds_notify.name,
  ]

  # Metadata to help Vivian or other team members when they receive the alert
  documentation {
    content   = "The GTFS Realtime raw bucket has dropped below 1500 writes in the last 15 minutes. This usually indicates the ingestion pipeline is stalled or a feed provider is down."
    mime_type = "text/markdown"
  }

  user_labels = {
    environment = "production"
    managed_by  = "terraform"
  }

  enabled = true
}
