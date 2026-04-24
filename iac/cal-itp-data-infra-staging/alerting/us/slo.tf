resource "google_monitoring_slo" "gtfs-rt-archiver-latency" {
  service = google_monitoring_service.gtfs-rt-archiver.service_id

  slo_id       = "gtfs-rt-archiver-latency"
  display_name = "99% 10s Latency for GTFS-RT Archiver"

  goal            = 0.99
  calendar_period = "DAY"

  basic_sli {
    latency {
      threshold = "10s"
    }
  }
}
