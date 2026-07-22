#!/usr/bin/env bash
# =============================================================================
#  Nivel 02 · Bloque 1 — Bootstrap del backend de Terraform
#  Siembra el bucket de estado remoto y deja lista la impersonacion keyless.
#  (El huevo y la gallina: este bucket NO puede crearlo Terraform, porque
#   Terraform lo necesita como backend desde su primer init.)
#  Costo: ~$0. Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
SA="terraform-sa@${PROJECT}.iam.gserviceaccount.com"
STATE_BUCKET="gs://${PROJECT}-tfstate"

gcloud config set project "$PROJECT" >/dev/null

echo "==> Habilitando APIs para impersonacion + estado ..."
gcloud services enable \
  iamcredentials.googleapis.com \
  storage.googleapis.com \
  serviceusage.googleapis.com \
  --project="$PROJECT"

echo "==> Creando bucket de estado remoto ..."
if gcloud storage buckets describe "$STATE_BUCKET" >/dev/null 2>&1; then
  echo "· $STATE_BUCKET ya existe."
else
  gcloud storage buckets create "$STATE_BUCKET" \
    --project="$PROJECT" --location="$REGION" \
    --uniform-bucket-level-access --public-access-prevention
fi
# Versionado = historial del estado. Si un apply corrompe algo, recuperas.
echo "· Activando versionado del estado ..."
gcloud storage buckets update "$STATE_BUCKET" --versioning

echo "==> Rol just-in-time de este bloque: gestionar APIs (serviceUsageAdmin) ..."
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:${SA}" \
  --role="roles/serviceusage.serviceUsageAdmin" --condition=None >/dev/null

echo "==> Verificando que puedes impersonar la SA (sembrado en Nivel 00) ..."
if gcloud iam service-accounts get-iam-policy "$SA" --format=json 2>/dev/null \
     | grep -q "iam.serviceAccountTokenCreator"; then
  echo "· Impersonacion OK (tienes tokenCreator sobre la SA)."
else
  echo "· OJO: falta el rol tokenCreator. Corre:"
  echo "    gcloud iam service-accounts add-iam-policy-binding $SA \\"
  echo "      --member=user:\$(gcloud config get-value account) \\"
  echo "      --role=roles/iam.serviceAccountTokenCreator"
fi

echo ""
echo "======================================================================="
echo "  Backend listo. Estado remoto: $STATE_BUCKET (versionado, privado)"
echo "  Ahora, en la carpeta de Terraform:"
echo "    terraform init      # configura el backend GCS y baja el provider"
echo "    terraform plan      # debe correr como la SA, sin llaves"
echo "    terraform apply     # escribe el estado en GCS"
echo "======================================================================="
