#!/usr/bin/env bash
# =============================================================================
#  Nivel 04 · TEARDOWN — apaga todo lo que cuesta.
#  Orden: Services (quita LBs) -> delivery pipeline -> politica binauthz -> cluster.
#  CONSERVA: la imagen en Artifact Registry, la red y el estado del Nivel 02.
#  Idempotente.
# =============================================================================
set -uo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
CLUSTER="lab-gke"

gcloud config set project "$PROJECT" >/dev/null
echo "==> Teardown del Nivel 04 ..."

# 1) Borrar los Services (desmantela los Load Balancers de GCP en ambos namespaces).
echo "· Borrando Services (staging + prod) ..."
kubectl delete svc web-app -n staging --ignore-not-found 2>/dev/null || true
kubectl delete svc web-app -n prod    --ignore-not-found 2>/dev/null || true
echo "· Esperando a que GKE quite los Load Balancers ..."
sleep 30

# 2) Borrar el delivery pipeline (con sus releases y rollouts).
echo "· Borrando el delivery pipeline ..."
gcloud deploy delivery-pipelines delete web-app-pipeline \
  --region="$REGION" --force --quiet 2>/dev/null || true

# 3) Restablecer Binary Authorization a permisivo (para no afectar futuros clusters).
echo "· Restableciendo la politica de Binary Authorization a ALLOW ..."
cat > /tmp/binauthz-allow.yaml <<EOF2
defaultAdmissionRule:
  evaluationMode: ALWAYS_ALLOW
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
globalPolicyEvaluationMode: ENABLE
name: projects/${PROJECT}/policy
EOF2
gcloud container binauthz policy import /tmp/binauthz-allow.yaml --quiet 2>/dev/null || true

# 4) Borrar el cluster (lo mas caro).
echo "· Borrando el cluster GKE (esto tarda) ..."
gcloud container clusters delete "$CLUSTER" --location="$REGION" --quiet

echo ""
echo "==> Verificando que no queden forwarding rules huerfanas:"
gcloud compute forwarding-rules list --format="table(name, region, IPAddress)" 2>/dev/null || true

echo ""
echo "======================================================================="
echo "  Teardown completo. Costo activo: \$0"
echo "  Se CONSERVAN: imagen en Artifact Registry, red, estado del Nivel 02."
echo "======================================================================="
