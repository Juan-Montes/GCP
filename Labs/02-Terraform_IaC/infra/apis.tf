# =============================================================================
#  Nivel 02 · apis.tf — APIs de GCP gestionadas COMO CODIGO
#
#  Este es el primer recurso real de Terraform del nivel: seguro, gratis y
#  reversible. Al aplicarlo pruebas de golpe que funcionan el estado remoto,
#  el bloqueo y la impersonacion.
# =============================================================================
locals {
  apis = [
    "compute.googleapis.com",
    "iamcredentials.googleapis.com",
    "storage.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.apis)

  project = var.project_id
  service = each.value

  # No apagar la API si se hace 'destroy': evita romper otros recursos.
  disable_on_destroy = false
}
