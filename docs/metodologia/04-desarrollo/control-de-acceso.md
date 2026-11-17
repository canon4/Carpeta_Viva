# Control de acceso a los documentos

Fase 4, paso 3: "Programar el control de acceso para proteger los documentos". Fuentes: ADR-0004, 0007, 0008, 0009, 0010, 0013, 0014, 0015 y el código de `backend/app` (`core/deps.py` y la capa `application` de cada módulo). Revisión de seguridad del 17-11-2026: la matriz de la sección 4 se verificó celda por celda contra el código; donde el código y las ADR no coinciden se indica y se lista en la sección 6.

## 1. Tres capas
1. **Autenticación** (`core/deps.py::usuario_actual`): token JWT válido, no vencido y usuario activo; si no, 401. El rol se lee de la base, no del token.
2. **Rol** (`requiere_roles(...)`): solo en rutas administrativas: zonas y hogares, madres y profesionales (coordinador o admin), auditoría (auditor o admin) y escritura de configuración (admin).
3. **Relación con el recurso** (capa `application`): se evalúa fila por fila y sección por sección. Denegar por defecto.

Las escrituras y las lecturas de expedientes, documentos, alertas, citas, inventario y alimentos, permitidas o denegadas, se registran con `core/audit.py::registrar_acceso`. No se registran: el listado de menores, las lecturas de zonas, hogares, madres y profesionales, ni la IP (solo el login la guarda). Ver sección 6.

## 2. Funciones de autorización reutilizadas
| Función | Módulo | Devuelve verdadero si |
|---|---|---|
| `puede_ver_menor` | menores | Profesional o defensor asignado; madre con asignación vigente en su hogar; coordinador de la zona del hogar vigente (sin asignación vigente no ve al NNA); admin; auditor (recibe los datos básicos completos, incluidos nombres y número de documento) |
| `tiene_permiso_seccion` | menores | Profesional o defensor asignado; madre con permiso activo de esa sección otorgado por el defensor. Coordinador, auditor y admin: siempre falso |
| `es_defensor_asignado` | profesionales | El profesional del usuario tiene `cargo = defensor` y está asignado al NNA (se evalúa el cargo, no el rol del usuario) |
| `puede_ver_hogar` | zonas_hogares | Admin y auditor; coordinador de la zona del hogar; madre del hogar; profesional o defensor con algún NNA cuya asignación vigente es ese hogar |
| `puede_gestionar_hogar` | zonas_hogares | Igual que `puede_ver_hogar` sin el auditor. Incluye a profesionales y defensores (hallazgo 2) |
| `esta_archivado` / `autorizado_para_ver_archivado` | archivo | Expediente cerrado: solo lectura. Verlo: coordinador de la zona del expediente, admin, auditor (metadatos) |
| `puede_ver_notas` | citas | Permiso de la sección asociada al tipo de cita; el tipo `otro` no tiene sección y sus notas las ve quien vea la cita |

El control de las rutas de `/zonas-hogares` es solo por rol. `puede_ver_hogar` y `puede_gestionar_hogar` se usan en inventario y alimentos, no en esas rutas.

## 3. Secciones del expediente
| Sección | Categorías documentales y datos | Quién la ve |
|---|---|---|
| Básica | identidad, educación, actas y traslados, otros, datos personales, estado | Quien pase `puede_ver_menor` (el auditor no recibe bytes de archivo) |
| familia | familiares, `familia_red_apoyo`, informes de trabajo social, citas `reunion_familia` | Profesionales y defensor asignados; madre con permiso |
| salud | categoría `salud`, informes médicos y de nutrición, citas `medica` | Profesionales y defensor asignados; madre con permiso |
| psicosocial | categoría `psicosocial`, informes psicosociales, citas `psicosocial` | Profesionales y defensor asignados; madre con permiso |

Un valor de catálogo nuevo sin sección asignada queda en "básica" solo si el admin declara `seccion_acceso` explícitamente al crearlo (ADR-0013 §5.1).

