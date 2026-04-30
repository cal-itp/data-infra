# STEPS — Cloning a Metabase Dashboard for a New Agency

A step-by-step guide for analysts. Replace every `<PLACEHOLDER>` with the
value for your situation.

## Mental model

- Any existing agency's dashboard can be the source — there is no canonical
  blessed template per dashboard family.
- Templates are **transient by default**. You generate one, apply it, and
  discard. Commit a template only if you've decided a specific shape is
  worth versioning.
- The flow is two phases:
  1. **Export** — source dashboard → YAML template
  2. **Apply** — template + per-agency context → new dashboard in target
     collection

## One-time setup

From the repo root, once per workstation:

```bash
python3 -m venv tools/metabase_dashboard_templates/.venv
tools/metabase_dashboard_templates/.venv/bin/pip install \
  -r tools/metabase_dashboard_templates/requirements.txt
```

## Per-session setup

```bash
# Pick the right environment — staging for testing, prod for real.
export METABASE_URL="<https://metabase-staging.dds.dot.ca.gov OR prod URL>"
export METABASE_API_KEY="<your-personal-api-key>"
```

Generate the API key from the Metabase admin UI under your account
settings. **Rotate it if you've shared it in a chat, ticket, or
screenshot.**

## Step 1 — Identify source and target

Gather four values from the Metabase UI before running anything.

| What                        | How to find it                                                                                                                |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `<SOURCE_DASHBOARD_ID>`     | Open the source dashboard. URL is `/dashboard/<id>-<slug>`; take the integer.                                                 |
| `<TARGET_DATABASE_ID>`      | Admin → Databases → click your target connection. URL is `/admin/databases/<id>`. Must expose every schema the source uses.   |
| `<TARGET_COLLECTION_ID>`    | Open the target collection. URL is `/collection/<id>-<slug>`.                                                                 |
| `<DASHBOARD_NAME>`          | Free text — e.g. `"Foothill - Feed Level V2"`.                                                                                |

Verify the target DB exposes the schemas the source dashboard needs (this
catches the most common apply-time error):

```bash
curl -s -H "X-API-Key: $METABASE_API_KEY" \
  "$METABASE_URL/api/database/<TARGET_DATABASE_ID>/metadata" | \
  jq -r '[.tables[].schema] | unique | .[]'
```

If the source uses `mart_payments` and the target DB only shows
`mart_gtfs`, you have the wrong target DB. Pick a different one.

## Step 2 — Identify substitutions

Open the source dashboard in Metabase and look for agency-specific text in:

- Dashboard description
- Card names
- Card descriptions
- Heading and text dashcards (the prose blocks between charts)
- Filter labels

For an MST → Foothill clone you might end up with:

| Literal in source                     | Variable name (your choice) |
| ------------------------------------- | --------------------------- |
| `MST`                                 | `agency_short`              |
| `Mendocino Transit Authority`         | `agency_long`               |

Variable name rules: letters, digits, underscores. Can't start with a
digit. No hyphens. (`agency-short` will be rejected; `agency_short` is
fine.)

## Step 3 — Export the source dashboard to a template

```bash
tools/metabase_dashboard_templates/.venv/bin/python \
  tools/metabase_dashboard_templates/cli.py \
  dashboard-to-template \
  --dashboard-id <SOURCE_DASHBOARD_ID> \
  --template-file /tmp/<TEMPLATE_NAME>.yml \
  --substitution "<LITERAL_1>=<VARNAME_1>" \
  --substitution "<LITERAL_2>=<VARNAME_2>"
```

Notes:

- `--substitution` is repeatable — one flag per `LITERAL=VARNAME` pair.
- The script auto-templatizes the dashboard name to `{{ dashboard_name }}`.
  Pass `--no-templatize-name` for migration-style 1:1 copies that should
  keep the source's name.
- Writing to `/tmp/` keeps templates out of the repo. The script will
  create any missing parent directories.

Expected last line:

```
Wrote template (NNN expressions) -> /tmp/<TEMPLATE_NAME>.yml
```

You may also see warnings like `warn: viz field id NNNNN unresolved...`.
These are stale Metabase catalog references in the source dashboard's
column-formatting/click-behavior settings. The export proceeds; those
specific column styles may revert to defaults on the target. Not an error.

## Step 4 — (Optional) Hand-edit the template

If something agency-specific isn't covered by your substitutions, open
`/tmp/<TEMPLATE_NAME>.yml` and replace literal strings with
`{{ varname }}` expressions directly. Add the corresponding key to your
apply context in Step 5.

## Step 5 — Dry-run the apply

Always do this before a real push.

```bash
tools/metabase_dashboard_templates/.venv/bin/python \
  tools/metabase_dashboard_templates/cli.py \
  template-to-dashboard \
  --template-file /tmp/<TEMPLATE_NAME>.yml \
  --template-context '{
    "database_id": <TARGET_DATABASE_ID>,
    "collection_id": <TARGET_COLLECTION_ID>,
    "dashboard_name": "<DASHBOARD_NAME>",
    "<VARNAME_1>": "<TARGET_VALUE_1>",
    "<VARNAME_2>": "<TARGET_VALUE_2>"
  }' \
  --dry-run
```

