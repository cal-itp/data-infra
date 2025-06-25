resource "kubernetes_namespace" "composer" {
  metadata {
    annotations = {
      name = "${local.namespace}-namespace"
    }

    labels = {
      namespace = local.namespace
    }

    name = local.namespace
  }
}

resource "google_service_account_key" "composer" {
  service_account_id = data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_name
}

resource "kubernetes_secret" "composer" {
  metadata {
    name      = local.secret
    namespace = local.namespace
  }
  data = {
    "service_account.json" = base64decode(google_service_account_key.composer.private_key)
    transitland-api-key    = data.kubernetes_secret.composer.data.transitland-api-key
  }
}
