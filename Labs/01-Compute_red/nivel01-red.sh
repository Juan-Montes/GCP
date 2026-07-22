#!/usr/bin/env bash
# =============================================================================
#  Nivel 01 · Bloque 1 — Red base (VPC custom + subred + firewall minimo)
#  Cimiento para el MIG + Load Balancer de los siguientes bloques.
#  Costo de este bloque: $0 (VPC, subredes y reglas de firewall no cobran).
#  Seguridad: SSH solo via IAP (no se expone tcp:22 a internet); las VMs
#  solo aceptan trafico de los rangos de health check / Load Balancer.
#  Idempotente: seguro de re-ejecutar.
# =============================================================================
set -euo pipefail

# ── PARAMETROS ───────────────────────────────────────────────────────────────
PROJECT="juan-devops-lab-dev"
REGION="us-central1"
NETWORK="lab-vpc"
SUBNET="lab-subnet-usc1"
SUBNET_RANGE="10.10.0.0/24"
APP_TAG="web"            # tag de red: las reglas solo alcanzan las VMs web
APP_PORT="80"

# Rangos OFICIALES de Google (fijos, no cambiarlos):
HC_RANGES="130.211.0.0/22,35.191.0.0/16"   # health checks + Load Balancer (GFE)
IAP_RANGE="35.235.240.0/20"                # Identity-Aware Proxy (SSH sin IP publica)

gcloud config set project "$PROJECT" >/dev/null

echo "==> Habilitando Compute Engine API (just-in-time) ..."
gcloud services enable compute.googleapis.com --project="$PROJECT"

# ── VPC en modo custom (tu declaras las subredes, no todas las regiones) ─────
if gcloud compute networks describe "$NETWORK" --project="$PROJECT" >/dev/null 2>&1; then
  echo "· VPC $NETWORK ya existe."
else
  echo "· Creando VPC custom $NETWORK ..."
  gcloud compute networks create "$NETWORK" \
    --project="$PROJECT" \
    --subnet-mode=custom \
    --bgp-routing-mode=regional
fi

# ── Subred en la region de trabajo ───────────────────────────────────────────
if gcloud compute networks subnets describe "$SUBNET" \
     --region="$REGION" --project="$PROJECT" >/dev/null 2>&1; then
  echo "· Subred $SUBNET ya existe."
else
  echo "· Creando subred $SUBNET ($SUBNET_RANGE) en $REGION ..."
  gcloud compute networks subnets create "$SUBNET" \
    --project="$PROJECT" \
    --network="$NETWORK" \
    --region="$REGION" \
    --range="$SUBNET_RANGE"
fi

# ── Firewall: SSH SOLO via IAP (nada de 0.0.0.0/0 al puerto 22) ──────────────
if gcloud compute firewall-rules describe "${NETWORK}-allow-ssh-iap" \
     --project="$PROJECT" >/dev/null 2>&1; then
  echo "· Regla ${NETWORK}-allow-ssh-iap ya existe."
else
  echo "· Firewall: SSH via IAP (${IAP_RANGE}) ..."
  gcloud compute firewall-rules create "${NETWORK}-allow-ssh-iap" \
    --project="$PROJECT" \
    --network="$NETWORK" \
    --direction=INGRESS --action=ALLOW \
    --rules=tcp:22 \
    --source-ranges="$IAP_RANGE" \
    --target-tags="$APP_TAG"
fi

# ── Firewall: health checks + Load Balancer hacia el puerto de la app ────────
if gcloud compute firewall-rules describe "${NETWORK}-allow-hc-lb" \
     --project="$PROJECT" >/dev/null 2>&1; then
  echo "· Regla ${NETWORK}-allow-hc-lb ya existe."
else
  echo "· Firewall: health checks + LB al tcp:${APP_PORT} ..."
  gcloud compute firewall-rules create "${NETWORK}-allow-hc-lb" \
    --project="$PROJECT" \
    --network="$NETWORK" \
    --direction=INGRESS --action=ALLOW \
    --rules="tcp:${APP_PORT}" \
    --source-ranges="$HC_RANGES" \
    --target-tags="$APP_TAG"
fi

echo ""
echo "======================================================================="
echo "  Bloque 1 (red) listo en $PROJECT."
echo "  VPC:      $NETWORK (custom, routing regional)"
echo "  Subred:   $SUBNET  $SUBNET_RANGE  @ $REGION"
echo "  Firewall: SSH via IAP + health-check/LB al tcp:$APP_PORT (tag: $APP_TAG)"
echo "  Costo:    \$0"
echo ""
echo "  Verifica:"
echo "    gcloud compute networks subnets list --filter=\"network:$NETWORK\""
echo "    gcloud compute firewall-rules list   --filter=\"network:$NETWORK\""
echo "======================================================================="
