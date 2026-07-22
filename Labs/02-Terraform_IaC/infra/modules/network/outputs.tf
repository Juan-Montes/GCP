# =============================================================================
#  Módulo: network — outputs
#  Los módulos de compute y balanceo (Bloques 3-4) consumirán estos valores.
# =============================================================================
output "network_id" {
  description = "ID de la VPC."
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "Nombre de la VPC."
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "ID de la subred."
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_self_link" {
  description = "Self link de la subred."
  value       = google_compute_subnetwork.subnet.self_link
}

output "app_tag" {
  description = "Tag de red de las VMs web."
  value       = var.app_tag
}
