# High-frequency archiver lane for study cohorts (issue #5566).
#
# A full parallel copy of the standard archiver pipeline, built from its own
# source in services/gtfs-rt-archiver-high-frequency. Nothing here touches the
# standard archiver's resources in service.tf / workflow.tf: the cohort feeds keep
# running on the standard 20s clock as well, so the published RT dataset never
# develops a gap for a study agency.
#
# Every resource except the data and config buckets is gated on
# var.high_frequency_enabled.

# Not count-gated: gating a data bucket on the toggle would delete the study's
# collected data the moment the study is switched off.
resource "google_storage_bucket" "gtfs-rt-raw-high-frequency" {
  name     = "calitp-gtfs-rt-raw-high-frequency"
  project  = "cal-itp-data-infra"
  location = "US-WEST2"

  # STANDARD, not Nearline/Coldline: those bill a 128 KiB minimum per object and
  # RT protobufs are far smaller, so a colder class would cost more, not less, for
  # this object shape -- and would add early-deletion fees on top.
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  # Deletes each object automatically 730 days after it was written, which outlasts
  # the planned ~1.5-year study so none of its data expires before it ends. This is a
  # deletion schedule, not a retention policy: a retention_policy does the
  # opposite and blocks deleting or replacing objects until they reach a set age
  # (calitp-gtfs-rt-raw-v2 has a 365-day one). This bucket deliberately has no
  # retention_policy, so study data -- or the output of a misconfigured run -- can
  # still be deleted early. Nothing blocks an overwrite either, but the archiver
  # partitions by full-precision publish time, so colliding paths are not expected.
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 730
    }
  }
}

# The archiver service account already holds project-level roles/storage.objectUser,
# so this binding is not strictly required. It is here so the grant is visible
# beside the bucket it applies to rather than only in the project-wide IAM module.
resource "google_storage_bucket_iam_member" "gtfs-rt-raw-high-frequency-writer" {
  bucket = google_storage_bucket.gtfs-rt-raw-high-frequency.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email}"
}

# The lane's download config: which feeds to archive, in the same JSONL format
# Airflow writes for the standard archiver. Maintained by hand under
# source/configs.jsonl.gz, so feeds can change without a PR and need not be in
# Airtable. Not count-gated, so the config survives turning the lane off and on.
resource "google_storage_bucket" "gtfs-rt-high-frequency-config" {
  name     = "calitp-gtfs-rt-high-frequency-config"
  project  = "cal-itp-data-infra"
  location = "US-WEST2"

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  # Keeps every previous version of source/configs.jsonl.gz, so feed changes made
  # without a PR still have a history.
  versioning {
    enabled = true
  }

  # The heartbeat only reads the last 5 days of dated copies; drop the rest,
  # including their noncurrent versions. The hand-edited source/ object is kept.
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age            = 30
      matches_prefix = ["gtfs_download_configs/"]
      with_state     = "ANY"
    }
  }
}

# Read by the heartbeat; read and written by the daily refresh workflow. As with
# the data bucket, the project-level roles/storage.objectUser already covers this,
# and the binding is here for visibility.
resource "google_storage_bucket_iam_member" "gtfs-rt-high-frequency-config-user" {
  bucket = google_storage_bucket.gtfs-rt-high-frequency-config.name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email}"
}

# Copies source/configs.jsonl.gz into today's gtfs_download_configs/dt=... path,
# because the heartbeat ignores configs older than 5 days.
resource "google_workflows_workflow" "gtfs-rt-archiver-high-frequency-config-refresh" {
  count = local.high_frequency_count

  name            = "gtfs-rt-archiver-high-frequency-config-refresh"
  description     = "GTFS-RT Archiver high-frequency daily download-config refresh"
  region          = "us-west2"
  project         = "cal-itp-data-infra"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

  source_contents = file("${local.hf_source_path}/config_refresh.yaml")

  user_env_vars = {
    "CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG" = google_storage_bucket.gtfs-rt-high-frequency-config.name
  }
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver-high-frequency-config-refresh" {
  count = local.high_frequency_count

  name        = "gtfs-rt-archiver-high-frequency-config-refresh"
  description = "GTFS-RT Archiver high-frequency daily download-config refresh"
  region      = "us-west2"
  project     = "cal-itp-data-infra"
  time_zone   = "America/Los_Angeles"
  schedule    = "0 4 * * *"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.gtfs-rt-archiver-high-frequency-config-refresh[0].id}/executions"

    oauth_token {
      service_account_email = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email
    }
  }
}

