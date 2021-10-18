#!/bin/bash
set -e

SRCDIR=$(dirname "$0")

. "$SRCDIR/config-cluster.sh"
. "$SRCDIR/config-nodepool.sh"

GKE_NODEPOOL_NODE_COUNT=${GKE_NODEPOOL_NODE_COUNTS[default-pool]}
GKE_NODEPOOL_NODE_LOCATION=${GKE_NODEPOOL_NODE_LOCATIONS[default-pool]}
GKE_NODEPOOL_MACHINE_TYPE=${GKE_NODEPOOL_MACHINE_TYPES[default-pool]}

if ! [ "$GKE_NODEPOOL_NODE_COUNT"    ] ||
   ! [ "$GKE_NODEPOOL_NODE_LOCATION" ] ||
   ! [ "$GKE_NODEPOOL_MACHINE_TYPE"  ] ; then
  printf 'fatal: missing one ore more required values for node-pool: %s\n' default-pool >&2
  printf 'provided values:\n'                                                           >&2
  printf 'GKE_NODEPOOL_NODE_COUNT=%s\n' "$GKE_NODEPOOL_NODE_COUNT"                      >&2
  printf 'GKE_NODEPOOL_NODE_LOCATION=%s\n' "$GKE_NODEPOOL_NODE_LOCATION"                >&2
  printf 'GKE_NODEPOOL_MACHINE_TYPE=%s\n' "$GKE_NODEPOOL_MACHINE_TYPE"                  >&2
  exit 1
fi

gcloud container clusters describe $GKE_NAME --region $GKE_REGION >/dev/null ||
gcloud container clusters create $GKE_NAME     \
  --region $GKE_REGION                         \
  --release-channel $GKE_CHANNEL               \
  --num-nodes $GKE_NODEPOOL_NODE_COUNT         \
  --node-locations $GKE_NODEPOOL_NODE_LOCATION \
  --enable-ip-alias                            \
  --enable-network-policy
#  --machine-type $GKE_NODEPOOL_MACHINE_TYPE  \

"$SRCDIR/nodepool-up.sh"

test -e "$GKE_KUBECONFIG" ||
KUBECONFIG=$GKE_KUBECONFIG gcloud container clusters get-credentials $GKE_NAME
KUBECONFIG=$GKE_KUBECONFIG kubectl apply -k "$SRCDIR/../system"
