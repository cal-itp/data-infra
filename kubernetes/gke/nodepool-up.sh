#!/bin/bash
set -e

SRCDIR=$(dirname "$0")
GKE_NODEPOOL_TGT=$1

. "$SRCDIR/config-cluster.sh"
. "$SRCDIR/config-nodepool.sh"

test -z "$GKE_NODEPOOL_TGT" || GKE_NODEPOOL_NAMES=("$GKE_NODEPOOL_TGT")

for GKE_NODEPOOL_NAME in "${GKE_NODEPOOL_NAMES[@]}"; do
  GKE_NODEPOOL_NODE_COUNT=${GKE_NODEPOOL_NODE_COUNTS[$GKE_NODEPOOL_NAME]}
  GKE_NODEPOOL_NODE_LOCATION=${GKE_NODEPOOL_NODE_LOCATIONS[$GKE_NODEPOOL_NAME]}
  GKE_NODEPOOL_MACHINE_TYPE=${GKE_NODEPOOL_MACHINE_TYPES[$GKE_NODEPOOL_NAME]}

  if ! [ "$GKE_NODEPOOL_NODE_COUNT"    ] ||
     ! [ "$GKE_NODEPOOL_NODE_LOCATION" ] ||
     ! [ "$GKE_NODEPOOL_MACHINE_TYPE"  ] ; then
    printf 'fatal: missing one ore more required values for node-pool: %s\n' "$GKE_NODEPOOL_NAME" >&2
    printf 'provided values:\n'                                                                   >&2
    printf 'GKE_NODEPOOL_NODE_COUNT=%s\n' "$GKE_NODEPOOL_NODE_COUNT"                              >&2
    printf 'GKE_NODEPOOL_NODE_LOCATION=%s\n' "$GKE_NODEPOOL_NODE_LOCATION"                        >&2
    printf 'GKE_NODEPOOL_MACHINE_TYPE=%s\n' "$GKE_NODEPOOL_MACHINE_TYPE"                          >&2
    exit 1
  fi

  gcloud container node-pools describe "$GKE_NODEPOOL_NAME" --region "$GKE_REGION" --cluster "$GKE_NAME" >/dev/null ||
  gcloud container node-pools create "$GKE_NODEPOOL_NAME" \
    --region  "$GKE_REGION"                               \
    --cluster "$GKE_NAME"                                 \
    --num-nodes      "$GKE_NODEPOOL_NODE_COUNT"           \
    --machine-type "$GKE_NODEPOOL_MACHINE_TYPE"           \
    --node-locations "$GKE_NODEPOOL_NODE_LOCATION"
done
