# Plan por fases

Reglas: las migraciones de base de datos terminan antes del código que las usa; backend y frontend avanzan en paralelo dentro de cada fase; seguridad revisa al cierre de cada fase; todo con datos sintéticos.

## Fase 0. Arranque (avance del 30/10/2026)
Hecho y verificado
- [x] Contexto, cuestionario y arquitectura base (`CLAUDE.md`, `CUESTIONARIO.md`, `Contexto/`).
- [x] ADR 0001 a 0006.
- [x] Estructura de Carpeta_Viva, `.gitignore` que excluye `backend/` y `frontend/`, `scripts/bootstrap.sh` y `.ps1`.
- [x] Backend: 15 módulos, autenticación JWT con auditoría de sesión, modelos del núcleo, migración inicial Alembic (sube, baja y no deja diferencias con los modelos), contrato `openapi.json`. 29 pruebas pasan (SQLite en memoria).
- [x] Frontend Angular: inicio de sesión, panel, 14 rutas con carga diferida, configuración en tiempo de ejecución, tipos generados desde OpenAPI. Compila en producción; 6 pruebas pasan.
- [x] Ontología núcleo de 8 clases con datos sintéticos y 4 consultas de competencia validadas (`ontologia/validar.py`).
- [x] 8 agentes en `.claude/agents/`.

Pendiente
- [ ] Levantar `docker-compose.yml` con Docker (no se probó: no había Docker en el entorno de verificación). Incluye confirmar que Fuseki arranca con `secoresearch/fuseki:6.2.0` y el dataset `ds`.
- [ ] Probar la migración y las pruebas contra PostgreSQL real (hasta ahora solo SQLite).
- [ ] Cargar `ontologia/core.ttl` en Fuseki (agente datos-infra).
- [ ] Instalar Graphify (`uv tool install graphifyy`, `graphify install --project`) y generar el grafo inicial (`/graphify .`) sobre Carpeta_Viva con datos sintéticos.
- [ ] Crear repositorios remotos y definir `BACKEND_REPO_URL` y `FRONTEND_REPO_URL` en `.env`.
- [ ] Nombre y marca del producto (Diego).

## Fase 1. Base de permisos
Autenticación completa (usuarios, cambio de contraseña, límite de intentos de inicio de sesión), Zonas y Hogares, Profesionales, Madres Sustitutas con firma, Auditoría de lectura y escritura.
- seguridad: modelo de amenazas (STRIDE), decisión de segundo factor, esquema del token en el frontend, base legal para datos de menores.
- ux-ui: sistema de diseño y marca provisional, flujos de la madre y del profesional.

## Fase 2. Menores y asignaciones
Menores y Expedientes, Asignaciones y Traslados, tablas `*_History`, permisos por expediente definidos por el profesional encargado, ocultar el expediente a la madre al cerrar la asignación, panel del profesional.

## Fase 3. Gestión documental
Carga multiformato, almacenamiento cifrado de archivos, versionado, flujo madre crea y profesional aprueba, firma, categorías documentales (definir con el operador). Digitalización del historial físico.

## Fase 4. Alertas y vida del hogar
Alertas y Evasiones (con números de emergencia y registro de recepción), Citas y Recordatorios, Inventario del Hogar, Control de Alimentos, alertas de visitas vencidas y documentos faltantes. Decidir aviso adicional por notificación al celular o SMS.

## Fase 5. IA, reportes y cierre
Asistente de IA (OCR, clasificación, embeddings, RAG con citas), reglas en la ontología (por ejemplo, sin informe psicosocial en 60 días), Reportes en cuatro niveles, Archivo y Cierre, respaldos diarios con prueba de restauración, prueba de carga a 1000 usuarios simultáneos.

## Orden de los agentes en cada fase
1. arquitecto: define el contrato y el ADR si cambia algo.
2. datos-infra y backend: migración, luego código.
3. backend y frontend en paralelo; ux-ui diseña antes del frontend.
4. test: pruebas y correcciones rápidas.
5. seguridad: revisión de cierre.
