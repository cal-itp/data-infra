import inspect
import os

from functools import wraps

from airflow.contrib.operators.gcp_container_operator import GKEPodOperator
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator

from calitp.config import is_development


@wraps(KubernetesPodOperator)
def PodOperator(*args, **kwargs):
    # TODO: tune this, and add resource limits
    namespace = "default"

    is_gke = kwargs.pop("is_gke", False)  # we want to always pop()

    if is_development() or is_gke:
        return GKEPodOperator(
            *args,
            in_cluster=False,
            project_id="cal-itp-data-infra",  # there currently isn't a staging cluster
            location=kwargs.pop("pod_location", os.environ["POD_LOCATION"]),
            cluster_name=kwargs.pop("cluster_name", os.environ["POD_CLUSTER_NAME"]),
            namespace=namespace,
            **kwargs,
        )

    else:
        return KubernetesPodOperator(*args, namespace=namespace, **kwargs)


PodOperator._gusty_parameters = (
    *inspect.signature(KubernetesPodOperator.__init__).parameters.keys(),
    "is_gke",
    "pod_location",
    "cluster_name",
)
