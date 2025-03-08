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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-982bffda"
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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-f2c6ebb9"
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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-4de9cc73"
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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-eda43ed7"
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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-dea74e39"
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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-52b37e88"
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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-2d506811"
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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-5b0c78e4"
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
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-22a6d081"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-a"
}
