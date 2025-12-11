resource "metabase_permissions_group" "data-analysts" {
  name = "Data Analysts"
}

resource "metabase_permissions_group" "all-users" {
  name = "All Users"
}

resource "metabase_permissions_group" "administrators" {
  name = "Administrators"
}
