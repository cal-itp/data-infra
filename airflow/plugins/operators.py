import os
from functools import wraps

from airflow.contrib.operators.gcp_container_operator import GKEPodOperator
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from calitp import is_development


@wraps(KubernetesPodOperator)
def pod_operator(*args, **kwargs):
    # note that when in_cluster is true, cluster_name is ignored
    if is_development():
        in_cluster = False
    else:
        in_cluster = True

    project_id = os.environ["GOOGLE_CLOUD_PROJECT"]
    cluster_name = os.environ["POD_CLUSTER_NAME"]
    location = os.environ["POD_LOCATION"]

    # TODO: tune this, and add resource limits
    namespace = "default"

    return GKEPodOperator(
        *args,
        in_cluster=in_cluster,
        project_id=project_id,
        location=location,
        cluster_name=cluster_name,
        namespace=namespace,
        **kwargs
    )
