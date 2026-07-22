# =============================================================================
#  Nivel 02 · variables.tf
# =============================================================================
variable "project_id" {
  description = "ID del proyecto de GCP."
  type        = string
}

variable "region" {
  description = "Region por defecto."
  type        = string
  default     = "us-central1"
}

variable "terraform_sa" {
  description = "Email de la service account que Terraform impersona."
  type        = string
}
