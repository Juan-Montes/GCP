# =============================================================================
#  Módulo: storage — bucket de estáticos (reconstruye el Nivel 01 Bloque 5)
#  Regional, acceso uniforme, versionado. Objetos públicos porque los servirá
#  el Load Balancer como backend bucket (los backend buckets sirven contenido
#  público). force_destroy=true para que 'destroy' pueda borrarlo con objetos.
# =============================================================================
resource "google_storage_bucket" "static" {
  name                        = var.bucket_name
  project                     = var.project_id
  location                    = upper(var.region)
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }

  labels = {
    entorno = "dev"
    nivel   = "02"
  }
}

# Lectura pública (decisión deliberada: son estáticos servidos por el LB).
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.static.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Objeto de ejemplo bajo /static para demostrar el split del path matcher.
resource "google_storage_bucket_object" "sample" {
  name         = "static/hola.html"
  bucket       = google_storage_bucket.static.name
  content_type = "text/html"
  content      = <<-HTML
    <!doctype html><html><head><meta charset="utf-8"><title>Estático</title></head>
    <body style="font-family:monospace;background:#111722;color:#EDEFF5;text-align:center;padding-top:20vh">
    <p>Servido por</p><h1 style="color:#E8731A">Cloud Storage</h1>
    <p>vía el Load Balancer · ruta /static/</p></body></html>
  HTML
}
