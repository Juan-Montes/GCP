# =============================================================================
#  Módulo: network — variables
#  Reconstruye la red del Nivel 01 (Bloque 1) como código reutilizable.
# =============================================================================
variable "project_id" {
  description = "ID del proyecto."
  type        = string
}

variable "region" {
  description = "Región de la subred."
  type        = string
}

variable "network_name" {
  description = "Nombre de la VPC."
  type        = string
  default     = "lab-vpc"
}

variable "subnet_name" {
  description = "Nombre de la subred."
  type        = string
  default     = "lab-subnet-usc1"
}

variable "subnet_cidr" {
  description = "Rango CIDR de la subred."
  type        = string
  default     = "10.10.0.0/24"
}

variable "app_tag" {
  description = "Tag de red al que aplican las reglas de firewall."
  type        = string
  default     = "web"
}

variable "app_port" {
  description = "Puerto de la app (health check / LB)."
  type        = number
  default     = 80
}

# Rangos OFICIALES de Google. Se dejan como variable para documentarlos,
# pero su default no deberia cambiar.
variable "health_check_ranges" {
  description = "Rangos de health checks + Load Balancer (GFE)."
  type        = list(string)
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
}

variable "iap_range" {
  description = "Rango de Identity-Aware Proxy (SSH sin IP pública)."
  type        = string
  default     = "35.235.240.0/20"
}
