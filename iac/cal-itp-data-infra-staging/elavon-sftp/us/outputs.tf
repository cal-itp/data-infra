output "kubernetes_service_elavon-sftp_load_balancer_status" {
  depends_on = [kubernetes_service_v1.elavon-sftp]
  value      = kubernetes_service_v1.elavon-sftp.status
}

output "kubernetes_service_elavon-sftp_username" {
  value = local.sftp_user
}
