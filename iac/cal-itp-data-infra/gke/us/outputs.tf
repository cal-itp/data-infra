output "google_container_cluster_tfer--data-infra-apps_self_link" {
  value = "${google_container_cluster.tfer--data-infra-apps.self_link}"
}

output "google_container_node_pool_tfer--data-infra-apps_apps-v2_id" {
  value = "${google_container_node_pool.tfer--data-infra-apps_apps-v2.id}"
}

output "google_container_node_pool_tfer--data-infra-apps_gtfsrt-v4_id" {
  value = "${google_container_node_pool.tfer--data-infra-apps_gtfsrt-v4.id}"
}

output "google_container_node_pool_tfer--data-infra-apps_jobs-v1_id" {
  value = "${google_container_node_pool.tfer--data-infra-apps_jobs-v1.id}"
}

output "google_container_node_pool_tfer--data-infra-apps_jupyterhub-users_id" {
  value = "${google_container_node_pool.tfer--data-infra-apps_jupyterhub-users.id}"
}
