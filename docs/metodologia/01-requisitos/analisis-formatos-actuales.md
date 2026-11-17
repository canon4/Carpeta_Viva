# Análisis de la situación actual y formatos documentales

Fase 1, paso 1: "Realizar entrevistas a los usuarios y analizar los formatos físicos y documentales actuales".
Fuentes: `CUESTIONARIO.md`, `docs/registro-decisiones-2026-10-29.md`, `Contexto/` y `docs/datos-sinteticos/` (solo datos sintéticos).

## 1. Contexto del proceso
- El ICBF restablece los derechos de los NNA (niños, niñas y adolescentes) y contrata un operador por municipio. En Florencia el operador es la Fundación Fundar.
- El operador tiene afiliadas a las madres sustitutas (voluntarias). Cada hogar tiene una madre; la norma permite hasta 13 NNA, en la práctica 5 o 6.
- Los hogares se agrupan en zonas; un coordinador administra cada zona.
- Cada NNA tiene un equipo: defensor de familia y profesionales (psicosocial, nutrición, trabajo social).

## 2. Cómo se trabaja hoy (sistema físico)
| Aspecto | Situación actual | Problema |
|---|---|---|
| Expediente del NNA | Carpeta física por NNA en el hogar o en la oficina del operador | Búsqueda lenta, riesgo de pérdida, sin copia |
| Flujo de revisión | La madre elabora el documento y el profesional lo revisa en visita | Sin trazabilidad de quién revisó ni cuándo |
| Firma | Firma manuscrita en cada documento | Repetitiva; sin registro centralizado |
| Traslados | Acta física; la carpeta viaja con el NNA | La madre anterior conserva copia de datos que ya no le corresponden |
| Alertas (evasión, citas) | Llamadas telefónicas | Sin registro de quién recibió el aviso ni cuándo |
| Inventario y alimentos | Cuadernos o planillas Excel de la madre | Sin consolidado por zona; vencimientos no controlados |
| Cierre del caso | Carpeta se archiva y se envía a un destino no definido | Sin paquete verificable |

## 3. Inventario de formatos analizados
Los 20 archivos de `docs/datos-sinteticos/` reproducen, con datos ficticios, los formatos que circulan hoy:

| # | Formato | Tipo de archivo | Contenido | Módulo destino |
|---|---|---|---|---|
| 01 | Reporte diario de la madre | TXT | Novedades del día por NNA | 7 Gestión Documental |
| 02 | Control de alimentos de la despensa | CSV | Producto, ingreso, perecedero, vencimiento | 9 Alimentos |
| 03 | Ficha del NNA del sistema anterior | JSON | Datos personales migrables | 5 Menores (RF10) |
| 04 | Acta de reunión con red de apoyo | MD | Asistentes y acuerdos | 8 Inventario (red de apoyo) |
| 05 | Correo del defensor sobre cita | HTML | Fecha y lugar de cita | 10 Citas |
| 06-07 | Información del padre y de la madre biológicos | DOCX | Contacto y estado | 5 Menores (sección familia) |
| 08 | Informe psicosocial | DOCX | Valoración profesional | 7 Documentos (sección psicosocial) |
| 09 | Datos del defensor de familia | DOCX | Contacto del defensor | 4 Profesionales |
| 10 | Reporte mensual de la madre | DOCX | Seguimiento mensual | 7 Documentos |
| 11 | Inventario de camas y muebles | XLSX | Ítem, cantidad, estado | 8 Inventario |
| 12 | Personas del hogar y red de apoyo | XLSX | Convivientes y contactos | 8 Inventario |
| 13 | Citas y recordatorios | XLSX | Tipo, fecha, lugar | 10 Citas |
| 14 | NNA por hogar y zona | XLSX | Asignaciones vigentes | 2 Zonas, 6 Asignaciones |
| 15 | Alertas y evasiones | XLSX | Fecha, NNA, quién fue avisado | 11 Alertas |
| 16 | Ficha de identificación del NNA | PDF | Datos de identidad | 5 Menores |
| 17 | Registro civil de nacimiento | PDF escaneado | Documento de identidad | 7 Documentos (identidad) |
| 18 | Historia médica resumida | PDF | Antecedentes de salud | 7 Documentos (salud) |
| 19 | Acta de traslado | PDF | Hogar origen, destino, motivo | 6 Asignaciones |
| 20 | Certificado escolar | PDF | Matrícula y grado | 7 Documentos (educación) |

Conclusión: los formatos llegan en papel, PDF escaneado, PDF con texto, Word, Excel y fotos del celular (`CUESTIONARIO.md` B2). Esto origina RF2 (carga multiformato), RF10 (migración) y el uso de OCR (RF12).

