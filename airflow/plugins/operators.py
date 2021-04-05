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
        project_id = os.environ["GOOGLE_CLOUD_PROJECT"]
        cluster_name = "us-west2-calitp-airflow-pro-332827a9-gke"
    else:
        in_cluster = True
        project_id = os.environ["GCP_PROJECT"]
        cluster_name = None

    # TODO: tune this, and add resource limits
    location = "us-west2-a"
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
