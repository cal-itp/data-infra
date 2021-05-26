#!/bin/sh
set -e

SRCDIR=$(dirname "$0")

. "$SRCDIR/config.sh"

if gcloud container clusters describe $GKE_NAME --region $GKE_REGION >/dev/null 2>&1; then
  gcloud container clusters delete $GKE_NAME --region $GKE_REGION
fi
rm -vf $GKE_KUBECONFIG
