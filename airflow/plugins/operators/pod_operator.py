import os

from functools import wraps
from pprint import pprint

from airflow.contrib.operators.gcp_container_operator import GKEPodOperator
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator

from calitp.config import is_development


@wraps(KubernetesPodOperator)
def PodOperator(*args, **kwargs):
    # TODO: tune this, and add resource limits
    namespace = "default"

    if kwargs.get('name') == 'gtfs-rt-validation':
        pprint(kwargs)
        # raise RuntimeError

    if is_development():
        return GKEPodOperator(
            *args,
            in_cluster=False,
            project_id="cal-itp-data-infra",  # there currently isn't a staging cluster
            location='us-west1',#kwargs.get('pod_location', os.environ["POD_LOCATION"]),
            cluster_name='data-infra-apps',#kwargs.get('cluster_name', os.environ["POD_CLUSTER_NAME"]),
            namespace=namespace,
            **kwargs,
        )

    else:
        return KubernetesPodOperator(*args, namespace=namespace, **kwargs)
