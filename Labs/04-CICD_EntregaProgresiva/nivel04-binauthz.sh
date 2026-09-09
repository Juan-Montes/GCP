#!/usr/bin/env bash
# =============================================================================
#  Nivel 04 · Bloque 5 — Binary Authorization (candado de cadena de suministro)
#  Importa la politica y activa su aplicacion en el cluster.
#  El cluster pasara a admitir SOLO imagenes de lab-images (+ sistema GKE).
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
CLUSTER="lab-gke"

gcloud config set project "$PROJECT" >/dev/null

echo "==> Habilitando Binary Authorization API ..."
gcloud services enable binaryauthorization.googleapis.com --project="$PROJECT"

echo "==> Importando la politica (allowlist: lab-images + sistema GKE) ..."
gcloud container binauthz policy import binauthz-policy.yaml --project="$PROJECT"

echo "==> Activando la aplicacion en el cluster (tarda unos minutos) ..."
gcloud container clusters update "$CLUSTER" --location="$REGION" \
  --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE

echo ""
echo "==> Politica activa:"
gcloud container binauthz policy export \
  --format="yaml(defaultAdmissionRule, admissionWhitelistPatterns)"

echo ""
echo "======================================================================="
echo "  Bloque 5 listo. El cluster solo admite imagenes de lab-images."
echo ""
echo "  Prueba el candado — esto DEBE ser rechazado (imagen no permitida):"
echo "    kubectl run test-bloqueado --image=nginx:alpine -n default"
echo "======================================================================="
