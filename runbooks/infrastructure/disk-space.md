# Disk Space Usage
We have an [alert](https://monitoring.calitp.org/alerting/grafana/Geo72Nf4z/view) that will trigger when any Kubernetes volume is more than 80% full. The resolution will depend on the affected service.

> After following any of these specific runbooks, check the general [Kubernetes dashboard](https://monitoring.calitp.org/d/oWe9aYxmk/1-kubernetes-deployment-statefulset-daemonset-metrics) in Grafana to verify the disk space consumption decreased to a safe level. The alert should also show as resolved in Slack after a couple minutes.

## ZooKeeper

[ZooKeeper](https://zookeeper.apache.org/) is deployed as part of our Sentry Helm chart. While autopurge should be enabled as part of the deployment values, we've had issues with it not working in the past. The following process will remove old logs and snapshots.
1. Login to a ZooKeeper pod with `kubectl exec --stdin --tty <pod_name> -n <namespace> -- bash`; the alert will tell you which volume is more than 80% full. For example, typically `kubectl exec --stdin --tty sentry-zookeeper-clickhouse-0 -n sentry -- bash` for cleaning up the Sentry ZooKeeper disk. **You will need to repeat this process for each pod in the StatefulSet.** (In the default Sentry Helm chart configuration, this means `sentry-zookeeper-clickhouse-1` and `sentry-zookeeper-clickhouse-2` as well).
2. Execute the cleanup script `./opt/bitnami/zookeeper/bin/zkCleanup.sh -n <count>`; `count` must be at least 3.
   1. If the executable does not exist in this location, you can find it with `find . -name zkCleanup.sh`.

Additional sections may be added to this runbook over time.

## Kafka (also failing consumers)
The [Kafka](https://kafka.apache.org/) pods themselves can also have unbound disk space usage if they are not properly configured to drop old data quickly enough. This can cascade into a variety of issues, as well as [snuba](https://getsentry.github.io/snuba/architecture/overview.html) workers being unable to actually pull events from Kafka, leading to a scenario that cannot recover without intervention. This list of steps is for resetting one particular consumer group for one particular topic, so it may need to be performed multiple times.

> The sensitive values referenced here are stored in Vaultwarden; the Helm chart does not yet support using only Secrets.

0. As a temporary measure, you can increase the capacity of the persistent volume of the pod having issues. You can either edit the persistent volume YAML directly, or `helm upgrade sentry apps/charts/sentry -n sentry -f apps/values/sentry_sensitive.yaml -f apps/charts/sentry/values.yaml --debug` after setting a larger volume size in `values.yaml`. Either way, you will likely have to restart the pod to let the change take effect.
1. Check if there are any failing consumer pods in [Workloads](https://console.cloud.google.com/kubernetes/workload?project=cal-itp-data-infra); you can use the logs to identify the topic and potentially the consumer group.
2. Check the consumer groups and/or topics, and reset the offsets to the latest as appropriate. This [GitHub issue](https://github.com/getsentry/self-hosted/issues/478#issuecomment-666254392) contains very helpful information. For example, to reset the `snuba-events-subscriptions-consumers` consumer that is failing to handle the `snuba-commit-log` topic:
   * `kubectl exec --stdin --tty sentry-kafka-0 -n sentry -- bash`
   * `/opt/bitnami/kafka/bin/kafka-consumer-groups.s --bootstrap-server 127.0.0.1:9092 --list`
   * `/opt/bitnami/kafka/bin/kafka-consumer-groups.s --bootstrap-server 127.0.0.1:9092 --group snuba-events-subscriptions-consumers -describe`
   * `/opt/bitnami/kafka/bin/kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --group snuba-events-subscriptions-consumers --topic snuba-commit-log --reset-offsets --to-latest --execute`
   * If you hit `Error: Assignments can only be reset if the group 'snuba-post-processor' is inactive, but the current state is Stable.`, you need to stop the consumers on the topic (by deleting the pods and/or deployment), resetting the offset, and starting the pods again (via `helm upgrade sentry apps/charts/sentry -n sentry -f apps/values/sentry_sensitive.yaml -f apps/charts/sentry/values.yaml --debug` if you deleted the deployment).
3. (Optional) If disk space is still maxed out and the consumers fail to recover even after increasing the disk space, stop the failing Kafka pod and delete its underlying PV, then repeat the steps again. **This will lose the in-flight data** but is preferable to the worker continuing to exist in a bad state.
4. (Optional) Check the existing `logRetentionHours` in [values.yaml](../../kubernetes/apps/charts/sentry/values.yaml); it should be set but may need to be shorter.
