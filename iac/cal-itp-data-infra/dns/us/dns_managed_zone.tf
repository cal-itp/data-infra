resource "google_dns_managed_zone" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns" {
  cloud_logging_config {
    enable_logging = "false"
  }

  description   = "Private zone for GKE cluster \"us-west2-calitp-airflow2-pr-88ca8ec6-gke\" with cluster suffix \"cluster.local.\" in project \"cal-itp-data-infra\" with scope \"CLUSTER_SCOPE\""
  dns_name      = "cluster.local."
  force_destroy = "false"
  name          = "gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns"

  private_visibility_config {
    gke_clusters {
      gke_cluster_name = "projects/cal-itp-data-infra/locations/us-west2/clusters/us-west2-calitp-airflow2-pr-88ca8ec6-gke"
    }
  }

  project    = "cal-itp-data-infra"
  visibility = "private"
}
