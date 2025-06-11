output "google_container_cluster_airflow-jobs-staging_name" {
  value = google_container_cluster.airflow-jobs-staging.name
}

output "google_container_cluster_airflow-jobs-staging_endpoint" {
  value = google_container_cluster.airflow-jobs-staging.endpoint
}

output "google_container_cluster_airflow-jobs-staging_ca_certificate" {
  value = google_container_cluster.airflow-jobs-staging.master_auth[0].cluster_ca_certificate
}
