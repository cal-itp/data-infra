import os
from functools import wraps

from airflow.contrib.operators.gcp_container_operator import GKEPodOperator
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from calitp import is_development


@wraps(KubernetesPodOperator)
def pod_operator(*args, **kwargs):
    # TODO: tune this, and add resource limits
    namespace = "default"

    if is_development():
        return GKEPodOperator(
            *args,
            in_cluster=False,
            project_id=os.environ["GOOGLE_CLOUD_PROJECT"],
            location=os.environ["POD_LOCATION"],
            cluster_name=os.environ["POD_CLUSTER_NAME"],
            namespace=namespace,
            **kwargs
        )

    else:
        return KubernetesPodOperator(*args, namespace=namespace, **kwargs)
