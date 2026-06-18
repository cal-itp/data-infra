"""Internal constants for the Metabase dashboard template tool.

Nothing here is user-configurable: the strip-key sets are dictated by the
Metabase API contract (which fields are server-generated and rejected or
ignored on write).  Pure data, stdlib-only.
"""

# ---------------------------------------------------------------------------
# Strip-key sets
#
# Empirically derived from the Metabase OpenAPI spec (v0.58) plus inspection
# of real GET payloads.  A field is "STRIP" if it is server-generated and
# either ignored or rejected on write.
# ---------------------------------------------------------------------------

STRIP_CARD_KEYS = {
    "id",
    "entity_id",
    "created_at",
    "updated_at",
    "last_used_at",
    "view_count",
    "query_average_duration",
    "creator_id",
    "made_public_by_id",
    "public_uuid",
    "dashboard_id",
    "can_write",
    "card_schema",
    "metabase_version",
    "dependency_analysis_version",
    "archived_directly",
    "download_perms",
    "initially_published_at",
    "cache_invalidated_at",
    "moderation_reviews",
    "legacy_query",
    "is_remote_synced",
    "source_card_id",
    "document_id",
    # Stripped because Metabase recomputes it from dataset_query, and the
    # source-DB-specific table_id/field_id values inside it are noise.
    "result_metadata",
}

STRIP_DASHCARD_KEYS = {
    "id",
    "entity_id",
    "created_at",
    "updated_at",
    "dashboard_id",
    "collection_authority_level",
    "action_id",
    # card_id is derived at apply time (each new card gets a fresh id);
    # virtual dashcards continue to be detected by visualization_settings.virtual_card.
    "card_id",
}

STRIP_DASHBOARD_KEYS = {
    "id",
    "entity_id",
    "created_at",
    "updated_at",
    "last_viewed_at",
    "last_used_param_values",
    "view_count",
    "creator_id",
    "made_public_by_id",
    "public_uuid",
    "can_write",
    "can_delete",
    "can_restore",
    "archived_directly",
    "param_fields",
    "last-edit-info",
    "collection",
    "collection_authority_level",
    "moderation_reviews",
    "dependency_analysis_version",
    "initially_published_at",
    "is_remote_synced",
}

# ---------------------------------------------------------------------------
# Jinja delimiters
#
# Metabase native-SQL queries carry their OWN `{{ ... }}` parameters -- field
# filters and variables -- e.g. `[[AND {{transaction_date_time_pacific}}]]`.
# Those are the same delimiters Jinja uses by default, so if we templated with
# the defaults the apply-time render would try to resolve Metabase's own
# parameters as one of our variables and blow up with `'<name>' is undefined`.
#
# Fix: move OUR templating onto a `$`-sigil delimiter family that Metabase
# never emits.  Jinja then passes Metabase's `{{ ... }}` (and its `[[ ... ]]`
# optional clauses, which Jinja already ignores) through untouched.  We also
# move the block/comment delimiters off the `{% %}` / `{# #}` defaults so a
# stray `{%`/`{#` inside a SQL string can never be misread either.
#
# Both ends of the pipeline MUST agree on these: emit_template_yaml writes
# them, make_jinja_env parses them.  The three start strings differ in their
# second character (`{`, `%`, `#`) so there is no prefix ambiguity, and none
# of these sequences appear in exported dashboard content.
JINJA_VARIABLE_START = "${"
JINJA_VARIABLE_END = "}"
JINJA_BLOCK_START = "$%"
JINJA_BLOCK_END = "%$"
JINJA_COMMENT_START = "$#"
JINJA_COMMENT_END = "#$"

# Subset of dashboard top-level keys that POST /api/dashboard/ accepts.
# Anything else gets attached via the follow-up PUT /api/dashboard/{id}.
POST_DASHBOARD_KEYS = {
    "name",
    "description",
    "collection_id",
    "collection_position",
    "parameters",
    "cache_ttl",
}