resource "google_pubsub_topic" "gtfs-rt-archiver-high-frequency-clock" {
  count = local.high_frequency_count

  name    = "gtfs-rt-archiver-high-frequency-clock"
  project = "cal-itp-data-infra"
}

resource "google_pubsub_topic" "gtfs-rt-archiver-high-frequency-heartbeat" {
  count = local.high_frequency_count

  name    = "gtfs-rt-archiver-high-frequency-heartbeat"
  project = "cal-itp-data-infra"
}

resource "google_pubsub_topic" "gtfs-rt-archiver-high-frequency" {
  count = local.high_frequency_count

  name    = "gtfs-rt-archiver-high-frequency"
  project = "cal-itp-data-infra"
}

resource "google_eventarc_trigger" "gtfs-rt-archiver-high-frequency-clock" {
  count = local.high_frequency_count

  name     = "gtfs-rt-archiver-high-frequency-clock"
  location = "us-west2"
  project  = "cal-itp-data-infra"

  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  destination {
    workflow = google_workflows_workflow.gtfs-rt-archiver-high-frequency-clock[0].id
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.gtfs-rt-archiver-high-frequency-clock[0].id
    }
  }
}

resource "google_workflows_workflow" "gtfs-rt-archiver-high-frequency-clock" {
  count = local.high_frequency_count

  name            = "gtfs-rt-archiver-high-frequency-clock"
  description     = "GTFS-RT Archiver high-frequency clock (study cohort)"
  region          = "us-west2"
  project         = "cal-itp-data-infra"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

  source_contents = templatefile("${local.hf_source_path}/clock_high_frequency.yaml", {
    cadence_seconds = var.high_frequency_cadence_seconds
    max_tick_index  = local.high_frequency_max_tick_index
  })

  # Quieter than the standard clock's LOG_ALL_CALLS / EXECUTION_HISTORY_DETAILED:
  # this workflow runs ~7x as many steps, and issue #5572 is actively trying to
  # reduce archiver log ingestion.
  call_log_level          = "LOG_ERRORS_ONLY"
  execution_history_level = "EXECUTION_HISTORY_BASIC"

  user_env_vars = {
    "CALITP_TOPIC__GTFS_RT_ARCHIVER_HEARTBEAT" = google_pubsub_topic.gtfs-rt-archiver-high-frequency-heartbeat[0].id
  }
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver-high-frequency-clock" {
  count = local.high_frequency_count

  name        = "gtfs-rt-archiver-high-frequency-clock"
  description = "GTFS-RT Archiver high-frequency clock (study cohort)"
  region      = "us-west2"
  project     = "cal-itp-data-infra"
  schedule    = "* * * * *"
  time_zone   = "America/Los_Angeles"

  pubsub_target {
    topic_name = google_pubsub_topic.gtfs-rt-archiver-high-frequency-clock[0].id

    # The clock does not read the payload; Pub/Sub just requires one.
    data = base64encode(jsonencode({}))
  }
}

data "archive_file" "gtfs-rt-archiver-high-frequency" {
  count = local.high_frequency_count

  output_path = local.hf_archive_path
  source_dir  = local.hf_source_path
  type        = "zip"

  excludes = [
    "**/.env",
    "**/.env.*",
    "**/tests/**",
    "**/.git/**",
    "**/.gitignore",
    "**/pyproject.toml",
    "**/*.yaml",
    "**/uv.lock",
    "**/README.md",
    "**/Dockerfile",
  ]
}

