# =============================================================================
#  infra · providers.tf — el provider lo genera Terragrunt por entorno.
#  Aquí solo queda la prueba de identidad (útil en dev y prod por igual).
# =============================================================================
data "google_client_openid_userinfo" "current" {}

output "terraform_identidad" {
  description = "Identidad efectiva de Terraform (la terraform-sa del entorno)."
  value       = data.google_client_openid_userinfo.current.email
}
