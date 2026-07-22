# =============================================================================
#  Entorno: PROD — mismos módulos, otra identidad y otro estado.
# =============================================================================
locals {
  project_id   = "juan-devops-lab-prod"
  region       = "us-central1"
  terraform_sa = "terraform-sa@juan-devops-lab-prod.iam.gserviceaccount.com"

  state_prefix = "prod"
}
