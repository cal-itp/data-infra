# STEPS — Cloning a Metabase Dashboard with the Interactive Wizard

A step-by-step guide for analysts cloning dashboards between Metabase Staging
and Metabase Prod (or saving them to a YAML template for later).

## What this tool does

You pick a source dashboard (from Staging, Prod, or a previously-saved YAML
template), pick a destination (Staging, Prod, or just a YAML file on disk),
and the wizard takes care of:

- Fetching the dashboard from the source instance.
- Following any "saved questions on top of saved questions" chains so the
  cloned dashboard isn't missing its underlying queries.
- Saving a Jinja-templated YAML to `templates/` so you can re-apply or audit
  later.
- Creating fresh cards, tabs, and the new dashboard on the destination
  instance — never modifying or overwriting anything that already exists.

The original tool was driven by long `--metabase-url ... --metabase-api-key ... --template-context '{...}'` command lines. That's still supported (see
`python cli.py --help`) but is now a fallback for CI use. **For everyday
work, run the wizard.**

## Mental model

- **Two source instances** — `Metabase Staging` and `Metabase Prod` — each
  with its own API key stored as a GCP Secret Manager secret. The wizard
  fetches the right key automatically based on the source you pick.
- **Two failure-safety gates** are built in:
  - Picking **Metabase Prod as a destination** requires a `[y/N]` confirm.
  - **Duplicate dashboard names** in the target collection trigger another
    `[y/N]` before any cards are created.
- **Nothing is ever overwritten.** Apply only POSTs new objects. The worst
  case is leftover orphan cards on a failed run — easy to trash via the
  Metabase UI.

______________________________________________________________________

## One-time setup

You only need to do this once per workstation.

### 1. Install Python dependencies

```bash
cd tools/metabase_dashboard_templates
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

This pulls in Jinja2, PyYAML, click, requests, and
`google-cloud-secret-manager`.

### 2. GCP authentication

The wizard reads Metabase API keys from **GCP Secret Manager**, which means
it needs your Google Cloud credentials. Cal-ITP uses **Workforce Identity
Federation** through `dot.ca.gov`, not personal Google accounts — that's why
the standard `gcloud auth application-default login` (without arguments)
won't work out of the box.

Use the cal-itp `glogin-*` aliases your `.zshrc` already has:

```bash
# For everyday work (you'll switch between these depending on which env
# you're querying):
glogin-calitp-staging      # auths against cal-itp-data-infra-staging
glogin-calitp-prod         # auths against cal-itp-data-infra
```

Each alias does the workforce-identity OAuth dance, writes credentials to
`~/.config/gcloud/adc_calitp.json`, and switches gcloud's active
configuration to point at the right project.

**The wizard will trigger this for you if needed.** If you run the wizard
without ADC set up, you'll see:

```
GCP Application Default Credentials are not configured.
Launching `gcloud auth application-default login` (a browser tab will open)...
```

Hit accept in the browser, control returns to the wizard, and the secret
fetch retries automatically. (Note: the automatic path uses the *generic*
gcloud login, which is fine for a fresh install. For cal-itp workforce
identity specifically, prefer the `glogin-calitp-*` aliases since they wire
the right project + ADC-file rotation.)

### 3. GCP IAM — once per cal-itp workstation

You need the **`roles/secretmanager.secretAccessor`** IAM role on both
Metabase API key secrets. Your team admin grants this once. To check whether
it's already set up for your account:

```bash
gcloud secrets describe metabase-dashboard-copy-tool-metabase-staging-api-key \
  --project=cal-itp-data-infra-staging
gcloud secrets describe metabase-dashboard-copy-tool-metabase-prod-api-key \
  --project=cal-itp-data-infra
```

Both should print the secret's metadata. If you see `PERMISSION_DENIED` or
`NOT_FOUND` you don't have access yet — ask in `#data-engineering` (or
whichever channel handles cal-itp IAM). The wizard will print the exact
`gcloud` command to fix permission issues if it hits one at runtime.

### 4. (Optional) Quota project

You may see a yellow warning about a missing quota project:

```
UserWarning: Your application has authenticated using end user credentials
from Google Cloud SDK without a quota project...
```

It's noise, not blocking. Silence it with:

```bash
gcloud auth application-default set-quota-project cal-itp-data-infra-staging
```

______________________________________________________________________

## Running the wizard

From the `tools/metabase_dashboard_templates/` directory:

```bash
.venv/bin/python cli.py interactive
```

That's the whole invocation. Everything else is a prompt.

### What you'll be asked, in order

1. **Where to copy from**

   ```
   Where would you like to copy a dashboard from?
     1 = Existing template in templates/
     2 = Metabase Staging
     3 = Metabase Prod
   ```

   Option 1 only appears if you have at least one YAML in `templates/` from
   a previous export. Pick 2 or 3 to fetch fresh.

