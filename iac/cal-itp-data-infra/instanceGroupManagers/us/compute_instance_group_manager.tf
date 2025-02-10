resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-apps-v2-0dfb61fb-grp" {
  base_instance_name = "gke-data-infra-apps-apps-v2-0dfb61fb"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-apps-v2-0dfb61fb-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "1"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-a55e8d05"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-b"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-apps-v2-24a4cc95-grp" {
  base_instance_name = "gke-data-infra-apps-apps-v2-24a4cc95"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-apps-v2-24a4cc95-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "2"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-b3e3e463"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-c"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-apps-v2-2729c0c0-grp" {
  base_instance_name = "gke-data-infra-apps-apps-v2-2729c0c0"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-apps-v2-2729c0c0-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "1"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-apps-v2-c92d48f3"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-a"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-gtfsrt-v4-2a13e092-grp" {
  base_instance_name = "gke-data-infra-apps-gtfsrt-v4-2a13e092"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-gtfsrt-v4-2a13e092-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "2"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-070f7b18"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-a"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-gtfsrt-v4-7577d4d7-grp" {
  base_instance_name = "gke-data-infra-apps-gtfsrt-v4-7577d4d7"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-gtfsrt-v4-7577d4d7-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "1"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-8c4a685b"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-c"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-gtfsrt-v4-b003cc53-grp" {
  base_instance_name = "gke-data-infra-apps-gtfsrt-v4-b003cc53"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-gtfsrt-v4-b003cc53-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "1"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-gtfsrt-v4-daedc7bd"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-b"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jobs-v1-625ec063-grp" {
  base_instance_name = "gke-data-infra-apps-jobs-v1-625ec063"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-jobs-v1-625ec063-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "1"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-40686f4e"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-c"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jobs-v1-8eec22fb-grp" {
  base_instance_name = "gke-data-infra-apps-jobs-v1-8eec22fb"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-jobs-v1-8eec22fb-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "1"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-dec41dab"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-b"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jobs-v1-cd18666b-grp" {
  base_instance_name = "gke-data-infra-apps-jobs-v1-cd18666b"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-jobs-v1-cd18666b-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "1"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jobs-v1-e0eae9ba"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-a"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jupyterhub-users-6aa76dbb-grp" {
  base_instance_name = "gke-data-infra-apps-jupyterhub-users-6aa76dbb"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "YES"
  }

  list_managed_instances_results = "PAGINATED"
  name                           = "gke-data-infra-apps-jupyterhub-users-6aa76dbb-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "3"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jupyterhub-users-af5c5f36"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-c"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jupyterhub-users-b57e08f4-grp" {
  base_instance_name = "gke-data-infra-apps-jupyterhub-users-b57e08f4"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-jupyterhub-users-b57e08f4-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "1"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jupyterhub-users-ed8f771a"
    name              = ""
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-a"
}

resource "google_compute_instance_group_manager" "tfer--gke-data-infra-apps-jupyterhub-users-dddc57ff-grp" {
  base_instance_name = "gke-data-infra-apps-jupyterhub-users-dddc57ff"

  instance_lifecycle_policy {
    default_action_on_failure = "REPAIR"
    force_update_on_repair    = "NO"
  }

  list_managed_instances_results = "PAGELESS"
  name                           = "gke-data-infra-apps-jupyterhub-users-dddc57ff-grp"
  project                        = "cal-itp-data-infra"

  standby_policy {
    initial_delay_sec = "0"
    mode              = "MANUAL"
  }

  target_size           = "2"
  target_stopped_size   = "0"
  target_suspended_size = "0"

  update_policy {
    max_surge_fixed         = "1"
    max_surge_percent       = "0"
    max_unavailable_fixed   = "1"
    max_unavailable_percent = "0"
    minimal_action          = "REPLACE"
    replacement_method      = "SUBSTITUTE"
    type                    = "OPPORTUNISTIC"
  }

  version {
    instance_template = "https://www.googleapis.com/compute/v1/projects/cal-itp-data-infra/regions/us-west1/instanceTemplates/gke-data-infra-apps-jupyterhub-users-7f61d909"
  }

  wait_for_instances_status = "STABLE"
  zone                      = "us-west1-b"
}
