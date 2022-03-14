GKE_NODEPOOL_NAMES=(
  'apps-v2'
  'gtfsrt-v1'
  'jupyterhub-users'
)

declare -A GKE_NODEPOOL_NODE_COUNTS
GKE_NODEPOOL_NODE_COUNTS=(
  ['apps-v2']=1
  ['gtfsrt-v1']=1
  ['jupyterhub-users']=1
)

declare -A GKE_NODEPOOL_NODE_LOCATIONS
GKE_NODEPOOL_NODE_LOCATIONS=(
  ['apps-v2']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
  ['gtfsrt-v1']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
  ['jupyterhub-users']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
)

declare -A GKE_NODEPOOL_MACHINE_TYPES
GKE_NODEPOOL_MACHINE_TYPES=(
  ['apps-v2']=n1-standard-4
  ['gtfsrt-v1']=n2-highcpu-8
  ['jupyterhub-users']=e2-highmem-2
)

declare -A GKE_NODEPOOL_TAINTS
GKE_NODEPOOL_TAINTS=(
  ['gtfsrt-v1']='resource-domain=gtfsrt:NoSchedule'
  ['jupyterhub-users']='hub.jupyter.org/dedicated=user'
)

declare -A GKE_NODEPOOL_LABELS
GKE_NODEPOOL_LABELS=(
  ['gtfsrt-v1']='resource-domain=gtfsrt'
  ['jupyterhub-users']='hub.jupyter.org/node-purpose=user'
)
