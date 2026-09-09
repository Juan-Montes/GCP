#!/usr/bin/env bash
# =============================================================================
#  Nivel 04 · Bloque 3 — Setup de Cloud Deploy
#  Concede permisos a la SA de ejecucion y registra el delivery pipeline.
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"

gcloud config set project "$PROJECT" >/dev/null
PNUM="$(gcloud projects describe "$PROJECT" --format='value(projectNumber)')"
EXEC_SA="${PNUM}-compute@developer.gserviceaccount.com"

echo "==> Asegurando el service agent de Cloud Deploy ..."
gcloud beta services identity create --service=clouddeploy.googleapis.com \
  --project="$PROJECT" >/dev/null 2>&1 || true
DEPLOY_AGENT="service-${PNUM}@gcp-sa-clouddeploy.iam.gserviceaccount.com"

echo "==> Permisos a la SA de EJECUCION (${EXEC_SA}) ..."
# jobRunner: ejecutar los jobs de despliegue · container.developer: aplicar a GKE
for ROLE in roles/clouddeploy.jobRunner roles/container.developer roles/logging.logWriter; do
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:${EXEC_SA}" --role="$ROLE" --condition=None >/dev/null
done

echo "==> El service agent de Cloud Deploy debe poder ACTUAR COMO la SA de ejecucion ..."
gcloud iam service-accounts add-iam-policy-binding "$EXEC_SA" \
  --member="serviceAccount:${DEPLOY_AGENT}" \
  --role="roles/iam.serviceAccountUser" >/dev/null 2>&1 || \
  echo "  (si fallo, el agent aun no propaga; reintenta en 1 min)"

echo "==> Registrando el delivery pipeline y los targets ..."
gcloud deploy apply --file=clouddeploy.yaml --region="$REGION" --project="$PROJECT"

echo ""
echo "==> Pipeline registrado:"
gcloud deploy delivery-pipelines describe web-app-pipeline --region="$REGION" \
  --format="value(name)"

echo ""
echo "======================================================================="
echo "  Bloque 3 (setup) listo. Ahora crea el primer release (ver instrucciones)."
echo "======================================================================="
