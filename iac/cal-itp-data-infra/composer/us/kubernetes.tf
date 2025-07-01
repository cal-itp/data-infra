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
    calitp-ckan-gtfs-schedule-key = data.kubernetes_secret.composer.data.calitp-ckan-gtfs-schedule-key
    transitland-api-key           = data.kubernetes_secret.composer.data.transitland-api-key
  }
}

resource "kubernetes_priority_class" "dbt-high-priority" {
  metadata {
    name = "dbt-high-priority"
  }
  global_default = false
  value          = 1000000
  description    = "This priority class should be used for dbt pods only."
}

resource "kubernetes_service_account" "composer-service-account" {
  metadata {
    name      = local.kubernetes_service_account
    namespace = local.namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_email
    }
  }
}
