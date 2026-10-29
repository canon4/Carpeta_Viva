# ADR-0005 Repositorios y frontend desacoplado

Estado: Aceptada (llamada del 29/10/2026)

## Contexto
Los cambios de interfaz deben poder desplegarse sin tumbar el backend. Dos desarrolladores. Claude no conserva contexto entre sesiones ni entre repositorios: lo que no está escrito en archivos se pierde.

## Decisión
- Carpeta_Viva es el repositorio de gobierno (contexto, agentes, ADR, plan, ontología, infraestructura). No contiene código de aplicación.
- `backend/` y `frontend/` son repositorios independientes anidados en Carpeta_Viva. Se excluyen en su `.gitignore` y se clonan con `scripts/bootstrap`. No se usan submódulos de Git.
- El frontend Angular se compila a archivos estáticos y se sirve con Nginx. Se despliega solo, por GitHub Actions cuando se configure.
- Contrato: API bajo `/api/v1` y `backend/openapi.json`, generado por `scripts/export_openapi.py` y verificado por una prueba que falla si está desactualizado. El frontend genera sus tipos con `npm run api:types`. Un cambio incompatible exige una versión nueva (`/api/v2`).
- Configuración del frontend (dirección de la API) en `public/config.json`, leída al iniciar y nunca en caché.
- Cada módulo del frontend carga de forma diferida.
- Cada repositorio tiene un `CLAUDE.md` corto que apunta a Carpeta_Viva. La sesión de Claude Code se abre en Carpeta_Viva para ver los tres. Los cambios que cruzan repositorios se anotan en `docs/adr/`.

## Consecuencias
- Un frontend viejo con un backend nuevo funciona mientras el cambio sea compatible.
- Hay tres historiales de Git que coordinar; el script de arranque y el contrato reducen el riesgo.
