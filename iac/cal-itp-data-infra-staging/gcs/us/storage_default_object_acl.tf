resource "google_storage_default_object_acl" "tfer--calitp-staging-data-analyses-portfolio" {
  bucket      = "calitp-staging-data-analyses-portfolio"
  role_entity = ["OWNER:project-editors-473674835135", "OWNER:project-owners-473674835135", "READER:project-viewers-473674835135"]
}

resource "google_storage_default_object_acl" "tfer--calitp-staging-data-analyses-portfolio-draft" {
  bucket      = "calitp-staging-data-analyses-portfolio-draft"
  role_entity = ["OWNER:project-editors-473674835135", "OWNER:project-owners-473674835135", "READER:project-viewers-473674835135"]
}

resource "google_storage_default_object_acl" "tfer--dataproc-staging-us-west2-473674835135-t87wkokr" {
  bucket      = "dataproc-staging-us-west2-473674835135-t87wkokr"
  role_entity = ["OWNER:project-editors-473674835135", "OWNER:project-owners-473674835135", "READER:project-viewers-473674835135"]
}

resource "google_storage_default_object_acl" "tfer--dataproc-temp-us-west2-473674835135-yuzmmdyk" {
  bucket      = "dataproc-temp-us-west2-473674835135-yuzmmdyk"
  role_entity = ["OWNER:project-editors-473674835135", "OWNER:project-owners-473674835135", "READER:project-viewers-473674835135"]
}
