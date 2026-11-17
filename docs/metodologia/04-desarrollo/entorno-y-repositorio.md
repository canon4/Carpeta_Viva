# Entorno de trabajo y repositorio por módulos

Fase 4, paso 1: "Configurar el entorno de trabajo y el repositorio estructurado por módulos". Herramientas: VS Code, Git y GitHub, Docker.

## 1. Tres repositorios
| Repositorio | Contenido | Remoto |
|---|---|---|
| `Carpeta_Viva` (gobierno) | `CLAUDE.md`, `docs/` (ADR, plan, metodología), `ontologia/`, `infra/`, `docker-compose.yml`, agentes | Local |
| `backend/` | FastAPI, migraciones, pruebas, `openapi.json` | `canon4/carpeta-viva-backend` |
| `frontend/` | Angular, Nginx | `canon4/carpeta-viva-frontend` |

`backend/` y `frontend/` están en el `.gitignore` de Carpeta_Viva y se clonan con `scripts/bootstrap.sh` (o `.ps1`), sin submódulos (ADR-0005). Cada uno tiene un `CLAUDE.md` corto que apunta al de gobierno. Un cambio que cruza repositorios (endpoint nuevo) se anota en `docs/adr/`.

## 2. Preparar el entorno
```bash
scripts/bootstrap.sh
```
```bash
cd backend && python -m venv .venv && .venv/Scripts/pip install -r requirements-dev.txt
```
```bash
cd backend && alembic upgrade head && python scripts/seed_sintetico.py
```
```bash
cd frontend && npm install && npm start
```
Detalle completo y Docker en `../06-despliegue/manual-instalacion.md`.

Extensiones de VS Code sugeridas: Python, Pylance, Ruff, Angular Language Service, ESLint, Docker, Mermaid Preview.

## 3. Estructura del backend (por módulo)
```
backend/app/
  main.py                 crea la app, registra routers bajo /api/v1
  core/                   transversal: config, database, deps (usuario_actual, requiere_roles),
                          security (JWT, hash), audit (registrar_acceso), almacenamiento (Fernet),
                          compresion, errors, ia_llm (interfaz ProveedorLLM)
  modules/registry.py     lista de los 16 módulos
  modules/<modulo>/
    api.py                rutas FastAPI (solo HTTP, sin reglas)
    application.py        casos de uso y autorización; única puerta hacia otros módulos
    domain.py             enumeraciones, validaciones y constantes de negocio
    repository.py         acceso a datos con SQLAlchemy
    models.py             tablas
    schemas.py            Pydantic de entrada y salida
backend/migrations/versions/   0001 a 0010 (Alembic)
backend/tests/                 test_<modulo>.py
```
Regla: un módulo solo importa la capa `application` de otro, con import local dentro de la función para evitar ciclos (ADR-0001, ADR-0008 §4).

## 4. Estructura del frontend
```
frontend/src/app/
  core/       auth (token en memoria, guards), api (tipos generados), config (config.json), navegacion.ts
  features/   login, shell, panel
  modules/    un directorio por módulo con <modulo>.routes.ts (carga diferida)
  shared/     componentes reutilizables
```
Los tipos del API se generan con `npm run api:types` desde `../backend/openapi.json`; no se escriben a mano.

## 5. Convenciones
- Idioma del dominio en español (nombres de tablas, funciones y rutas); sin emojis; íconos SVG.
- Ramas: `main` estable; una rama por tarea `feat/<modulo>-<tema>`, `fix/<tema>`, `docs/<tema>`. Fusión a `main` solo con revisión cruzada (`revision-cruzada.md`).
- Commits en presente y en español, con el módulo al inicio: `documentos: agrega devolución con motivo`.
- Migraciones antes del código que las usa; nunca editar una migración ya aplicada.
- Tras cambiar endpoints: `python scripts/export_openapi.py`; una prueba falla si el contrato está desactualizado.
- Sin secretos en el código; `.env` no se versiona.
- Solo datos sintéticos (`scripts/seed_sintetico.py`, `docs/datos-sinteticos/`).

## 6. Tablero Kanban
Columnas: Pendiente, Requisitos listos, Diseño aprobado, En desarrollo (WIP 1 por persona), En revisión cruzada, Probado, Desplegado. Una tarjeta por historia de usuario (`../01-requisitos/historias-de-usuario.md`). Detalle de las puertas de calidad en `../00-indice.md`.
