# =============================================================================
#  Nivel 02 · edge.tf — storage + loadbalancer, encadenando compute y storage
# =============================================================================
module "storage" {
  source = "./modules/storage"

  project_id  = var.project_id
  region      = var.region
  bucket_name = "${var.project_id}-static"

  depends_on = [google_project_service.enabled]
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  project_id = var.project_id

  # Encadenamiento de módulos: todo por referencia.
  instance_group     = module.compute.instance_group
  health_check_id    = module.compute.health_check_id
  static_bucket_name = module.storage.bucket_name
}

output "lb_ip" {
  description = "IP pública del Load Balancer."
  value       = module.loadbalancer.lb_ip
}
