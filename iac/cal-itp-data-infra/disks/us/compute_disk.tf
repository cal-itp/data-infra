resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-apps-v2-0dfb61fb-5kvg" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-apps-v2-0dfb61fb-5kvg"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-gtfsrt-v4-b003cc53-b7vi" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-gtfsrt-v4-b003cc53-b7vi"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-jobs-v1-8eec22fb-aazx" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jobs-v1-8eec22fb-aazx"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-jupyterhub-users-dddc57ff-cbrw" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-dddc57ff-cbrw"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-b-002F-gke-data-infra-apps-jupyterhub-users-dddc57ff-u7p2" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-dddc57ff-u7p2"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-b"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-apps-v2-24a4cc95-bdau" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-apps-v2-24a4cc95-bdau"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-apps-v2-24a4cc95-xdkc" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-apps-v2-24a4cc95-xdkc"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-gtfsrt-v4-7577d4d7-lz65" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-gtfsrt-v4-7577d4d7-lz65"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-jobs-v1-625ec063-5q8v" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jobs-v1-625ec063-5q8v"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-jupyterhub-users-6aa76dbb-b03b" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-6aa76dbb-b03b"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

resource "google_compute_disk" "tfer--us-west1-c-002F-gke-data-infra-apps-jupyterhub-users-6aa76dbb-juyr" {
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

  image                     = "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-1308-gke1128001-cos-113-18244-236-70-c-cgpv1-pre"
  licenses                  = ["https://www.googleapis.com/compute/v1/projects/cos-cloud-shielded/global/licenses/shielded-cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos", "https://www.googleapis.com/compute/v1/projects/cos-cloud/global/licenses/cos-pcid", "https://www.googleapis.com/compute/v1/projects/gke-node-images/global/licenses/gke-node"]
  name                      = "gke-data-infra-apps-jupyterhub-users-6aa76dbb-juyr"
  physical_block_size_bytes = "4096"
  project                   = "cal-itp-data-infra"
  provisioned_iops          = "0"
  provisioned_throughput    = "0"
  size                      = "100"
  type                      = "pd-standard"
  zone                      = "us-west1-c"
}

