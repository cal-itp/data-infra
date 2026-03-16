{% macro _bigquery__get_extended_catalog_sql() %}
    select
        tables.table_catalog as table_database,
        tables.table_schema,
        case
            when tables.is_date_shard then concat(tables.table_name, '*')
            else tables.table_name
        end as table_name,
        tables.table_type,
        tables.table_comment,
        NULL as table_owner,
        -- coalesce column metadata fields to ensure they are non-null for catalog generation
        -- external table columns are not present in COLUMN_FIELD_PATHS
        coalesce(columns.column_name, '<unknown>') as column_name,
        coalesce(columns.column_index, 1) as column_index,
        coalesce(columns.column_type, '<unknown>') as column_type,
        coalesce(columns.column_comment, '') as column_comment,

        'Shard count' as `stats__date_shards__label`,
        table_stats.shard_count as `stats__date_shards__value`,
        'The number of date shards in this table' as `stats__date_shards__description`,
        tables.is_date_shard as `stats__date_shards__include`,

        'Shard (min)' as `stats__date_shard_min__label`,
        table_stats.shard_min as `stats__date_shard_min__value`,
        'The first date shard in this table' as `stats__date_shard_min__description`,
        tables.is_date_shard as `stats__date_shard_min__include`,

        'Shard (max)' as `stats__date_shard_max__label`,
        table_stats.shard_max as `stats__date_shard_max__value`,
        'The last date shard in this table' as `stats__date_shard_max__description`,
        tables.is_date_shard as `stats__date_shard_max__include`,

        '# Rows' as `stats__num_rows__label`,
        table_stats.row_count as `stats__num_rows__value`,
        'Approximate count of rows in this table' as `stats__num_rows__description`,
        tables.is_table as `stats__num_rows__include`,

        'Approximate Size' as `stats__num_bytes__label`,
        table_stats.size_bytes as `stats__num_bytes__value`,
        'Approximate size of table as reported by BigQuery' as `stats__num_bytes__description`,
        tables.is_table as `stats__num_bytes__include`,

        'Partitioned By' as `stats__partitioning_type__label`,
        column_stats.partition_column as `stats__partitioning_type__value`,
        'The partitioning column for this table' as `stats__partitioning_type__description`,
        column_stats.is_partitioned as `stats__partitioning_type__include`,

        'Clustered By' as `stats__clustering_fields__label`,
        column_stats.clustering_columns as `stats__clustering_fields__value`,
        'The clustering columns for this table' as `stats__clustering_fields__description`,
        column_stats.is_clustered as `stats__clustering_fields__include`

    from tables
    join table_stats
        on table_stats.table_catalog = tables.table_catalog
        and table_stats.table_schema = tables.table_schema
        and table_stats.table_name = tables.table_name
    left join column_stats
        on column_stats.table_catalog = tables.table_catalog
        and column_stats.table_schema = tables.table_schema
        and column_stats.shard_name = table_stats.latest_shard_name
    left join columns
        on columns.table_catalog = tables.table_catalog
        and columns.table_schema = tables.table_schema
        and columns.shard_name = table_stats.latest_shard_name
{% endmacro %}
