# =============================================================================
#  Nivel 03 · Bloque 1 — Imagen de la app web (nginx)
#  nginx-alpine ejecuta los scripts de /docker-entrypoint.d/ al arrancar, así
#  que la página se genera con la identidad REAL del pod en cada arranque.
# =============================================================================
FROM nginx:1.27-alpine

# Parcha los paquetes del SO durante el build: cierra CVEs heredadas de la
# base (p.ej. la CVE critica de openssl que detecto el escaneo).
RUN apk update && apk upgrade --no-cache

# Script que renderiza el index con la identidad del pod (Downward API).
COPY 40-render-index.sh /docker-entrypoint.d/40-render-index.sh
RUN chmod +x /docker-entrypoint.d/40-render-index.sh

EXPOSE 80