## 4. Matriz de permisos por rol (verificada contra el código)
L: lee; E: escribe; -: sin acceso. "Propios": relación vigente con el NNA u hogar. "Defensor" es el usuario con rol defensor; ver la nota bajo la tabla.

| Recurso | Madre | Profesional | Defensor | Coordinador | Auditor | Admin |
|---|---|---|---|---|---|---|
| Zonas y hogares (`/zonas-hogares`) | - (su hogar sale en `/madres/yo`) | - | - | L/E de todas las zonas (hallazgo 1) | - | L/E |
| Madres y profesionales (perfiles) | L su perfil; E su firma | - | - | L/E de todos (sin filtro de zona, hallazgo 1) | - | L/E |
| Expediente básico (datos personales, estado) | L propios | L/E propios | L/E propios | L/E su zona | L (incluye nombres y documento) | L/E |
| Historial de cambios del expediente | - | L propios | L propios | L su zona | L | L |
| Secciones sensibles | L con permiso | L/E propios | L/E propios | - (solo crea familiares, hallazgo 9) | - | - (solo crea familiares y lista permisos) |
| Permisos de sección a la madre | L si tiene permiso de familia | L propios | E propios (si su cargo es defensor) | - | - | L |
| Asignaciones y traslados | L vigentes propias | L propios | L/E propios | L su zona; E si el hogar de destino o el de la asignación es de su zona (hallazgo 8) | L | L/E |
| Crear documento del NNA | E propios (borrador; con permiso si es sensible) | E propios (queda aprobado) | E propios (queda aprobado) | E solo migración con motivo (aprobado) | - | E solo migración con motivo (aprobado) |
| Crear documento del hogar | E su hogar (borrador) | - | - | E su zona (aprobado) | - | E (aprobado) |
| Aprobar o devolver | - | E propios | E propios | - | - | - |
| Contenido de archivos | L propios; sensibles con permiso | L propios | L propios | L su zona, solo básica y documentos de hogar | - (nunca bytes) | L básica y de hogar; sensibles: - |
| Metadatos de documentos | L propios | L propios | L propios | L su zona, solo básica | L no sensibles | L no sensibles |
| Informes profesionales (reportes de expediente) | L con permiso de sección | L/E propios | L/E propios | L si es de sección básica | L si es de sección básica | L si es de sección básica |
| Inventario: pedido (crear o editar tipo y cantidad) | - | - | - | E su zona | - | E |
| Inventario: ítems existentes y estado | E su hogar | E con NNA en el hogar (hallazgo 2) | E con NNA en el hogar (hallazgo 2) | L/E su zona (puede cambiar el estado, hallazgo 2) | L | E |
| Inventario: confirmar recepción | E su hogar | - | - | - | - | E |
| Inventario: fotos | E su hogar; L | - | - | - | L (bytes; ADR-0014 §2.1) | L/E; oculta |
| Convivientes y red de apoyo | L/E su hogar | L/E con NNA en el hogar (hallazgo 2) | L/E con NNA en el hogar (hallazgo 2) | L/E su zona | L | L/E |
| Alimentos | L/E su hogar | L | L | L su zona | L | L/E |
| Citas médicas, psicosociales y otras | L/E propios | L | L | L | L (notas de `otro` visibles) | L/E |
| Citas reunión con familia | L | L | L/E propios | L | L | L/E |
| Reportar evasión | E propios | E propios | E propios | E su zona | - | E |
| Ver alerta, marcar vista | Destinatario o quien la generó | Destinatario o quien la generó | Destinatario o quien la generó | L su zona | L sin descripción ni detalle | L |
| Cerrar alerta | Si la generó (a confirmar, hallazgo 10) | Asignado o quien la generó | Asignado o quien la generó | E su zona | - | E |
| Reportes (cuatro niveles) | Su madre y los NNA que ve | NNA propios | NNA propios | General y zona: la suya; madre de su zona; NNA de su zona | Agregados; sin descarga | Todos |
| Asistente de IA: consultar y resumir | Lo que puede ver | Lo que puede ver; apoyo a la redacción | Lo que puede ver; apoyo a la redacción | Lo que puede ver (sin secciones sensibles) | Consulta denegada; resumen de documento posible (hallazgo 3) | Lo que puede ver (sin secciones sensibles) |
| Asistente de IA: historial | El propio | El propio | El propio | El propio | Metadatos de todos | Todo, con preguntas y respuestas de otros (hallazgo 11) |
| Auditoría (`/auditoria`) | - | - | - | - | L | L |
| Archivo: cerrar | - | - | - | E su zona | - | E |
| Archivo: estado | - | - | - | L su zona | L | L |
| Archivo: listado de archivados | - | - | - | L su zona | - | L |
| Archivo: paquete | - | - | - | L su zona, con secciones sensibles (hallazgo 12) | - | L, con secciones sensibles |
| Configuración | L catálogos activos | L catálogos activos | L catálogos activos | L catálogos activos | L catálogos activos | L/E |

