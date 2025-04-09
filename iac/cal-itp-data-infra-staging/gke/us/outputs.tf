output "google_container_cluster_nginx_staging_self_link" {
  value = google_container_cluster.nginx-staging.self_link
}

output "google_container_cluster_nginx_staging_endpoint" {
  value = google_container_cluster.nginx-staging.endpoint
}

output "google_container_cluster_nginx_staging_ca_certificate" {
  value = google_container_cluster.nginx-staging.master_auth[0].cluster_ca_certificate
}
