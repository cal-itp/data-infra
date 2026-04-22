resource "google_monitoring_notification_channel" "calitp-meta" {
  display_name = "calitp-meta"
  type         = "slack"
  labels = {
    channel_name = "#calitp-meta"
    team         = "minifast"
  }
}
