# Resolving Disk Space Usage and Pod Offset Errors

We have an [alert](https://monitoring.calitp.org/alerting/grafana/Geo72Nf4z/view) that will trigger when any Kubernetes volume is more than 80% full, placing a message in the #data-infra-alerts channel of the Cal-ITP Slack group. The resolution path will depend on the affected service.

After following any of these specific runbook sections, check the Disk Usage section of the general [Kubernetes dashboard](https://monitoring.calitp.org/d/oWe9aYxmk/1-kubernetes-deployment-statefulset-daemonset-metrics) in Grafana to verify the disk space consumption has decreased to a safe level for any impacted volumes. The alert should also show as resolved in Slack a couple minutes after recovery.

## Identifying affected service

In the expanded details for the alert message posted to Slack, look for a line indicating the `persistentvolumeclaim` (PVC), e.g.

```console
persistentvolumeclaim=sentry-clickhouse-data-sentry-clickhouse-1,
```

Using Lens, you can easily track down what service this PVC is associated with by first opening the **Storage** > **Persistent Volume Claims** section in Lens, then finding or searching for the named PVC. Once found, you can click the associated **Pod** and the **Controlled By** field will tell you what higher-level `Deployment` or `StatefulSet` that pod was created by—telling you which service is affected. The PVC shown above, for example, leads to the `StatefulSet` named `sentry-clickhouse`.

## Possible actions

In any case of disk usage reaching capacity, there are two approaches to resolving the issue:

- Reduce disk usage
- Increase disk capacity

Some services are designed to be able to operate within finite storage and may need intervention to help them do that, see the [Service-specific additional steps](#service-specific-additional-steps) section below for guidance on some such services.

If however you determine that the growth in disk usage is likely legitimate and consisting of data we generally want to retain, it may just be time to increase the requested disk size for the affected volume.

## Increasing disk capacity

In a pinch, you can edit a PVC directly in Kubernetes to see if that resolves an issue. After a PVC's request size is increased, the pod it is bound too will need to be manually destroyed and then the new requested size will be applied by the cloud provider's storage controlled before the volume gets re-bound to the next instance of the pod. It may be additionally necessary to shell into the pod or node it's hosted on and execute `resize2fs` on the mounted volume to resize the filesystem within the volume to fill the newly available space.

However it is important to apply the new requested disk capacity value upstream in source control so that future syncs from GitHub to Kubernetes will not reset it. This typically involved identifying the relevant Helm chart and configuration value to change within one of this repositories Helm values YAML files. [PR #3170](https://github.com/cal-itp/data-infra/pull/3170) provides an example of this being done for the Clickhouse data volume.

## Service-specific additional steps

### ZooKeeper

[ZooKeeper](https://zookeeper.apache.org/) is deployed as part of our Sentry Helm chart. While autopurge should be enabled as part of the deployment values, we've had issues with it not working in the past. The following process will remove old logs and snapshots.

1. Log in to a ZooKeeper Kubernetes pod with `kubectl exec --stdin --tty <pod_name> -n <namespace> -- bash`; the Grafana alert will tell you which volume is more than 80% full. For example, we typically need to use `kubectl exec --stdin --tty sentry-zookeeper-clickhouse-0 -n sentry -- bash` for cleaning up the Sentry ZooKeeper disk. **You will need to repeat this process for each pod in the StatefulSet** (in the default Sentry Helm chart configuration, this means `sentry-zookeeper-clickhouse-1` and `sentry-zookeeper-clickhouse-2` as well).
2. Execute the cleanup script `./opt/bitnami/zookeeper/bin/zkCleanup.sh -n <count>`; `count` must be at least 3.
   1. If the executable does not exist in this location, you can find it with `find . -name zkCleanup.sh`.

### Kafka

The [Kafka](https://kafka.apache.org/) pods themselves can have unbound disk space usage if they are not properly configured to drop old data quickly enough. This can cascade into a variety of issues, such as [snuba](https://getsentry.github.io/snuba/architecture/overview.html) workers being unable to actually pull events from Kafka, leading to a scenario that cannot recover without intervention. This list of steps is for resetting one particular service, consumer group, and topic, so it may need to be performed multiple times.

> The sensitive values referenced here are stored in Vaultwarden; the Helm chart does not yet support using only Secrets.

As a temporary measure, you can increase the capacity of the persistent volume of the pod having issues. You can either edit the persistent volume YAML directly, or run `helm upgrade sentry apps/charts/sentry -n sentry -f apps/values/sentry_sensitive.yaml -f apps/charts/sentry/values.yaml --debug` after setting a larger volume size in `values.yaml`. Either way, you will likely have to restart the pod to let the change take effect.

The rest of these instructions are relevant not just for disk space issues, but also for resolving a common cause of failing consumers. For instance, when Sentry experiences issues for more than a fleeting moment, sometimes internal logging can get backed up when the service recovers. Two Kubernetes workloads, `sentry-snuba-subscription-consumer-events` and `sentry-snuba-subscription-consumer-transactions`, are both particularly susceptible to these sorts of errors, which correspond to a message of "Broker: Offset out of range" when clicking through to the "App Errors" tab for a failing pod in the Google Cloud Console UI.

1. Check if there are any failing consumer pods in [Workloads](https://console.cloud.google.com/kubernetes/workload?project=cal-itp-data-infra); you can use a failing pod's logs to identify its topic and potentially its consumer group. To resolve the issue, we need to reset the offset for the Kafka consumer groups and topics associated with these workloads.
2. Access the Kafka service directly via kubectl (in this example, we're logging into the `sentry-kafka` workload via a pod named `sentry-kafka-0`, but any pod for a given Kafka workload will do the trick): `kubectl exec --stdin --tty sentry-kafka-0 -n sentry -- bash`
3. Run the following to get a list of consumer groups associated with different processes we run: `/opt/bitnami/kafka/bin/kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --list`. If things are slow on the pod and you're getting timeouts on this command, it can sometimes help to add a `--timeout 50000` or some other arbitrary number of milliseconds to the end of the command, since the default is 5000. Same goes for any other command you run on the pod.
4. Locate the entries in the list returned by the previous list that seem clearly related to the workload(s) you're trying to resolve. In this example case, that's these two groups: `snuba-events-subscriptions-consumers` and `snuba-transactions-subscriptions-consumers`. For each of them, run the following to get a list of current storage offsets and the topics associated with them: `/opt/bitnami/kafka/bin/kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --group [GROUP NAME] -describe`
5. You will likely see an entry in the table that comes back that has a positive value in the `LAG` column, meaning the consumer is behind where it should be in logging. Make note of the topic associated with any rows that have a lag, and then run the following: `/opt/bitnami/kafka/bin/kafka-consumer-groups.sh --bootstrap-server 127.0.0.1:9092 --group [GROUP NAME] --topic [TOPIC NAME] --reset-offsets --to-latest --execute`. If you hit `Error: Assignments can only be reset if the group 'snuba-post-processor' is inactive, but the current state is Stable.`, you need to stop the consumers on the topic (by deleting the pods and/or deployment), resetting the offset, and starting the pods again (via `helm upgrade sentry apps/charts/sentry -n sentry -f apps/values/sentry_sensitive.yaml -f apps/charts/sentry/values.yaml --debug` if you deleted the deployment).
6. After doing that for a given group, go back to the failing Kubernetes workload in the Google Cloud UI and delete its pods, allowing them to recreate. Once they recreate, they should go green. Do this for every group you identified as belonging to one of the workloads that was failing with the Kafka offset error.
7. (Optional) If disk space is still maxed out and the consumers fail to recover even after increasing the disk space, stop the failing Kafka pod and delete its underlying persistent volume, then repeat the steps again. **This will lose all in-flight data**, but is preferable to the worker continuing to exist in a bad state.
8. (Optional) Check the existing `logRetentionHours` in [values.yaml](../../kubernetes/apps/charts/sentry/values.yaml); it should be set but may need to be made shorter.
