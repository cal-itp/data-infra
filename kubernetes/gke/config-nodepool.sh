GKE_NODEPOOL_NAMES=(
  'apps-v2'
  'gtfsrt-v3'
  'gtfsrt-v4'
  'jupyterhub-users'
  'jobs-v1'
)

declare -A GKE_NODEPOOL_NODE_COUNTS
GKE_NODEPOOL_NODE_COUNTS=(
  ['apps-v2']=1
  ['gtfsrt-v3']=1
  ['gtfsrt-v4']=1
  ['jupyterhub-users']=1
  ['jobs-v1']=1
)

declare -A GKE_NODEPOOL_NODE_LOCATIONS
GKE_NODEPOOL_NODE_LOCATIONS=(
  ['apps-v2']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
  ['gtfsrt-v3']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
  ['gtfsrt-v4']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
  ['jupyterhub-users']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
  ['jobs-v1']=$GKE_REGION-a
)

declare -A GKE_NODEPOOL_MACHINE_TYPES
GKE_NODEPOOL_MACHINE_TYPES=(
  ['apps-v2']=n1-standard-4
  ['gtfsrt-v3']=c2-standard-8
  ['gtfsrt-v4']=c2-standard-4
  ['jupyterhub-users']=e2-highmem-2
  ['jobs-v1']=c2-standard-4
)

declare -A GKE_NODEPOOL_TAINTS
GKE_NODEPOOL_TAINTS=(
  ['gtfsrt-v3']='resource-domain=gtfsrt:NoSchedule'
  ['gtfsrt-v4']='resource-domain=gtfsrtv3:NoSchedule'
  ['jupyterhub-users']='hub.jupyter.org/dedicated=user'
  ['jobs-v1']='pod-role=computetask:NoSchedule'
)

declare -A GKE_NODEPOOL_LABELS
GKE_NODEPOOL_LABELS=(
  ['gtfsrt-v3']='resource-domain=gtfsrt'
  ['gtfsrt-v4']='resource-domain=gtfsrtv3'
  ['jupyterhub-users']='hub.jupyter.org/node-purpose=user'
  ['jobs-v1']='pod-role=computetask'
)
