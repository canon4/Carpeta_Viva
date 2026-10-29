# Sistema de gestión documental para hogares sustitutos

Estado: Fase 0 (arranque). Plan en `docs/plan-por-fases.md`. Hito: avance para el docente el 30/10/2026.
Registro de lo acordado en la llamada del 29/10/2026: `docs/registro-decisiones-2026-10-29.md`.
Módulos y su alcance: `docs/modulos.md`.

## Contexto (fuente: `Contexto/` y conversaciones)
- El ICBF restablece los derechos de NNA (niños, niñas y adolescentes) y asigna un operador por municipio. En Florencia el operador es la Fundación Fundar, que tiene afiliadas a las madres sustitutas, voluntarias.
- Cada hogar sustituto tiene una madre. La norma permite hasta 13 NNA, pero en la práctica son 5 o 6 por hacinamiento.
- Hoy cada NNA tiene una carpeta física con: datos personales, documentos de identidad, información de padre y madre, historial médico y psicosocial, datos del defensor a cargo, actas de traslado y otros. Las categorías documentales aún no están definidas.
- El hogar también genera información propia: inventario de camas y muebles, personas que viven en el hogar, red de apoyo, control de alimentos (fecha de ingreso, perecedero, vencimiento) y reportes de la madre.
- Cliente: los operadores (fundaciones). Actores: madre sustituta, NNA, profesional (psicosocial, nutrición, trabajo social), defensor, coordinador, auditor. Indirectos: familia biológica, salud, educación.
- Organización: zonas (zona 1, zona 2...), con hogares dentro de cada zona.
- Modelo previo: `Contexto/ICBF.pdf` (ER con tablas `*_History`) y `Contexto/SistemaICBF.rdf`.
- Normativa: leyes colombianas. Citadas: Ley 1581/2012, Decreto 1377/2013, Res. 1619/2017, Res. 2634/2019. Seguridad valida vigencia y suma Ley 1098/2006 y Ley 594/2000. Falta definir la base legal para tratar datos de menores.

## Tipo de proyecto y equipo
Trabajo académico y prototipo para operadores/ICBF; posible venta posterior. 2 desarrolladores. Marca propia por crear. Diego define el modelo de negocio; los agentes desarrollan.

## Volumen estimado
- 35 hogares en Florencia, 5 a 6 NNA por hogar: 175 a 210 NNA simultáneos.
- Estancia promedio 6 meses: 350 a 420 ingresos por año.
- Unos 100 archivos por NNA (pueden ser más): 35 000 a 42 000 documentos por año.
- Capacidad objetivo: 1000 usuarios simultáneos.

## Módulos (12 + 3 transversales)
1 Autenticación y Accesos, 2 Zonas y Hogares, 3 Madres Sustitutas, 4 Profesionales, 5 Menores y Expedientes, 6 Asignaciones y Traslados, 7 Gestión Documental, 8 Inventario del Hogar, 9 Control de Alimentos, 10 Citas y Recordatorios, 11 Alertas y Evasiones, 12 Reportes. Transversales: Asistente de IA, Auditoría, Archivo y Cierre. Detalle en `docs/modulos.md`.

## Reglas de negocio acordadas
- El defensor y los demás profesionales ven solo los NNA que tienen asignados, en un panel propio (menores por hogar y zona, alertas, documentos por revisar, próximas citas). El coordinador ve su zona. No hay módulo aparte por rol: es una vista distinta del mismo sistema.
- El profesional encargado de cada NNA define qué parte del expediente ve cada persona. Datos sensibles solo para profesionales y la madre asignada si el profesional lo habilita.
- La madre crea los documentos; los profesionales revisan y aprueban. La madre carga su firma una sola vez; cada persona responde por la validez de su firma.
- Citas: el sistema no las asigna, solo recuerda (médicas, psicosociales, reuniones con familia biológica).
- Evasión: al registrar el reporte, la alerta llega por la aplicación al defensor y a la profesional psicosocial asignados, y la misma pantalla muestra los números de emergencia (Policía de Infancia y Adolescencia, defensor, psicosocial). Se registra quién la recibió y cuándo la vio. Aviso adicional por notificación al celular o SMS, a evaluar. El "módulo de evaluaciones" mencionado en la llamada se interpreta como este módulo de alertas.
- Reportes: generales, por zona, por NNA y por madre.
- Cuando el NNA sale del hogar, el expediente se oculta a la madre; nunca se elimina. Al cierre se archiva y se envía a un destino aún no definido.

## Requisitos funcionales
RF1 Expedientes por NNA y hogar con asignación (inicio y fin). RF2 Carga multiformato (papel digitalizado, PDF, Word/Excel, fotos del celular). RF3 Versionado e historial. RF4 Flujo madre crea, profesional revisa y aprueba o devuelve. RF5 Firma única cargada por la madre. RF6 Permisos por expediente. RF7 Ocultar expediente a la madre al salir el NNA. RF8 Archivo y envío al cierre. RF9 Alertas: visitas vencidas, documentos faltantes, citas médicas, visitas y evasiones. RF10 Migración del historial físico. RF11 Auditoría de todo acceso. RF12 IA: búsqueda en lenguaje natural, resumen, clasificación al cargar, OCR, faltantes e inconsistencias, apoyo a la redacción; solo recupera y resume con cita y solo ve lo que el usuario puede ver. RF13 Inventario del hogar. RF14 Control de alimentos. RF15 Recordatorios de citas. RF16 Reportes en cuatro niveles. RF17 Zonas y hogares.

