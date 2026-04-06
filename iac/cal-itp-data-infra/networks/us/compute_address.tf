resource "google_compute_address" "enghouse-sftp-address" {
  name         = "enghouse-sftp-address"
  region       = "us-west2"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "elavon-sftp-address" {
  name         = "elavon-sftp-address"
  region       = "us-west2"
  address_type = "EXTERNAL"
}
