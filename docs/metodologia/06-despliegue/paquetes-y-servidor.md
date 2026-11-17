# Paquetes y servidor

Fecha: 2026-11-17. Fuente: `docker-compose.yml`, `backend/Dockerfile`, `frontend/Dockerfile`, `frontend/nginx.conf`, `.env.example`, ADR-0012.

Leyenda: [VERIFICADO] comprobado en este entorno; [IMPLEMENTADO] existe en el repositorio pero no se ha probado en ejecución; [PROPUESTA] no existe todavía.

Estado general: ni `docker-compose.yml` ni el despliegue en Dokploy se han probado (`docs/plan-por-fases.md`, Fase 0: "no había Docker en el entorno de verificación"). La migración tampoco se ha probado contra PostgreSQL real.

## 1. Imágenes de producción

| Componente | Imagen / base | Origen | Puerto interno | Estado |
|---|---|---|---|---|
| Backend (FastAPI) | `python:3.12-slim` + `tesseract-ocr`, `tesseract-ocr-spa`, `curl` | `backend/Dockerfile` | 8000 | [IMPLEMENTADO] |
| Frontend + Nginx | build `node:22-alpine`, runtime `nginx:1.27-alpine` | `frontend/Dockerfile` | 80 | [IMPLEMENTADO] |
| PostgreSQL + pgvector | `pgvector/pgvector:pg16` | `docker-compose.yml` | 5432 | [IMPLEMENTADO] |
| Fuseki | `secoresearch/fuseki:6.2.0` (dataset `ds`) | `docker-compose.yml` | 3030 | [IMPLEMENTADO], arranque con dataset `ds` sin confirmar |

Detalles:
- Backend: usuario no root `app`; al arrancar ejecuta `alembic upgrade head` y luego `uvicorn app.main:app --host 0.0.0.0 --port 8000`. Las migraciones corren, por tanto, en cada arranque del contenedor. Archivos cifrados en `/data/archivos` (volumen).
- Frontend: compila Angular dentro de la imagen (Angular 22 exige Node reciente, ADR-0005). `nginx.conf` sin proxy a `/api/` (ADR-0012). `docker/30-generar-config.sh` genera `config.json` al arrancar con `API_URL` (defecto `/api/v1`) y `ACCESOS_RAPIDOS_DESARROLLO` (defecto `false`).
- PostgreSQL: `infra/postgres/init/001-extensiones.sql` crea `vector` y `pgcrypto` solo en la primera inicialización del volumen.
- Versiones: las etiquetas se fijaron en el repositorio; verificar con búsqueda web antes de cada actualización mayor [PENDIENTE: revisión periódica, y fijar por digest si se quiere reproducibilidad].
- Demo local: `infra/nginx/default.conf` (con `proxy_pass http://backend:8000`) y `infra/frontend/config.json` se montan sobre la imagen del frontend solo en `docker-compose.yml`.

## 2. Variables de entorno (sin valores)

Fuente: `.env.example`. Los valores van en `.env` (local) o en el panel de Dokploy (servidor); nunca en el repositorio.

| Variable | Usada por | Notas |
|---|---|---|
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | postgres, `DATABASE_URL` del compose | Secreto: contraseña |
| `FUSEKI_ADMIN_PASSWORD` | fuseki | Secreto |
| `JWT_SECRET` | backend | Secreto; en producción el arranque falla si queda el valor por defecto |
| `ARCHIVOS_CLAVE_MAESTRA` | backend, seed | Secreto (clave Fernet). Perderla impide descifrar los archivos: respaldarla aparte |
| `ENVIRONMENT` | backend | `development` o `production` |
| `CORS_ORIGINS` | backend | Lista JSON con el origen del frontend |
| `DATABASE_URL` | backend | Compose la arma; en Dokploy se define a mano |
| `FUSEKI_URL` | backend | Compose: `http://fuseki:3030/ds` |
| `ARCHIVOS_DIR` | backend | `/data/archivos` |
| `POLICIA_INFANCIA_TELEFONO` | backend | Valor por defecto; un admin lo cambia luego sin redesplegar (ADR-0009) |
| `IA_LLM_PROVEEDOR`, `IA_LLM_MODELO` | backend | `anthropic` o `groq` |
| `ANTHROPIC_API_KEY`, `GROQ_API_KEY` | backend | Secretos |
| `IA_EMBEDDINGS_MODELO`, `IA_EMBEDDINGS_VERSION` | backend | Embeddings locales |
| `IA_ANONIMIZADO_POR_DEFECTO`, `IA_INDEXAR_AUTOMATICAMENTE`, `IA_INDEXACION_PENDIENTE_UMBRAL_MINUTOS` | backend | Ver ADR-0010; no pasar el anonimizado a `false` sin ADR-0002 |
| `API_URL`, `ACCESOS_RAPIDOS_DESARROLLO` | frontend (contenedor) | Opcionales; los defectos son los de producción |
| `FRONTEND_DIST` | (obsoleta) | Ya no se usa |
| `BACKEND_REPO_URL`, `FRONTEND_REPO_URL` | `scripts/bootstrap.*` | Solo desarrollo |

