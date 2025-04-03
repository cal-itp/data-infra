resource "google_storage_bucket_iam_policy" "tfer--analysis-output-models" {
  bucket = "b/analysis-output-models"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket = "b/artifacts.cal-itp-data-infra.appspot.com"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--cal-itp-data-infra-002E-appspot-002E-com" {
  bucket = "b/cal-itp-data-infra.appspot.com"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-aggregator-scraper" {
  bucket = "b/calitp-aggregator-scraper"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-airtable" {
  bucket = "b/calitp-airtable"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-amplitude-benefits-events" {
  bucket = "b/calitp-amplitude-benefits-events"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-analytics-data" {
  bucket = "b/calitp-analytics-data"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    },
    {
      "members": [
        "serviceAccount:jupyterlab@cal-itp-data-infra.iam.gserviceaccount.com",
        "user:charlie.c@jarv.us",
        "user:tiffany@calitp.org"
      ],
      "role": "roles/storage.objectCreator"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-backups-grafana" {
  bucket = "b/calitp-backups-grafana"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:backup-grafana@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-backups-metabase" {
  bucket = "b/calitp-backups-metabase"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:backup-metabase@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-backups-sentry" {
  bucket = "b/calitp-backups-sentry"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:backup-sentry@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-backups-test" {
  bucket = "b/calitp-backups-test"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:backups-test@cal-itp-data-infra.iam.gserviceaccount.com",
        "serviceAccount:metabase-backup@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-ci-artifacts" {
  bucket = "b/calitp-ci-artifacts"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-dbt-artifacts" {
  bucket = "b/calitp-dbt-artifacts"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-dbt-python-models" {
  bucket = "b/calitp-dbt-python-models"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-elavon-parsed" {
  bucket = "b/calitp-elavon-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-elavon-raw" {
  bucket = "b/calitp-elavon-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-download-config" {
  bucket = "b/calitp-gtfs-download-config"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-rt-parsed" {
  bucket = "b/calitp-gtfs-rt-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-rt-raw-deprecated" {
  bucket = "b/calitp-gtfs-rt-raw-deprecated"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketWriter"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-rt-raw-v2" {
  bucket = "b/calitp-gtfs-rt-raw-v2"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    },
    {
      "members": [
        "serviceAccount:gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectCreator"
    },
    {
      "members": [
        "serviceAccount:gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectViewer"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-rt-validation" {
  bucket = "b/calitp-gtfs-rt-validation"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-schedule-parsed" {
  bucket = "b/calitp-gtfs-schedule-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-schedule-parsed-hourly" {
  bucket = "b/calitp-gtfs-schedule-parsed-hourly"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-schedule-raw-v2" {
  bucket = "b/calitp-gtfs-schedule-raw-v2"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-schedule-unzipped" {
  bucket = "b/calitp-gtfs-schedule-unzipped"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-schedule-unzipped-hourly" {
  bucket = "b/calitp-gtfs-schedule-unzipped-hourly"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-schedule-validation" {
  bucket = "b/calitp-gtfs-schedule-validation"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:gtfs-rt-archiver@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectCreator"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-gtfs-schedule-validation-hourly" {
  bucket = "b/calitp-gtfs-schedule-validation-hourly"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-jamesl-gcp-components-tfstate" {
  bucket = "b/calitp-jamesl-gcp-components-tfstate"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-map-tiles" {
  bucket = "b/calitp-map-tiles"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "allUsers"
      ],
      "role": "roles/storage.objectViewer"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-metabase-data-public" {
  bucket = "b/calitp-metabase-data-public"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "allUsers"
      ],
      "role": "roles/storage.objectViewer"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-ntd-api-products" {
  bucket = "b/calitp-ntd-api-products"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-ntd-report-validation" {
  bucket = "b/calitp-ntd-report-validation"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-ntd-xlsx-products-clean" {
  bucket = "b/calitp-ntd-xlsx-products-clean"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-ntd-xlsx-products-raw" {
  bucket = "b/calitp-ntd-xlsx-products-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-payments-littlepay-parsed" {
  bucket = "b/calitp-payments-littlepay-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-payments-littlepay-raw" {
  bucket = "b/calitp-payments-littlepay-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-prod-gcp-components-tfstate" {
  bucket = "b/calitp-prod-gcp-components-tfstate"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-publish" {
  bucket = "b/calitp-publish"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-publish-data-analysis" {
  bucket = "b/calitp-publish-data-analysis"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "allUsers"
      ],
      "role": "roles/storage.objectViewer"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-reports-data" {
  bucket = "b/calitp-reports-data"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-state-geoportal-scrape" {
  bucket = "b/calitp-state-geoportal-scrape"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--calitp-state-highway-network-stops" {
  bucket = "b/calitp-state-highway-network-stops"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--cold-storage-outputs-gtfs-data-test" {
  bucket = "b/cold-storage-outputs-gtfs-data-test"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--cold-storage-outputs-gtfs-data-test-charlie-test" {
  bucket = "b/cold-storage-outputs-gtfs-data-test-charlie-test"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--dataproc-staging-us-west2-1005246706141-sfgmtgyp" {
  bucket = "b/dataproc-staging-us-west2-1005246706141-sfgmtgyp"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--dataproc-temp-us-west2-1005246706141-x9mtxbwg" {
  bucket = "b/dataproc-temp-us-west2-1005246706141-x9mtxbwg"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--dev-calitp-aggregator-scraper" {
  bucket = "b/dev-calitp-aggregator-scraper"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--dev-calitp-gtfs-rt-raw" {
  bucket = "b/dev-calitp-gtfs-rt-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:dev-gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com",
        "serviceAccount:gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--dev-calitp-test-sandbox" {
  bucket = "b/dev-calitp-test-sandbox"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--export-ysjqwvyxc4ti3jmahojq" {
  bucket = "b/export-ysjqwvyxc4ti3jmahojq"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--gtfs-data" {
  bucket = "b/gtfs-data"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com",
        "serviceAccount:project-473674835135@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com",
        "serviceAccount:project-473674835135@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectViewer"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--gtfs-data-reports" {
  bucket = "b/gtfs-data-reports"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--gtfs-data-test" {
  bucket = "b/gtfs-data-test"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com",
        "serviceAccount:project-473674835135@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra",
        "serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com",
        "serviceAccount:gtfs-rt-archiver-test@cal-itp-data-infra.iam.gserviceaccount.com",
        "serviceAccount:local-airflow-dev@cal-itp-data-infra-staging.iam.gserviceaccount.com",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com",
        "serviceAccount:project-473674835135@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectViewer"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--gtfs-data-test-reports" {
  bucket = "b/gtfs-data-test-reports"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--gtfs-schedule-backfill-test" {
  bucket = "b/gtfs-schedule-backfill-test"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--gtfs-schedule-backfill-test-deprecated" {
  bucket = "b/gtfs-schedule-backfill-test-deprecated"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--littlepay-data-extract-prod" {
  bucket = "b/littlepay-data-extract-prod"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--rt-parsed" {
  bucket = "b/rt-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--rt-parsed-deprecated" {
  bucket = "b/rt-parsed-deprecated"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--staging-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket = "b/staging.cal-itp-data-infra.appspot.com"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-aggregator-scraper" {
  bucket = "b/test-calitp-aggregator-scraper"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-airtable" {
  bucket = "b/test-calitp-airtable"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-dbt-artifacts" {
  bucket = "b/test-calitp-dbt-artifacts"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-dbt-python-models" {
  bucket = "b/test-calitp-dbt-python-models"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-elavon" {
  bucket = "b/test-calitp-elavon"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-elavon-parsed" {
  bucket = "b/test-calitp-elavon-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-elavon-raw" {
  bucket = "b/test-calitp-elavon-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-config" {
  bucket = "b/test-calitp-gtfs-config"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-download-config" {
  bucket = "b/test-calitp-gtfs-download-config"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:dev-gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectViewer"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-raw" {
  bucket = "b/test-calitp-gtfs-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-rt-parsed" {
  bucket = "b/test-calitp-gtfs-rt-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-rt-raw" {
  bucket = "b/test-calitp-gtfs-rt-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:gtfs-rt-archiver-test@cal-itp-data-infra.iam.gserviceaccount.com",
        "serviceAccount:gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-rt-raw-v2" {
  bucket = "b/test-calitp-gtfs-rt-raw-v2"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:gtfs-rt-archiver-v3@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-rt-validation" {
  bucket = "b/test-calitp-gtfs-rt-validation"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-parsed" {
  bucket = "b/test-calitp-gtfs-schedule-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-parsed-hourly" {
  bucket = "b/test-calitp-gtfs-schedule-parsed-hourly"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-processed" {
  bucket = "b/test-calitp-gtfs-schedule-processed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-raw" {
  bucket = "b/test-calitp-gtfs-schedule-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-raw-v2" {
  bucket = "b/test-calitp-gtfs-schedule-raw-v2"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra",
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:project-1005246706141@storage-transfer-service.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectViewer"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-raw-v2-backfill-test" {
  bucket = "b/test-calitp-gtfs-schedule-raw-v2-backfill-test"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-unzipped" {
  bucket = "b/test-calitp-gtfs-schedule-unzipped"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-unzipped-hourly" {
  bucket = "b/test-calitp-gtfs-schedule-unzipped-hourly"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-validation" {
  bucket = "b/test-calitp-gtfs-schedule-validation"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-gtfs-schedule-validation-hourly" {
  bucket = "b/test-calitp-gtfs-schedule-validation-hourly"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-ntd-api-products" {
  bucket = "b/test-calitp-ntd-api-products"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-ntd-report-validation" {
  bucket = "b/test-calitp-ntd-report-validation"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-ntd-xlsx-products-clean" {
  bucket = "b/test-calitp-ntd-xlsx-products-clean"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-ntd-xlsx-products-raw" {
  bucket = "b/test-calitp-ntd-xlsx-products-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-payments-littlepay-parsed" {
  bucket = "b/test-calitp-payments-littlepay-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-payments-littlepay-raw" {
  bucket = "b/test-calitp-payments-littlepay-raw"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-publish" {
  bucket = "b/test-calitp-publish"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-publish-data-analysis" {
  bucket = "b/test-calitp-publish-data-analysis"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-reports-data" {
  bucket = "b/test-calitp-reports-data"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    },
    {
      "members": [
        "serviceAccount:calitp-py-ci@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectAdmin"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-sentry" {
  bucket = "b/test-calitp-sentry"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-state-geoportal-scrape" {
  bucket = "b/test-calitp-state-geoportal-scrape"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-rt-parsed" {
  bucket = "b/test-rt-parsed"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-rt-validations" {
  bucket = "b/test-rt-validations"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--us-002E-artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  bucket = "b/us.artifacts.cal-itp-data-infra.appspot.com"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--us-west2-calitp-airflow2-pr-171e4e47-bucket" {
  bucket = "b/us-west2-calitp-airflow2-pr-171e4e47-bucket"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra",
        "serviceAccount:1005246706141-compute@developer.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--us-west2-calitp-airflow2-pr-31e41084-bucket" {
  bucket = "b/us-west2-calitp-airflow2-pr-31e41084-bucket"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra",
        "serviceAccount:composer2-service-account@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--us-west2-calitp-airflow2-pr-88ca8ec6-bucket" {
  bucket = "b/us-west2-calitp-airflow2-pr-88ca8ec6-bucket"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra",
        "serviceAccount:composer2-service-account@cal-itp-data-infra.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra",
        "projectOwner:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}
