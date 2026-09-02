#!/usr/bin/env bash
# =============================================================================
#  Nivel 03 · Bloque 5 — Workload Identity (pods keyless)
#  Vincula una KSA (Kubernetes) con una GSA (GCP) para que la app acceda a
#  GCP sin llaves. Cierra la historia keyless del Nivel 00.
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
GSA="web-app-sa"
GSA_EMAIL="${GSA}@${PROJECT}.iam.gserviceaccount.com"
KSA="web-app-ksa"
NS="default"
BUCKET="gs://${PROJECT}-wi-demo"

gcloud config set project "$PROJECT" >/dev/null

echo "==> 1/6 GSA de runtime (identidad de la app en GCP) ..."
gcloud iam service-accounts describe "$GSA_EMAIL" >/dev/null 2>&1 || \
  gcloud iam service-accounts create "$GSA" \
    --display-name="App runtime (Workload Identity)"

echo "==> 2/6 Bucket de demo + objeto que la app leera sin llaves ..."
gcloud storage buckets describe "$BUCKET" >/dev/null 2>&1 || \
  gcloud storage buckets create "$BUCKET" --location="$REGION" --uniform-bucket-level-access
printf '%s\n' "Este mensaje se leyo desde Cloud Storage SIN una sola llave, via Workload Identity." \
  | gcloud storage cp - "$BUCKET/mensaje.txt"

echo "==> 3/6 Permiso MINIMO al GSA: leer objetos de ESTE bucket ..."
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:${GSA_EMAIL}" --role=roles/storage.objectViewer >/dev/null

echo "==> 4/6 KSA (identidad de la app en Kubernetes) ..."
kubectl create serviceaccount "$KSA" -n "$NS" --dry-run=client -o yaml | kubectl apply -f -

echo "==> 5/6 Enlace Workload Identity: la KSA puede actuar como la GSA ..."
gcloud iam service-accounts add-iam-policy-binding "$GSA_EMAIL" \
  --role=roles/iam.workloadIdentityUser \
  --member="serviceAccount:${PROJECT}.svc.id.goog[${NS}/${KSA}]"

echo "==> 6/6 Anotar la KSA con el email de la GSA ..."
kubectl annotate serviceaccount "$KSA" -n "$NS" \
  iam.gke.io/gcp-service-account="$GSA_EMAIL" --overwrite

echo ""
echo "======================================================================="
echo "  Bloque 5 listo. KSA '${KSA}' vinculada a GSA '${GSA_EMAIL}'."
echo "  La propagacion del enlace tarda ~1-2 min. Prueba con el pod wi-test."
echo "======================================================================="
