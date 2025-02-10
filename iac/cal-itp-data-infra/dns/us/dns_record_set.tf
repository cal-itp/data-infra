resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__dns-002E-_udp-002E-kube-dns-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_dns._udp.kube-dns.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 53 kube-dns.kube-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__dns-tcp-002E-_tcp-002E-kube-dns-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_dns-tcp._tcp.kube-dns.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 53 kube-dns.kube-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__http-002E-_tcp-002E-default-http-backend-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_http._tcp.default-http-backend.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 80 default-http-backend.kube-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__https-002E-_tcp-002E-kubernetes-002E-default-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_https._tcp.kubernetes.default.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 443 kubernetes.default.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__legacy-002E-_tcp-002E-gmp-operator-002E-gke-gmp-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_legacy._tcp.gmp-operator.gke-gmp-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 8443 gmp-operator.gke-gmp-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__otlp-grpc-002E-_tcp-002E-airflow-monitoring-service-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_otlp-grpc._tcp.airflow-monitoring-service.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 4317 airflow-monitoring-service.composer-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__otlp-http-002E-_tcp-002E-airflow-monitoring-service-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_otlp-http._tcp.airflow-monitoring-service.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 4318 airflow-monitoring-service.composer-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__statsd-collectd-002E-_udp-002E-airflow-monitoring-service-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_statsd-collectd._udp.airflow-monitoring-service.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 8125 airflow-monitoring-service.composer-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__statsd-ot-002E-_udp-002E-airflow-monitoring-service-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_statsd-ot._udp.airflow-monitoring-service.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 8126 airflow-monitoring-service.composer-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns__webhook-002E-_tcp-002E-gmp-operator-002E-gke-gmp-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "_webhook._tcp.gmp-operator.gke-gmp-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 443 gmp-operator.gke-gmp-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_airflow-monitoring-service-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "airflow-monitoring-service.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.130.198"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_airflow-monitoring-service-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "airflow-monitoring-service.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 25 4317 airflow-monitoring-service.composer-system.svc.cluster.local.", "10 25 4318 airflow-monitoring-service.composer-system.svc.cluster.local.", "10 25 8125 airflow-monitoring-service.composer-system.svc.cluster.local.", "10 25 8126 airflow-monitoring-service.composer-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_airflow-redis-service-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "airflow-redis-service.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.131.240"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_airflow-sqlproxy-service-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "airflow-sqlproxy-service.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.129.206"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_antrea-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "antrea.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.131.43"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_cluster-002E-local-002E--NS" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["ns-gcp-private.googledomains.com."]
  ttl          = "21600"
  type         = "NS"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_cluster-002E-local-002E--SOA" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["ns-gcp-private.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300"]
  ttl          = "21600"
  type         = "SOA"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_custom-metrics-stackdriver-adapter-002E-composer-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "custom-metrics-stackdriver-adapter.composer-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.130.249"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_default-http-backend-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "default-http-backend.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.128.114"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_default-http-backend-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "default-http-backend.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 80 default-http-backend.kube-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_dns-version-002E-cluster-002E-local-002E--TXT" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "dns-version.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["\"1.0.0\""]
  ttl          = "30"
  type         = "TXT"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_gmp-operator-002E-gke-gmp-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "gmp-operator.gke-gmp-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.128.124"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_gmp-operator-002E-gke-gmp-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "gmp-operator.gke-gmp-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 50 443 gmp-operator.gke-gmp-system.svc.cluster.local.", "10 50 8443 gmp-operator.gke-gmp-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_kube-dns-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "kube-dns.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.128.10"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_kube-dns-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "kube-dns.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 50 53 kube-dns.kube-system.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_kubernetes-002E-default-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "kubernetes.default.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.128.1"]
  ttl          = "30"
  type         = "A"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_kubernetes-002E-default-002E-svc-002E-cluster-002E-local-002E--SRV" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "kubernetes.default.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10 100 443 kubernetes.default.svc.cluster.local."]
  ttl          = "30"
  type         = "SRV"
}

resource "google_dns_record_set" "tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns_metrics-server-002E-kube-system-002E-svc-002E-cluster-002E-local-002E--A" {
  managed_zone = "google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.name"
  name         = "metrics-server.kube-system.svc.google_dns_managed_zone.tfer--gke-us-west2-calitp-airflow2-pr-88ca8ec6-gke-98ed8a64-dns.dns_name"
  project      = "cal-itp-data-infra"
  rrdatas      = ["10.15.130.150"]
  ttl          = "30"
  type         = "A"
}
