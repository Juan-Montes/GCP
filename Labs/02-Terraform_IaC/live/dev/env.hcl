# =============================================================================
#  Entorno: DEV — lo único que distingue a dev de prod.
# =============================================================================
locals {
  project_id   = "juan-devops-lab-dev"
  region       = "us-central1"
  terraform_sa = "terraform-sa@juan-devops-lab-dev.iam.gserviceaccount.com"

  # Adoptamos el estado que Terraform ya creó en los bloques anteriores.
  state_prefix = "nivel02"
}
