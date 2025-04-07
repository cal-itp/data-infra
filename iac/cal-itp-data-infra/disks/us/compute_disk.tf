resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-2df32811-310a-4273-9369-0cf65e9d514e" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-2df32811-310a-4273-9369-0cf65e9d514e\",\"kubernetes.io/created-for/pvc/name\":\"data-postgresql-0\",\"kubernetes.io/created-for/pvc/namespace\":\"monitoring-grafana\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-2df32811-310a-4273-9369-0cf65e9d514e"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-3bba6b29-5241-41ff-81a2-8a38b8ba7593" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-3bba6b29-5241-41ff-81a2-8a38b8ba7593\",\"kubernetes.io/created-for/pvc/name\":\"grafana\",\"kubernetes.io/created-for/pvc/namespace\":\"monitoring-grafana\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-3bba6b29-5241-41ff-81a2-8a38b8ba7593"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "10"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-3d587612-adf4-4ab3-b30e-9409486d22c6" {
  description               = "{\"kubernetes.io/created-for/pv/name\":\"pvc-3d587612-adf4-4ab3-b30e-9409486d22c6\",\"kubernetes.io/created-for/pvc/name\":\"claim-bill\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  name                      = "gke-data-infra-apps-0f-pvc-3d587612-adf4-4ab3-b30e-9409486d22c6"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "10"
  type                      = "pd-standard"
  zone                      = "us-west1-a"

  labels = {
    goog-gke-volume = ""
  }
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-5155c951-748b-4f8a-ad98-8629bc1573d4" {
  description               = "{\"kubernetes.io/created-for/pv/name\":\"pvc-5155c951-748b-4f8a-ad98-8629bc1573d4\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  name                      = "gke-data-infra-apps-0f-pvc-5155c951-748b-4f8a-ad98-8629bc1573d4"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "30"
  type                      = "pd-standard"
  zone                      = "us-west1-a"

  labels = {
    goog-gke-volume = ""
  }
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-6b64b50a-58a6-4a4e-aabf-2c4f235c6d83" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-6b64b50a-58a6-4a4e-aabf-2c4f235c6d83\",\"kubernetes.io/created-for/pvc/name\":\"prometheus-alertmanager\",\"kubernetes.io/created-for/pvc/namespace\":\"monitoring-prometheus\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-6b64b50a-58a6-4a4e-aabf-2c4f235c6d83"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "10"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-7526a8e0-c331-40e9-9f3d-edada78927f3" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-7526a8e0-c331-40e9-9f3d-edada78927f3\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-rabbitmq-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-7526a8e0-c331-40e9-9f3d-edada78927f3"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-97d95db4-2b75-4c66-b548-6df3e4ff5503" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-97d95db4-2b75-4c66-b548-6df3e4ff5503\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-kafka-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-97d95db4-2b75-4c66-b548-6df3e4ff5503"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "16"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-b2ded399-2acb-46c7-97ba-b842f30bf19b" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-b2ded399-2acb-46c7-97ba-b842f30bf19b\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-zookeeper-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-b2ded399-2acb-46c7-97ba-b842f30bf19b"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-e06770ed-a26e-4870-a40f-2741eead8318" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e06770ed-a26e-4870-a40f-2741eead8318\",\"kubernetes.io/created-for/pvc/name\":\"redis-data-sentry-sentry-redis-replicas-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-e06770ed-a26e-4870-a40f-2741eead8318"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-e3fce3a0-6b39-4a23-b9b3-6f099c1e4152" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e3fce3a0-6b39-4a23-b9b3-6f099c1e4152\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-sentry-postgresql-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-e3fce3a0-6b39-4a23-b9b3-6f099c1e4152"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "200"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-e97e933f-a97d-408e-afa7-e031986063c1" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e97e933f-a97d-408e-afa7-e031986063c1\",\"kubernetes.io/created-for/pvc/name\":\"hub-db-dir\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-e97e933f-a97d-408e-afa7-e031986063c1"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "32"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-a5b1d3cd-ad12-405c-ab13-687bced0ff1e" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-a5b1d3cd-ad12-405c-ab13-687bced0ff1e\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-zookeeper-clickhouse-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-a5b1d3cd-ad12-405c-ab13-687bced0ff1e"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "16"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-c5a1db47-2181-432e-8fb4-081420b87c0a" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-c5a1db47-2181-432e-8fb4-081420b87c0a\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-c5a1db47-2181-432e-8fb4-081420b87c0a"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-c7a31ebc-2f7e-40c0-a468-dd6a35c5809e" {
  description               = "{\"kubernetes.io/created-for/pv/name\":\"pvc-c7a31ebc-2f7e-40c0-a468-dd6a35c5809e\",\"kubernetes.io/created-for/pvc/name\":\"data-dagster-postgresql-0\",\"kubernetes.io/created-for/pvc/namespace\":\"dagster\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  name                      = "pvc-c7a31ebc-2f7e-40c0-a468-dd6a35c5809e"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-a"

  labels = {
    goog-gke-volume = ""
  }
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-3265ecbf-c279-4cc3-8e67-f98174ad19e9" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-3265ecbf-c279-4cc3-8e67-f98174ad19e9\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-kafka-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-3265ecbf-c279-4cc3-8e67-f98174ad19e9"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "16"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-53c7e604-a011-419d-96eb-429b7c2b8c70" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-53c7e604-a011-419d-96eb-429b7c2b8c70\",\"kubernetes.io/created-for/pvc/name\":\"data-sftp-server-0\",\"kubernetes.io/created-for/pvc/namespace\":\"prod-sftp-ingest-elavon\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-53c7e604-a011-419d-96eb-429b7c2b8c70"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "50"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-c9e0b814-b6ad-4a2a-903a-1357d22f0640" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-c9e0b814-b6ad-4a2a-903a-1357d22f0640\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-rabbitmq-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-c9e0b814-b6ad-4a2a-903a-1357d22f0640"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-e936ca8a-3a35-4308-ac51-ade47e24d8ea" {
  description               = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e936ca8a-3a35-4308-ac51-ade47e24d8ea\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  name                      = "gke-data-infra-apps-0f-pvc-e936ca8a-3a35-4308-ac51-ade47e24d8ea"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "30"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
  labels = {
    goog-gke-volume = ""
  }
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-eece374b-c967-4bcd-b32f-504b4718d5e7" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-eece374b-c967-4bcd-b32f-504b4718d5e7\",\"kubernetes.io/created-for/pvc/name\":\"redis-data-sentry-sentry-redis-replicas-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-eece374b-c967-4bcd-b32f-504b4718d5e7"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-51920f4f-17fb-4119-88d3-7ab7946939c9" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-51920f4f-17fb-4119-88d3-7ab7946939c9\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-51920f4f-17fb-4119-88d3-7ab7946939c9"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-f4d846de-ac9f-402c-a213-d175e8a78161" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-f4d846de-ac9f-402c-a213-d175e8a78161\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-zookeeper-clickhouse-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-f4d846de-ac9f-402c-a213-d175e8a78161"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "16"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-1e3b74fe-ca10-4d96-8c33-b1ec0c0f3ef1" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-1e3b74fe-ca10-4d96-8c33-b1ec0c0f3ef1\",\"kubernetes.io/created-for/pvc/name\":\"data-database-0\",\"kubernetes.io/created-for/pvc/namespace\":\"metabase\"}"

  labels = {
    goog-gke-volume = ""
    workload        = "metabase-database"
  }

  name                      = "gke-data-infra-apps-0f-pvc-1e3b74fe-ca10-4d96-8c33-b1ec0c0f3ef1"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "20"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-4abf7dc1-3ee1-4a8d-9ae5-5818998838bd" {
  description               = "{\"kubernetes.io/created-for/pv/name\":\"pvc-4abf7dc1-3ee1-4a8d-9ae5-5818998838bd\",\"kubernetes.io/created-for/pvc/name\":\"claim-admin\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  name                      = "gke-data-infra-apps-0f-pvc-4abf7dc1-3ee1-4a8d-9ae5-5818998838bd"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "10"
  type                      = "pd-standard"
  zone                      = "us-west1-c"

  labels = {
    goog-gke-volume = ""
  }
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-5a9722fe-da89-48b2-a633-3bd3f4e8ab78" {
  description               = "{\"kubernetes.io/created-for/pv/name\":\"pvc-5a9722fe-da89-48b2-a633-3bd3f4e8ab78\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-kafka-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  name                      = "gke-data-infra-apps-0f-pvc-5a9722fe-da89-48b2-a633-3bd3f4e8ab78"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "16"
  type                      = "pd-standard"
  zone                      = "us-west1-c"

  labels = {
    goog-gke-volume = ""
  }
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-5dd43bea-6458-469b-8148-0fcd1a4f1317" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-5dd43bea-6458-469b-8148-0fcd1a4f1317\",\"kubernetes.io/created-for/pvc/name\":\"redis-data-sentry-sentry-redis-replicas-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-5dd43bea-6458-469b-8148-0fcd1a4f1317"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-5f1039b1-f4bb-48e0-b925-0b9f4936b92c" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-5f1039b1-f4bb-48e0-b925-0b9f4936b92c\",\"kubernetes.io/created-for/pvc/name\":\"data-database-0\",\"kubernetes.io/created-for/pvc/namespace\":\"metabase-preprod\"}"

  labels = {
    goog-gke-volume           = ""
    goog-k8s-cluster-location = "us-west1"
    goog-k8s-cluster-name     = "data-infra-apps"
    goog-k8s-node-pool-name   = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-5f1039b1-f4bb-48e0-b925-0b9f4936b92c"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "10"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-998826b4-8586-42ac-b030-874e1c622155" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-998826b4-8586-42ac-b030-874e1c622155\",\"kubernetes.io/created-for/pvc/name\":\"prometheus-server\",\"kubernetes.io/created-for/pvc/namespace\":\"monitoring-prometheus\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-998826b4-8586-42ac-b030-874e1c622155"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-9b28062d-4fd5-40de-b406-057aa3722b1a" {
  description               = "{\"kubernetes.io/created-for/pv/name\":\"pvc-9b28062d-4fd5-40de-b406-057aa3722b1a\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  name                      = "gke-data-infra-apps-0f-pvc-9b28062d-4fd5-40de-b406-057aa3722b1a"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "30"
  type                      = "pd-standard"
  zone                      = "us-west1-c"

  labels = {
    goog-gke-volume = ""
  }
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-a2132b96-edf4-4249-83e0-40a615961c37" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-a2132b96-edf4-4249-83e0-40a615961c37\",\"kubernetes.io/created-for/pvc/name\":\"data-database-0\",\"kubernetes.io/created-for/pvc/namespace\":\"metabase\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-a2132b96-edf4-4249-83e0-40a615961c37"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "20"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-e0a4118c-165d-4187-8ff4-95f01a6b95e1" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e0a4118c-165d-4187-8ff4-95f01a6b95e1\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-rabbitmq-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-e0a4118c-165d-4187-8ff4-95f01a6b95e1"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-fd2ef2a6-9c8c-4715-abe6-94795af047db" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-fd2ef2a6-9c8c-4715-abe6-94795af047db\",\"kubernetes.io/created-for/pvc/name\":\"redis-data-sentry-sentry-redis-master-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "gke-data-infra-apps-0f-pvc-fd2ef2a6-9c8c-4715-abe6-94795af047db"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "8"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-3fb43fc4-3b64-478a-aca4-87ab2f21c969" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-3fb43fc4-3b64-478a-aca4-87ab2f21c969\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-3fb43fc4-3b64-478a-aca4-87ab2f21c969"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-41ab9b2e-5c2d-4ce7-8581-60808f17a720" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-41ab9b2e-5c2d-4ce7-8581-60808f17a720\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-zookeeper-clickhouse-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-41ab9b2e-5c2d-4ce7-8581-60808f17a720"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "16"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-4c20f5a4-a28e-430e-b7f3-43c7d9d7f03f" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-4c20f5a4-a28e-430e-b7f3-43c7d9d7f03f\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-kafka-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-4c20f5a4-a28e-430e-b7f3-43c7d9d7f03f"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "16"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-51ff509f-72b2-46d8-9467-4fea927ba042" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-51ff509f-72b2-46d8-9467-4fea927ba042\",\"kubernetes.io/created-for/pvc/name\":\"sentry-data\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-51ff509f-72b2-46d8-9467-4fea927ba042"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "10"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-d18eba0e-6dbc-4f9f-a543-61770e61aefe" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-d18eba0e-6dbc-4f9f-a543-61770e61aefe\",\"kubernetes.io/created-for/pvc/name\":\"data-database-0\",\"kubernetes.io/created-for/pvc/namespace\":\"metabase-test\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-gke-cluster-id-base32 = "b7q6s5ghvzbrxcigz62lkdgeeggldd76ipme2xfbzcvpmcrghpqq"
    goog-gke-cost-management   = ""
    goog-gke-volume            = ""
    goog-k8s-cluster-location  = "us-west1"
    goog-k8s-cluster-name      = "data-infra-apps"
    goog-k8s-node-pool-name    = "apps-v2"
  }

  name                      = "pvc-d18eba0e-6dbc-4f9f-a543-61770e61aefe"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "10"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west2-a-002F-gke-us-west2-calitp-ai-pvc-544d90c0-5c8e-4c46-bbc0-2666f0037678" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-544d90c0-5c8e-4c46-bbc0-2666f0037678\",\"kubernetes.io/created-for/pvc/name\":\"airflow-redis-volume-airflow-redis-0\",\"kubernetes.io/created-for/pvc/namespace\":\"default\"}"

  labels = {
    goog-composer-environment = "calitp-airflow2-prod"
    goog-composer-location    = "us-west2"
    goog-composer-version     = "composer-1-17-7-airflow-2-0-2"
    goog-gke-volume           = ""
    goog-k8s-cluster-location = "us-west2-a"
    goog-k8s-cluster-name     = "us-west2-calitp-airflow2-pr-171e4e47-gke"
    goog-k8s-node-pool-name   = "default-pool"
  }

  name                      = "gke-us-west2-calitp-ai-pvc-544d90c0-5c8e-4c46-bbc0-2666f0037678"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "2"
  type                      = "pd-standard"
  zone                      = "us-west2-a"
}

