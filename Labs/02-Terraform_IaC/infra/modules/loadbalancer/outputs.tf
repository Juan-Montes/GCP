# =============================================================================
#  Módulo: loadbalancer — outputs
# =============================================================================
output "lb_ip" {
  description = "IP pública del Load Balancer."
  value       = google_compute_global_address.lb_ip.address
}
