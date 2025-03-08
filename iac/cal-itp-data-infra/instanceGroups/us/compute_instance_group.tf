resource "google_compute_instance_group" "tfer--us-west1-a-002F-gke-data-infra-apps-apps-v2-2729c0c0-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-apps-v2-2729c0c0-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-a/instances/gke-data-infra-apps-apps-v2-2729c0c0-3vg6"]
  name        = "gke-data-infra-apps-apps-v2-2729c0c0-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-a"
}

resource "google_compute_instance_group" "tfer--us-west1-a-002F-gke-data-infra-apps-gtfsrt-v4-2a13e092-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-gtfsrt-v4-2a13e092-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-a/instances/gke-data-infra-apps-gtfsrt-v4-2a13e092-7dtl", "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-a/instances/gke-data-infra-apps-gtfsrt-v4-2a13e092-pwqm"]
  name        = "gke-data-infra-apps-gtfsrt-v4-2a13e092-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-a"
}

resource "google_compute_instance_group" "tfer--us-west1-a-002F-gke-data-infra-apps-jobs-v1-cd18666b-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-jobs-v1-cd18666b-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-a/instances/gke-data-infra-apps-jobs-v1-cd18666b-cxrn"]
  name        = "gke-data-infra-apps-jobs-v1-cd18666b-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-a"
}

resource "google_compute_instance_group" "tfer--us-west1-b-002F-gke-data-infra-apps-apps-v2-0dfb61fb-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-apps-v2-0dfb61fb-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-b/instances/gke-data-infra-apps-apps-v2-0dfb61fb-0y3d"]
  name        = "gke-data-infra-apps-apps-v2-0dfb61fb-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-b"
}

resource "google_compute_instance_group" "tfer--us-west1-b-002F-gke-data-infra-apps-gtfsrt-v4-b003cc53-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-gtfsrt-v4-b003cc53-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-b/instances/gke-data-infra-apps-gtfsrt-v4-b003cc53-k8nt"]
  name        = "gke-data-infra-apps-gtfsrt-v4-b003cc53-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-b"
}

resource "google_compute_instance_group" "tfer--us-west1-b-002F-gke-data-infra-apps-jobs-v1-8eec22fb-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-jobs-v1-8eec22fb-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-b/instances/gke-data-infra-apps-jobs-v1-8eec22fb-8ol9"]
  name        = "gke-data-infra-apps-jobs-v1-8eec22fb-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-b"
}

resource "google_compute_instance_group" "tfer--us-west1-c-002F-gke-data-infra-apps-apps-v2-24a4cc95-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-apps-v2-24a4cc95-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-c/instances/gke-data-infra-apps-apps-v2-24a4cc95-10ql", "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-c/instances/gke-data-infra-apps-apps-v2-24a4cc95-3ber"]
  name        = "gke-data-infra-apps-apps-v2-24a4cc95-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-c"
}

resource "google_compute_instance_group" "tfer--us-west1-c-002F-gke-data-infra-apps-gtfsrt-v4-7577d4d7-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-gtfsrt-v4-7577d4d7-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-c/instances/gke-data-infra-apps-gtfsrt-v4-7577d4d7-vd84"]
  name        = "gke-data-infra-apps-gtfsrt-v4-7577d4d7-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-c"
}

resource "google_compute_instance_group" "tfer--us-west1-c-002F-gke-data-infra-apps-jobs-v1-625ec063-grp" {
  description = "This instance group is controlled by Instance Group Manager 'gke-data-infra-apps-jobs-v1-625ec063-grp'. To modify instances in this group, use the Instance Group Manager API: https://cloud.google.com/compute/docs/reference/latest/instanceGroupManagers"
  instances   = ["https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/zones/us-west1-c/instances/gke-data-infra-apps-jobs-v1-625ec063-2s5x"]
  name        = "gke-data-infra-apps-jobs-v1-625ec063-grp"
  network     = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/global/networks/default"
  project     = "cal-itp-data-infra"
  zone        = "us-west1-c"
}
