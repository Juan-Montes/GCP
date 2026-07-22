# =============================================================================
#  Nivel 02 · network.tf — el root module invoca al módulo de red
# =============================================================================
module "network" {
  source = "./modules/network"

  project_id = var.project_id
  region     = var.region

  # Garantiza que la API de compute esté habilitada ANTES de crear la red.
  # Esto es lo que hace que un 'apply' desde cero funcione (KPI del nivel).
  depends_on = [google_project_service.enabled]
}

output "red_vpc" {
  description = "Nombre de la VPC creada por Terraform."
  value       = module.network.network_name
}

output "red_subred" {
  description = "Self link de la subred."
  value       = module.network.subnet_self_link
}
