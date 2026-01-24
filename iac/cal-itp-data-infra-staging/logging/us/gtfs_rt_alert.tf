# the empty data block is required to inherit the `provider "google"` block from provider.tf
data "google_project" "project" {
}

resource "google_monitoring_notification_channel" "email" {
  project      = data.google_project.project.project_id
  type         = "email"
  display_name = "GTFS-RT Archivers Email Alert Channel"
  description  = "Send gtfs-rt archivers alerts to email."
  labels = {
    # email_address = "dds.app.notify@dot.ca.gov"
    email_address = "daniel.huang@dot.ca.gov"
  }
}

resource "google_monitoring_alert_policy" "gtfs_rt_bucket_writes_alert" {
  project               = data.google_project.project.project_id
  display_name          = "GTFS-RT Bucket Writes Alert"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email.name]

  # Condition: metric < 1500 in a 15‑minute period
  conditions {
    display_name = "Less than 1500 writes to staging GTFS‑RT bucket in 15 minutes"
    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.staging_gtfs_rt_bucket_writes_metric.name}\" AND resource.type=\"gcs_bucket\""
      duration   = "900s"          # 15 minutes
      comparison = "COMPARISON_LT"
      threshold_value = 1500
      aggregations {
        # 60‑second alignment gives per‑minute counts; the 15‑minute duration
        # then sums those to evaluate the threshold.
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  # Condition: no writes detected for 15 minutes
  conditions {
    display_name = "No writes to staging GTFS‑RT bucket in 15 minutes"
    condition_absent {
      filter   = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.staging_gtfs_rt_bucket_writes_metric.name}\" AND resource.type=\"gcs_bucket\""
      duration = "900s"          # 15 minutes
    }
  }

  documentation {
    content   = "This alert triggers when the number of writes to the staging GTFS‑RT bucket is less than 1500 in 15 minutes, or when no writes are detected for 15 minutes."
    mime_type = "text/markdown"
  }
}

# Trigger when **no** writes are detected for 2 minutes
resource "google_monitoring_alert_policy" "gtfs_rt_test_alert" {
  project               = data.google_project.project.project_id
  display_name          = "GTFS-RT Test Alert – Guaranteed Trigger"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.email.name]

  conditions {
    display_name = "No writes to staging GTFS‑RT bucket in 2 minutes"
    condition_absent {
      filter   = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.staging_gtfs_rt_bucket_writes_metric.name}\" AND resource.type=\"gcs_bucket\""
      duration = "120s"          # Minimum 2 minutes for absence conditions
    }
  }

  documentation {
    content   = "This test alert fires whenever no writes are received by the GTFS‑RT bucket within a 2‑minute window."
    mime_type = "text/markdown"
  }
}
