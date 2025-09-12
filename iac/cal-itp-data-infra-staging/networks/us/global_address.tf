resource "google_compute_global_address" "static-load-balancer-address" {
  name = "static-load-balancer-address"
}

resource "google_compute_global_address" "enghouse-sftp" {
  name = "enghouse-sftp-load-balancer"
}