Nota sobre defensor: otorgar permisos, crear o cerrar asignaciones y crear NNA exigen `cargo = defensor` en el perfil del profesional; las citas de reunión con familia exigen `rol = defensor` en el usuario. El sistema no valida que rol y cargo coincidan (hallazgo 13).

## 5. Reglas que cierran canales laterales
- Cerrar una asignación revoca los permisos de la madre (ADR-0007 §2.6). El código lo hace con un `commit` intermedio, no en una sola transacción (hallazgo 14).
- El auditor nunca recibe bytes de documentos (`/contenido`, versiones y paquete) ni de informes exportados (ADR-0008 §4). Excepción decidida en ADR-0014 §2.1: puede leer las fotos de inventario. Es una excepción al criterio de ADR-0007 §3 y conviene ratificarla.
- El historial de la IA de un usuario y los reportes exportados revalidan permisos al leer o descargar (ADR-0010). El admin lee el historial sin revalidar (hallazgo 11).
- Las notas de las citas se ocultan sin permiso de sección (ADR-0009 §2), salvo el tipo `otro`.
- El expediente archivado no admite escritura: documentos, versiones, informes, citas y alertas nuevas (ADR-0010 §3.2). Las escrituras de inventario, alimentos y datos del NNA no dependen del expediente.
- Las fotos de inventario exigen declaración de que no muestran a los NNA y el admin puede ocultarlas (ADR-0014 §2.1).
- Las descargas de documentos llevan `X-Content-Type-Options: nosniff` y `Cache-Control: no-store`.