resource "google_compute_disk" "tfer--us-west2-a-002F-gke-us-west2-calitp-ai-pvc-60bf5634-5335-4812-a5fd-fa35dfef3267" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-60bf5634-5335-4812-a5fd-fa35dfef3267\",\"kubernetes.io/created-for/pvc/name\":\"airflow-redis-volume-airflow-redis-0\",\"kubernetes.io/created-for/pvc/namespace\":\"default\"}"

  labels = {
    goog-composer-environment = "calitp-airflow-prod"
    goog-composer-location    = "us-west2"
    goog-composer-version     = "composer-1-14-2-airflow-1-10-14"
    goog-gke-volume           = ""
  }

  name                      = "gke-us-west2-calitp-ai-pvc-60bf5634-5335-4812-a5fd-fa35dfef3267"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "2"
  type                      = "pd-standard"
  zone                      = "us-west2-a"
}

resource "google_compute_disk" "tfer--us-west2-a-002F-gke-us-west2-calitp-ai-pvc-74f6d8c4-8ef8-4519-b72f-7da8c079dcfb" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-74f6d8c4-8ef8-4519-b72f-7da8c079dcfb\",\"kubernetes.io/created-for/pvc/name\":\"airflow-redis-volume-airflow-redis-0\",\"kubernetes.io/created-for/pvc/namespace\":\"default\"}"

  labels = {
    goog-composer-environment = "calitp-airflow2-prod"
    goog-composer-location    = "us-west2"
    goog-composer-version     = "composer-1-17-5-airflow-2-1-4"
    goog-gke-volume           = ""
  }

  name                      = "gke-us-west2-calitp-ai-pvc-74f6d8c4-8ef8-4519-b72f-7da8c079dcfb"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "2"
  type                      = "pd-standard"
  zone                      = "us-west2-a"
}

