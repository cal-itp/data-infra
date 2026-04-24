resource "google_monitoring_notification_channel" "calitp-slack-gcp-monitoring" {
  display_name = "gcp-monitoring"
  type         = "slack"
  labels = {
    channel_name = "#gcp-monitoring"
    team         = "cal-itp"
  }
}
