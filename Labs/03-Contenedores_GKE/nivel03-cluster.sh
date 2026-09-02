#!/usr/bin/env bash
# =============================================================================
#  Nivel 03 · Bloque 2 — Cluster GKE Autopilot
#
#  ATENCION: primer recurso con COSTO real de este nivel. Autopilot cobra por
#  los recursos que piden tus pods. Al terminar la sesion:
#     gcloud container clusters delete lab-gke --location=us-central1 --quiet
#
#  Diseno:
#   · Autopilot: Google gestiona los nodos; tu solo declaras pods.
#   · Regional: plano de control y nodos repartidos entre zonas.
#   · Workload Identity activado por defecto (lo usaremos en el Bloque 5).
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
CLUSTER="lab-gke"

gcloud config set project "$PROJECT" >/dev/null

echo "==> Habilitando la API de GKE ..."
gcloud services enable container.googleapis.com --project="$PROJECT"

# Autopilot necesita una red VPC-native. Usamos la 'default' (Autopilot
# gestiona los rangos de pods/servicios). En produccion usarias una VPC
# custom con rangos secundarios definidos.
if ! gcloud compute networks describe default --project="$PROJECT" >/dev/null 2>&1; then
  echo "· Creando red default (auto) para el cluster ..."
  gcloud compute networks create default --subnet-mode=auto --project="$PROJECT"
fi

echo "==> Creando cluster GKE Autopilot (tarda ~5-9 min) ..."
if gcloud container clusters describe "$CLUSTER" --location="$REGION" >/dev/null 2>&1; then
  echo "· Cluster $CLUSTER ya existe."
else
  gcloud container clusters create-auto "$CLUSTER" \
    --location="$REGION" \
    --project="$PROJECT"
fi

echo "==> Obteniendo credenciales para kubectl ..."
gcloud container clusters get-credentials "$CLUSTER" \
  --location="$REGION" --project="$PROJECT"

echo ""
echo "==> Verificando la conexion al cluster:"
kubectl cluster-info
echo ""
kubectl get nodes    # en Autopilot puede salir vacio hasta que haya pods

echo ""
echo "======================================================================="
echo "  Bloque 2 listo. Cluster: $CLUSTER ($REGION, Autopilot)"
echo "  kubectl ya apunta a este cluster (contexto configurado)."
echo ""
echo "  >> COSTO ACTIVO: hay un cluster corriendo. Al terminar la sesion:"
echo "     gcloud container clusters delete $CLUSTER --location=$REGION --quiet"
echo "======================================================================="
