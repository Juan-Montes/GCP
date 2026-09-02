#!/usr/bin/env bash
# =============================================================================
#  Nivel 03 · Bloque 1 — Artifact Registry + build/push con Cloud Build
#  Crea el repo Docker, construye la imagen en la nube y la publica.
#  Costo: casi $0 (Cloud Build tiene capa gratuita; el registry cobra centavos).
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
REPO="lab-images"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/web-app:v1"

gcloud config set project "$PROJECT" >/dev/null

echo "==> Habilitando APIs (Artifact Registry, Cloud Build, escaneo) ..."
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  containerscanning.googleapis.com \
  --project="$PROJECT"

echo "==> Creando repositorio Docker en Artifact Registry ..."
if gcloud artifacts repositories describe "$REPO" --location="$REGION" >/dev/null 2>&1; then
  echo "· Repo $REPO ya existe."
else
  gcloud artifacts repositories create "$REPO" \
    --repository-format=docker \
    --location="$REGION" \
    --description="Imagenes del portafolio DevOps"
fi

# El SA que corre Cloud Build (compute default) necesita empujar al registry
# y escribir logs. Se concede de forma proactiva para evitar el fallo comun.
echo "==> Concediendo permisos al service account de Cloud Build ..."
PNUM="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')"
CB_SA="${PNUM}-compute@developer.gserviceaccount.com"
for ROLE in roles/artifactregistry.writer roles/logging.logWriter; do
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:${CB_SA}" --role="$ROLE" --condition=None >/dev/null
done

echo "==> Construyendo y publicando la imagen con Cloud Build ..."
# Cloud Build sube el contexto (Dockerfile + scripts), construye y hace push.
gcloud builds submit --tag "$IMAGE" .

echo ""
echo "==> Imagen publicada en Artifact Registry:"
gcloud artifacts docker images list \
  "${REGION}-docker.pkg.dev/${PROJECT}/${REPO}" \
  --format="table(package, version, createTime)"

echo ""
echo "======================================================================="
echo "  Bloque 1 listo. Imagen: $IMAGE"
echo "  El Deployment del Bloque 3 la referenciará por esta ruta exacta."
echo "  El escaneo de vulnerabilidades corre solo tras el push (ver Bloque 6)."
echo "======================================================================="
