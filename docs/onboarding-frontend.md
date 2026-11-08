# Guía rápida para trabajar en el frontend

No se necesita Docker para desarrollar el frontend. Esto deja un backend local con los mismos datos de demo que usa el resto del equipo.

## 1. Backend local

```
git clone https://github.com/canon4/carpeta-viva-backend.git
cd carpeta-viva-backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements-dev.txt
copy .env.example .env
```

Edita `.env`: deja `DATABASE_URL` apuntando a un Postgres local con la extensión `pgvector` (o instala Postgres 16 + `pgvector` por tu cuenta; no hace falta Docker). Las variables de IA (`ANTHROPIC_API_KEY`, etc.) pueden quedar vacías o con el valor de ejemplo — las pantallas de IA simplemente no tendrán respuesta del LLM hasta que alguien configure una clave real.

```
alembic upgrade head
python scripts/seed_sintetico.py
uvicorn app.main:app --reload
```

Verifica en `http://localhost:8000/api/v1/health`.

## 2. Usuarios de demo (los mismos para todo el equipo)

El script de siembra (`scripts/seed_sintetico.py`) crea siempre los mismos correos y contraseña — no importa quién lo corra, los datos quedan idénticos:

| Correo | Rol | Contraseña |
|---|---|---|
| admin@demo.local | admin | demo12345 |
| coordinador@demo.local | coordinador | demo12345 |
| madre@demo.local | madre | demo12345 |
| profesional@demo.local | profesional | demo12345 |
| defensor@demo.local | defensor | demo12345 |
| auditor@demo.local | auditor | demo12345 |

## 3. Frontend

```
git clone https://github.com/canon4/carpeta-viva-frontend.git
cd carpeta-viva-frontend
npm install
npm run api:types   # regenera los tipos desde ../carpeta-viva-backend/openapi.json
npm start           # http://localhost:4200, /api se redirige a http://localhost:8000
```

Requiere Node >= 22.22.3 o >= 24.15.0 (Angular 22, ver ADR-0005). Si `npm start` se queja de la versión de Node, actualízalo primero.

En `http://localhost:4200/login` hay botones de acceso rápido por rol (solo en desarrollo local, nunca en Docker/VPS): no hace falta escribir usuario y contraseña cada vez, pero usan el mismo login real contra el backend.

## 4. Si prefieres no correr tu propio backend

En vez del paso 1, apunta el frontend a un backend ya corriendo (por ejemplo el de otro compañero en la misma red, o uno en un servidor): cambia `apiUrl` en `public/config.json` por esa dirección. Los datos y usuarios de demo serán los que ese backend tenga sembrados.

## 5. Qué hay disponible ahora

Backend completo: Fases 1-5 (zonas/hogares, madres, profesionales, menores y expedientes, asignaciones, documentos, inventario, alimentos, citas, alertas, IA, reportes, archivo y cierre). Contrato en `carpeta-viva-backend/openapi.json`, 143/144 pruebas pasan (el fallo restante es un defecto conocido y preexistente de la librería de configuración, no del código de negocio). Pendiente de configurar antes de usar: `ANTHROPIC_API_KEY` real para el asistente de IA, y Tesseract para OCR si se corre fuera de Docker.
