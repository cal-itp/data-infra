resource "google_monitoring_notification_channel" "calitp-slack-gcp-monitoring" {
  display_name = "gcp-monitoring"
  type         = "slack"
  labels = {
    channel_name = "#gcp-monitoring"
    team         = "cal-itp"
  }

  # The Slack OAuth token is set outside Terraform; the API rejects updates that drop it.
  lifecycle {
    ignore_changes = [labels["auth_token"]]
  }
}
