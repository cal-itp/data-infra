locals {
  source_path = "${path.module}/../../../../cloud-functions/gtfs-rt-archiver"
  archive_zip = "gtfs-rt-archiver.zip"
}

data "archive_file" "gtfs-rt-archiver" {
  type             = "zip"
  source_dir       = local.source_dir
  output_path      = local.archive_zip
  output_file_mode = "0666"
}

resource "google_storage_bucket_object" "gtfs-rt-archiver" {
  name                = local.archive_zip
  bucket              = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-cloud-functions_name
  source              = local.archive_zip
  content_disposition = "attachment"
  content_type        = "application/zip"
  depends_on          = [data.archive_file.gtfs-rt-archiver]

  provisioner "local-exec" {
    when    = create
    command = "rm ${data.archive_file.gtfs-rt-archiver.output_path}"
  }
}

resource "google_cloudfunctions2_function" "gtfs-rt-archiver" {
  name     = "gtfs-rt-archiver"
  location = "us-west2"

  depends_on = [google_storage_bucket_object.gtfs-rt-archiver]

  service_config {
    available_memory = "512M"
    service          = "gtfs-rt-archiver"
  }

  build_config {
    runtime     = "python311"
    entry_point = "process_cloud_event"

    source {
      storage_source {
        bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-cloud-functions_name
        object = local.archive_zip
      }
    }
  }
}
