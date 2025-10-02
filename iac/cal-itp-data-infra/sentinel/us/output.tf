output "GCP_project_id" {
  value = data.google_project.project.project_id
}

output "GCP_project_number" {
  value = data.google_project.project.number
}

output "GCP_subscription_name" {
  value = google_pubsub_subscription.sentinel-subscription.name
}
