resource "metabase_permissions_graph" "graph" {
  advanced_permissions = false

  permissions = [
    {
      create_queries = "query-builder-and-native"
      database       = metabase_database.bigquery.id
      download = {
        schemas = "full"
      }
      group     = metabase_permissions_group.all-users.id
      view_data = "unrestricted"
    },
    {
      create_queries = "query-builder-and-native"
      database       = 2
      download = {
        schemas = "full"
      }
      group     = metabase_permissions_group.data-analysts.id
      view_data = "unrestricted"
    },
  ]
}
