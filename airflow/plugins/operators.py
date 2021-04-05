import os
from functools import wraps

from gke_pod_operator_shim import GKEPodOperator2
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from calitp import is_development


@wraps(KubernetesPodOperator)
def pod_operator(*args, **kwargs):
    # note that when in_cluster is true, cluster_name is ignored
    in_cluster = not is_development()
    cluster_name = "us-west2-calitp-airflow-pro-332827a9-gke"

    # TODO: tune this, and add resource limits
    project_id = os.environ["GOOGLE_CLOUD_PROJECT"]
    location = "us-west2-a"
    namespace = "default"
    return GKEPodOperator2(
        *args,
        in_cluster=in_cluster,
        project_id=project_id,
        location=location,
        cluster_name=cluster_name,
        namespace=namespace,
        **kwargs
    )
