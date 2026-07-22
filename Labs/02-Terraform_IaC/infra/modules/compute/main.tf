# =============================================================================
#  Módulo: compute — recursos
# =============================================================================

# Resuelve la imagen MÁS RECIENTE de la familia. Si horneas una nueva con
# Packer, un 'apply' la detecta -> recrea la plantilla -> rolling update.
data "google_compute_image" "web" {
  family  = var.image_family
  project = var.project_id
}

# Health check global: lo usan el autohealing (aquí) y el LB (Bloque 4).
resource "google_compute_health_check" "web" {
  name    = "lab-web-hc"
  project = var.project_id

  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.app_port
    request_path = "/"
  }
}

# Plantilla de instancia (global). name_prefix + create_before_destroy hacen
# que un cambio genere una versión nueva ANTES de borrar la vieja.
resource "google_compute_instance_template" "web" {
  name_prefix  = "lab-web-tpl-"
  project      = var.project_id
  machine_type = var.machine_type
  tags         = [var.app_tag]

  labels = {
    nivel   = "02"
    entorno = "dev"
  }

  disk {
    source_image = data.google_compute_image.web.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = var.subnet_id
    # Sin bloque access_config => SIN IP pública (igual que el Nivel 01).
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# MIG regional.
resource "google_compute_region_instance_group_manager" "web" {
  name    = "lab-web-mig"
  project = var.project_id
  region  = var.region

  base_instance_name        = "lab-web-mig"
  distribution_policy_zones = var.distribution_zones

  version {
    instance_template = google_compute_instance_template.web.id
  }

  # El LB del Bloque 4 buscará el puerto por NOMBRE, no por número.
  named_port {
    name = "http"
    port = var.app_port
  }

  # Autohealing: recrea una VM viva pero con la app muerta.
  auto_healing_policies {
    health_check      = google_compute_health_check.web.id
    initial_delay_sec = 180
  }

  # LA JOYA — rolling update declarado. En MIG regional, max_surge debe ser
  # 0 o >= número de zonas. Con 2 zonas: surge=2, unavailable=0 => cero downtime.
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = length(var.distribution_zones)
    max_unavailable_fixed = 0
  }
}

# Autoescalado (recurso aparte que apunta al MIG).
resource "google_compute_region_autoscaler" "web" {
  name    = "lab-web-autoscaler"
  project = var.project_id
  region  = var.region
  target  = google_compute_region_instance_group_manager.web.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 60

    cpu_utilization {
      target = var.target_cpu
    }
  }
}
