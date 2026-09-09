#!/usr/bin/env bash
# =============================================================================
#  Nivel 04 · Bloque 1 — Recrear la base (cluster + destinos del pipeline)
#
#  Recrea el cluster GKE Autopilot y crea los dos destinos por los que el
#  pipeline promovera cada release: los namespaces 'staging' y 'prod'.
#  (Dos namespaces en un cluster = flujo de promocion sin duplicar costo.)
#
#  ATENCION: costo activo (cluster). Al terminar:
#     gcloud container clusters delete lab-gke --location=us-central1 --quiet
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
CLUSTER="lab-gke"

gcloud config set project "$PROJECT" >/dev/null

echo "==> Habilitando APIs (GKE + Cloud Deploy) ..."
gcloud services enable \
  container.googleapis.com \
  clouddeploy.googleapis.com \
  --project="$PROJECT"

# Red default (conservada del Nivel 03).
if ! gcloud compute networks describe default --project="$PROJECT" >/dev/null 2>&1; then
  echo "· Creando red default (auto) ..."
  gcloud compute networks create default --subnet-mode=auto --project="$PROJECT"
fi

echo "==> Recreando cluster GKE Autopilot (tarda ~5-9 min) ..."
if gcloud container clusters describe "$CLUSTER" --location="$REGION" >/dev/null 2>&1; then
  echo "· Cluster $CLUSTER ya existe."
else
  gcloud container clusters create-auto "$CLUSTER" --location="$REGION"
fi

echo "==> Credenciales para kubectl ..."
gcloud container clusters get-credentials "$CLUSTER" --location="$REGION"

echo "==> Creando los dos destinos del pipeline (namespaces) ..."
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod    --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "==> Verificacion:"
kubectl get namespaces staging prod
echo ""
kubectl cluster-info | head -1

echo ""
echo "======================================================================="
echo "  Bloque 1 listo. Cluster: $CLUSTER ($REGION, Autopilot)"
echo "  Destinos del pipeline: namespace 'staging' y namespace 'prod'"
echo ""
echo "  >> COSTO ACTIVO. Al terminar la sesion:"
echo "     gcloud container clusters delete $CLUSTER --location=$REGION --quiet"
echo "======================================================================="
