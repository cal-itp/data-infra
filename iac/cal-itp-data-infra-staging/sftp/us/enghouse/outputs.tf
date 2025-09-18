output "kubernetes_service_enghouse-sftp_load_balancer_status" {
  depends_on = [kubernetes_service.enghouse-sftp]
  value      = kubernetes_service.enghouse-sftp.status
}

output "kubernetes_service_enghouse-sftp_username" {
  value = local.sftp_user
}
