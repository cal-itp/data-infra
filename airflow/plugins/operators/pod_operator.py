import os
from functools import wraps

# FYI, one day we may need to add apache-airflow-providers-cncf-kubernetes==3.0.0 to requirements.txt if we self-host
# But it's already installed in the Composer environment
from airflow.contrib.operators.gcp_container_operator import GKEPodOperator
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from airflow.kubernetes.secret import Secret


@wraps(KubernetesPodOperator)
def PodOperator(*args, **kwargs):
    if "startup_timeout_seconds" not in kwargs:
        kwargs["startup_timeout_seconds"] = 300

    if "secrets" in kwargs:
        kwargs["secrets"] = map(lambda d: Secret(**d), kwargs["secrets"])

    if "SERVICE_ACCOUNT_NAME" in os.environ:
        kwargs["service_account_name"] = os.environ.get("SERVICE_ACCOUNT_NAME")

    location = os.environ.get("POD_LOCATION")
    cluster_name = os.environ.get("POD_CLUSTER_NAME")
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
    namespace = os.environ.get("POD_SECRETS_NAMESPACE")

    return GKEPodOperator(
        *args,
        in_cluster=False,
        project_id=project_id,
        location=location,
        cluster_name=cluster_name,
        namespace=namespace,
        image_pull_policy="Always",
        **kwargs,
    )
