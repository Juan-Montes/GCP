# =============================================================================
#  Terragrunt RAÍZ — configuración común a todos los entornos.
#  Lee los valores del entorno (env.hcl) y genera backend + provider al vuelo.
#  Los terragrunt.hcl de dev y prod son idénticos; SOLO cambia su env.hcl.
# =============================================================================
locals {
  env          = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  project_id   = local.env.locals.project_id
  region       = local.env.locals.region
  terraform_sa = local.env.locals.terraform_sa
  state_prefix = local.env.locals.state_prefix
}

# Estado remoto: un solo bucket, un prefijo por entorno.
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket   = "juan-devops-lab-dev-tfstate"
    prefix   = local.state_prefix
    location = "us-central1"
  }
}

# Provider generado por entorno: mismo módulo, distinta identidad/proyecto.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
  project                     = "${local.project_id}"
  region                      = "${local.region}"
  impersonate_service_account = "${local.terraform_sa}"
}
EOF
}

# Inputs que consumen las variables del módulo infra.
inputs = {
  project_id   = local.project_id
  region       = local.region
  terraform_sa = local.terraform_sa
}
