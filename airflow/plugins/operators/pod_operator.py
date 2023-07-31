import inspect
import os
from functools import wraps

# FYI, one day we may need to add apache-airflow-providers-cncf-kubernetes==3.0.0 to requirements.txt if we self-host
# But it's already installed in the Composer environment
from airflow.contrib.operators.gcp_container_operator import GKEPodOperator
from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from airflow.kubernetes.secret import Secret


@wraps(KubernetesPodOperator)
def PodOperator(*args, **kwargs):
    # TODO: tune this, and add resource limits
    namespace = kwargs.pop("namespace", "default")

    if "startup_timeout_seconds" not in kwargs:
        kwargs["startup_timeout_seconds"] = 300

    is_gke = kwargs.pop("is_gke", False)  # we want to always pop()

    if "secrets" in kwargs:
        kwargs["secrets"] = map(lambda d: Secret(**d), kwargs["secrets"])

    # do we ever have non-GKE pods?
    if os.environ["AIRFLOW_ENV"] == "development" or is_gke:
        return GKEPodOperator(
            *args,
            in_cluster=False,
            project_id="cal-itp-data-infra",  # there currently isn't a staging cluster
            location=kwargs.pop("pod_location", os.environ["POD_LOCATION"]),
            cluster_name=kwargs.pop("cluster_name", os.environ["POD_CLUSTER_NAME"]),
            namespace=namespace,
            image_pull_policy="Always",
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
