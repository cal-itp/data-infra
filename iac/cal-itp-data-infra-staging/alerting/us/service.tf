resource "google_monitoring_service" "gtfs-rt-archiver" {
  service_id   = "gtfs-rt-archiver"
  display_name = "GTFS-RT Archiver"

  basic_service {
    service_type = "CLOUD_RUN"
    service_labels = {
      location     = "us-west2"
      service_name = "gtfs-rt-archiver"
    }
  }
}
