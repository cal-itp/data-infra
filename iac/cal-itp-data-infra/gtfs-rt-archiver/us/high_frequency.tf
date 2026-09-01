# High-frequency archiver lane for study cohorts (issue #5566).
#
# A full parallel copy of the standard archiver pipeline, built from the same
# source zip and differing only in configuration. Nothing here touches the
# production resources in service.tf / workflow.tf: the cohort feeds keep running
# on the standard 20s clock as well, so the production RT dataset never develops a
# gap for a study agency.
#
# Every resource except the bucket is gated on the cohort being non-empty.

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

  # Deliberately no retention_policy. calitp-gtfs-rt-raw-v2 has a 365-day one,
  # which would make a runaway's objects undeletable for a year.
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 180
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

resource "google_pubsub_topic" "gtfs-rt-archiver-high-frequency-clock" {
  count = local.high_frequency_enabled

  name    = "gtfs-rt-archiver-high-frequency-clock"
  project = "cal-itp-data-infra"
}

resource "google_pubsub_topic" "gtfs-rt-archiver-high-frequency-heartbeat" {
  count = local.high_frequency_enabled

  name    = "gtfs-rt-archiver-high-frequency-heartbeat"
  project = "cal-itp-data-infra"
}

resource "google_pubsub_topic" "gtfs-rt-archiver-high-frequency" {
  count = local.high_frequency_enabled

  name    = "gtfs-rt-archiver-high-frequency"
  project = "cal-itp-data-infra"
}

resource "google_eventarc_trigger" "gtfs-rt-archiver-high-frequency-clock" {
  count = local.high_frequency_enabled

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
  count = local.high_frequency_enabled

  name            = "gtfs-rt-archiver-high-frequency-clock"
  description     = "GTFS-RT Archiver high-frequency clock (study cohort)"
  region          = "us-west2"
  project         = "cal-itp-data-infra"
  service_account = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

  source_contents = templatefile("${local.source_path}/clock_high_frequency.yaml", {
    cadence_seconds = var.high_frequency_cadence_seconds
    max_tick_index  = local.high_frequency_max_tick_index
  })

  # Quieter than the production clock's LOG_ALL_CALLS / EXECUTION_HISTORY_DETAILED:
  # this workflow runs ~7x as many steps, and issue #5572 is actively trying to
  # reduce archiver log ingestion.
  call_log_level          = "LOG_ERRORS_ONLY"
  execution_history_level = "EXECUTION_HISTORY_BASIC"

  user_env_vars = {
    "CALITP_TOPIC__GTFS_RT_ARCHIVER_HEARTBEAT" = google_pubsub_topic.gtfs-rt-archiver-high-frequency-heartbeat[0].id
  }
}

resource "google_cloud_scheduler_job" "gtfs-rt-archiver-high-frequency-clock" {
  count = local.high_frequency_enabled

  name        = "gtfs-rt-archiver-high-frequency-clock"
  description = "GTFS-RT Archiver high-frequency clock (study cohort)"
  region      = "us-west2"
  project     = "cal-itp-data-infra"
  schedule    = "* * * * *"
  time_zone   = "America/Los_Angeles"

  pubsub_target {
    topic_name = google_pubsub_topic.gtfs-rt-archiver-high-frequency-clock[0].id

    # The clock forwards this into each tick's message. Setting {"limit": 1}
    # canaries a single feed for the first hour of a study without a redeploy.
    data = base64encode(jsonencode({ limit = null }))
  }
}

resource "google_cloudfunctions2_function" "gtfs-rt-archiver-high-frequency-heartbeat" {
  count = local.high_frequency_enabled

  name     = "gtfs-rt-archiver-high-frequency-heartbeat"
  location = "us-west2"

  depends_on = [google_storage_bucket_object.gtfs-rt-archiver]

  service_config {
    available_cpu    = "167m"
    available_memory = "256M"
    ingress_settings = "ALLOW_INTERNAL_ONLY"

    min_instance_count             = 1
    all_traffic_on_latest_revision = true
    service_account_email          = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

    environment_variables = {
      CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-download-config_name}"
      CALITP_TOPIC__GTFS_RT_ARCHIVER      = google_pubsub_topic.gtfs-rt-archiver-high-frequency[0].id

      # Presence of this variable is what puts the heartbeat into cohort mode. A
      # JSON array, because feed names come from Airtable free text and can
      # contain commas.
      CALITP_GTFS_RT_HIGH_FREQUENCY_COHORT = jsonencode(var.high_frequency_cohort)
    }
  }

  build_config {
    runtime     = "python311"
    entry_point = "process_clock_event"

    automatic_update_policy {}

    source {
      storage_source {
        bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-rt-archiver_name
        object = "gtfs-rt-archiver-${data.archive_file.gtfs-rt-archiver.output_sha512}.zip"
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
  count = local.high_frequency_enabled

  name     = "gtfs-rt-archiver-high-frequency"
  location = "us-west2"

  depends_on = [google_storage_bucket_object.gtfs-rt-archiver]

  service_config {
    available_cpu    = "167m"
    available_memory = "256M"
    ingress_settings = "ALLOW_INTERNAL_ONLY"

    # The hardest guardrail in this change. A separate instance pool means a
    # misconfigured cohort throttles only the study, never the production
    # archiver's 300-instance pool, and bounds the lane's compute spend
    # structurally rather than by policy.
    max_instance_count               = 5
    max_instance_request_concurrency = 1

    all_traffic_on_latest_revision = true
    service_account_email          = data.terraform_remote_state.iam.outputs.google_service_account_gtfs-rt-archiver_email

    environment_variables = {
      CALITP_BUCKET__GTFS_RT_RAW = "gs://${google_storage_bucket.gtfs-rt-raw-high-frequency.name}"
      REQUEST_CONNECT_TIMEOUT    = 1

      # Must stay below the cadence. At the production value of 10s, up to four
      # requests would stack against a slow feed -- a thundering herd on a server
      # that is already struggling.
      REQUEST_READ_TIMEOUT = var.high_frequency_cadence_seconds - 1

      # This bucket has no retention policy, so a colliding object path would
      # overwrite silently. Turn that into a logged PreconditionFailed instead.
      # Deliberately not set in production, where benign Pub/Sub redelivery
      # legitimately rewrites the same object.
      CALITP_GTFS_RT_FAIL_ON_OVERWRITE = "true"
    }
  }

  build_config {
    runtime     = "python311"
    entry_point = "process_heartbeat_event"

    automatic_update_policy {}

    source {
      storage_source {
        bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-rt-archiver_name
        object = "gtfs-rt-archiver-${data.archive_file.gtfs-rt-archiver.output_sha512}.zip"
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
