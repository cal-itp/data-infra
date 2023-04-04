# Disk Space Usage
We have an [alert](https://monitoring.calitp.org/alerting/grafana/Geo72Nf4z/view) that will trigger when any Kubernetes volume is more than 80% full. The resolution will depend on the affected service.

> After following any of these specific runbooks, check the general [Kubernetes dashboard](https://monitoring.calitp.org/d/oWe9aYxmk/1-kubernetes-deployment-statefulset-daemonset-metrics) in Grafana to verify the disk space consumption decreased to a safe level. The alert should also show as resolved in Slack after a couple minutes.

## ZooKeeper

[ZooKeeper](https://zookeeper.apache.org/) is deployed as part of our Sentry Helm chart. While autopurge should be enabled as part of the deployment values, we've had issues with it not working in the past. The following process will remove old logs and snapshots.
1. Login to a ZooKeeper pod with `kubectl exec --stdin --tty <pod_name> -n <namespace> -- bash`; the alert will tell you which volume is more than 80% full. For example, typically `kubectl exec --stdin --tty sentry-zookeeper-clickhouse-0 -n sentry -- bash` for cleaning up the Sentry ZooKeeper disk. **You will need to repeat this process for each pod in the StatefulSet.** (In the default Sentry Helm chart configuration, this means `sentry-zookeeper-clickhouse-1` and `sentry-zookeeper-clickhouse-2` as well).
2. Execute the cleanup script `./opt/bitnami/zookeeper/bin/zkCleanup.sh -n <count>`; `count` must be at least 3.
   1. If the executable does not exist in this location, you can find it with `find . -name zkCleanup.sh`.

Additional sections may be added to this runbook over trime.
