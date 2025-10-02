resource "google_project_service" "enable-logging-api" {
  service = "logging.googleapis.com"
  project = data.google_project.project.project_id
}

resource "google_pubsub_topic" "sentineliam-topic" {
  count   = var.topic-name != "sentineliam-topic" ? 0 : 1
  name    = var.topic-name
  project = data.google_project.project.project_id
}

resource "google_pubsub_subscription" "sentinel-subscription" {
  project    = data.google_project.project.project_id
  name       = "sentinel-subscription-IAMlogs"
  topic      = var.topic-name
  depends_on = [google_pubsub_topic.sentineliam-topic]
}

resource "google_logging_project_sink" "sentinel-sink" {
  project     = data.google_project.project.project_id
  count       = var.organization-id == "" ? 1 : 0
  name        = "IAM-logs-sentinel-sink"
  destination = "pubsub.googleapis.com/projects/${data.google_project.project.project_id}/topics/${var.topic-name}"
  depends_on  = [google_pubsub_topic.sentineliam-topic]

  filter                 = "protoPayload.serviceName=iam.googleapis.com"
  unique_writer_identity = true
}

resource "google_logging_organization_sink" "sentinel-organization-sink" {
  count       = var.organization-id == "" ? 0 : 1
  name        = "IAM-logs-organization-sentinel-sink"
  org_id      = var.organization-id
  destination = "pubsub.googleapis.com/projects/${data.google_project.project.project_id}/topics/${var.topic-name}"

  filter           = "protoPayload.serviceName=iam.googleapis.com"
  include_children = true
}

resource "google_project_iam_binding" "log-writer" {
  count   = var.organization-id == "" ? 1 : 0
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"

  members = [
    google_logging_project_sink.sentinel-sink[0].writer_identity
  ]
}

resource "google_project_iam_binding" "log-writer-organization" {
  count   = var.organization-id == "" ? 0 : 1
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"

  members = [
    google_logging_organization_sink.sentinel-organization-sink[0].writer_identity
  ]
}
