resource "metabase_collection" "reports" {
  name        = "Reports"
  description = "Contains reports accessible to business analysts."
}

resource "metabase_collection_graph" "graph" {
  permissions = [
    {
      group      = metabase_permissions_group.data-analysts.id
      collection = metabase_collection.reports.id
      permission = "write"
    }
  ]
}
