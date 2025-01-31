resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-2a93aefe-28c7-46ba-93f2-a86ff6f4aafa" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-2a93aefe-28c7-46ba-93f2-a86ff6f4aafa\",\"kubernetes.io/created-for/pvc/name\":\"claim-katrinamkaiser\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-2a93aefe-28c7-46ba-93f2-a86ff6f4aafa"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-2df32811-310a-4273-9369-0cf65e9d514e" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-2df32811-310a-4273-9369-0cf65e9d514e\",\"kubernetes.io/created-for/pvc/name\":\"data-postgresql-0\",\"kubernetes.io/created-for/pvc/namespace\":\"monitoring-grafana\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-2df32811-310a-4273-9369-0cf65e9d514e"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-3bba6b29-5241-41ff-81a2-8a38b8ba7593" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-3bba6b29-5241-41ff-81a2-8a38b8ba7593\",\"kubernetes.io/created-for/pvc/name\":\"grafana\",\"kubernetes.io/created-for/pvc/namespace\":\"monitoring-grafana\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-3bba6b29-5241-41ff-81a2-8a38b8ba7593"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-3d587612-adf4-4ab3-b30e-9409486d22c6" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-3d587612-adf4-4ab3-b30e-9409486d22c6\",\"kubernetes.io/created-for/pvc/name\":\"claim-bill\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-3d587612-adf4-4ab3-b30e-9409486d22c6"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-5155c951-748b-4f8a-ad98-8629bc1573d4" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-5155c951-748b-4f8a-ad98-8629bc1573d4\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-5155c951-748b-4f8a-ad98-8629bc1573d4"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "30"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-6b64b50a-58a6-4a4e-aabf-2c4f235c6d83" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-6b64b50a-58a6-4a4e-aabf-2c4f235c6d83\",\"kubernetes.io/created-for/pvc/name\":\"prometheus-alertmanager\",\"kubernetes.io/created-for/pvc/namespace\":\"monitoring-prometheus\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-6b64b50a-58a6-4a4e-aabf-2c4f235c6d83"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-7526a8e0-c331-40e9-9f3d-edada78927f3" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-7526a8e0-c331-40e9-9f3d-edada78927f3\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-rabbitmq-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-7526a8e0-c331-40e9-9f3d-edada78927f3"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-97d95db4-2b75-4c66-b548-6df3e4ff5503" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-97d95db4-2b75-4c66-b548-6df3e4ff5503\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-kafka-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-97d95db4-2b75-4c66-b548-6df3e4ff5503"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "16"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-b2ded399-2acb-46c7-97ba-b842f30bf19b" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-b2ded399-2acb-46c7-97ba-b842f30bf19b\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-zookeeper-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-b2ded399-2acb-46c7-97ba-b842f30bf19b"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-e06770ed-a26e-4870-a40f-2741eead8318" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e06770ed-a26e-4870-a40f-2741eead8318\",\"kubernetes.io/created-for/pvc/name\":\"redis-data-sentry-sentry-redis-replicas-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-e06770ed-a26e-4870-a40f-2741eead8318"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-e3fce3a0-6b39-4a23-b9b3-6f099c1e4152" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e3fce3a0-6b39-4a23-b9b3-6f099c1e4152\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-sentry-postgresql-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-e3fce3a0-6b39-4a23-b9b3-6f099c1e4152"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "200"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-0f-pvc-e97e933f-a97d-408e-afa7-e031986063c1" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e97e933f-a97d-408e-afa7-e031986063c1\",\"kubernetes.io/created-for/pvc/name\":\"hub-db-dir\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-e97e933f-a97d-408e-afa7-e031986063c1"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-apps-v2-2729c0c0-8ms8" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-apps-v2-2729c0c0-8ms8"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-gtfsrt-v4-2a13e092-k2sh" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-gtfsrt-v4-2a13e092-k2sh"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-gtfsrt-v4-2a13e092-qr7i" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-gtfsrt-v4-2a13e092-qr7i"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-jobs-v1-cd18666b-d7vg" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jobs-v1-cd18666b-d7vg"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-gke-data-infra-apps-jupyterhub-users-b57e08f4-ldpn" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-b57e08f4-ldpn"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-39448e03-f6dd-4cd1-88ee-030e9a4c6864" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-39448e03-f6dd-4cd1-88ee-030e9a4c6864\",\"kubernetes.io/created-for/pvc/name\":\"claim-fsalemi\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-39448e03-f6dd-4cd1-88ee-030e9a4c6864"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-a5b1d3cd-ad12-405c-ab13-687bced0ff1e" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-a5b1d3cd-ad12-405c-ab13-687bced0ff1e\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-zookeeper-clickhouse-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-a5b1d3cd-ad12-405c-ab13-687bced0ff1e"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "16"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-bd1e9f34-09a4-4b74-8b70-ec0991eab635" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-bd1e9f34-09a4-4b74-8b70-ec0991eab635\",\"kubernetes.io/created-for/pvc/name\":\"claim-albeedobson\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-bd1e9f34-09a4-4b74-8b70-ec0991eab635"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-c5a1db47-2181-432e-8fb4-081420b87c0a" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-c5a1db47-2181-432e-8fb4-081420b87c0a\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-c5a1db47-2181-432e-8fb4-081420b87c0a"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-c7a31ebc-2f7e-40c0-a468-dd6a35c5809e" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-c7a31ebc-2f7e-40c0-a468-dd6a35c5809e\",\"kubernetes.io/created-for/pvc/name\":\"data-dagster-postgresql-0\",\"kubernetes.io/created-for/pvc/namespace\":\"dagster\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-c7a31ebc-2f7e-40c0-a468-dd6a35c5809e"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-a-002F-pvc-d7742e0a-a969-458c-a91a-7af8f49f6472" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-d7742e0a-a969-458c-a91a-7af8f49f6472\",\"kubernetes.io/created-for/pvc/name\":\"claim-mdsaifulislamfahim\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-d7742e0a-a969-458c-a91a-7af8f49f6472"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-a"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-16a68482-25de-4d96-9e3b-3cfd0db3e368" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-16a68482-25de-4d96-9e3b-3cfd0db3e368\",\"kubernetes.io/created-for/pvc/name\":\"claim-natam1\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-16a68482-25de-4d96-9e3b-3cfd0db3e368"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-3265ecbf-c279-4cc3-8e67-f98174ad19e9" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-3265ecbf-c279-4cc3-8e67-f98174ad19e9\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-kafka-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-3265ecbf-c279-4cc3-8e67-f98174ad19e9"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "16"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-53c7e604-a011-419d-96eb-429b7c2b8c70" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-53c7e604-a011-419d-96eb-429b7c2b8c70\",\"kubernetes.io/created-for/pvc/name\":\"data-sftp-server-0\",\"kubernetes.io/created-for/pvc/namespace\":\"prod-sftp-ingest-elavon\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-53c7e604-a011-419d-96eb-429b7c2b8c70"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "50"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-88d137db-2ba6-4aa6-b94d-2d5f77714c7c" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-88d137db-2ba6-4aa6-b94d-2d5f77714c7c\",\"kubernetes.io/created-for/pvc/name\":\"claim-evansiroky\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-88d137db-2ba6-4aa6-b94d-2d5f77714c7c"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-bd2749b9-7e64-4991-83e4-9b694beac49b" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-bd2749b9-7e64-4991-83e4-9b694beac49b\",\"kubernetes.io/created-for/pvc/name\":\"claim-mjumbewu\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-bd2749b9-7e64-4991-83e4-9b694beac49b"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-c9e0b814-b6ad-4a2a-903a-1357d22f0640" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-c9e0b814-b6ad-4a2a-903a-1357d22f0640\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-rabbitmq-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-c9e0b814-b6ad-4a2a-903a-1357d22f0640"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-cd04012e-8535-4d35-b3b6-16f2750b2fb9" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-cd04012e-8535-4d35-b3b6-16f2750b2fb9\",\"kubernetes.io/created-for/pvc/name\":\"claim-noah-2dca\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-cd04012e-8535-4d35-b3b6-16f2750b2fb9"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "50"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-e936ca8a-3a35-4308-ac51-ade47e24d8ea" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e936ca8a-3a35-4308-ac51-ade47e24d8ea\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-e936ca8a-3a35-4308-ac51-ade47e24d8ea"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "30"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-0f-pvc-eece374b-c967-4bcd-b32f-504b4718d5e7" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-eece374b-c967-4bcd-b32f-504b4718d5e7\",\"kubernetes.io/created-for/pvc/name\":\"redis-data-sentry-sentry-redis-replicas-1\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-eece374b-c967-4bcd-b32f-504b4718d5e7"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-apps-v2-0dfb61fb-qloc" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-apps-v2-0dfb61fb-qloc"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-gtfsrt-v4-b003cc53-d25a" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-gtfsrt-v4-b003cc53-d25a"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-jobs-v1-8eec22fb-9fgb" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jobs-v1-8eec22fb-9fgb"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-jupyterhub-users-dddc57ff-2iq0" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-dddc57ff-2iq0"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-jupyterhub-users-dddc57ff-rb5c" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-dddc57ff-rb5c"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-51920f4f-17fb-4119-88d3-7ab7946939c9" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-51920f4f-17fb-4119-88d3-7ab7946939c9\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-51920f4f-17fb-4119-88d3-7ab7946939c9"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-56236315-a154-4f43-b3f0-8bb7915da9e4" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-56236315-a154-4f43-b3f0-8bb7915da9e4\",\"kubernetes.io/created-for/pvc/name\":\"claim-themightychris\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-56236315-a154-4f43-b3f0-8bb7915da9e4"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-8ae88cc0-46d6-4dbd-b554-ebb1fd75df28" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-8ae88cc0-46d6-4dbd-b554-ebb1fd75df28\",\"kubernetes.io/created-for/pvc/name\":\"claim-monicamorenoespinoza\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-8ae88cc0-46d6-4dbd-b554-ebb1fd75df28"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-b75ef8be-704f-4c95-b75f-8b75e7f8216e" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-b75ef8be-704f-4c95-b75f-8b75e7f8216e\",\"kubernetes.io/created-for/pvc/name\":\"claim-erikamov\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-b75ef8be-704f-4c95-b75f-8b75e7f8216e"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-b9f30810-bebd-43b6-81d1-cb17699cd116" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-b9f30810-bebd-43b6-81d1-cb17699cd116\",\"kubernetes.io/created-for/pvc/name\":\"claim-lottspot\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-b9f30810-bebd-43b6-81d1-cb17699cd116"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-bf1cfbb8-d529-4199-a4c1-2f83e4369a21" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-bf1cfbb8-d529-4199-a4c1-2f83e4369a21\",\"kubernetes.io/created-for/pvc/name\":\"claim-shweta487\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-bf1cfbb8-d529-4199-a4c1-2f83e4369a21"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-cb1787db-828d-4577-8d5b-35e46c43f3a7" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-cb1787db-828d-4577-8d5b-35e46c43f3a7\",\"kubernetes.io/created-for/pvc/name\":\"claim-hhmckay\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-cb1787db-828d-4577-8d5b-35e46c43f3a7"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-pvc-f4d846de-ac9f-402c-a213-d175e8a78161" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-f4d846de-ac9f-402c-a213-d175e8a78161\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-zookeeper-clickhouse-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-f4d846de-ac9f-402c-a213-d175e8a78161"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "16"
  type                        = "pd-standard"
  zone                        = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-1e3b74fe-ca10-4d96-8c33-b1ec0c0f3ef1" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-1e3b74fe-ca10-4d96-8c33-b1ec0c0f3ef1\",\"kubernetes.io/created-for/pvc/name\":\"data-database-0\",\"kubernetes.io/created-for/pvc/namespace\":\"metabase\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-1e3b74fe-ca10-4d96-8c33-b1ec0c0f3ef1"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "20"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-4abf7dc1-3ee1-4a8d-9ae5-5818998838bd" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-4abf7dc1-3ee1-4a8d-9ae5-5818998838bd\",\"kubernetes.io/created-for/pvc/name\":\"claim-admin\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-4abf7dc1-3ee1-4a8d-9ae5-5818998838bd"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-537c2c55-3c90-44db-a36d-6bd4a4b0ebc2" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-537c2c55-3c90-44db-a36d-6bd4a4b0ebc2\",\"kubernetes.io/created-for/pvc/name\":\"claim-amandaha8\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-537c2c55-3c90-44db-a36d-6bd4a4b0ebc2"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-5a9722fe-da89-48b2-a633-3bd3f4e8ab78" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-5a9722fe-da89-48b2-a633-3bd3f4e8ab78\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-kafka-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-5a9722fe-da89-48b2-a633-3bd3f4e8ab78"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "16"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-5dd43bea-6458-469b-8148-0fcd1a4f1317" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-5dd43bea-6458-469b-8148-0fcd1a4f1317\",\"kubernetes.io/created-for/pvc/name\":\"redis-data-sentry-sentry-redis-replicas-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-5dd43bea-6458-469b-8148-0fcd1a4f1317"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-5f1039b1-f4bb-48e0-b925-0b9f4936b92c" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-5f1039b1-f4bb-48e0-b925-0b9f4936b92c\",\"kubernetes.io/created-for/pvc/name\":\"data-database-0\",\"kubernetes.io/created-for/pvc/namespace\":\"metabase-preprod\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-5f1039b1-f4bb-48e0-b925-0b9f4936b92c"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-6d2d7ce8-56d1-45bc-bd6a-9b0a70c4c697" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-6d2d7ce8-56d1-45bc-bd6a-9b0a70c4c697\",\"kubernetes.io/created-for/pvc/name\":\"claim-csuyat-2ddot\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-6d2d7ce8-56d1-45bc-bd6a-9b0a70c4c697"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-780faa09-e65d-46f6-8809-6d69eaa6073f" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-780faa09-e65d-46f6-8809-6d69eaa6073f\",\"kubernetes.io/created-for/pvc/name\":\"claim-charlie-2dcostanzo\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-780faa09-e65d-46f6-8809-6d69eaa6073f"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-789ca26b-60f7-4b82-ba71-63b519969b5a" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-789ca26b-60f7-4b82-ba71-63b519969b5a\",\"kubernetes.io/created-for/pvc/name\":\"claim-chnvd\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-789ca26b-60f7-4b82-ba71-63b519969b5a"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-7f5d3f75-5bdd-430d-a47b-d9111ae2d66b" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-7f5d3f75-5bdd-430d-a47b-d9111ae2d66b\",\"kubernetes.io/created-for/pvc/name\":\"claim-benjaminbressette\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-7f5d3f75-5bdd-430d-a47b-d9111ae2d66b"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-8e1af0b5-de26-4747-93b8-2f1bcd6f9c1b" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-8e1af0b5-de26-4747-93b8-2f1bcd6f9c1b\",\"kubernetes.io/created-for/pvc/name\":\"claim-edasmalchi\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-8e1af0b5-de26-4747-93b8-2f1bcd6f9c1b"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-998826b4-8586-42ac-b030-874e1c622155" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-998826b4-8586-42ac-b030-874e1c622155\",\"kubernetes.io/created-for/pvc/name\":\"prometheus-server\",\"kubernetes.io/created-for/pvc/namespace\":\"monitoring-prometheus\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-998826b4-8586-42ac-b030-874e1c622155"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-9b28062d-4fd5-40de-b406-057aa3722b1a" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-9b28062d-4fd5-40de-b406-057aa3722b1a\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-9b28062d-4fd5-40de-b406-057aa3722b1a"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "30"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-a2132b96-edf4-4249-83e0-40a615961c37" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-a2132b96-edf4-4249-83e0-40a615961c37\",\"kubernetes.io/created-for/pvc/name\":\"data-database-0\",\"kubernetes.io/created-for/pvc/namespace\":\"metabase\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-a2132b96-edf4-4249-83e0-40a615961c37"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "20"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-da85fe84-416e-4013-8253-d01d82ebaf2d" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-da85fe84-416e-4013-8253-d01d82ebaf2d\",\"kubernetes.io/created-for/pvc/name\":\"claim-hunterowens\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-da85fe84-416e-4013-8253-d01d82ebaf2d"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-e0a4118c-165d-4187-8ff4-95f01a6b95e1" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-e0a4118c-165d-4187-8ff4-95f01a6b95e1\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-rabbitmq-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-e0a4118c-165d-4187-8ff4-95f01a6b95e1"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-0f-pvc-fd2ef2a6-9c8c-4715-abe6-94795af047db" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-fd2ef2a6-9c8c-4715-abe6-94795af047db\",\"kubernetes.io/created-for/pvc/name\":\"redis-data-sentry-sentry-redis-master-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\"}"
  enable_confidential_compute = "false"
  name                        = "gke-data-infra-apps-0f-pvc-fd2ef2a6-9c8c-4715-abe6-94795af047db"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "8"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-apps-v2-24a4cc95-c6nc" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-apps-v2-24a4cc95-c6nc"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-apps-v2-24a4cc95-r80w" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-apps-v2-24a4cc95-r80w"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-gtfsrt-v4-7577d4d7-2q5e" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-gtfsrt-v4-7577d4d7-2q5e"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-jobs-v1-625ec063-7qyx" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jobs-v1-625ec063-7qyx"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-jupyterhub-users-6aa76dbb-0ipn" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-6aa76dbb-0ipn"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-jupyterhub-users-6aa76dbb-58p2" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-6aa76dbb-58p2"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-jupyterhub-users-6aa76dbb-f0y0" {
  enable_confidential_compute = "false"

  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SECURE_BOOT"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1305-gke1699000-cos-113-18244-236-5-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-6aa76dbb-f0y0"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-32c3a666-3ae5-4cfc-8129-84f571239f42" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-32c3a666-3ae5-4cfc-8129-84f571239f42\",\"kubernetes.io/created-for/pvc/name\":\"claim-cathyxlin\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-32c3a666-3ae5-4cfc-8129-84f571239f42"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "32"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-3fb43fc4-3b64-478a-aca4-87ab2f21c969" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-3fb43fc4-3b64-478a-aca4-87ab2f21c969\",\"kubernetes.io/created-for/pvc/name\":\"sentry-clickhouse-data-sentry-clickhouse-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-3fb43fc4-3b64-478a-aca4-87ab2f21c969"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-41ab9b2e-5c2d-4ce7-8581-60808f17a720" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-41ab9b2e-5c2d-4ce7-8581-60808f17a720\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-zookeeper-clickhouse-0\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-41ab9b2e-5c2d-4ce7-8581-60808f17a720"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "16"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-4c20f5a4-a28e-430e-b7f3-43c7d9d7f03f" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-4c20f5a4-a28e-430e-b7f3-43c7d9d7f03f\",\"kubernetes.io/created-for/pvc/name\":\"data-sentry-kafka-2\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-4c20f5a4-a28e-430e-b7f3-43c7d9d7f03f"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "16"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-51ff509f-72b2-46d8-9467-4fea927ba042" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-51ff509f-72b2-46d8-9467-4fea927ba042\",\"kubernetes.io/created-for/pvc/name\":\"sentry-data\",\"kubernetes.io/created-for/pvc/namespace\":\"sentry\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-51ff509f-72b2-46d8-9467-4fea927ba042"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-a2132f03-9613-4f28-8a87-157d93e7b5e9" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-a2132f03-9613-4f28-8a87-157d93e7b5e9\",\"kubernetes.io/created-for/pvc/name\":\"claim-tiffanychu90\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-a2132f03-9613-4f28-8a87-157d93e7b5e9"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "75"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-c27aa4d3-2472-4d81-916c-668a4c3e4828" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-c27aa4d3-2472-4d81-916c-668a4c3e4828\",\"kubernetes.io/created-for/pvc/name\":\"claim-vevetron\",\"kubernetes.io/created-for/pvc/namespace\":\"jupyterhub\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-c27aa4d3-2472-4d81-916c-668a4c3e4828"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "100"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-pvc-d18eba0e-6dbc-4f9f-a543-61770e61aefe" {
  description                 = "{\"kubernetes.io/created-for/pv/name\":\"pvc-d18eba0e-6dbc-4f9f-a543-61770e61aefe\",\"kubernetes.io/created-for/pvc/name\":\"data-database-0\",\"kubernetes.io/created-for/pvc/namespace\":\"metabase-test\",\"storage.gke.io/created-by\":\"pd.csi.storage.gke.io\"}"
  enable_confidential_compute = "false"
  name                        = "pvc-d18eba0e-6dbc-4f9f-a543-61770e61aefe"
  physical_block_size_bytes   = "4096"
  project                     = "cal-itp-data-infra"
  provisioned_iops            = "0"
  provisioned_throughput      = "0"
  size                        = "10"
  type                        = "pd-standard"
  zone                        = "us-west1-c"
}
