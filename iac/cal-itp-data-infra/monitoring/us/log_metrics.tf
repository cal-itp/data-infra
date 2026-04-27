# Log-based metrics derived from the GTFS-RT archiver's structured logs.
# Each counts occurrences of a specific error event emitted by
# services/gtfs-rt-archiver-v3/gtfs_rt_archiver_v3/tasks.py, labeled by
# the fields logged alongside — making them alertable and chartable via
# Cloud Monitoring and Managed Service for Prometheus.

resource "google_logging_metric" "gtfs_rt_archiver_http_errors" {
  name        = "gtfs_rt_archiver_http_errors"
  description = "Count of unexpected HTTP response codes from GTFS-RT feed requests, labeled by response code and source feed."

  filter = <<-EOT
    resource.type="k8s_container"
    resource.labels.cluster_name="data-infra-apps"
    jsonPayload.event="unexpected HTTP response code from feed request"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "namespace"
      value_type  = "STRING"
      description = "Kubernetes namespace the archiver pod is in."
    }
    labels {
      key         = "exc_type"
      value_type  = "STRING"
      description = "Exception class name raised by the HTTP client."
    }
    labels {
      key         = "code"
      value_type  = "STRING"
      description = "HTTP response status code."
    }
    labels {
      key         = "record_name"
      value_type  = "STRING"
      description = "Feed name (usually agency + feed type)."
    }
    labels {
      key         = "record_feed_type"
      value_type  = "STRING"
      description = "Feed type (e.g. vehicle_positions, trip_updates)."
    }
  }

  label_extractors = {
    "namespace"        = "EXTRACT(resource.labels.namespace_name)"
    "exc_type"         = "EXTRACT(jsonPayload.exc_type)"
    "code"             = "EXTRACT(jsonPayload.code)"
    "record_name"      = "EXTRACT(jsonPayload.record_name)"
    "record_feed_type" = "EXTRACT(jsonPayload.record_feed_type)"
  }
}

resource "google_logging_metric" "gtfs_rt_archiver_request_errors" {
  name        = "gtfs_rt_archiver_request_errors"
  description = "Count of non-HTTP request exceptions raised by GTFS-RT feed downloads (e.g. connection errors, timeouts)."

  filter = <<-EOT
    resource.type="k8s_container"
    resource.labels.cluster_name="data-infra-apps"
    jsonPayload.event="request exception occurred from feed request"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "namespace"
      value_type  = "STRING"
      description = "Kubernetes namespace the archiver pod is in."
    }
    labels {
      key         = "exc_type"
      value_type  = "STRING"
      description = "Exception class name raised by the HTTP client."
    }
    labels {
      key         = "record_name"
      value_type  = "STRING"
      description = "Feed name (usually agency + feed type)."
    }
    labels {
      key         = "record_feed_type"
      value_type  = "STRING"
      description = "Feed type (e.g. vehicle_positions, trip_updates)."
    }
  }

  label_extractors = {
    "namespace"        = "EXTRACT(resource.labels.namespace_name)"
    "exc_type"         = "EXTRACT(jsonPayload.exc_type)"
    "record_name"      = "EXTRACT(jsonPayload.record_name)"
    "record_feed_type" = "EXTRACT(jsonPayload.record_feed_type)"
  }
}

resource "google_logging_metric" "gtfs_rt_archiver_non_fetch_errors" {
  name        = "gtfs_rt_archiver_non_fetch_errors"
  description = "Count of non-request exceptions raised during GTFS-RT feed download processing (outside the HTTP request itself)."

  filter = <<-EOT
    resource.type="k8s_container"
    resource.labels.cluster_name="data-infra-apps"
    jsonPayload.event="other non-request exception occurred during download_feed"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "namespace"
      value_type  = "STRING"
      description = "Kubernetes namespace the archiver pod is in."
    }
    labels {
      key         = "exc_type"
      value_type  = "STRING"
      description = "Exception class name raised."
    }
    labels {
      key         = "record_name"
      value_type  = "STRING"
      description = "Feed name (usually agency + feed type)."
    }
    labels {
      key         = "record_feed_type"
      value_type  = "STRING"
      description = "Feed type (e.g. vehicle_positions, trip_updates)."
    }
  }

  label_extractors = {
    "namespace"        = "EXTRACT(resource.labels.namespace_name)"
    "exc_type"         = "EXTRACT(jsonPayload.exc_type)"
    "record_name"      = "EXTRACT(jsonPayload.record_name)"
    "record_feed_type" = "EXTRACT(jsonPayload.record_feed_type)"
  }
}