2. **Which dashboard** (only if source was a Metabase instance)

   ```
   Which dashboard would you like to copy?
     1 = (CCJPA) Reconciliation dashboard (LittlePay to Elavon) (id: 304)
     2 = Payments Overview (id: 12)
     ...
   ```

   Sorted alphabetically. The `(id: N)` lets you cross-reference with
   Metabase URLs (`/dashboard/<id>-...`).

3. **Substitutions** (optional)

   ```
   Swap any literal text for Jinja variables in the template? [y/N]:
   ```

   If you're cloning MST's dashboard for Foothill, this is where you'd
   define `MST → agency_short`, `Mendocino Transit Authority → agency_long`,
   etc. Loops until you say no. Skip with `n` if you just want a structural
   copy.

   If a substitution literal appears inside a larger word (e.g. `LIST`
   inside `customer_LIST`), the wizard flags it during export and asks
   whether to substitute that specific occurrence. Each unique surrounding
   token is asked once; the decision is cached for the rest of the export.

4. **Where to copy to**

   ```
   Where would you like to copy it to?
     0 = Template only (stop here; template already saved)
     1 = Metabase Staging
     2 = Metabase Prod
   ```

   Option 0 only appears when the source was a Metabase fetch (you can't
   "template-only" a template — that'd be a copy). Picking `2 = Metabase Prod` adds an explicit confirm:

   ```
   You chose Metabase Prod as the destination. This will create a new
   dashboard and cards on production.  Continue? [y/N]:
   ```

5. **Target context** (only if destination is Staging or Prod)

   ```
   Target database (where the dashboard's queries will run):
     1 = Cal-ITP Warehouse (id: 3)
     ...

   Target collection (where the new dashboard will live):
     1 = Cal-ITP Reports (id: 12)
     2 = Cal-ITP Reports / Payments (id: 22)
     3 = Personal Collection (id: 5)
     ...

   New dashboard name [<source name>]: <type your name, e.g. "Foothill - Feed Level V2">
   ```

   - Collection paths show their parent chain so nested duplicates
     (`Reports` inside multiple parents) are distinguishable.
   - The new dashboard name defaults to the source name; you can override.
     `#`, `:`, leading dashes, and other YAML-meta characters are safe to
     include — they'll survive the YAML round-trip.

6. **Substitution values** (only if you set up substitutions in step 3, or
   if the template you picked already has them)

   ```
   This template uses 2 additional substitution variable(s):
     agency_long: Foothill Transit
     agency_short: foothill
   ```

7. **Duplicate-name guard** (only if a non-archived dashboard with your
   chosen name already exists in the target collection)

   ```
   A dashboard named '<your name>' already exists in the target collection
   (id 304).  Continuing will create a second dashboard with the same name
   (Metabase permits duplicates).  Proceed? [y/N]:
   ```

That's it. After the last prompt, the wizard runs through:

- Creating supporting cards (in dependency order),
- Creating main cards,
- Creating the dashboard shell,
- Attaching tabs and dashcards,

and prints a `View: <URL>` line. Click that URL to see the new dashboard.

______________________________________________________________________

## Templates on disk

Every Metabase fetch saves a YAML to:

```
tools/metabase_dashboard_templates/templates/<id>-<slug>-<timestamp>.yml
```

e.g. `304-ccjpa-reconciliation-dashboard-littlepay-to-elavon-20260517-143215.yml`.

The id prefix groups exports by dashboard. The timestamp suffix lets you
keep historical versions side by side (a re-export never silently clobbers
an older one). The wizard's "Existing template" picker shows all of them.

Templates aren't committed to the repo unless you explicitly want to version
one. Treat them as transient by default — re-export from prod whenever you
need a fresh copy.

______________________________________________________________________

## Verifying the result

Open the `View:` URL from the wizard's output and check, in priority order:

1. **Filters connect to cards.** Click a dashboard parameter; the cards
   should react. If filters don't update the cards, something went wrong
   with `parameter_mappings` — flag it.
2. **Card queries return data.** Each card should show real numbers, not a
   SQL error. If staging shows empty / null cards but prod has data, the
   issue is usually that staging's database connection doesn't carry the
   agency's data — not a tool bug (see "Why staging clones look empty"
   below).
3. **Substitutions rendered.** If you set up substitutions, card titles,
   headings, and descriptions should show your target values, not the
   source's literal text.
4. **Tabs preserved.** If the source dashboard had tabs, the new one should
   too, with the same names + same cards under each.

______________________________________________________________________

## Why staging clones often look empty

In prod, each transit agency has its own BigQuery database connection in
Metabase (e.g. one for CCJPA, one for MST, etc.) — that's how data is
isolated between agencies. Staging Metabase typically has a single unified
warehouse connection that doesn't carry agency-specific data the same way.

So a CCJPA dashboard cloned from prod to staging will:

- Render structurally correctly (cards, tabs, layout, parameters).
- Show empty / null results in the cards because staging's BigQuery doesn't
  have CCJPA rows for those tables.

