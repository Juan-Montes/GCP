# =============================================================================
#  Nivel 02 · compute.tf — el root invoca al módulo de compute
#  Nótese cómo se ENCADENAN los módulos: la subred y el tag vienen del módulo
#  de red por referencia, no por strings hardcodeados.
# =============================================================================
module "compute" {
  source = "./modules/compute"

  project_id = var.project_id
  region     = var.region

  subnet_id = module.network.subnet_id
  app_tag   = module.network.app_tag
}

output "compute_mig" {
  description = "Nombre del MIG creado."
  value       = module.compute.mig_name
}
