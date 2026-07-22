// =============================================================================
//  Nivel 01 · Bloque 2 — Golden image con Packer (builder googlecompute)
//
//  Patron: hornear la app EN la imagen, no configurarla al arranque.
//  Las VMs del MIG nacen listas -> autoescalado en segundos, no minutos.
//
//  Auth: usa las Application Default Credentials (gcloud auth application-default
//        login). Sin llaves JSON: mismo principio keyless del Nivel 00.
//
//  Ciclo: Packer levanta una VM temporal -> corre provisioners -> apaga ->
//         crea la imagen -> BORRA la VM. Unico costo del bloque (~2 min, centavos).
//
//  Uso:  packer init .  &&  packer validate .  &&  packer build .
// =============================================================================

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "project_id" {
  type    = string
  default = "juan-devops-lab-dev"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

// Familia de imagen: el MIG pedira "la mas reciente de esta familia".
// Asi versionas imagenes sin tocar la plantilla de instancias.
variable "image_family" {
  type    = string
  default = "lab-web-app"
}

source "googlecompute" "web" {
  project_id   = var.project_id
  zone         = var.zone

  // Imagen base: Debian 12 (ligera y con soporte largo).
  source_image_family = "debian-12"
  ssh_username        = "packer"

  // Nombre unico por build + familia para el versionado.
  image_name        = "lab-web-app-{{timestamp}}"
  image_family      = var.image_family
  image_description = "Nginx + app demo, horneada con Packer (Nivel 01)"

  // VM temporal barata: solo vive durante el build.
  machine_type = "e2-micro"
  disk_size    = 10
  disk_type    = "pd-standard"

  // La VM de build necesita salida a internet para instalar paquetes.
  // Usamos la red default (efimera), NO nuestra lab-vpc: la lab-vpc esta
  // cerrada a proposito y no tiene NAT todavia. La imagen resultante es
  // independiente de la red donde se horneo.
  network = "default"

  // Etiquetas para rastrear el origen de la imagen (buena practica de trazabilidad).
  image_labels = {
    entorno   = "dev"
    nivel     = "01"
    construido = "packer"
  }
}

build {
  name    = "lab-web-app"
  sources = ["source.googlecompute.web"]

  // 1) Instalar y preparar Nginx.
  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    inline = [
      "set -e",
      "echo '--> Instalando nginx...'",
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
    ]
  }

  // 2) Pagina que muestra el NOMBRE DE LA INSTANCIA que responde.
  //    Clave para DEMOSTRAR el balanceo en el Bloque 4: al recargar veras
  //    cambiar el hostname -> prueba visual de que el LB reparte trafico.
  provisioner "shell" {
    inline = [
      "set -e",
      "sudo tee /usr/local/bin/render-index.sh > /dev/null <<'EOF'",
      "#!/bin/bash",
      "HOST=$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/name)",
      "ZONE=$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/zone | awk -F/ '{print $NF}')",
      "cat > /var/www/html/index.html <<HTML",
      "<!doctype html><html><head><meta charset='utf-8'><title>Lab Nivel 01</title>",
      "<style>body{font-family:monospace;background:#111722;color:#EDEFF5;display:flex;",
      "align-items:center;justify-content:center;height:100vh;margin:0}",
      ".c{text-align:center}.h{color:#E8731A;font-size:2rem}</style></head>",
      "<body><div class='c'><p>Servido por la instancia</p>",
      "<p class='h'>$HOST</p><p>zona: $ZONE</p></div></body></html>",
      "HTML",
      "EOF",
      "sudo chmod +x /usr/local/bin/render-index.sh",
    ]
  }

  // 3) Servicio systemd que regenera el index en CADA arranque.
  //    Necesario porque el hostname cambia en cada VM nueva del MIG.
  provisioner "shell" {
    inline = [
      "set -e",
      "sudo tee /etc/systemd/system/render-index.service > /dev/null <<'EOF'",
      "[Unit]",
      "Description=Genera index.html con el hostname de esta instancia",
      "After=network-online.target",
      "Before=nginx.service",
      "",
      "[Service]",
      "Type=oneshot",
      "ExecStart=/usr/local/bin/render-index.sh",
      "RemainAfterExit=yes",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo systemctl enable render-index.service",
      "echo '--> Imagen lista.'",
    ]
  }
}
