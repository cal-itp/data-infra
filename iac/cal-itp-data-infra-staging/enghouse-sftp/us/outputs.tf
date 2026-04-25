output "kubernetes_service_enghouse-sftp_load_balancer_status" {
  depends_on = [kubernetes_service_v1.enghouse-sftp]
  value      = kubernetes_service_v1.enghouse-sftp.status
}

output "kubernetes_service_enghouse-sftp_username" {
  value = local.sftp_user
}