resource "google_compute_disk" "tfer--us-west2-b-002F-pvc-f4d9e2dd-2fc3-4fac-8ba0-cd8b9043c3a1" {
  description = "{\"kubernetes.io/created-for/pv/name\":\"pvc-f4d9e2dd-2fc3-4fac-8ba0-cd8b9043c3a1\",\"kubernetes.io/created-for/pvc/name\":\"airflow-redis-volume-airflow-redis-0\",\"kubernetes.io/created-for/pvc/namespace\":\"composer-system\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"

  labels = {
    goog-composer-environment      = "calitp-airflow2-prod-composer2-patch"
    goog-composer-environment-uuid = "b2062ffc-a77d-44a2-8b4e-05f8f5bf4996"
    goog-composer-location         = "us-west2"
    goog-composer-version          = "composer-2-6-0-airflow-2-5-3"
    goog-gke-cluster-id-base32     = "tdwyuzfom5eu7lab72embfwhnqd5e3i7cx7eoimiiuqzdpyqcnoq"
    goog-gke-cost-management       = ""
    goog-gke-cost-management       = ""
    goog-gke-volume                = ""
    goog-k8s-cluster-location      = "us-west2"
    goog-k8s-cluster-name          = "us-west2-calitp-airflow2-pr-88ca8ec6-gke"
    goog-k8s-node-pool-name        = "pool-2"
  }

  name                      = "pvc-f4d9e2dd-2fc3-4fac-8ba0-cd8b9043c3a1"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  size                      = "2"
  type                      = "pd-standard"
  zone                      = "us-west2-b"
}
