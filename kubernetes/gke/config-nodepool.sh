GKE_NODEPOOL_NAMES=(
  'default-pool'
  'apps-v1'
)

declare -A GKE_NODEPOOL_NODE_COUNTS
GKE_NODEPOOL_NODE_COUNTS=(
  ['default-pool']=1
  ['apps-v1']=1
)

declare -A GKE_NODEPOOL_NODE_LOCATIONS
GKE_NODEPOOL_NODE_LOCATIONS=(
  ['default-pool']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
  ['apps-v1']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
)

declare -A GKE_NODEPOOL_MACHINE_TYPES
GKE_NODEPOOL_MACHINE_TYPES=(
  ['default-pool']=e2-medium
  ['apps-v1']=n1-standard-4
)
