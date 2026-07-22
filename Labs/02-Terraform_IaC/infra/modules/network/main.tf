# =============================================================================
#  Módulo: network — recursos
#  Mismas decisiones de diseño que el Nivel 01, ahora declaradas:
#   · VPC en modo custom (tú declaras subredes, no todas las regiones)
#   · SSH SOLO por IAP (nada de 0.0.0.0/0 al puerto 22)
#   · Las VMs solo aceptan tráfico de los rangos de health check / LB
# =============================================================================

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false        # modo custom
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr
}

# SSH únicamente vía Identity-Aware Proxy.
resource "google_compute_firewall" "allow_ssh_iap" {
  name      = "${var.network_name}-allow-ssh-iap"
  project   = var.project_id
  network   = google_compute_network.vpc.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.iap_range]
  target_tags   = [var.app_tag]
}

# Health checks + Load Balancer hacia el puerto de la app.
resource "google_compute_firewall" "allow_hc_lb" {
  name      = "${var.network_name}-allow-hc-lb"
  project   = var.project_id
  network   = google_compute_network.vpc.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_port)]
  }

  source_ranges = var.health_check_ranges
  target_tags   = [var.app_tag]
}
