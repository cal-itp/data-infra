output "GCP_project_id" {
  value = data.google_project.project.project_id
}

output "GCP_project_number" {
  value = data.google_project.project.number
}

output "GCP_subscription_name" {
  value = google_pubsub_subscription.sentinel-subscription.name
}

output "workload_identity_pool_id" {
  value = local.workload_identity_pool_id
}

output "Service_account_email" {
  value = "${google_service_account.sentinel-service-account.account_id}@${data.google_project.project.project_id}.iam.gserviceaccount.com"
}

output "Identity_federation_pool_id" {
  value = local.workload_identity_pool_id
}

output "Identity_federation_provider_id" {
  value = google_iam_workload_identity_pool_provider.sentinel-workload-identity-pool-provider.workload_identity_pool_provider_id
}
