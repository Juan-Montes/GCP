# =============================================================================
#  DEV · platform — este archivo es IDÉNTICO al de prod. Ahí está el DRY.
# =============================================================================
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../infra"
}
