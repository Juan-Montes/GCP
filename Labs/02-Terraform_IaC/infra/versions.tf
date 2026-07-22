# =============================================================================
#  infra · versions.tf — sin bloque backend: Terragrunt lo genera por entorno.
# =============================================================================
terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
