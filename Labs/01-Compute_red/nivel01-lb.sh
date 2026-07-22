#!/usr/bin/env bash
# =============================================================================
#  Nivel 01 · Bloque 4 — Load Balancer HTTP externo (Application LB global)
#
#  Encadena: IP estatica -> forwarding rule -> target proxy -> url map ->
#            backend service -> MIG (por named-port http + health check).
#  SIN Cloud CDN (a proposito): para VER el balanceo el contenido no se cachea.
#
#  ATENCION: costo activo (LB + VMs). Al terminar: bash nivel01-teardown.sh
#  Idempotente.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
REGION="us-central1"
MIG="lab-web-mig"
HEALTH_CHECK="lab-web-hc"

ADDRESS="lab-web-ip"
BACKEND="lab-web-backend"
URL_MAP="lab-web-urlmap"
PROXY="lab-web-proxy"
FW_RULE="lab-web-fr"

# Application LB global moderno. Si tu version se queja del scheme,
# cambia a EXTERNAL (el clasico) y re-ejecuta.
SCHEME="EXTERNAL_MANAGED"

gcloud config set project "$PROJECT" >/dev/null

# 1) IP estatica global (la cara publica, fija) ──────────────────────────────
if gcloud compute addresses describe "$ADDRESS" --global >/dev/null 2>&1; then
  echo "· IP $ADDRESS ya existe."
else
  echo "· Reservando IP estatica global ..."
  gcloud compute addresses create "$ADDRESS" --global --ip-version=IPV4
fi
LB_IP=$(gcloud compute addresses describe "$ADDRESS" --global --format="value(address)")

# 2) Backend service (el cerebro: named-port + health check) ─────────────────
if gcloud compute backend-services describe "$BACKEND" --global >/dev/null 2>&1; then
  echo "· Backend service $BACKEND ya existe."
else
  echo "· Creando backend service (HTTP, port-name=http, sin CDN) ..."
  gcloud compute backend-services create "$BACKEND" \
    --global \
    --load-balancing-scheme="$SCHEME" \
    --protocol=HTTP \
    --port-name=http \
    --health-checks="$HEALTH_CHECK"
fi

# 3) Adjuntar el MIG regional como backend ───────────────────────────────────
echo "· Adjuntando el MIG $MIG como backend ..."
gcloud compute backend-services add-backend "$BACKEND" \
  --global \
  --instance-group="$MIG" \
  --instance-group-region="$REGION" \
  --balancing-mode=UTILIZATION \
  --max-utilization=0.8 2>/dev/null \
  && echo "  backend adjuntado." || echo "  (el MIG ya estaba adjunto)"

# 4) URL map (todo el trafico -> backend) ────────────────────────────────────
if gcloud compute url-maps describe "$URL_MAP" --global >/dev/null 2>&1; then
  echo "· URL map $URL_MAP ya existe."
else
  echo "· Creando URL map ..."
  gcloud compute url-maps create "$URL_MAP" --global --default-service="$BACKEND"
fi

# 5) Target HTTP proxy ───────────────────────────────────────────────────────
if gcloud compute target-http-proxies describe "$PROXY" --global >/dev/null 2>&1; then
  echo "· Proxy $PROXY ya existe."
else
  echo "· Creando target HTTP proxy ..."
  gcloud compute target-http-proxies create "$PROXY" --global --url-map="$URL_MAP"
fi

# 6) Forwarding rule (IP:80 -> proxy) ────────────────────────────────────────
if gcloud compute forwarding-rules describe "$FW_RULE" --global >/dev/null 2>&1; then
  echo "· Forwarding rule $FW_RULE ya existe."
else
  echo "· Creando forwarding rule (IP estatica : 80) ..."
  gcloud compute forwarding-rules create "$FW_RULE" \
    --global \
    --load-balancing-scheme="$SCHEME" \
    --address="$ADDRESS" \
    --target-http-proxy="$PROXY" \
    --ports=80
fi

echo ""
echo "==================================================================="
echo "  Bloque 4 listo. Load Balancer HTTP externo activo."
echo "  IP publica:  http://$LB_IP"
echo ""
echo "  El LB tarda 3-5 min (a veces mas) en propagar. Al principio veras"
echo "  404/502 -> es normal, espera y recarga."
echo ""
echo "  Ver el balanceo (recarga varias veces; el hostname debe cambiar):"
echo "    curl -s http://$LB_IP | grep -Eo 'lab-web-mig-[a-z0-9]+'"
echo ""
echo "  >> COSTO ACTIVO: LB + VMs. Al terminar: bash nivel01-teardown.sh"
echo "==================================================================="
