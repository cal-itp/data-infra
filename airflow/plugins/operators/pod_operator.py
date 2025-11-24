import os
from functools import wraps

from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from airflow.providers.cncf.kubernetes.secret import Secret
from airflow.providers.google.cloud.operators.kubernetes_engine import (
    GKEStartPodOperator,
)


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

    return GKEStartPodOperator(
        *args,
        in_cluster=False,
        project_id=project_id,
        location=location,
        cluster_name=cluster_name,
        namespace=namespace,
        image_pull_policy="Always",
        **kwargs,
    )
