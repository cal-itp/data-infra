from .config import format_table_name, get_bucket, get_project_id

user_defined_macros = dict(
    get_project_id=get_project_id,
    get_bucket=get_bucket,
    THE_FUTURE='DATE("2099-01-01")',
)

user_defined_filters = dict(
    table=lambda x: format_table_name(x, is_staging=False, full_name=True),
    quote=lambda s: '"%s"' % s,
)
