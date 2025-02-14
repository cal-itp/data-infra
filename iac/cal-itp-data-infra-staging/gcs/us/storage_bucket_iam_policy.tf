resource "google_storage_bucket_iam_policy" "tfer--calitp-staging-data-analyses-portfolio" {
  bucket = "b/calitp-staging-data-analyses-portfolio"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra-staging",
        "projectOwner:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketReader"
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

resource "google_storage_bucket_iam_policy" "tfer--calitp-staging-data-analyses-portfolio-draft" {
  bucket = "b/calitp-staging-data-analyses-portfolio-draft"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra-staging",
        "projectOwner:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketReader"
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

resource "google_storage_bucket_iam_policy" "tfer--dataproc-staging-us-west2-473674835135-t87wkokr" {
  bucket = "b/dataproc-staging-us-west2-473674835135-t87wkokr"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra-staging",
        "projectOwner:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--dataproc-temp-us-west2-473674835135-yuzmmdyk" {
  bucket = "b/dataproc-temp-us-west2-473674835135-yuzmmdyk"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra-staging",
        "projectOwner:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketReader"
    }
  ]
}
POLICY
}

resource "google_storage_bucket_iam_policy" "tfer--test-calitp-amplitude-benefits-events" {
  bucket = "b/test-calitp-amplitude-benefits-events"

  policy_data = <<POLICY
{
  "bindings": [
    {
      "members": [
        "projectEditor:cal-itp-data-infra-staging",
        "projectOwner:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyBucketReader"
    },
    {
      "members": [
        "projectEditor:cal-itp-data-infra-staging",
        "projectOwner:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyObjectOwner"
    },
    {
      "members": [
        "projectViewer:cal-itp-data-infra-staging"
      ],
      "role": "roles/storage.legacyObjectReader"
    }
  ]
}
POLICY
}
