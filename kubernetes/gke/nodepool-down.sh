#!/bin/bash
set -e

SRCDIR=$(dirname "$0")
GKE_NODEPOOL_TGT=$1

. "$SRCDIR/config-cluster.sh"
. "$SRCDIR/config-nodepool.sh"

if ! [ "$GKE_NODEPOOL_TGT" ] || [ "$GKE_NODEPOOL_TGT" = '-h' ] || [ "$GKE_NODEPOOL_TGT" = '--help' ]; then
  printf 'usage: %s <NODEPOOL_NAME>\n' "$0"
  exit 0
fi

gcloud container node-pools describe "$GKE_NODEPOOL_TGT" --region "$GKE_REGION" --cluster "$GKE_NAME" >/dev/null 2>&1 ||
exit 0

for GKE_NODEPOOL_NAME in "${GKE_NODEPOOL_NAMES[@]}"; do
  if [ "$GKE_NODEPOOL_TGT" = "$GKE_NODEPOOL_NAME" ]; then
    printf 'fatal: refusing to down a configured node-pool. remove "%s" from GKE_NODEPOOL_NAMES before proceeding.\n' "$GKE_NODEPOOL_TGT" >&2
    exit 1
  fi
done

KUBECONFIG=$GKE_KUBECONFIG kubectl drain --ignore-daemonsets -l cloud.google.com/gke-nodepool=$GKE_NODEPOOL_TGT

gcloud container node-pools delete "$GKE_NODEPOOL_TGT" \
  --region "$GKE_REGION"                               \
  --cluster "$GKE_NAME"