## Requisitos no funcionales
1000 usuarios simultáneos; Android y computador; alfabetización digital baja a media; baja visión; lectura asistida opcional; conectividad buena; respaldos diarios (a evaluar); caídas tolerables y pérdida de datos no tolerable; autenticación usuario y contraseña con JWT; leyes colombianas de datos; solo datos sintéticos en desarrollo; éxito medido por tiempo de búsqueda, reducción de papel y tiempo de revisión.

## Arquitectura
Backend: monolito modular de un solo despliegue (ADR-0001), cuatro capas: aplicación (FastAPI), dominio, persistencia (PostgreSQL con pgvector, Apache Jena Fuseki), con módulos que se comunican solo por la capa de aplicación. Diagrama: `Contexto/arquitectura.jpeg`.
Frontend: Angular, desacoplado del backend (ADR-0005). Se compila a archivos estáticos servidos por Nginx y se despliega solo, sin tumbar el backend. Carga diferida por módulo. Configuración (dirección de la API) leída en tiempo de ejecución desde `config.json`.
Contrato: API versionada bajo `/api/v1` y especificación OpenAPI (`backend/openapi.json`); el frontend genera sus tipos desde ese archivo. Un cambio de endpoint incompatible requiere versión nueva.
Despliegue: VPS propio; demostración local con `docker-compose.yml`.

## Estructura de repositorios
```
Carpeta_Viva/          repositorio de gobierno (este)
  CLAUDE.md, CUESTIONARIO.md, Contexto/, docs/, ontologia/
  .claude/agents/      agentes
  infra/               nginx y scripts de PostgreSQL
  docker-compose.yml, .env.example
  scripts/bootstrap.*  clona o inicializa backend y frontend
  backend/             repositorio propio (ignorado aquí)
  frontend/            repositorio propio (ignorado aquí)
```
Carpeta_Viva no lleva código de aplicación. Backend y frontend están en `.gitignore` de Carpeta_Viva y se clonan aparte con `scripts/bootstrap`. La sesión de Claude Code se abre en Carpeta_Viva para ver los tres. Cada repositorio tiene su `CLAUDE.md` corto que apunta a este. Los cambios que cruzan repositorios (endpoint nuevo) se anotan en `docs/adr/`.

## Web semántica
- Ontología núcleo de 8 clases: Menor, MadreSustituta, HogarSustituto, Zona, Asignacion, Profesional, Reporte, Documento (`ontologia/core.ttl`, ADR-0006). Inventario, alimentos y citas quedan en PostgreSQL por ahora.
- Fuseki guarda identificadores y relaciones, nunca contenido sensible en texto.
- La IA es un módulo aparte. Consulta el grafo por la capa de aplicación (nunca directo) para que los permisos siempre se apliquen; el contenido de texto libre lo resuelven los embeddings.
- Más adelante, reglas en la ontología (por ejemplo, sin informe psicosocial en 60 días, alerta de documento faltante).
- Graphify (`uv tool install graphifyy`, `graphify install --project`, `/graphify .`, `graphify update .`) es el grafo de contexto para desarrollar. No reemplaza a Fuseki. Solo sobre código, documentos de diseño y datos sintéticos.

## Agentes y modelos
| Agente | Modelo | Uso |
|---|---|---|
| arquitecto | sonnet, esfuerzo alto | Diseño, ADR, coordinación, contratos entre repositorios |
| seguridad | sonnet, esfuerzo alto | Amenazas, privacidad, cumplimiento |
| ux-ui | sonnet | Flujos, pantallas, accesibilidad |
| test | haiku | Pruebas, ejecución y correcciones rápidas |
| backend | sonnet | FastAPI, módulos, repositorios, auditoría, OpenAPI |
| frontend | sonnet | Angular, vistas por rol, cliente generado desde OpenAPI |
| datos-infra | sonnet | PostgreSQL, Fuseki, archivos, respaldos, Docker, VPS |
| ia | sonnet, esfuerzo alto | OCR, embeddings, RAG con citas |

Enrutamiento
- Sesión principal: sonnet con esfuerzo alto para pensar y decidir.
- Tareas complejas: sonnet. Trabajo rápido y correcciones puntuales: haiku. Si haiku falla dos veces, escalar a sonnet.
- Agentes independientes trabajan en paralelo (backend y frontend). Las migraciones de base de datos terminan antes del código que las usa.
- Todo cambio que toque datos de menores pasa por seguridad.

## Puntos abiertos
1. Destino y formato del archivo final del expediente.
2. Tabla de retención documental y base legal para datos de menores.
3. IA externa: anonimizado por defecto, datos reales solo con contrato (ADR-0002).
4. Datos en nube pública y posible transferencia internacional (Ley 1581).
5. Valor legal de la firma cargada como imagen.
6. Segundo factor para profesionales; hoy solo usuario y contraseña.
7. Aviso adicional de evasión (notificación al celular o SMS) y su costo.
8. Sin GPU declarada: IA por API. Sin integraciones externas por ahora. Presupuesto sin definir.
9. Sin profesionales disponibles para pruebas de usuario.
10. URLs de los repositorios remotos de backend y frontend.

## Reglas del proyecto
- Nunca datos reales de menores en desarrollo ni pruebas.
- Toda decisión de arquitectura en `docs/adr/NNNN-titulo.md`.
- Ningún secreto en repositorios; `.env` no se versiona.
- Respuestas breves y en español; sin emojis; íconos SVG.
