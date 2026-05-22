variable "run_metadata_migration" {
  description = "Set to true to export Airflow metadata (connections, variables, pools) from composer2 and import into composer3"
  type        = bool
  default     = false
}

resource "null_resource" "migrate_composer_metadata" {
  count = var.run_metadata_migration ? 1 : 0

  depends_on = [google_composer_environment.calitp-staging-composer3]

  triggers = {
    rerun = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      TMPDIR=$$(mktemp -d)
      trap "rm -rf $$TMPDIR" EXIT

      echo "=== Step 1: Export connections from composer2 ==="
      gcloud composer environments run calitp-staging-composer --location us-west2 \
        connections -- export - 2>/dev/null > $$TMPDIR/connections.json

      echo "=== Step 2: Export variables from composer2 ==="
      gcloud composer environments run calitp-staging-composer --location us-west2 \
        variables -- export - 2>/dev/null > $$TMPDIR/variables.json

      echo "=== Step 3: Export pools from composer2 ==="
      gcloud composer environments run calitp-staging-composer --location us-west2 \
        pools -- list --output json 2>/dev/null > $$TMPDIR/pools.list.json

      echo "=== Step 4: Transform pools to dict format ==="
      python3 -c "
import json
with open('$$TMPDIR/pools.list.json') as f:
    pools = json.load(f)
result = {}
for p in pools:
    name = p.pop('pool')
    p['slots'] = int(p['slots'])
    p['include_deferred'] = p.get('include_deferred', 'False') == 'True'
    result[name] = p
with open('$$TMPDIR/pools.json', 'w') as f:
    json.dump(result, f, indent=2)
"

      echo "=== Step 5: Upload exports to composer3 bucket ==="
      BUCKET3=$$(gcloud composer environments describe calitp-staging-composer3 \
        --location us-west2 --format='value(config.dagGcsPrefix)' | sed 's|gs://||;s|/dags||')
      gcloud storage cp $$TMPDIR/connections.json $$TMPDIR/variables.json $$TMPDIR/pools.json "gs://$$BUCKET3/"

      echo "=== Step 6: Import connections to composer3 ==="
      gcloud composer environments run calitp-staging-composer3 --location us-west2 \
        connections -- import --overwrite /home/airflow/gcs/data/connections.json 2>&1 \
        | grep -v "^\[" | grep -v "direnv:" | grep -v "Executing" | grep -v "Command has" | grep -v "Use ctrl-c" || true

      echo "=== Step 7: Import variables to composer3 ==="
      gcloud composer environments run calitp-staging-composer3 --location us-west2 \
        variables -- import /home/airflow/gcs/data/variables.json 2>&1 \
        | grep -v "^\[" | grep -v "direnv:" | grep -v "Executing" | grep -v "Command has" | grep -v "Use ctrl-c" || true

      echo "=== Step 8: Import pools to composer3 ==="
      gcloud composer environments run calitp-staging-composer3 --location us-west2 \
        pools -- import /home/airflow/gcs/data/pools.json 2>&1 \
        | grep -v "^\[" | grep -v "direnv:" | grep -v "Executing" | grep -v "Command has" | grep -v "Use ctrl-c" || true

      echo "=== Migration complete ==="
    EOT
  }
}
