resource "google_monitoring_notification_channel" "calitp-meta" {
  display_name = "calitp-meta"
  type         = "slack"
  labels = {
    channel_name = "#calitp-meta"
    team         = "minifast"
  }
}

resource "google_monitoring_notification_channel" "gcp-monitoring" {
  display_name = "gcp-monitoring"
  type         = "slack"
  labels = {
    channel_name = "#gcp-monitoring"
    team         = "cal-itp"
  }
}
