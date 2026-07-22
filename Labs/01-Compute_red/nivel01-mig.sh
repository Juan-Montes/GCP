#!/usr/bin/env bash
# =============================================================================
#  Nivel 01 · Bloque 3 — Plantilla + MIG regional + autoescalado
#
#  ATENCION: primer bloque CON COSTO. Las VMs se quedan encendidas.
#  Arrancamos con min=1 (e2-micro) para mantener el gasto minimo.
#  Al terminar la sesion: bash nivel01-teardown.sh
#
#  Diseno:
#   · VMs SIN IP publica -> el LB (Bloque 4) sera la unica entrada.
#   · MIG REGIONAL -> instancias repartidas entre zonas (resiliencia gratis).
#   · Autohealing (recrea VM con app muerta) + Autoescalado (crece por carga).
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
NETWORK="lab-vpc"
SUBNET="lab-subnet-usc1"
IMAGE_FAMILY="lab-web-app"
APP_TAG="web"

TEMPLATE="lab-web-tpl"
MIG="lab-web-mig"
HEALTH_CHECK="lab-web-hc"
MACHINE_TYPE="e2-micro"     # la mas barata que sirve para esto

# Autoescalado: min bajo para cuidar el credito.
MIN_REPLICAS=1
MAX_REPLICAS=3
TARGET_CPU=0.60             # escala al 60% de CPU promedio

gcloud config set project "$PROJECT" >/dev/null

# ── Health check: alimenta AUTOHEALING y (en el Bloque 4) al Load Balancer ───
if gcloud compute health-checks describe "$HEALTH_CHECK" --project="$PROJECT" >/dev/null 2>&1; then
  echo "· Health check $HEALTH_CHECK ya existe."
else
  echo "· Creando health check HTTP en / (puerto 80) ..."
  gcloud compute health-checks create http "$HEALTH_CHECK" \
    --project="$PROJECT" \
    --port=80 \
    --request-path="/" \
    --check-interval=10s \
    --timeout=5s \
    --healthy-threshold=2 \
    --unhealthy-threshold=3
fi

# ── Plantilla de instancias ──────────────────────────────────────────────────
# Nota: las plantillas son INMUTABLES. Para cambiar la imagen se crea una
# plantilla nueva y se hace rolling update del MIG (eso lo veras al final).
if gcloud compute instance-templates describe "$TEMPLATE" --project="$PROJECT" >/dev/null 2>&1; then
  echo "· Plantilla $TEMPLATE ya existe (son inmutables; para cambiarla, crea otra version)."
else
  echo "· Creando plantilla $TEMPLATE desde la familia de imagen $IMAGE_FAMILY ..."
  gcloud compute instance-templates create "$TEMPLATE" \
    --project="$PROJECT" \
    --machine-type="$MACHINE_TYPE" \
    --image-family="$IMAGE_FAMILY" \
    --image-project="$PROJECT" \
    --network="$NETWORK" \
    --subnet="$SUBNET" \
    --region="$REGION" \
    --no-address \
    --tags="$APP_TAG" \
    --metadata=enable-oslogin=TRUE \
    --labels=nivel=01,entorno=dev
  # --no-address  : SIN IP publica. Entrada solo por el LB; SSH solo por IAP.
  # --image-family: siempre toma la MAS RECIENTE de la familia (versionado).
fi

# ── MIG regional ─────────────────────────────────────────────────────────────
if gcloud compute instance-groups managed describe "$MIG" \
     --region="$REGION" --project="$PROJECT" >/dev/null 2>&1; then
  echo "· MIG $MIG ya existe."
else
  echo "· Creando MIG regional $MIG (tamano inicial: $MIN_REPLICAS) ..."
  gcloud compute instance-groups managed create "$MIG" \
    --project="$PROJECT" \
    --region="$REGION" \
    --template="$TEMPLATE" \
    --size="$MIN_REPLICAS" \
    --health-check="$HEALTH_CHECK" \
    --initial-delay=180
  # --initial-delay: no mates la VM durante los primeros 3 min (tiempo de boot).
fi

# ── Named port: el LB del Bloque 4 buscara el puerto por NOMBRE, no por numero
echo "· Declarando named-port http:80 (lo consumira el Load Balancer) ..."
gcloud compute instance-groups managed set-named-ports "$MIG" \
  --project="$PROJECT" \
  --region="$REGION" \
  --named-ports=http:80

# ── Autoescalado ─────────────────────────────────────────────────────────────
echo "· Configurando autoescalado (min=$MIN_REPLICAS, max=$MAX_REPLICAS, CPU=$TARGET_CPU) ..."
gcloud compute instance-groups managed set-autoscaling "$MIG" \
  --project="$PROJECT" \
  --region="$REGION" \
  --min-num-replicas="$MIN_REPLICAS" \
  --max-num-replicas="$MAX_REPLICAS" \
  --target-cpu-utilization="$TARGET_CPU" \
  --cool-down-period=60

echo ""
echo "==> Estado del MIG (las VMs tardan ~1-2 min en quedar RUNNING):"
gcloud compute instance-groups managed list-instances "$MIG" \
  --region="$REGION" --project="$PROJECT" \
  --format="table(instance.basename(), status, instanceStatus, instanceHealth[0].detailedHealthState)"

echo ""
echo "======================================================================="
echo "  Bloque 3 listo."
echo "  Plantilla: $TEMPLATE   MIG: $MIG ($REGION, regional)"
echo "  Autoescalado: ${MIN_REPLICAS}-${MAX_REPLICAS} VMs @ ${TARGET_CPU} CPU"
echo "  Autohealing:  ON (health check $HEALTH_CHECK)"
echo ""
echo "  >> COSTO ACTIVO: hay VMs encendidas. Al terminar:  bash nivel01-teardown.sh"
echo ""
echo "  Las VMs NO tienen IP publica (por diseno). Para entrar:"
echo "    gcloud compute ssh <NOMBRE_VM> --zone=<ZONA> --tunnel-through-iap"
echo "======================================================================="
