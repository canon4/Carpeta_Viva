# Metodología de desarrollo: entregables por fase

Proyecto: sistema de gestión documental para hogares sustitutos (Carpeta Viva).
Equipo: Diego Cañón y Dina Herrera. Fecha: 17-11-2026.
Enfoque híbrido Cascada + Kanban: cada fase tiene una puerta de calidad (no se avanza sin aprobar la anterior) y el trabajo de cada fase fluye por un tablero con límite de una tarea activa por persona.

Alcance de esta entrega: fases 1 a 5. La fase 6 (despliegue) tiene documentos de avance, pero queda fuera de esta entrega. No se usa Postman: las pruebas de integración se automatizan con pytest.

Estado: **Hecho** (entregable completo y verificado contra el código), **Parcial** (existe con pendientes declarados), **Pendiente**. En las fases 1 a 3 el estado se refiere al documento; en las fases 4 y 5, a la implementación y las pruebas.

Donde faltaba información del operador, del ICBF o jurídica, los requisitos se completan con supuestos documentados en [supuestos.md](01-requisitos/supuestos.md), a validar antes de usar datos reales.

## Tabla de la metodología

| N° | Fase | Paso | Entregable | Herramienta | Estado |
|---|---|---|---|---|---|
| 1 | Levantamiento de requisitos | Entrevistas y análisis de formatos actuales | [analisis-formatos-actuales.md](01-requisitos/analisis-formatos-actuales.md), `CUESTIONARIO.md`, [supuestos.md](01-requisitos/supuestos.md) | Google Forms / Docs | Hecho (perfiles y entrevistas simuladas por falta de profesionales, S01; guion listo para madres) |
| | | Requisitos funcionales | [requisitos-funcionales.md](01-requisitos/requisitos-funcionales.md) | Google Docs | Hecho |
| | | Requisitos no funcionales | [requisitos-no-funcionales.md](01-requisitos/requisitos-no-funcionales.md) | Google Docs | Hecho |
| | | Reglas de negocio e historias de usuario | [reglas-de-negocio.md](01-requisitos/reglas-de-negocio.md), [historias-de-usuario.md](01-requisitos/historias-de-usuario.md), [matriz-trazabilidad.md](01-requisitos/matriz-trazabilidad.md) | Trello | Hecho (44 reglas, 90 historias en 17 épicas, 92 requisitos funcionales) |
| 2 | Diseño de la arquitectura | Estructura general | [estructura-general.md](02-arquitectura/estructura-general.md), ADR-0001, 0005 | Visual Paradigm | Hecho |
| | | Estrategia de almacenamiento | [estrategia-almacenamiento.md](02-arquitectura/estrategia-almacenamiento.md), ADR-0003, 0008 | Visual Paradigm | Hecho |
| | | Diagramas de componentes y contenedores | [diagramas-c4.md](02-arquitectura/diagramas-c4.md) | Visual Paradigm (Mermaid) | Hecho |
| | | Fronteras lógicas entre módulos | [fronteras-modulos.md](02-arquitectura/fronteras-modulos.md) | Visual Paradigm | Hecho |
| 3 | Diseño lógico y físico | Modelo entidad-relación y normalización | [modelo-er.md](03-diseno/modelo-er.md), [modelo-er.dbml](03-diseno/modelo-er.dbml) | dbdiagram.io | Hecho |
| | | Script de base de datos | [script-bd.sql](03-diseno/script-bd.sql) | dbdiagram.io / PostgreSQL | Hecho |
| | | Diagrama de clases | [diagrama-clases.md](03-diseno/diagrama-clases.md) | Visual Paradigm (Mermaid) | Hecho |
| | | Bocetos de pantalla y rutas de conexión | [pantallas.md](03-diseno/pantallas.md), [rutas-api.md](03-diseno/rutas-api.md), `docs/ux/brief-google-stitch.md` | Figma / Google Stitch | Hecho |
| 4 | Desarrollo | Entorno y repositorio por módulos | [entorno-y-repositorio.md](04-desarrollo/entorno-y-repositorio.md) | VS Code, Git y GitHub, Docker | Hecho |
| | | Lógica de negocio por módulo | [logica-por-modulo.md](04-desarrollo/logica-por-modulo.md) | VS Code | Parcial (63 de 90 historias implementadas; 12 parciales y 15 pendientes) |
| | | Control de acceso | [control-de-acceso.md](04-desarrollo/control-de-acceso.md) | VS Code | Parcial (2FA, profesionales sin zona, cifrado en base; ver ADR-0016) |
| | | Revisión cruzada | [revision-cruzada.md](04-desarrollo/revision-cruzada.md) | GitHub | Hecho |
| 5 | Pruebas e integración | Pruebas unitarias por módulo | [plan-de-pruebas.md](05-pruebas/plan-de-pruebas.md) | pytest, Vitest | Parcial (backend 217/218, frontend 18/19 al 17-11-2026) |
| | | Pruebas de integración | [plan-de-pruebas.md](05-pruebas/plan-de-pruebas.md) sección 5 | pytest y `TestClient` | Parcial (falta PostgreSQL real) |
| | | Validación de seguridad | [plan-de-pruebas.md](05-pruebas/plan-de-pruebas.md) sección 6 | pytest | Parcial |
| | | Corrección de errores | [plan-de-pruebas.md](05-pruebas/plan-de-pruebas.md) | GitHub Issues, Dokploy | Hecho |
| 6 | Despliegue | Paquetes de producción | [paquetes-y-servidor.md](06-despliegue/paquetes-y-servidor.md) | Docker Compose | Fuera de esta entrega |
| | | Configurar servidor y poner en marcha | [paquetes-y-servidor.md](06-despliegue/paquetes-y-servidor.md), ADR-0012 | Hostinger, Dokploy, GitHub Actions | Fuera de esta entrega |
| | | Manual de instalación y de usuario | [manual-instalacion.md](06-despliegue/manual-instalacion.md), [manual-usuario.md](06-despliegue/manual-usuario.md) | Google Docs | Fuera de esta entrega |
| | | Monitoreo y correcciones | [monitoreo.md](06-despliegue/monitoreo.md) | Dokploy | Fuera de esta entrega |

## Tablero Kanban y puertas de calidad
| Columna | Entra cuando | Puerta de calidad (Cascada) |
|---|---|---|
| Pendiente | Hay una historia de usuario | - |
| Requisitos listos | Tiene criterios de aceptación y RF asociado | Ambos integrantes entienden objetivo y criterios |
| Diseño aprobado | Tiene ADR o diagrama aprobado si cambia datos, contrato o arquitectura | Revisión de arquitectura; seguridad si toca datos de menores |
| En desarrollo | WIP 1 por persona | Prohibido iniciar sin diseño aprobado |
| En revisión cruzada | Pull request abierto | Lista de `revision-cruzada.md` |
| Probado | El compañero probó y la suite pasa | No rompe otros módulos |
| Desplegado | Fusionado en `main` y desplegado | Checklist posdespliegue de `monitoreo.md` |

## Correspondencia con el plan del proyecto
Las cinco fases de construcción de `docs/plan-por-fases.md` (base de permisos, menores, documental, alertas y vida del hogar, IA y cierre) recorren cada una las fases 2 a 5 de esta metodología, por incrementos de módulos.

## Puntos abiertos que afectan los entregables
Los 10 de `CLAUDE.md`: destino del archivo final, tabla de retención y base legal, IA con datos reales, nube y transferencia internacional, valor legal de la firma, segundo factor, aviso por SMS, presupuesto y GPU, profesionales para pruebas y URLs de repositorios (resuelto).