resource "google_storage_bucket_object" "gtfs-rt-archiver-high-frequency" {
  count = local.high_frequency_count

  name   = "gtfs-rt-archiver-high-frequency-${data.archive_file.gtfs-rt-archiver-high-frequency[0].output_sha512}.zip"
  bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-rt-archiver_name
  source = local.hf_archive_path

  content_type = "application/zip"
  depends_on   = [data.archive_file.gtfs-rt-archiver-high-frequency]

  provisioner "local-exec" {
    when    = create
    command = "rm ${data.archive_file.gtfs-rt-archiver-high-frequency[0].output_path}"
  }
}

resource "google_cloudfunctions2_function" "gtfs-rt-archiver-high-frequency-heartbeat" {
  count = local.high_frequency_count

  name     = "gtfs-rt-archiver-high-frequency-heartbeat"
  location = "us-west2"

  depends_on = [google_storage_bucket_object.gtfs-rt-archiver-high-frequency]

  service_config {
    available_cpu    = "167m"
    available_memory = "256M"
    ingress_settings = "ALLOW_INTERNAL_ONLY"

    min_instance_count             = 1
    all_traffic_on_latest_revision = true
    service_account_email          = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

    environment_variables = {
      CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG = "gs://${google_storage_bucket.gtfs-rt-high-frequency-config.name}"
      CALITP_TOPIC__GTFS_RT_ARCHIVER      = google_pubsub_topic.gtfs-rt-archiver-high-frequency[0].id
    }
  }

  build_config {
    runtime     = "python311"
    entry_point = "process_clock_event"

    automatic_update_policy {}

    source {
      storage_source {
        bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-rt-archiver_name
        object = google_storage_bucket_object.gtfs-rt-archiver-high-frequency[0].name
      }
    }
  }

  event_trigger {
    trigger_region = "us-west2"
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.gtfs-rt-archiver-high-frequency-heartbeat[0].id
    # A missed tick at this cadence is worthless and a retried one both costs
    # money and adds load on the agency's endpoint.
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email
  }
}

resource "google_cloudfunctions2_function" "gtfs-rt-archiver-high-frequency" {
  count = local.high_frequency_count

  name     = "gtfs-rt-archiver-high-frequency"
  location = "us-west2"

  depends_on = [google_storage_bucket_object.gtfs-rt-archiver-high-frequency]

  service_config {
    available_cpu    = "167m"
    available_memory = "256M"
    ingress_settings = "ALLOW_INTERNAL_ONLY"

    # The hardest guardrail in this change. A separate instance pool means a
    # misconfigured cohort throttles only the study, never the standard
    # archiver's 300-instance pool, and bounds the lane's compute spend
    # structurally rather than by policy.
    #
    # Sized at twice the README's 5-feed cap. With concurrency 1, a request holds
    # an instance for up to REQUEST_CONNECT_TIMEOUT + REQUEST_READ_TIMEOUT (one
    # full cadence), so 5 slow feeds need 5 instances at once before cold starts;
    # the second 5 is headroom. Nothing else enforces the cap, since the feed
    # list is a config file, so this is also what bounds a config with too many
    # feeds: it slows the study down instead of costing more.
    max_instance_count               = 10
    max_instance_request_concurrency = 1

    all_traffic_on_latest_revision = true
    service_account_email          = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

    environment_variables = {
      CALITP_BUCKET__GTFS_RT_RAW = "gs://${google_storage_bucket.gtfs-rt-raw-high-frequency.name}"
      REQUEST_CONNECT_TIMEOUT    = 1

      # Must stay below the cadence. At the standard archiver's 10s, up to four
      # requests would stack against a slow feed -- a thundering herd on a server
      # that is already struggling.
      REQUEST_READ_TIMEOUT = var.high_frequency_cadence_seconds - 1

    }
  }

  build_config {
    runtime     = "python311"
    entry_point = "process_heartbeat_event"

    automatic_update_policy {}

    source {
      storage_source {
        bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-rt-archiver_name
        object = google_storage_bucket_object.gtfs-rt-archiver-high-frequency[0].name
      }
    }
  }

  event_trigger {
    trigger_region        = "us-west2"
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.gtfs-rt-archiver-high-frequency[0].id
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email
  }
}
