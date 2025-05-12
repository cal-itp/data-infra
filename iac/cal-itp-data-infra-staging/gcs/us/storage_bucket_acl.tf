resource "google_storage_bucket_acl" "tfer--calitp-staging-data-analyses-portfolio" {
  bucket = "calitp-staging-data-analyses-portfolio"
}

resource "google_storage_bucket_acl" "tfer--calitp-staging-data-analyses-portfolio-draft" {
  bucket = "calitp-staging-data-analyses-portfolio-draft"
}

resource "google_storage_bucket_acl" "tfer--dataproc-staging-us-west2-473674835135-t87wkokr" {
  bucket = "dataproc-staging-us-west2-473674835135-t87wkokr"
}

resource "google_storage_bucket_acl" "tfer--dataproc-temp-us-west2-473674835135-yuzmmdyk" {
  bucket = "dataproc-temp-us-west2-473674835135-yuzmmdyk"
}

resource "google_storage_bucket_acl" "tfer--calitp-staging-gcp-components-tfstate" {
  bucket = "calitp-staging-gcp-components-tfstate"
}
