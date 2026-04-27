resource "kubernetes_secret_v1" "enghouse-sftp-hostkeys" {
  type                           = "Opaque"
  wait_for_service_account_token = true

  metadata {
    namespace = "default"
    name      = "enghouse-sftp-hostkeys"
  }

  data = {
    "id_rsa"     = data.google_secret_manager_secret_version.enghouse-sftp-private-key.secret_data
    "id_rsa.pub" = data.google_secret_manager_secret_version.enghouse-sftp-public-key.secret_data
  }
}

resource "kubernetes_secret_v1" "enghouse-sftp-authorizedkey" {
  type                           = "Opaque"
  wait_for_service_account_token = true

  metadata {
    namespace = "default"
    name      = "enghouse-sftp-authorizedkey"
  }

  data = {
    "authorized_keys" = data.google_secret_manager_secret_version.enghouse-sftp-authorizedkey.secret_data
  }
}

resource "kubernetes_service_account_v1" "sftp-pod-service-account" {
  metadata {
    namespace = "default"
    name      = "sftp-pod-service-account"

    annotations = {
      "iam.gke.io/gcp-service-account" = data.terraform_remote_state.iam.outputs.google_service_account_sftp-pod-service-account_email
    }
  }
}

resource "kubernetes_deployment_v1" "enghouse-sftp" {
  metadata {
    namespace = "default"
    name      = "enghouse-sftp-deployment"

    labels = {
      app = "enghouse-sftp"
    }
  }

  wait_for_rollout = true

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "enghouse-sftp"
      }
    }

    template {
      metadata {
        labels = {
          app = "enghouse-sftp"
        }

        annotations = {
          "gke-gcsfuse/volumes" = "true"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.sftp-pod-service-account.metadata.0.name

        toleration {
          effect   = "NoSchedule"
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = "amd64"
        }

        volume {
          name = "gcs-volume"
          csi {
            driver = "gcsfuse.csi.storage.gke.io"
            volume_attributes = {
              bucketName   = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-enghouse-raw_name
              mountOptions = "uid=2222,gid=2222,file-mode=777,dir-mode=777"
            }
          }
        }

        volume {
          name = "sftp-hostkeys"
          secret {
            secret_name  = "enghouse-sftp-hostkeys"
            default_mode = "0600"
          }
        }

        volume {
          name = "sftp-authorizedkey"
          secret {
            secret_name  = "enghouse-sftp-authorizedkey"
            default_mode = "0600"
          }
        }

        security_context {
          supplemental_groups = []

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "sftp-server"
          image = "alpine"

          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = false
            run_as_non_root            = false

            capabilities {
              add  = []
              drop = ["NET_RAW"]
            }
          }

          env {
            name  = "SFTP_USER"
            value = local.sftp_user
          }

          port {
            container_port = 22
          }

          volume_mount {
            name       = "gcs-volume"
            mount_path = "/home/${local.sftp_user}/data"
            read_only  = false
          }

          volume_mount {
            name       = "sftp-hostkeys"
            mount_path = "/etc/ssh/hostkey"
            read_only  = true
          }

          volume_mount {
            name       = "sftp-authorizedkey"
            mount_path = "/tmp/ssh-keys"
            read_only  = true
          }

          command = [
            "/bin/sh", "-c", <<EOT
            apk update
            apk add openssl openssh openssh-server
            addgroup -g 2222 sftpusers
            adduser -u 2222 -S -G sftpusers -s /sbin/nologin -D -H ${local.sftp_user}
            echo '${local.sftp_user}:enghousesftpuserpassword' | chpasswd

            mkdir -p /home/${local.sftp_user}/.ssh
            cp /tmp/ssh-keys/authorized_keys /home/${local.sftp_user}/.ssh/authorized_keys
            chmod 700 /home/${local.sftp_user}/.ssh
            chmod 600 /home/${local.sftp_user}/.ssh/authorized_keys
            chown -R ${local.sftp_user}:sftpusers /home/${local.sftp_user}/.ssh

            echo "HostKey /etc/ssh/hostkey/id_rsa" >> /etc/ssh/sshd_config
            echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
            echo "PermitRootLogin no" >> /etc/ssh/sshd_config
            echo "X11Forwarding no" >> /etc/ssh/sshd_config
            echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
            echo "Match User ${local.sftp_user}" >> /etc/ssh/sshd_config
            echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config
            echo "ForceCommand internal-sftp" >> /etc/ssh/sshd_config
            echo "ChrootDirectory %h" >> /etc/ssh/sshd_config
            /usr/sbin/sshd -D -e
            EOT
          ]
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "enghouse-sftp" {
  metadata {
    namespace = "default"
    name      = "enghouse-sftp"
  }

  wait_for_load_balancer = true

  spec {
    type             = "LoadBalancer"
    load_balancer_ip = data.terraform_remote_state.networks.outputs.google_compute_address_enghouse-sftp-address_ip

    selector = {
      app = kubernetes_deployment_v1.enghouse-sftp.metadata.0.labels.app
    }

    port {
      port        = 22
      target_port = 22
    }
  }
}
