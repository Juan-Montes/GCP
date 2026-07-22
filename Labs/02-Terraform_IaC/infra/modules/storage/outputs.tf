# =============================================================================
#  Módulo: storage — outputs
# =============================================================================
output "bucket_name" {
  description = "Nombre del bucket (lo consume el backend bucket del LB)."
  value       = google_storage_bucket.static.name
}
