# Módulos

Doce módulos de negocio y tres transversales. Una carpeta por módulo en `backend/app/modules/` y en `frontend/src/app/modules/`.

| # | Módulo | Qué hace | Fase |
|---|---|---|---|
| 1 | Autenticación y Accesos | Inicio de sesión con JWT, roles y permisos por expediente y por zona. | 1 |
| 2 | Zonas y Hogares | Organiza los hogares sustitutos por zona y guarda los datos de cada hogar (capacidad, habilitación). | 1 |
| 3 | Madres Sustitutas | Perfil, habilitación, capacitaciones con vencimiento y firma que se carga una sola vez. | 1 |
| 4 | Profesionales | Quién es el defensor, el psicosocial y el nutricionista de cada menor. De aquí salen los permisos y los destinatarios de alertas. | 1 |
| 5 | Menores y Expedientes | Carpeta digital de cada menor: datos personales, información de padre y madre, historial médico y psicosocial, estado. | 2 |
| 6 | Asignaciones y Traslados | Vincula al menor con el hogar con fecha de inicio y fin; registra actas de traslado. | 2 |
| 7 | Gestión Documental | Carga en cualquier formato, clasificación, versionado y flujo de revisión: la madre crea, el profesional revisa y aprueba. | 3 |
| 8 | Inventario del Hogar | Camas, muebles, personas que viven en el hogar y red de apoyo. | 4 |
| 9 | Control de Alimentos | Fecha de ingreso de cada mercado, si es perecedero y fecha de vencimiento. | 4 |
| 10 | Citas y Recordatorios | Avisa de citas médicas, psicosociales y reuniones con familia biológica. No asigna citas. | 4 |
| 11 | Alertas y Evasiones | Registra el reporte de evasión, notifica al defensor y a la psicosocial asignados, muestra los números de emergencia y guarda quién recibió y vio la alerta. Alertas de visitas vencidas y documentos faltantes. | 4 |
| 12 | Reportes | Generales, por zona, por menor y por madre. | 5 |
| T1 | Asistente de IA | Busca, resume y clasifica con citas; OCR; consulta solo por la capa de aplicación. | 5 |
| T2 | Auditoría | Registra todo acceso a expedientes y los eventos de sesión. Desde la fase 1. | 1 |
| T3 | Archivo y Cierre | Archiva el expediente al cierre y lo exporta al destino por definir. | 5 |

## Vistas por rol (no hay módulo aparte)
- Madre: sus NNA asignados, documentos propios, inventario, alimentos, citas, alertas.
- Profesional y defensor: panel con los NNA a su cargo agrupados por hogar y zona, alertas pendientes, documentos por revisar y próximas citas.
- Coordinador: lo mismo para su zona, más administración de hogares, madres y profesionales.
- Auditor: auditoría, documentos y reportes en solo lectura.
La visibilidad actual en `frontend/src/app/core/navegacion.ts` es provisional.
