#!/usr/bin/env bash
# =============================================================================
#  Nivel 01 · Bloque 2 — Construir la golden image con Packer
#  Prepara permisos, valida, construye y verifica.
#  Costo: solo la VM temporal del build (~2 min en e2-micro => centavos).
#  Idempotente: re-ejecutar solo crea una imagen nueva en la misma familia.
# =============================================================================
set -euo pipefail

PROJECT="juan-devops-lab-dev"
IMAGE_FAMILY="lab-web-app"

echo "==> 1/4 Verificando prerequisitos ..."
command -v packer >/dev/null 2>&1 || {
  echo "ERROR: Packer no esta instalado."
  echo "  macOS:  brew tap hashicorp/tap && brew install hashicorp/tap/packer"
  echo "  Linux:  https://developer.hashicorp.com/packer/install"
  exit 1
}
packer version

# Packer usa ADC (no gcloud auth login). Debe existir el archivo.
if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
  echo "ERROR: no hay Application Default Credentials."
  echo "  Corre: gcloud auth application-default login"
  echo "         gcloud auth application-default set-quota-project $PROJECT"
  exit 1
fi
echo "· ADC presentes."

echo ""
echo "==> 2/4 Asegurando permisos de la SA / usuario para construir imagenes ..."
# Packer necesita crear una VM temporal y una imagen. Con tu usuario (Owner)
# ya alcanza; esto es por si luego corres el build desde CI con la SA.
SA="terraform-sa@${PROJECT}.iam.gserviceaccount.com"
for ROLE in roles/compute.instanceAdmin.v1 roles/compute.storageAdmin roles/iam.serviceAccountUser; do
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:${SA}" \
    --role="$ROLE" --condition=None >/dev/null
done
echo "· Roles just-in-time otorgados a $SA (para el build desde CI mas adelante)."

echo ""
echo "==> 3/4 Construyendo la imagen (Packer levanta y BORRA una VM temporal) ..."
packer init .
packer validate .
packer build .

echo ""
echo "==> 4/4 Verificando la imagen publicada ..."
gcloud compute images list \
  --project="$PROJECT" \
  --filter="family:${IMAGE_FAMILY}" \
  --format="table(name, family, creationTimestamp, status)"

echo ""
echo "==> Confirmando que NO quedaron VMs temporales encendidas (disciplina de costo):"
gcloud compute instances list --project="$PROJECT" || true

echo ""
echo "======================================================================="
echo "  Bloque 2 listo. Imagen publicada en la familia: $IMAGE_FAMILY"
echo "  El MIG del Bloque 3 pedira 'la mas reciente de esta familia'."
echo "  Si la lista de instancias salio vacia, Packer limpio bien: costo ~\$0."
echo "======================================================================="
