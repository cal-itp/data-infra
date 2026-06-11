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