## 6. Diferencias entre el código y las ADR o esta matriz (detectadas el 17-11-2026)
La matriz describe el comportamiento previo a ADR-0016. Corregidos por ADR-0016: hallazgo 1 (zonas, hogares y madres; profesionales sigue abierto), 3, 4, 8 y, de 15, el trigger de solo inserción y el `login_fallido` sin correo escrito. El resto requiere decisión:
1. **Coordinador sin filtro de zona (alto).** `/zonas-hogares`, `/madres` y `/profesionales` solo exigen rol coordinador o admin: cualquier coordinador lista y modifica todas las zonas, hogares, madres y profesionales. Además `PUT /hogares/{id}` permite cambiar `madre_id` de un hogar de otra zona, lo que da a esa madre acceso a los NNA del hogar. Contradice ADR-0007 §2.2 y RN03.
2. **Escritura de profesionales en inventario (medio).** `puede_gestionar_hogar` deja a profesionales y defensores con un NNA en el hogar crear ítems (nacen como recibidos), cambiar el estado físico, y escribir convivientes y red de apoyo. El coordinador también puede cambiar el estado de un ítem. ADR-0015 limitó alimentos y citas, no inventario. Hay una prueba que da por bueno el permiso del profesional.
3. **Auditor y resumen de IA de un documento (medio).** `GET /ia/documentos/{id}/resumen` no excluye al auditor: obtiene un resumen del contenido de documentos no sensibles y de hogar, contra ADR-0007 §3 y ADR-0008 §4.
4. **Tipo de archivo (alto).** `POST /documentos` y `/version` no validan el tipo: aceptan cualquier `content_type` declarado, solo se controla el tamaño. Inventario valida el tipo declarado, no los bytes. Se necesita lista de tipos permitidos y validación por firma (bytes).
5. **Documento de hogar sin revisor (medio).** Un documento de hogar enviado por la madre queda en revisión sin revisor posible (`_puede_revisar` exige `menor_id`).
6. **Sin endpoint de asignación de profesionales (alto de funcionalidad).** `menores_profesionales` solo se llena por semilla o base de datos. Tampoco hay fin de asignación: un profesional conserva acceso al NNA indefinidamente.
7. **Texto claro en la base (alto).** `fragmentos_documento.texto`, `reportes.contenido`, `ia_consultas.pregunta` y `respuesta`, `familiares` y `madres_sustitutas.firma_ref` quedan sin cifrar; el cifrado en reposo cubre solo archivos. `firma_ref` es una cadena libre, se puede reemplazar sin límite y no se aplica a los documentos.
8. **Traslado entre zonas (medio).** Al crear un traslado solo se valida la zona del hogar de destino: un coordinador puede trasladar a su zona un NNA de otra zona y pasar a verlo.
9. **Coordinador y admin crean familiares (bajo).** `crear_familiar` los permite aunque no pueden leer la sección familia.
10. **Cierre de alerta por quien la generó (bajo).** La madre que reporta una evasión puede cerrarla. Confirmar con el operador.
11. **Historial de IA para admin (medio).** El admin ve preguntas y respuestas completas de todos los usuarios, incluidas respuestas con contenido de secciones sensibles que él no puede leer. Debería ver solo metadatos, como el auditor.
12. **Paquete de archivo con secciones sensibles (decisión a ratificar).** Coordinador de la zona y admin descargan el paquete con todos los documentos descifrados, incluidos los sensibles (ADR-0010 §3.2 y §3.5). Está en tensión con ADR-0007 §2.2. Requiere decisión de seguridad y validación jurídica.
13. **Rol y cargo no validados (bajo).** Un usuario con rol `profesional` y cargo `defensor` otorga permisos; uno con rol `defensor` y otro cargo no.
14. **Revocación de permisos sin transacción única (bajo).** `revocar_permisos_de_usuario` hace `commit` intermedio; un fallo posterior puede dejar un traslado sin asignación nueva.
15. **Auditoría de solo inserción solo por convención (alto).** Sin trigger ni permisos de base de datos que impidan `UPDATE` y `DELETE`. Faltan registros de lecturas de listados, de zonas, hogares, madres y profesionales, e IP fuera del login. `login_fallido` guarda el correo escrito, que puede contener una contraseña mal digitada.
16. **Auditor lee datos básicos completos (a ratificar).** Recibe nombres, fecha de nacimiento y número de documento, y asignaciones con motivo. ADR-0007 §3 habla de metadatos. Aplicar minimización o ratificar la lectura.
17. **Documentos sensibles invisibles al auditor.** ADR-0007 §3 le da metadatos de documentos sensibles; el código se los oculta (`GET /documentos/auditor` excluye `sensible`). Es más restrictivo que la ADR.

## 7. Pendientes de seguridad
- En el frontend solo `/configuracion` tiene `rolGuard`; las demás rutas dependen del menú y del 403 del backend (el backend es la barrera real).
- Cambio de contraseña, bloqueo por intentos, revocación de tokens y segundo factor (HU03, HU04, punto abierto 6). Hoy: JWT de 60 minutos sin revocación.
- Un NNA existente sin permiso responde 403 y uno inexistente 404 (permite saber qué identificadores existen); evaluar responder 404 en ambos casos.
- Validación jurídica de que el defensor es quien autoriza a la madre (ADR-0007 §2.5).
- Rotación de `ARCHIVOS_CLAVE_MAESTRA` (ADR-0008 §1). Las fotos de inventario y los informes exportados se guardan cifrados pero se leen sin verificar hash.
- Anonimización de la IA: ver RNF14.
