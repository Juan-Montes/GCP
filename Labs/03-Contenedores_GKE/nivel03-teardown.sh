#!/usr/bin/env bash
# =============================================================================
#  Nivel 03 · TEARDOWN — apaga todo lo que cuesta.
#  Orden: app (quita el LB) -> Workload Identity -> cluster (lo mas caro).
#  CONSERVA: la imagen en Artifact Registry, la red default y el estado del N02.
#  Idempotente: si algo ya no existe, sigue de largo.
# =============================================================================
set -uo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
CLUSTER="lab-gke"

gcloud config set project "$PROJECT" >/dev/null
echo "==> Teardown del Nivel 03 ..."

# ── 1) La app. Borrar el Service tipo LoadBalancer desmantela el LB de GCP.
echo "· Borrando app (Deployment, Service, HPA) ..."
kubectl delete -f k8s/web-app.yaml --ignore-not-found 2>/dev/null || true
kubectl delete -f k8s/hpa.yaml --ignore-not-found 2>/dev/null || true
kubectl delete pod load-gen wi-test --ignore-not-found 2>/dev/null || true

# Esperar a que GKE termine de quitar el Load Balancer (evita huerfanos).
echo "· Esperando a que el Load Balancer se elimine ..."
sleep 30

# ── 2) Workload Identity + bucket de demo.
echo "· Borrando recursos de Workload Identity ..."
kubectl delete serviceaccount web-app-ksa --ignore-not-found 2>/dev/null || true
gcloud iam service-accounts delete \
  "web-app-sa@${PROJECT}.iam.gserviceaccount.com" --quiet 2>/dev/null || true
gcloud storage rm --recursive "gs://${PROJECT}-wi-demo" --quiet 2>/dev/null || true

# ── 3) El cluster (lo mas caro). Tarda unos minutos.
echo "· Borrando el cluster GKE (esto tarda) ..."
gcloud container clusters delete "$CLUSTER" --location="$REGION" --quiet

# ── Verificacion: no deben quedar LBs huerfanos.
echo ""
echo "==> Verificando que no queden forwarding rules huerfanas:"
gcloud compute forwarding-rules list --format="table(name, region, IPAddress)" 2>/dev/null || true

echo ""
echo "======================================================================="
echo "  Teardown completo. Costo activo: \$0"
echo "  Se CONSERVAN (baratos/gratis, utiles para el Nivel 04):"
echo "    · Imagen  lab-images/web-app:v1  en Artifact Registry"
echo "    · Red default y bucket de estado del Nivel 02"
echo "  Para reconstruir: nivel03-cluster.sh + kubectl apply -f k8s/"
echo "======================================================================="
