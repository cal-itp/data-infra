output "google_container_cluster_tfer--data-infra-apps_self_link" {
  value = google_container_cluster.tfer--data-infra-apps.self_link
}

output "google_container_node_pool_tfer--data-infra-apps_apps-v2_id" {
  value = google_container_node_pool.tfer--data-infra-apps_apps-v2.id
}

output "google_container_node_pool_tfer--data-infra-apps_gtfsrt-v4_id" {
  value = google_container_node_pool.tfer--data-infra-apps_gtfsrt-v4.id
}

output "google_container_node_pool_tfer--data-infra-apps_jobs-v1_id" {
  value = google_container_node_pool.tfer--data-infra-apps_jobs-v1.id
}

output "google_container_node_pool_tfer--data-infra-apps_jupyterhub-users_id" {
  value = google_container_node_pool.tfer--data-infra-apps_jupyterhub-users.id
}

output "google_container_cluster_airflow-jobs_name" {
  value = google_container_cluster.airflow-jobs.name
}

output "google_container_cluster_airflow-jobs_endpoint" {
  value = google_container_cluster.airflow-jobs.endpoint
}

output "google_container_cluster_airflow-jobs_ca_certificate" {
  value = google_container_cluster.airflow-jobs.master_auth[0].cluster_ca_certificate
}

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
