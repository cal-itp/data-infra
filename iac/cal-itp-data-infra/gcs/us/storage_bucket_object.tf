resource "google_storage_bucket_object" "calitp_gtfs_index" {
  name         = "index.html"
  bucket       = google_storage_bucket.calitp-gtfs.name
  content_type = "text/html"
  content      = <<EOF
    <!DOCTYPE html>
    <html lang='en'>
      <head>
        <title>Cal-ITP</title>
        <meta charset='utf-8'>
      </head>
      <body>Hello from Cal-ITP.</body>
    </html>
  EOF
}
