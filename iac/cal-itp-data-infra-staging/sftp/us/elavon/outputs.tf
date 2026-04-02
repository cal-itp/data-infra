output "kubernetes_service_elavon-sftp_load_balancer_status" {
  depends_on = [kubernetes_service.elavon-sftp]
  value      = kubernetes_service.elavon-sftp.status
}

output "kubernetes_service_elavon-sftp_username" {
  value = local.sftp_user
}