## 4. Actores y necesidades (entrevistas)
| Actor | Necesidad principal | Fuente |
|---|---|---|
| Madre sustituta | Registrar documentos y novedades desde el celular sin pasos complejos | Cuestionario C3, G1, G2 |
| Profesional (psicosocial, nutrición, trabajo social) | Revisar y aprobar documentos de sus NNA en un solo panel | Cuestionario C3, registro 8 |
| Defensor de familia | Ver solo sus NNA, decidir qué ve la madre, recibir alertas de evasión | Cuestionario E4, registro 7-8 |
| Coordinador de zona | Ver su zona, administrar hogares, madres y profesionales | `docs/modulos.md` |
| Auditor | Trazabilidad de accesos sin ver contenido sensible | Cuestionario E5, ADR-0007 |
| Administrador | Configurar catálogos y parámetros sin redesplegar | ADR-0013 |
| Indirectos: familia biológica, salud, educación | No usan el sistema; son fuente de documentos | `CLAUDE.md` |

## 5. Guiones de entrevista
El cuestionario (`CUESTIONARIO.md`) se respondió con el equipo. No hay profesionales disponibles para entrevistas (punto abierto 9); por eso, según el supuesto S01, sus necesidades se modelan con perfiles y entrevistas simuladas (sección 6). La entrevista a madres sí puede aplicarse.

**Madre sustituta**
1. ¿Qué documentos de cada niño guarda usted y dónde?
2. ¿Cuánto tarda en encontrar un documento cuando se lo piden?
3. ¿Qué documentos elabora usted y quién se los revisa?
4. ¿Qué celular usa y cómo se conecta a internet?
5. ¿Cómo avisa hoy si un niño se evade? ¿A quién llama primero?
6. ¿Cómo lleva el control de la comida y de los muebles?
7. ¿Qué le cuesta más del manejo de papeles?
8. ¿Tiene dificultad para leer letras pequeñas en el celular?

**Profesional y defensor**
1. ¿Cuántos NNA tiene a cargo y en cuántos hogares?
2. ¿Cómo recibe hoy los documentos que elabora la madre y cuánto tarda en revisarlos?
3. ¿Qué documentos son obligatorios por NNA y en qué plazos?
4. ¿Qué información de un NNA no debería ver la madre?
5. ¿Cómo se entera hoy de una evasión y qué hace primero?
6. ¿Qué le pediría a un asistente que busca y resume documentos?

**Coordinador y auditor**
1. ¿Qué información consolida cada mes para el operador o el ICBF?
2. ¿Cómo verifica que las visitas y las citas se cumplieron?
3. ¿Qué evidencia le piden en una auditoría y cómo la reúne hoy?
4. ¿Qué pasa con la carpeta cuando el caso se cierra?

## 6. Perfiles de usuario y entrevistas simuladas (supuesto S01)
Los perfiles son **simulados**: personas ficticias construidas con el cuestionario, el contexto del operador y los datos sintéticos. Sirven para derivar necesidades; no son testimonios reales y se reemplazan cuando haya entrevistas.

| Perfil | Rasgos | Lo que diría en la entrevista | Necesidades que se derivan | Requisitos |
|---|---|---|---|---|
| Rosa, madre sustituta, 52 años | 5 NNA, celular Android de gama baja, lee con dificultad letras pequeñas | "Cuando la profesional pide el registro civil tengo que buscar en la caja de cada niño" | Subir fotos desde el celular, encontrar rápido, letra grande, pocos pasos | RF2.1, RF12.1, RNF15, RNF16 |
| Laura, psicosocial, 31 años | 40 NNA en 8 hogares, revisa en visitas | "Los informes de la madre me llegan cuando voy al hogar; pasan días" | Bandeja de documentos por revisar, aprobar o devolver con motivo, alertas de plazos | RF1.4, RF4.2, RF9.6 |
| Andrés, defensor de familia, 45 años | Responde legalmente por el caso | "La madre no tiene por qué ver la historia psicológica completa" | Decidir qué ve la madre, alerta inmediata de evasión con números a mano | RF6.2, RF9.2, RF9.3 |
| Marta, coordinadora de zona, 40 años | 12 hogares | "Cada mes armo en Excel cuántos niños hay y qué falta" | Panel de zona, reportes, pedidos de inventario, verificación de citas | RF1.5, RF16.2, RF13.1, RF15.2 |
| Jorge, auditor interno, 38 años | Control del proceso | "Necesito saber quién abrió qué expediente, no leer los informes" | Auditoría filtrable, metadatos sin contenido | RF11.2, RF6.4, RF6.5 |
| Sofía, administradora del sistema, 29 años | Soporte del operador | "Cada vez que cambian un teléfono hay que llamar al programador" | Catálogos, parámetros y cuentas sin redesplegar | RF18.1, RF18.2, RF0.6 |

## 7. Línea base y métricas de éxito
Métricas de `CUESTIONARIO.md` H4. La línea base es la estimación del supuesto S02 y se reemplaza por la medición real en la primera visita a los hogares.

| Indicador | Línea base estimada (S02) | Meta (S03) | Cómo se mide |
|---|---|---|---|
| Tiempo de búsqueda de un documento | 15 minutos | Menos de 1 minuto | Cronometrar 10 búsquedas con madres antes y después |
| Tiempo de revisión de un documento | 5 días hábiles | 2 días hábiles o menos | Fechas de envío y aprobación registradas por el sistema |
| Papel por NNA | 100 hojas | 70 % menos a los 3 meses | Conteo de hojas archivadas por mes |
