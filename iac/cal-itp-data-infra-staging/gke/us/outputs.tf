output "google_container_cluster_sftp-endpoints_name" {
  value = google_container_cluster.sftp-endpoints.name
}

output "google_container_cluster_sftp-endpoints_endpoint" {
  value = google_container_cluster.sftp-endpoints.endpoint
}

output "google_container_cluster_sftp-endpoints_ca_certificate" {
  value     = google_container_cluster.sftp-endpoints.master_auth[0].cluster_ca_certificate
  sensitive = true
}