This is **expected** and **safe** (the clone is isolated from prod data, not
broken). For validating the *tool* this is fine; for validating actual
dashboard logic, you'd test against prod (write to a sandbox collection like
`Personal / Migration Tests`).

______________________________________________________________________

## Troubleshooting

| Symptom                                                                                | Likely cause                                                                               | Fix                                                                                                            |
| -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| `GCP Application Default Credentials are not configured`                               | ADC not set up at all                                                                      | Run `glogin-calitp-staging` (or `glogin-calitp-prod`) and re-run the wizard.                                   |
| `Error code invalid_grant: Refresh token has expired`                                  | Workforce identity ADC has aged out (~16h)                                                 | Re-run `glogin-calitp-staging` / `glogin-calitp-prod` to refresh.                                              |
| `GCP returned 403 on '<secret>'`                                                       | Either secret doesn't exist OR you lack the IAM role                                       | The error message includes copy-paste `gcloud secrets describe` + `add-iam-policy-binding` commands. Run them. |
| `Template references source-card int ids [...] that have no matching supporting_cards` | Template was exported by an older version of this tool                                     | Re-export the dashboard with the current wizard (which handles supporting cards correctly).                    |
| `Metabase rejected request: POST /api/card ... 500 ...`                                | Apply-side error                                                                           | Response body printer surfaces Metabase's actual complaint. Paste it for diagnosis.                            |
| `table '<X>.<Y>' not found in target DB metadata`                                      | Target DB you picked lacks a schema the source uses                                        | Re-run, pick a different target DB in the database picker.                                                     |
| Cards show empty / null on staging                                                     | Staging DB doesn't carry the agency's data (per-agency isolation doesn't exist in staging) | Expected — see "Why staging clones often look empty" above.                                                    |
| Duplicate cards in target collection after a re-clone                                  | Card names are not deduped; re-cloning creates duplicates                                  | Archive the unused set via Metabase UI. The dashboard-name dedupe guard catches the dashboard-level case only. |

If the wizard errors halfway through (e.g. while creating cards), you'll
have orphan cards in your target collection. Open the collection in
Metabase, multi-select the orphans, "Move to trash." Then re-run.

______________________________________________________________________

## Gotchas

- **Always apply against Staging before Prod.** Mistakes on staging are
  cheap to clean up; on prod they're visible to agencies. The y/N
  confirmation on prod gives you one more chance to abort.

- **The wizard always creates, never modifies.** A re-export + re-apply of
  the same dashboard with the same name doesn't update the existing
  dashboard — it creates a second one with the same name. The duplicate-name
  guard catches this with a y/N prompt, but if you confirm, you really will
  end up with two side-by-side. To "update" a dashboard, archive the old one
  first.

- **Templates accumulate.** Each export adds a timestamped file to
  `templates/`. Nothing prunes them. Clean up by hand when the directory
  gets noisy.

- **Workforce identity tokens expire.** Cal-ITP's `glogin-calitp-*` tokens
  expire after about 16 hours. If the wizard worked yesterday but fails
  today with a `403`, your first move is `glogin-calitp-staging` or
  `glogin-calitp-prod`.

- **Substitution literals are simple `.replace()` matches.** Pick distinctive
  strings (full agency names, full identifiers) rather than short fragments
  that might appear as substrings elsewhere. The wizard does flag embedded
  occurrences (`LIST` inside `customer_LIST` → prompt) but distinctive
  literals reduce the noise.

- **API keys never appear in `ps`.** The wizard fetches them from GCP at
  runtime; they live in memory and aren't passed as flags. (The
  non-interactive subcommands optionally take `--metabase-api-key`, which
  would show up in `ps` — prefer `--gcp-secret` or the env var
  `METABASE_API_KEY_RAW` in scripts.)

______________________________________________________________________

## Non-interactive flow (for scripts / CI)

If you need to drive this from a CI pipeline or shell script, the original
two-step subcommands still work:

```bash
# Export
.venv/bin/python cli.py \
  --metabase-url "https://metabase-staging.dds.dot.ca.gov" \
  --gcp-secret "projects/cal-itp-data-infra-staging/secrets/metabase-dashboard-copy-tool-metabase-staging-api-key/versions/latest" \
  dashboard-to-template \
  --dashboard-id 304 \
  --template-file templates/304.yml

# Apply
.venv/bin/python cli.py \
  --metabase-url "https://metabase-staging.dds.dot.ca.gov" \
  --gcp-secret "projects/cal-itp-data-infra-staging/secrets/metabase-dashboard-copy-tool-metabase-staging-api-key/versions/latest" \
  template-to-dashboard \
  --template-file templates/304.yml \
  --template-context '{"database_id": 3, "collection_id": 22, "dashboard_name": "Foothill - Feed Level V2"}' \
  --dry-run
```

Add `--dry-run` to apply for a render-only check. Drop it to actually push.

But for everyday work — including most prod migrations — the wizard is the
intended path.
