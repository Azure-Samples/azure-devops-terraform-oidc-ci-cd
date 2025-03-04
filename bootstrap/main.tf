resource "random_string" "unique_name" {
  length  = 3
  special = false
  upper   = false
  numeric = false
}
