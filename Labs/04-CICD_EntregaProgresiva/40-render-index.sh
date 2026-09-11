#!/bin/sh
# Version CANARY: marca visible (teal + texto) para distinguirla de la estable
# durante el despliegue progresivo.
POD="${POD_NAME:-$(hostname)}"
NODE="${NODE_NAME:-sin-nodo}"
NS="${POD_NAMESPACE:-default}"
REL="${RELEASE:-canary}"

cat > /usr/share/nginx/html/index.html <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>Lab Nivel 04 · Canary</title>
<style>
  body{font-family:monospace;background:#111722;color:#EDEFF5;display:flex;
       align-items:center;justify-content:center;height:100vh;margin:0}
  .c{text-align:center} .h{color:#2DD4BF;font-size:2rem;margin:.4rem 0}
  .m{color:#8A93A6;font-size:.9rem} .r{color:#2DD4BF;font-size:1.1rem}
</style></head>
<body><div class="c">
  <p>Servido por el pod</p>
  <p class="h">${POD}</p>
  <p class="r">release: ${REL}</p>
  <p class="m">namespace: ${NS} &middot; nodo: ${NODE}</p>
</div></body></html>
HTML
