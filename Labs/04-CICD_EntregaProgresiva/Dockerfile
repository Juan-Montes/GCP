FROM nginx:1.27-alpine

# Parcha los paquetes del SO durante el build (cierra CVEs de la base).
RUN apk update && apk upgrade --no-cache

# Script que renderiza el index con la identidad del pod (Downward API).
COPY 40-render-index.sh /docker-entrypoint.d/40-render-index.sh
RUN chmod +x /docker-entrypoint.d/40-render-index.sh

EXPOSE 80
