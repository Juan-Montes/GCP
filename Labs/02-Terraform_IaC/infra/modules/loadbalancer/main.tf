# =============================================================================
#  Módulo: loadbalancer — Application LB externo global + split estático/dinámico
#
#  Flujo:  IP -> forwarding rule -> target proxy -> url map -> {backend service, backend bucket}
#  El url map rutea:  /static/*  -> bucket   ·   todo lo demás -> MIG
# =============================================================================

# 1) IP estática global (la cara pública).
resource "google_compute_global_address" "lb_ip" {
  name    = "lab-web-ip"
  project = var.project_id
}

# 2) Backend service: el MIG. Reusa el health check del módulo de compute.
resource "google_compute_backend_service" "mig" {
  name                  = "lab-web-backend"
  project               = var.project_id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  port_name             = "http"
  health_checks         = [var.health_check_id]

  backend {
    group           = var.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }
}

# 3) Backend bucket: el enchufe entre el bucket de estáticos y el LB.
#    Sin CDN a propósito, para ver el contenido en vivo (no cacheado).
resource "google_compute_backend_bucket" "static" {
  name        = "lab-web-static-backend"
  project     = var.project_id
  bucket_name = var.static_bucket_name
  enable_cdn  = false
}

# 4) URL map con el SPLIT: /static/* al bucket, el resto al MIG.
resource "google_compute_url_map" "web" {
  name            = "lab-web-urlmap"
  project         = var.project_id
  default_service = google_compute_backend_service.mig.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "static-split"
  }

  path_matcher {
    name            = "static-split"
    default_service = google_compute_backend_service.mig.id

    path_rule {
      paths   = ["/static", "/static/*"]
      service = google_compute_backend_bucket.static.id
    }
  }
}

# 5) Target proxy + forwarding rule (IP:80 -> proxy).
resource "google_compute_target_http_proxy" "web" {
  name    = "lab-web-proxy"
  project = var.project_id
  url_map = google_compute_url_map.web.id
}

resource "google_compute_global_forwarding_rule" "web" {
  name                  = "lab-web-fr"
  project               = var.project_id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.web.id
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "80"
}
