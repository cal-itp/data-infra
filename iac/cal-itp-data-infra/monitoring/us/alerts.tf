# Alert policies for the GTFS-RT archiver, matching the pair of alerts
# that previously existed in our in-cluster Grafana / Prometheus stack.
#
# Both queries use the `rate([2m]) * 20` idiom that converts per-second
# rate back to "events per 20-second tick" — which equals the number of
# feeds when the scheduler is healthy, since the ticker fires at :00,
# :20, and :40 every minute (services/gtfs-rt-archiver-v3/ticker.py).

data "google_monitoring_notification_channel" "gtfs_rt_archiver_email" {
  display_name = "GTFS-RT Archivers Email Alert Channel - DDS App Notify"
}

resource "google_monitoring_alert_policy" "gtfs_rt_archiver_huey_tasks_expiring" {
  display_name = "GTFS-RT archiver: Huey tasks expiring"
  combiner     = "OR"
  severity     = "WARNING"

  conditions {
    display_name = "Huey task expirations > 0"

    condition_prometheus_query_language {
      # Any tasks expiring at all is abnormal — it means the consumer
      # queue is backed up past the task TTL.
      query               = "sum(rate(huey_task_signals_total{namespace=\"gtfs-rt-v3\", signal=\"expired\"}[2m])) * 20 > 0"
      duration            = "300s"
      evaluation_interval = "60s"
      alert_rule          = "HueyTasksExpiring"
    }
  }

  notification_channels = [data.google_monitoring_notification_channel.gtfs_rt_archiver_email.name]

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      One or more Huey tasks are expiring before the consumer can run
      them. This usually means the consumer worker pool is too small
      for the incoming tick rate, the Redis broker is having issues,
      or a downstream step (e.g. uploads) is slow enough to back up
      the queue.

      Check:
      - Pod health: `kubectl get pods -n gtfs-rt-v3`
      - Redis: `kubectl logs -n gtfs-rt-v3 deploy/redis`
      - Throughput and p99 latency on the GTFS RT Archiver dashboard
    EOT
  }
}

resource "google_monitoring_alert_policy" "gtfs_rt_archiver_huey_too_few_successes" {
  display_name = "GTFS-RT archiver: Huey task completions too low"
  combiner     = "OR"
  severity     = "WARNING"

  conditions {
    display_name = "Huey task completions < 265 per tick"

    condition_prometheus_query_language {
      # When all feeds are healthy we expect ~the full feed count to
      # complete each 20s tick. 265 is the empirical floor below which
      # something is visibly wrong.
      query               = "sum(rate(huey_task_signals_total{namespace=\"gtfs-rt-v3\", signal=\"complete\"}[2m])) * 20 < 265"
      duration            = "300s"
      evaluation_interval = "60s"
      alert_rule          = "HueyTooFewSuccesses"
    }
  }

  notification_channels = [data.google_monitoring_notification_channel.gtfs_rt_archiver_email.name]

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      Huey task completions per tick have dropped below 265. In a
      healthy state this should roughly equal the count of configured
      feeds, since the ticker fires every 20 seconds and each feed
      produces one task per tick.

      A drop indicates feeds are timing out, the consumer is
      under-provisioned, or feeds are being dropped upstream.

      Check:
      - HTTP Errors / Non-HTTP Request Errors / Non-Fetch Errors
        panels on the GTFS RT Archiver dashboard
      - Airtable Configuration Age (is feed config stale?)
      - Consumer pod count and resource saturation
    EOT
  }
}
