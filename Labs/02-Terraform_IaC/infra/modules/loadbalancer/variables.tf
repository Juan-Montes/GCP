# =============================================================================
#  Módulo: loadbalancer — variables
# =============================================================================
variable "project_id" {
  type = string
}

variable "instance_group" {
  description = "Self link del grupo de instancias del MIG (viene de compute)."
  type        = string
}

variable "health_check_id" {
  description = "ID del health check (viene de compute; se reusa aquí)."
  type        = string
}

variable "static_bucket_name" {
  description = "Nombre del bucket de estáticos (viene de storage)."
  type        = string
}
