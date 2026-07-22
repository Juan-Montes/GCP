#!/usr/bin/env bash
# =============================================================================
#  Nivel 01 · Bloque 5 — Bucket de Cloud Storage para estáticos
#
#  Regional (misma región que las VMs: locality + mas barato que multi-region).
#  Uniform bucket-level access (sin ACLs por objeto: gobernanza limpia por IAM).
#  Versionado ON (recuperas objetos sobreescritos o borrados).
#  Costo: practicamente $0 (unos KB de estaticos).
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
# El project id ya es unico globalmente -> lo usamos de prefijo del bucket.
BUCKET="gs://${PROJECT}-static"
PUBLIC_HOST="https://storage.googleapis.com/${PROJECT}-static"

gcloud config set project "$PROJECT" >/dev/null

# 1) Crear el bucket (seguro por defecto: acceso uniforme por IAM) ────────────
if gcloud storage buckets describe "$BUCKET" >/dev/null 2>&1; then
  echo "· Bucket $BUCKET ya existe."
else
  echo "· Creando bucket regional $BUCKET ..."
  gcloud storage buckets create "$BUCKET" \
    --project="$PROJECT" \
    --location="$REGION" \
    --uniform-bucket-level-access
fi

# 2) Versionado de objetos ───────────────────────────────────────────────────
echo "· Activando versionado ..."
gcloud storage buckets update "$BUCKET" --versioning

# 3) Subir un asset de ejemplo ───────────────────────────────────────────────
echo "· Subiendo asset de ejemplo (css/estilo.css) ..."
echo "/* estatico servido desde Cloud Storage */ body{font-family:monospace}" > /tmp/estilo.css
gcloud storage cp /tmp/estilo.css "$BUCKET/css/estilo.css"

# 4) Exponer SOLO lectura publica (decision DELIBERADA para estaticos) ────────
# Nota de seguridad: hacer un bucket publico es una eleccion consciente.
# El acceso uniforme hace que este permiso sea limpio y auditable (un solo
# binding IAM, no ACLs regadas por objeto). En produccion muchas veces se
# mantiene PRIVADO y se sirve via el Load Balancer (backend bucket) -> Nivel 02.
echo "· Concediendo lectura publica (allUsers -> objectViewer) ..."
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member=allUsers \
  --role=roles/storage.objectViewer >/dev/null

echo ""
echo "==> Objetos en el bucket:"
gcloud storage ls --recursive "$BUCKET"

echo ""
echo "======================================================================="
echo "  Bloque 5 listo. Bucket de estaticos operativo."
echo "  Bucket:      $BUCKET (regional $REGION, acceso uniforme, versionado)"
echo "  URL publica: $PUBLIC_HOST/css/estilo.css"
echo ""
echo "  Verifica (debe devolver el CSS):"
echo "    curl -s $PUBLIC_HOST/css/estilo.css"
echo ""
echo "  El bucket cuesta ~\$0: se conserva entre sesiones. Para borrarlo:"
echo "    gcloud storage rm --recursive $BUCKET"
echo "======================================================================="
