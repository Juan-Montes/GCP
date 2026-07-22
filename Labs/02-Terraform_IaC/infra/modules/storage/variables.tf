# =============================================================================
#  Módulo: storage — variables
# =============================================================================
variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "bucket_name" {
  description = "Nombre global del bucket de estáticos."
  type        = string
}
