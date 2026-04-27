resource "google_monitoring_dashboard" "gtfs_rt_archiver" {
  dashboard_json = file("${path.module}/dashboards/gtfs-rt-archiver.json")
}
