# =============================================================================
#  PROD · platform — nótese que es BYTE POR BYTE igual al de dev.
#  Toda la diferencia entre entornos vive en ../env.hcl.
# =============================================================================
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../infra"
}
