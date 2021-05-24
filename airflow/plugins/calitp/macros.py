from calitp.utils import get_project_id, get_bucket, format_table_name

user_defined_macros = dict(get_project_id=get_project_id, get_bucket=get_bucket)

user_defined_filters = dict(
    table=lambda x: format_table_name(x, is_staging=False, full_name=True),
    quote=lambda s: '"%s"' % s,
)
