#!/usr/bin/env bash
# =============================================================================
#  Nivel 00 · Bootstrap de gobernanza — Portafolio DevOps en GCP
#  Crea proyectos dev/prod, habilita APIs base, una service account de
#  automatizacion SIN llaves (impersonacion) y un presupuesto con alertas.
#  Idempotente: seguro de re-ejecutar.
#
#  Uso:  1) Edita el bloque PARAMETROS.
#        2) Corre en Cloud Shell:  bash bootstrap-nivel00.sh
# =============================================================================
set -euo pipefail

# ── PARAMETROS (edita estos) ────────────────────────────────────────────────
PREFIX="juan-devops"                     # prefijo de tus IDs de proyecto
BILLING_ACCOUNT="01FED4-8B58D4-2B02ED"   # <- de: gcloud billing accounts list
BUDGET_AMOUNT="250"                       # en la MONEDA de tu cuenta (USD o MXN)
                                         # Ojo: si tu cuenta factura en MXN,
                                         # 50 MXN es muy poco: ajusta el numero.

# IDs de proyecto (deben ser unicos globalmente; si chocan, agrega un sufijo)
PROJECT_DEV="${PREFIX}-lab-dev"
PROJECT_PROD="${PREFIX}-lab-prod"

# APIs base de gobernanza. Las de compute/GKE/etc. se habilitan POR NIVEL,
# just-in-time, para mantener superficie minima.
BASE_APIS=(
  cloudresourcemanager.googleapis.com
  cloudbilling.googleapis.com
  billingbudgets.googleapis.com
  iam.googleapis.com
  serviceusage.googleapis.com
  monitoring.googleapis.com
  logging.googleapis.com
)

MY_ID="$(gcloud config get-value account 2>/dev/null)"

# ── Funciones ────────────────────────────────────────────────────────────────
create_project () {
  local pid="$1"
  if gcloud projects describe "$pid" >/dev/null 2>&1; then
    echo "· Proyecto $pid ya existe, lo reutilizo."
  else
    echo "· Creando proyecto $pid ..."
    gcloud projects create "$pid" --name="$pid"
  fi
  echo "· Vinculando facturacion a $pid ..."
  gcloud billing projects link "$pid" --billing-account="$BILLING_ACCOUNT" >/dev/null
  echo "· Habilitando APIs base en $pid ..."
  gcloud services enable "${BASE_APIS[@]}" --project="$pid"
}

setup_sa () {
  local pid="$1"
  local sa="terraform-sa"
  local sa_email="${sa}@${pid}.iam.gserviceaccount.com"
  if gcloud iam service-accounts describe "$sa_email" --project="$pid" >/dev/null 2>&1; then
    echo "· Service account $sa_email ya existe."
  else
    echo "· Creando service account de automatizacion en $pid ..."
    gcloud iam service-accounts create "$sa" \
      --project="$pid" \
      --display-name="Automatizacion Terraform (sin llaves)"
  fi
  # Baseline MINIMO. Ampliaremos roles just-in-time en cada nivel.
  gcloud projects add-iam-policy-binding "$pid" \
    --member="serviceAccount:${sa_email}" \
    --role="roles/viewer" --condition=None >/dev/null
  # Te permite IMPERSONAR la SA sin descargar llaves JSON (anti-patron evitado).
  gcloud iam service-accounts add-iam-policy-binding "$sa_email" \
    --project="$pid" \
    --member="user:${MY_ID}" \
    --role="roles/iam.serviceAccountTokenCreator" >/dev/null
  echo "· SA lista: ${sa_email} (impersonacion ON, 0 llaves)."
}

create_budget () {
  if gcloud billing budgets list --billing-account="$BILLING_ACCOUNT" \
       --format="value(displayName)" 2>/dev/null | grep -q "Portafolio DevOps"; then
    echo "· Presupuesto ya existe, lo omito."
    return
  fi
  echo "· Creando presupuesto de ${BUDGET_AMOUNT} con alertas 25/50/90/100% + forecast ..."
  gcloud billing budgets create \
    --billing-account="$BILLING_ACCOUNT" \
    --display-name="Portafolio DevOps - alerta ${BUDGET_AMOUNT}" \
    --budget-amount="${BUDGET_AMOUNT}" \
    --threshold-rule=percent=0.25 \
    --threshold-rule=percent=0.50 \
    --threshold-rule=percent=0.90 \
    --threshold-rule=percent=1.0 \
    --threshold-rule=percent=1.0,basis=forecasted-spend
}

# ── Ejecucion ────────────────────────────────────────────────────────────────
echo "==> Contexto: cuenta ${MY_ID} · facturacion ${BILLING_ACCOUNT}"
create_project "$PROJECT_DEV"
create_project "$PROJECT_PROD"
setup_sa "$PROJECT_DEV"
setup_sa "$PROJECT_PROD"
create_budget

echo ""
echo "======================================================================="
echo "  Nivel 00 completado."
echo "  dev : $PROJECT_DEV"
echo "  prod: $PROJECT_PROD"
echo ""
echo "  Verifica el presupuesto:"
echo "    gcloud billing budgets list --billing-account=$BILLING_ACCOUNT"
echo "  Impersona la SA (ejemplo, sin llaves):"
echo "    gcloud storage buckets list --project=$PROJECT_DEV \\"
echo "      --impersonate-service-account=terraform-sa@${PROJECT_DEV}.iam.gserviceaccount.com"
echo "======================================================================="
