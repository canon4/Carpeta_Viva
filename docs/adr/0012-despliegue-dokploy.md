# 0012. Despliegue en el VPS con Dokploy: apps separadas, ruteo por path

## Estado
Aceptado.

## Contexto
El VPS de despliegue (IP `2.24.97.209`) ya tiene Dokploy instalado para administrar
despliegues, y existe el registro DNS `vikahome.zogui.cloud` → `2.24.97.209` (TTL 14400,
sin proxy de Cloudflare) para este proyecto.

El `docker-compose.yml` de este repositorio (Carpeta_Viva) junta backend y frontend en un
solo stack para demo local: el nginx del frontend hace `proxy_pass http://backend:8000`
usando el nombre de servicio del propio compose. Pero backend y frontend son repositorios
independientes (ADR-0005: "frontend se despliega sin tocar el backend"), y Dokploy permite
agrupar varias aplicaciones independientes bajo un mismo Proyecto. Desplegarlas como dos
apps separadas rompe ese `proxy_pass http://backend:8000`, porque no comparten red
automáticamente.

## Decisión
1. **Un proyecto Dokploy "carpeta-viva" con dos aplicaciones independientes**: `backend`
   (repo `carpeta-viva-backend`, `backend/Dockerfile`) y `frontend` (repo
   `carpeta-viva-frontend`, `frontend/Dockerfile`). Cada una se redespliega sola, sin tumbar
   la otra.
2. **Mismo dominio, ruteo por path en Traefik (el proxy que trae Dokploy)**: ambas apps
   usan el host `vikahome.zogui.cloud`.
   - App `backend`: regla con `Path` = `/api`, puerto interno `8000`.
   - App `frontend`: regla por defecto (`/`), puerto interno `80`.
   - No se crea un subdominio nuevo para la API: evita un registro DNS adicional y el
     frontend sigue llamando a `apiUrl: "/api/v1"` (mismo origen), sin cambiar código.
3. **El nginx del frontend ya no proxea `/api/`** en el despliegue de Dokploy: Traefik
   intercepta ese path antes de llegar al contenedor. Se creó `frontend/nginx.conf` (sin el
   bloque de proxy) para que la imagen standalone no dependa de un host `backend` que no
   existe en su red. El `infra/nginx/default.conf` de este repositorio (con el proxy) se
   mantiene solo para el `docker-compose.yml` de demo local, donde sí hace falta.
4. **`config.json` se genera al arrancar el contenedor**, no se monta desde fuera: se
   agregó `frontend/docker/30-generar-config.sh` (vía `/docker-entrypoint.d/` de la imagen
   `nginx:1.27-alpine`), controlado por las variables de entorno `API_URL` (por defecto
   `/api/v1`) y `ACCESOS_RAPIDOS_DESARROLLO` (por defecto `false`). En Dokploy no hace falta
   configurar nada: los valores por defecto ya son los de producción.
5. **Despliegue automático vía GitHub Actions**: cada repo (`backend`, `frontend`) llama al
   webhook de despliegue que Dokploy expone por aplicación (pestaña "Deployments" de la
   app → "Deploy Webhook") al hacer push a `main`. La URL del webhook se guarda como secreto
   de GitHub (`DOKPLOY_DEPLOY_WEBHOOK`) en cada repositorio, nunca en el código.

## Variables de entorno a configurar en Dokploy (app `backend`)
`ENVIRONMENT=production`, `DATABASE_URL`, `JWT_SECRET`, `ARCHIVOS_CLAVE_MAESTRA`,
`CORS_ORIGINS=["https://vikahome.zogui.cloud"]`, `POLICIA_INFANCIA_TELEFONO`,
`ANTHROPIC_API_KEY` y el resto de variables de IA de `.env.example`. `main.py` ya rechaza
el arranque en producción si `JWT_SECRET` o `ARCHIVOS_CLAVE_MAESTRA` se dejan en su valor de
desarrollo.

## Consecuencias
- Redesplegar el frontend (un cambio de estilos, por ejemplo) no reinicia el backend, y
  viceversa — cumple ADR-0005.
- Si alguna vez se necesita HTTPS explícito: queda a cargo de Dokploy/Traefik (certificado
  Let's Encrypt por dominio), no de este repositorio. **Punto abierto**: confirmar en el
  panel de Dokploy que el certificado para `vikahome.zogui.cloud` esté activo antes de
  anunciar la URL.
- Postgres y Fuseki no forman parte de esta decisión: pueden seguir viviendo donde ya están
  (la base compartida del VPS mencionada en `docs/onboarding-frontend.md`) o moverse a apps
  de base de datos de Dokploy; se decide aparte.
- Si en el futuro se necesita escalar el backend a más de una réplica, el ruteo por `Path`
  en el mismo dominio sigue funcionando sin cambios (Traefik balancea entre réplicas de la
  misma app).