Hallazgo: el compose no pasa `FUSEKI_URL` ni credenciales de Fuseki al backend con autenticación; el backend usa `http://fuseki:3030/ds` sin contraseña. [PENDIENTE: confirmar si el backend ya escribe en Fuseki y cómo se autentica.]

## 3. Servidor: VPS Hostinger con Dokploy (ADR-0012)

- VPS con Dokploy instalado; DNS `vikahome.zogui.cloud` apuntando a la IP del VPS (registro creado, sin proxy de Cloudflare).
- Un proyecto Dokploy `carpeta-viva` con dos aplicaciones independientes:
  - `backend`: repo `carpeta-viva-backend`, `backend/Dockerfile`, puerto 8000, regla de Traefik `Path` = `/api`.
  - `frontend`: repo `carpeta-viva-frontend`, `frontend/Dockerfile`, puerto 80, ruta `/`.
- Mismo host para ambas; el frontend llama a `/api/v1` en el mismo origen. Redesplegar una no reinicia la otra (ADR-0005).
- HTTPS: Let's Encrypt por Traefik/Dokploy. [PENDIENTE: confirmar certificado activo para el dominio antes de anunciar la URL, ADR-0012.]
- PostgreSQL y Fuseki: ADR-0012 no decide dónde viven. [PENDIENTE de decisión: apps de base de datos de Dokploy o base compartida.] Reglas fijas: nunca publicados a la red pública, solo accesibles por la red interna de Docker/Dokploy; volúmenes persistentes para `pgdata`, `fuseki_databases`, `fuseki_configuration` y archivos.
- El volumen de archivos del backend (`/data/archivos`) debe configurarse como volumen persistente en Dokploy [PENDIENTE: verificar].
- Dimensionamiento [PROPUESTA]: 35 000 a 42 000 documentos por año; con un tamaño medio de 1 a 3 MB serían 35 a 125 GB por año de archivos más PostgreSQL y embeddings. Definir disco del VPS con margen de 2 a 3 años y revisar con datos reales de tamaño.
- Auditoría: la tabla `auditoria_accesos` no está particionada por fecha [PENDIENTE, regla de datos-infra]; requiere migración Alembic previa.

## 4. GitHub Actions

Existe (en cada repositorio, `.github/workflows/deploy.yml`, idéntico):
- Disparador: push a `main`.
- Acción: `curl --fail --request POST` al webhook de despliegue de Dokploy, tomado del secreto `DOKPLOY_DEPLOY_WEBHOOK`.
- Estado: [IMPLEMENTADO], no verificado en ejecución real.

Falta [PENDIENTE]:
- Crear el secreto `DOKPLOY_DEPLOY_WEBHOOK` en cada repositorio con la URL de cada app.
- Integración continua: ejecutar `pytest` (backend) y `npm test` + `npm run build` (frontend) antes de llamar al webhook; hoy se despliega sin pruebas.
- Prueba de migraciones `upgrade`/`downgrade` contra PostgreSQL real en CI (servicio `pgvector/pgvector:pg16`).
- Verificación de que `backend/openapi.json` está actualizado.
- Escaneo de dependencias e imágenes.
- Rama protegida y despliegue solo si CI pasa.

## 5. Orden de arranque y migraciones

1. PostgreSQL (con `vector` y `pgcrypto`; el init solo corre con volumen nuevo) y Fuseki.
2. Backend: espera a PostgreSQL sano (compose: `depends_on: service_healthy`); ejecuta `alembic upgrade head` al arrancar y luego uvicorn. Healthcheck: `GET /api/v1/health`.
3. Frontend: en compose espera al backend sano; en Dokploy es independiente.
4. Datos sintéticos (solo demo): perfil `demo`, servicio `seed`.

Reglas de migración:
- Cambios de esquema como migración Alembic antes del código que los usa (CLAUDE.md).
- Al migrar en el arranque, con varias réplicas del backend habría carreras entre migraciones [PROPUESTA: separar un paso de migración si se escala a más de una réplica].
- Antes de migrar en servidor: respaldo de PostgreSQL (ver `monitoreo.md`).
- El downgrade existe en cada migración; probarlo antes de depender de él para reversión.
- Referencia de esquema completo: `docs/metodologia/03-diseno/script-bd.sql` (generado por SQLAlchemy porque Alembic offline falla en la migración 0009).
