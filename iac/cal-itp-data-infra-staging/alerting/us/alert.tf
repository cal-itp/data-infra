resource "google_monitoring_alert_policy" "alert_policy" {
  display_name          = "Burn rate on 99% 10s Latency for GTFS-RT Archiver"
  combiner              = "OR"
  notification_channels = [google_monitoring_notification_channel.calitp-meta.id]

  conditions {
    display_name = "Burn rate on 99% 10s Latency for GTFS-RT Archiver"
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.gtfs-rt-archiver-latency.id}\", \"3600s\")"
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      trigger {
        count = 1
      }
    }
  }
}
