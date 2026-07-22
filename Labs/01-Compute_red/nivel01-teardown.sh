#!/usr/bin/env bash
# =============================================================================
#  Nivel 01 · TEARDOWN — apaga todo lo que cuesta dinero.
#
#  Borra en ORDEN INVERSO de dependencias (lo que GCP exige):
#    LB -> autoescalador -> MIG -> plantilla -> health check
#  NO borra la red ni la imagen (cuestan $0 y las reusas en la proxima sesion).
#
#  Corre esto SIEMPRE al terminar de trabajar.
#  Idempotente: si algo ya no existe, sigue de largo.
# =============================================================================
set -uo pipefail   # sin -e: queremos continuar aunque un recurso ya no exista

PROJECT="juan-devops-lab-dev"
REGION="us-central1"

MIG="lab-web-mig"
TEMPLATE="lab-web-tpl"
HEALTH_CHECK="lab-web-hc"
# Recursos del Bloque 4 (aun no existen; el teardown ya los contempla):
FW_RULE="lab-web-fr"
PROXY="lab-web-proxy"
URL_MAP="lab-web-urlmap"
BACKEND="lab-web-backend"
ADDRESS="lab-web-ip"

gcloud config set project "$PROJECT" >/dev/null
echo "==> Teardown del Nivel 01 en $PROJECT ..."

# ── Front del Load Balancer (Bloque 4) ───────────────────────────────────────
gcloud compute forwarding-rules delete "$FW_RULE" --global --quiet 2>/dev/null \
  && echo "· Forwarding rule borrada." || echo "· (sin forwarding rule)"
gcloud compute target-http-proxies delete "$PROXY" --quiet 2>/dev/null \
  && echo "· Proxy borrado." || echo "· (sin proxy)"
gcloud compute url-maps delete "$URL_MAP" --quiet 2>/dev/null \
  && echo "· URL map borrado." || echo "· (sin url map)"
gcloud compute backend-services delete "$BACKEND" --global --quiet 2>/dev/null \
  && echo "· Backend service borrado." || echo "· (sin backend service)"
gcloud compute addresses delete "$ADDRESS" --global --quiet 2>/dev/null \
  && echo "· IP estatica liberada." || echo "· (sin IP estatica)"

# ── Autoescalador + MIG (aqui estan las VMs que cobran) ──────────────────────
gcloud compute instance-groups managed stop-autoscaling "$MIG" \
  --region="$REGION" --quiet 2>/dev/null \
  && echo "· Autoescalado detenido." || echo "· (sin autoescalado)"

gcloud compute instance-groups managed delete "$MIG" \
  --region="$REGION" --quiet 2>/dev/null \
  && echo "· MIG borrado (VMs apagadas)." || echo "· (sin MIG)"

# ── Plantilla y health check ─────────────────────────────────────────────────
gcloud compute instance-templates delete "$TEMPLATE" --quiet 2>/dev/null \
  && echo "· Plantilla borrada." || echo "· (sin plantilla)"
gcloud compute health-checks delete "$HEALTH_CHECK" --quiet 2>/dev/null \
  && echo "· Health check borrado." || echo "· (sin health check)"

echo ""
echo "==> VERIFICACION FINAL — no debe quedar NADA encendido:"
gcloud compute instances list --project="$PROJECT"
gcloud compute forwarding-rules list --project="$PROJECT"

echo ""
echo "======================================================================="
echo "  Teardown completo. Costo activo: \$0"
echo "  Se CONSERVAN (gratis, listos para la proxima sesion):"
echo "    · VPC lab-vpc + subred + reglas de firewall"
echo "    · Imagen de la familia lab-web-app"
echo "  Para reconstruir todo:  bash nivel01-mig.sh && bash nivel01-lb.sh"
echo "======================================================================="
