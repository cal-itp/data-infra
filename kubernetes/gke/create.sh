#!/bin/sh
set -e

SRCDIR=$(dirname "$0")

. "$SRCDIR/config.sh"

gcloud container clusters describe $GKE_NAME --region $GKE_REGION >/dev/null ||
gcloud container clusters create $GKE_NAME \
  --region $GKE_REGION                     \
  --release-channel $GKE_CHANNEL           \
  --num-nodes $GKE_NUM_NODES               \
  --node-locations $GKE_LOCATIONS          \
  --enable-ip-alias                        \
  --enable-network-policy
#  --machine-type $GKE_MACHINE_TYPE         \

test -e "$GKE_KUBECONFIG" ||
KUBECONFIG=$GKE_KUBECONFIG gcloud container clusters get-credentials $GKE_NAME
