# Resolving Disk Space Issues on Kubernetes Volumes

After the decommission of Sentry and the in-cluster Grafana / Prometheus / Loki / Promtail stack, the only stateful workload remaining on the `data-infra-apps` cluster is JupyterHub — its hub database PVC and per-user PVCs (typically 32–100Gi each).

**There are no automated PVC fill alerts on this cluster.** Google Managed Service for Prometheus was disabled in #5269, and the in-cluster Prometheus / Grafana stack that previously raised these alerts is gone. Disk pressure currently surfaces only when a workload starts failing (e.g. JupyterHub user uploads error out, or hub DB writes block). If we re-add stateful workloads beyond JupyterHub, an alert path is worth re-establishing — either re-enabling GMP and adding a PodMonitoring + alert policy, or wiring a custom Cloud Monitoring metric.

## Identifying the affected volume

The alert payload includes the `persistentvolumeclaim` and `namespace` labels. From there:

```bash
kubectl get pvc <PVC-NAME> -n <NAMESPACE> -o yaml
kubectl describe pvc <PVC-NAME> -n <NAMESPACE>
```

The PVC's `Used By` field (or `volumeName` plus `kubectl get pod -n <NAMESPACE>` filtered by claimName) identifies the consuming pod.

## Possible actions

There are two ways to resolve disk pressure:

- **Reduce disk usage** — typically by deleting old or transient data inside the volume (e.g. an analyst's downloaded CSVs in their JupyterHub home).
- **Increase disk capacity** — for cases where the growth is legitimate.

## Increasing disk capacity

The cluster's `standard` storage class allows in-place expansion. To grow a PVC live:

```bash
kubectl patch pvc <PVC-NAME> -n <NAMESPACE> --type=merge \
  -p '{"spec":{"resources":{"requests":{"storage":"<NEW-SIZE>"}}}}'
```

The cloud provider expands the underlying disk and `resize2fs` runs automatically against the ext4 filesystem on next mount; in some cases the pod needs a manual restart for the new size to be visible inside the container.

For workloads that re-render their PVC spec from a Helm chart on every CI deploy (e.g. JupyterHub user volumes via `singleuser.storage.capacity`), apply the new size **upstream in the chart values** as well so it isn't reset on the next reconcile. [PR #3170](https://github.com/cal-itp/data-infra/pull/3170) shows the pattern.
