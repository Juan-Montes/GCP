# =============================================================================
#  Módulo: compute — variables
#  Reconstruye el MIG del Nivel 01 (Bloque 3) como código, con rolling update.
# =============================================================================
variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_id" {
  description = "ID de la subred (viene del módulo network)."
  type        = string
}

variable "app_tag" {
  description = "Tag de red de las VMs web (viene del módulo network)."
  type        = string
}

variable "image_family" {
  description = "Familia de imagen horneada con Packer."
  type        = string
  default     = "lab-web-app"
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "app_port" {
  type    = number
  default = 80
}

variable "min_replicas" {
  type    = number
  default = 1
}

variable "max_replicas" {
  type    = number
  default = 3
}

variable "target_cpu" {
  description = "Utilización de CPU objetivo para autoescalar (0-1)."
  type        = number
  default     = 0.6
}

# Pinnear 2 zonas: resiliencia suficiente + hace válido y barato el rolling
# update (max_surge en MIG regional debe ser 0 o >= número de zonas).
variable "distribution_zones" {
  type    = list(string)
  default = ["us-central1-a", "us-central1-f"]
}
