# Manual de instalación

Fecha: 2026-11-17. Todo con datos sintéticos. Ningún valor secreto aparece aquí: use los marcadores `<...>`.

Estado: los pasos del backend y frontend sin Docker están respaldados por los README de cada repositorio. Los pasos con `docker compose` y el despliegue en servidor son [NO PROBADOS] (`docs/plan-por-fases.md`, Fase 0).

## 1. Instalación local

### Requisitos
- Git.
- Docker Desktop (Docker Engine con Compose v2) para el stack completo.
- Opcional, para desarrollo sin Docker: Python 3.12, Node 22.22 o superior (Angular 22, ADR-0005; con Node más viejo compile solo dentro de Docker).
- Puertos libres: 8080 (aplicación), 5432 y 3030 (solo en 127.0.0.1).

### Paso 1. Obtener el código
Desde la raíz de Carpeta_Viva:
```
bash scripts/bootstrap.sh        # Windows: scripts\bootstrap.ps1
```
Clona `backend/` y `frontend/` según `BACKEND_REPO_URL` y `FRONTEND_REPO_URL` (si no están definidas, crea repositorios vacíos) y copia `.env.example` a `.env` si no existe.

### Paso 2. Configurar `.env`
Edite `.env` (no se versiona). Defina como mínimo:
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `FUSEKI_ADMIN_PASSWORD`
- `JWT_SECRET`: valor largo y aleatorio.
- `ARCHIVOS_CLAVE_MAESTRA`: clave Fernet. Generar con:
  `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`
- `POLICIA_INFANCIA_TELEFONO`: número ficticio en local.
- `ANTHROPIC_API_KEY` / `GROQ_API_KEY`: opcionales; sin ellas el asistente de IA no podrá llamar al LLM.
- `ENVIRONMENT=development`, `CORS_ORIGINS=["http://localhost:8080"]`.

### Paso 3. Levantar el stack
```
docker compose up -d --build
docker compose ps
```
Servicios: `postgres`, `fuseki`, `backend`, `frontend`. El backend ejecuta `alembic upgrade head` al arrancar, por lo que las migraciones se aplican solas. Si falla, revise `docker compose logs backend`.

### Paso 4. Migraciones (manual, si hace falta)
```
docker compose exec backend alembic upgrade head
docker compose exec backend alembic current      # debe mostrar 0010 (head)
```

### Paso 5. Datos sintéticos de prueba
Solo en demo, nunca en un entorno que pueda ser producción:
```
docker compose --profile demo up -d seed
# o contra el stack ya corriendo:
docker compose exec backend python scripts/seed_sintetico.py
```
Crea usuarios, zona, hogar, madre y profesional de ejemplo (contraseña de demo documentada en `backend/README.md`).

### Paso 6. Verificación
- `curl http://localhost:8080/api/v1/health` (por Nginx) debe responder estado correcto.
- Abrir `http://localhost:8080` e iniciar sesión con un usuario sintético.
- Documentación interactiva de la API: `/docs` del backend.
- PostgreSQL: `docker compose exec postgres psql -U <POSTGRES_USER> -d <POSTGRES_DB> -c "\dx"` debe listar `vector` y `pgcrypto`.
- Fuseki: `http://localhost:3030` debe abrir y existir el dataset `ds` [sin confirmar; Fase 0 pendiente].
- Ontología en Fuseki: carga de `ontologia/core.ttl` [PENDIENTE].

### Alternativa sin Docker para desarrollo
Backend (desde `backend/`):
```
python -m venv .venv && . .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
pytest
```
Sin `DATABASE_URL`, usa por defecto un PostgreSQL local en `localhost:5432`.
Frontend (desde `frontend/`): `npm install`, `npm run api:types`, `npm start` (http://localhost:4200, `/api` redirige a `localhost:8000`).

## 2. Instalación en servidor (VPS con Dokploy, ADR-0012)

Requisitos: VPS con Dokploy, registro DNS del dominio hacia la IP del VPS, repositorios en GitHub.

1. En Dokploy cree el proyecto `carpeta-viva`.
2. Base de datos: cree PostgreSQL con pgvector (imagen `pgvector/pgvector:pg16`) y Fuseki (`secoresearch/fuseki:6.2.0`) con volúmenes persistentes, sin puertos públicos. [PENDIENTE: decisión de dónde viven, ADR-0012.] Ejecute `CREATE EXTENSION IF NOT EXISTS vector; CREATE EXTENSION IF NOT EXISTS pgcrypto;`.
3. App `backend`: repo `carpeta-viva-backend`, Dockerfile `backend/Dockerfile`, puerto 8000, dominio `vikahome.zogui.cloud` con ruta `Path` = `/api`. Volumen persistente montado en `/data/archivos`. Variables: `ENVIRONMENT=production`, `DATABASE_URL`, `JWT_SECRET`, `ARCHIVOS_CLAVE_MAESTRA`, `ARCHIVOS_DIR`, `FUSEKI_URL`, `CORS_ORIGINS=["https://<dominio>"]`, `POLICIA_INFANCIA_TELEFONO` y las de IA. El arranque falla si `JWT_SECRET` o la clave maestra quedan en el valor de desarrollo.
4. App `frontend`: repo `carpeta-viva-frontend`, Dockerfile `frontend/Dockerfile`, puerto 80, ruta `/`. No requiere variables (defectos de producción).
5. Active HTTPS (Let's Encrypt) en el dominio y confirme el certificado.
6. En cada app copie la URL de "Deploy Webhook" y guárdela como secreto `DOKPLOY_DEPLOY_WEBHOOK` en el repositorio de GitHub correspondiente.
7. Despliegue inicial manual desde Dokploy; el backend migra al arrancar.
8. NO cargue datos sintéticos de demo (`seed`) en el servidor de producción.
9. Verifique con la lista de `monitoreo.md`, sección 6.

## 3. Actualización

- Servidor: push a `main` en el repositorio dispara el webhook (GitHub Actions) y Dokploy reconstruye solo esa app. Sin CI de pruebas todavía [PENDIENTE]: ejecute `pytest` y `npm test` localmente antes de empujar.
- Con cambio de esquema: haga respaldo de PostgreSQL antes (ver `monitoreo.md`), despliegue el backend (migra al arrancar) y después el frontend si depende del cambio. Si el contrato de la API cambia de forma incompatible, publique versión nueva (`/api/v2`).
- Local: `git pull` en cada repositorio, `docker compose up -d --build`.

## 4. Reversión

- Aplicación: en Dokploy, redespliegue la imagen/commit anterior de la app afectada (o `git revert` y push a `main`).
- Esquema: `alembic downgrade -1` (o a la revisión indicada) desde el contenedor del backend. Los downgrade existen en cada migración pero [no se han probado contra PostgreSQL real]. Un downgrade puede perder datos de columnas o tablas nuevas; ante duda restaure el respaldo previo.
- Orden: primero revertir el código que usa la migración, luego el esquema.
- Local: `docker compose down` conserva los volúmenes; `docker compose down -v` BORRA los datos (úselo solo para reiniciar la demo).