`--dry-run` renders the template and prints the resulting dashboard spec
as JSON. No HTTP writes happen.

Common dry-run errors and what they mean:

- `'<X>' is undefined` — you forgot a context key. Add it.
- `table '<X>.<Y>' not found in target DB metadata` — the target DB
  doesn't have a schema the source uses. Pick a different target DB
  (re-do the schema check from Step 1).

## Step 6 — Real apply

Same command, drop `--dry-run`:

```bash
tools/metabase_dashboard_templates/.venv/bin/python \
  tools/metabase_dashboard_templates/cli.py \
  template-to-dashboard \
  --template-file /tmp/<TEMPLATE_NAME>.yml \
  --template-context '<same JSON as the dry-run>'
```

Output:

```
  created card <id>: '<name>'
  ... (more cards) ...
  created dashboard <id>: '<DASHBOARD_NAME>'
  attached N dashcards
View: <METABASE_URL>/dashboard/<NEW_DASHBOARD_ID>
```

## Step 7 — Verify

Open the View URL. Check, in priority order:

1. **Filters connect to cards.** Click a dashboard parameter; the cards
   should react. If filters don't update the cards, something's wrong
   with `parameter_mappings` in the apply path — flag this on the issue.
2. **Card queries return data.** Each card should show real numbers, not
   a SQL error.
3. **Substitutions rendered.** Card titles, headings, descriptions should
   show your `<TARGET_VALUE_*>` strings, not raw `MST` or
   `{{ agency_short }}`.
4. **Column styling matches source (mostly).** Stale viz field IDs from
   Step 3 may cause some columns to lose their formatting. If the
   divergence is severe, see "Cleaning a noisy source" below.

## Step 8 — Cleanup

For a test push you don't want to keep:

- Delete the dashboard from Metabase: kebab menu → Move to Trash
- Delete the orphan cards from the same collection
- Delete the local template: `rm /tmp/<TEMPLATE_NAME>.yml`

## Excludes / gitignore

Ad-hoc template files do not belong in the repo. Two clean approaches:

1. **Always write to `/tmp/`** (recommended — nothing to commit, nothing
   to gitignore).
2. **Write to a local working dir and gitignore it.** Add to `.gitignore`:
   ```
   /templates/
   /tools/metabase_dashboard_templates/templates/
   ```

If you've already accidentally staged a stray template:

```bash
git restore --staged <path-to-stray.yml>
rm <path-to-stray.yml>
```

If a stray template is already on a feature branch but not yet pushed,
`git rm --cached` plus a follow-up commit will get it out of the index.

## Cleaning a noisy source

If your export produced lots of `warn: viz field id ... unresolved`
warnings (more than ~10), the source dashboard has significant catalog
drift — typically because the warehouse changed shape and Metabase
re-indexed with new field IDs. Two responses:

- **Best**: open the source dashboard in Metabase and re-apply each
  affected column-formatting/click-behavior rule (Metabase will rebind
  to current IDs on save). Re-export. Warnings should be gone.
- **Acceptable**: pick a different source dashboard that has fewer
  warnings — there's no canonical version, so any clean dashboard works.

## Troubleshooting cheatsheet

| Symptom                                              | Likely cause                                | Fix                                                                  |
| ---------------------------------------------------- | ------------------------------------------- | -------------------------------------------------------------------- |
| `'<key>' is undefined`                               | Missing context key                         | Add `"<key>": "<value>"` to `--template-context`                     |
| `table '<X>.<Y>' not found in target DB metadata`    | Target DB lacks a needed schema             | Pick a different target DB (re-run the metadata check from Step 1)   |
| `field id NNNNN not found in source DB metadata`    | Stale ref in source's MBQL query            | Fix the source dashboard's query in Metabase, or pick a cleaner source |
| `warn: viz field id NNNNN unresolved` (warning)     | Stale ref in source's display settings      | Cosmetic — that column's styling will revert to default on target    |
| `--substitution must be LITERAL=VARNAME`             | Malformed flag                              | Format is `"text=var_name"`, one `=` only, valid identifier on right |
| `FileNotFoundError` writing template                 | Output path's parent missing                | Resolved automatically in current version                            |
| Filters don't react to changes on the new dashboard  | parameter_mappings card_id rewrite broke    | File a bug — this should not happen                                  |

## Gotchas

- API keys appear in `ps` output if you pass them via `--metabase-api-key`
  on the command line. Prefer the env var form (`METABASE_API_KEY`).
- Always apply against staging before production. Mistakes on staging are
  easy to clean up; on production they're visible to agencies.
- The four payments reference dashboard families (Littlepay flat,
  Littlepay variable, Enghouse flat, MSC tracking) live in separate
  per-agency collections. Pick a representative agency dashboard for each
  family as the source rather than looking for a single canonical version.
