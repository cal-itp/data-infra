resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-apps-v2-0dfb61fb-grp" {
  base_instance_name             = "gke-data-infra-apps-apps-v2-0dfb61fb"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-apps-v2-0dfb61fb-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "1"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-a55e8d05"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-b"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-apps-v2-24a4cc95-grp" {
  base_instance_name             = "gke-data-infra-apps-apps-v2-24a4cc95"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-apps-v2-24a4cc95-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "2"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-b3e3e463"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-c"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-apps-v2-2729c0c0-grp" {
  base_instance_name             = "gke-data-infra-apps-apps-v2-2729c0c0"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-apps-v2-2729c0c0-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "1"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-c92d48f3"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-a"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-gtfsrt-v4-2a13e092-grp" {
  base_instance_name             = "gke-data-infra-apps-gtfsrt-v4-2a13e092"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-gtfsrt-v4-2a13e092-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "2"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-070f7b18"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-a"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-gtfsrt-v4-7577d4d7-grp" {
  base_instance_name             = "gke-data-infra-apps-gtfsrt-v4-7577d4d7"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-gtfsrt-v4-7577d4d7-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "1"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-8c4a685b"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-c"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-gtfsrt-v4-b003cc53-grp" {
  base_instance_name             = "gke-data-infra-apps-gtfsrt-v4-b003cc53"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-gtfsrt-v4-b003cc53-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "1"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-daedc7bd"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-b"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jobs-v1-625ec063-grp" {
  base_instance_name             = "gke-data-infra-apps-jobs-v1-625ec063"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-jobs-v1-625ec063-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "1"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-40686f4e"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-c"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jobs-v1-8eec22fb-grp" {
  base_instance_name             = "gke-data-infra-apps-jobs-v1-8eec22fb"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-jobs-v1-8eec22fb-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "1"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-dec41dab"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-b"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jobs-v1-cd18666b-grp" {
  base_instance_name             = "gke-data-infra-apps-jobs-v1-cd18666b"
  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-jobs-v1-cd18666b-grp"
  project                        = "cal-itp-data-infra"
  target_size                    = "1"
  wait_for_instances             = "false"

  update_policy {
    max_surge_fixed       = "1"
    max_unavailable_fixed = "1"
    minimal_action        = "REPLACE"
    replacement_method    = "SUBSTITUTE"
    type                  = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-e0eae9ba"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-a"
}
