# =============================================================================
#  Módulo: compute — outputs
#  El módulo de balanceo (Bloque 4) consumirá el grupo de instancias y el
#  health check desde aquí.
# =============================================================================
output "instance_group" {
  description = "Self link del grupo de instancias (backend del LB)."
  value       = google_compute_region_instance_group_manager.web.instance_group
}

output "mig_name" {
  description = "Nombre del MIG."
  value       = google_compute_region_instance_group_manager.web.name
}

output "health_check_id" {
  description = "ID del health check (lo reusa el backend service del LB)."
  value       = google_compute_health_check.web.id
}
