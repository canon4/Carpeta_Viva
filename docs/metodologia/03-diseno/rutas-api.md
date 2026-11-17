# Rutas de la API

Fuentes: `backend/openapi.json` (contrato), `backend/app/modules/*/api.py` (dependencias de rol), `backend/app/modules/*/application.py` (autorización por fila), ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0013, ADR-0014, ADR-0015, `docs/guia-api.md`. Solo datos sintéticos.

## Cómo leer este documento

- Todas las rutas cuelgan de `/api/v1`; la columna Ruta lo omite.
- `openapi.json` tiene 111 rutas (paths) y 137 operaciones (método más ruta). Las tablas de abajo listan las 137 operaciones, agrupadas por módulo, en el orden del contrato. El conteo por módulo está en cada título.
- Dos niveles de autorización:
  1. Nivel de ruta: el `api.py` exige un rol con `requiere_roles(...)`. Solo ocurre en `zonas_hogares`, `madres`, `profesionales`, `configuracion` y `auditoria`.
  2. Nivel de fila: el resto de las rutas exige solo token válido (`usuario_actual`) y el caso de uso decide por rol y por asignación real (`menores.puede_ver_menor`, `menores.tiene_permiso_seccion`, `zonas_hogares.puede_ver_hogar`). La columna Roles lo describe en lenguaje llano.
- Un acceso no autorizado responde 403, no 404; 401 si falta el token o es inválido; 422 si los datos son inválidos (`docs/guia-api.md`). Casi toda lectura y escritura queda en `auditoria_accesos`, incluidos los intentos denegados (ADR-0008 sección 6).
- Roles: `madre`, `profesional`, `defensor`, `coordinador`, `auditor`, `admin` (`auth/domain.py`). "Profesional o defensor asignado" significa que existe una fila en `menores_profesionales` para ese menor y ese profesional (el cargo no se distingue salvo donde se indique).
- Regla transversal: el `auditor` nunca recibe contenido (archivos, paquetes, informes exportados, texto de consultas de IA); solo metadatos (ADR-0007 punto 3, ADR-0008, ADR-0010).
- RF: requisito funcional de `CLAUDE.md` (RF1 a RF17). "M<n>" indica el módulo de `docs/modulos.md` cuando no hay un RF propio (por ejemplo, la administración de madres y profesionales es soporte de RF1 y RF6).
- "Público" significa sin token. Los diagnósticos `GET /<módulo>/_estado` no son de negocio y no piden autenticación.

Resumen RF de `CLAUDE.md` usado aquí: RF1 expedientes y asignación, RF2 carga multiformato, RF3 versionado e historial, RF4 flujo de revisión, RF5 firma única, RF6 permisos por expediente, RF7 ocultar al salir el NNA, RF8 archivo y envío, RF9 alertas, RF10 migración histórica, RF11 auditoría, RF12 IA, RF13 inventario, RF14 alimentos, RF15 recordatorios de citas, RF16 reportes en cuatro niveles, RF17 zonas y hogares.

## Sistema (1) y Autenticación y Accesos (3)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 1 | GET | `/health` | Estado del servicio (versión) | Público | Operación |
| 2 | POST | `/auth/login` | Iniciar sesión con correo y contraseña; devuelve el JWT y registra el evento de sesión | Público | M1, RF11 |
| 3 | GET | `/auth/me` | Usuario autenticado (correo, rol, zona) | Cualquier autenticado | M1 |
| 4 | GET | `/auth/_estado` | Diagnóstico del módulo | Público | Operación |

## Zonas y Hogares (9)

Todas las operaciones de negocio exigen `coordinador` o `admin` a nivel de ruta. Hallazgo: no hay filtro por zona (cualquier coordinador lista y modifica todas las zonas y hogares; solo `usuarios.zona_id` limita al coordinador en otros módulos).

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 5 | GET | `/zonas-hogares/zonas` | Listar zonas | coordinador, admin | RF17 |
| 6 | POST | `/zonas-hogares/zonas` | Crear zona | coordinador, admin | RF17 |
| 7 | GET | `/zonas-hogares/zonas/{zona_id}` | Obtener zona | coordinador, admin | RF17 |
| 8 | PUT | `/zonas-hogares/zonas/{zona_id}` | Actualizar zona | coordinador, admin | RF17 |
| 9 | POST | `/zonas-hogares/hogares` | Crear hogar sustituto (capacidad, habilitación) | coordinador, admin | RF17 |
| 10 | GET | `/zonas-hogares/hogares` | Listar hogares, con filtro opcional por zona | coordinador, admin | RF17 |
| 11 | GET | `/zonas-hogares/hogares/{hogar_id}` | Obtener hogar | coordinador, admin | RF17 |
| 12 | PUT | `/zonas-hogares/hogares/{hogar_id}` | Actualizar hogar (capacidad, madre asignada, estado) | coordinador, admin | RF17 |
| 13 | GET | `/zonas-hogares/_estado` | Diagnóstico del módulo | Público | Operación |

## Madres Sustitutas (7)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 14 | GET | `/madres/_estado` | Diagnóstico del módulo | Público | Operación |
| 15 | GET | `/madres/yo` | Perfil de la madre autenticada, con el id de su hogar | madre | M3 |
| 16 | PUT | `/madres/yo/firma` | Cargar la firma única (hoy solo una referencia en texto plano) | madre | RF5 |
| 17 | GET | `/madres` | Listar madres sustitutas | coordinador, admin | M3 |
| 18 | POST | `/madres` | Crear madre sustituta | coordinador, admin | M3 |
| 19 | GET | `/madres/{madre_id}` | Obtener madre | coordinador, admin | M3 |
| 20 | PUT | `/madres/{madre_id}` | Actualizar dirección, teléfono y estado de certificación | coordinador, admin | M3 |

## Profesionales (5)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 21 | GET | `/profesionales/_estado` | Diagnóstico del módulo | Público | Operación |
| 22 | POST | `/profesionales` | Crear profesional (defensor, psicosocial, nutrición, trabajo social) | coordinador, admin | M4 |
| 23 | GET | `/profesionales` | Listar, con filtro opcional por cargo | coordinador, admin | M4 |
| 24 | GET | `/profesionales/{profesional_id}` | Obtener profesional | coordinador, admin | M4 |
| 25 | PUT | `/profesionales/{profesional_id}` | Actualizar profesional | coordinador, admin | M4 |

Faltante: no hay endpoint para asignar un profesional a un menor (tabla `menores_profesionales`), de la que dependen permisos, paneles y destinatarios de evasión.

## Menores y Expedientes (13)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 26 | GET | `/menores/_estado` | Diagnóstico del módulo | Público | Operación |
| 27 | POST | `/menores` | Crear expediente de menor | coordinador, admin, profesional con cargo defensor | RF1 |
| 28 | GET | `/menores` | Listar expedientes con filtros (zona, hogar, estado) | admin y auditor (todos); coordinador (su zona); profesional o defensor (sus asignados); madre (NNA con asignación vigente en su hogar) | RF1, RF6, RF7 |
| 29 | GET | `/menores/panel/profesional` | Panel del profesional: menores por zona y hogar | profesional, defensor (otros roles reciben lista vacía) | RF1 |
| 30 | GET | `/menores/panel/zona` | Panel de la zona: menores por hogar, solo datos básicos | coordinador con zona (otros roles reciben lista vacía) | RF1 |
| 31 | GET | `/menores/{menor_id}` | Obtener expediente (datos básicos) | admin y auditor; coordinador de la zona; profesional o defensor asignado; madre con asignación vigente | RF1, RF6, RF7 |
| 32 | PUT | `/menores/{menor_id}` | Actualizar datos o estado; escribe snapshot en `menores_history` | admin; coordinador de la zona; profesional o defensor asignado | RF1, RF3 |
| 33 | GET | `/menores/{menor_id}/historial` | Historial de cambios del expediente | Quien ve el menor, excepto la madre (esta recibe 403) | RF3 |
| 34 | GET | `/menores/{menor_id}/familiares` | Listar padre, madre y otros familiares (sección `familia`) | Profesional o defensor asignado; madre con permiso `familia` (coordinador, auditor y admin no) | RF1, RF6 |
| 35 | POST | `/menores/{menor_id}/familiares` | Registrar familiar | admin; coordinador de la zona; profesional o defensor asignado | RF1, RF6 |
| 36 | GET | `/menores/{menor_id}/permisos` | Listar permisos de expediente (ACL) | Profesional o defensor asignado; madre con permiso `familia`; admin | RF6 |
| 37 | POST | `/menores/{menor_id}/permisos` | Otorgar a la madre una sección sensible (`familia`, `salud`, `psicosocial`) | Solo el profesional con cargo defensor asignado al menor | RF6 |
| 38 | DELETE | `/menores/{menor_id}/permisos/{permiso_id}` | Revocar permiso (desactiva, no borra) | Solo el defensor asignado al menor | RF6, RF7 |

## Asignaciones y Traslados (7)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 39 | GET | `/asignaciones/_estado` | Diagnóstico del módulo | Público | Operación |
| 40 | POST | `/asignaciones` | Crear ingreso o traslado (el traslado cierra la vigente y revoca permisos de la madre saliente) | admin; coordinador de la zona del hogar de destino; defensor asignado al menor | RF1, RF7 |
| 41 | GET | `/asignaciones` | Listar con filtros (menor, hogar, zona, estado) | admin y auditor (todas); coordinador (su zona); profesional o defensor (sus menores); madre (solo vigentes de su hogar) | RF1, RF7 |
| 42 | GET | `/asignaciones/menor/{menor_id}/vigente` | Asignación vigente de un menor | Quien puede ver el menor | RF1 |
| 43 | GET | `/asignaciones/{asignacion_id}` | Obtener asignación | admin y auditor; coordinador de la zona; profesional o defensor asignado; madre del hogar | RF1 |
| 44 | PUT | `/asignaciones/{asignacion_id}/cerrar` | Cerrar asignación (egreso): snapshot, revoca permisos y pone el menor en `egresado` | admin; coordinador de la zona; defensor asignado al menor | RF1, RF7 |
| 45 | GET | `/asignaciones/{asignacion_id}/historial` | Historial de la asignación | Quien ve la asignación, excepto la madre | RF3 |

## Gestión Documental (17)

Regla de lectura de un documento (ADR-0008 sección 4): si la categoría no mapea a sección sensible basta ver el menor; si mapea (`salud`, `psicosocial`, `familia`), se exige permiso de sección (profesional o defensor asignado; madre habilitada por el defensor). Documentos de hogar: madre del hogar, coordinador de la zona, admin y auditor (metadatos).

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 46 | GET | `/documentos/_estado` | Diagnóstico del módulo | Público | Operación |
| 47 | POST | `/documentos` | Subir documento (multipart): cifra, calcula hash, indexa para IA en segundo plano | madre (nace `borrador`; menor con asignación vigente y permiso de sección si es sensible, o su hogar); profesional o defensor asignado (nace `aprobado`); coordinador o admin con `migracion=true` y motivo (nace `aprobado`); admin y coordinador de la zona para documentos de hogar | RF2, RF4, RF10 |
| 48 | GET | `/documentos` | Listar documentos con filtros (menor, hogar, categoría, estado de flujo); cada fila pasa por la regla de lectura | Autenticado, filtrado por fila | RF2, RF6 |
| 49 | GET | `/documentos/auditor` | Metadatos de documentos no sensibles, nunca contenido | Solo auditor | RF11 |
| 50 | GET | `/documentos/menor/{menor_id}/seccion/{seccion}` | Documentos y reportes de una sección sensible del expediente | Quien tenga permiso de esa sección (profesional o defensor asignado; madre habilitada) | RF1, RF6 |
| 51 | POST | `/documentos/reportes` | Crear informe clínico (JSON); queda definitivo, sin flujo de aprobación | Profesional o defensor asignado | RF1 |
| 52 | GET | `/documentos/reportes` | Listar informes clínicos (filtros menor y tipo) | Autenticado, por la regla de sección del tipo de informe | RF1, RF6 |
| 53 | GET | `/documentos/reportes/{reporte_id}` | Obtener informe clínico | Quien tenga acceso a su sección | RF1, RF6 |
| 54 | GET | `/documentos/{documento_id}` | Metadatos de un documento | Quien cumpla la regla de lectura (incluye auditor, solo metadatos) | RF2, RF6 |
| 55 | GET | `/documentos/{documento_id}/contenido` | Descargar el archivo descifrado | Regla de lectura, excepto auditor (siempre 403) | RF2, RF11 |
| 56 | GET | `/documentos/{documento_id}/vista` | Ver en pantalla (solo PDF e imágenes, `inline`) | Igual que descarga; 422 si el tipo no es visualizable (ADR-0011) | RF2 |
| 57 | PUT | `/documentos/{documento_id}/enviar` | Enviar a revisión (`borrador` a `en_revision`) | Creador o quien tendría permiso de creación | RF4 |
| 58 | PUT | `/documentos/{documento_id}/aprobar` | Aprobar (`en_revision` a `aprobado`); guarda revisor y fecha | Profesional o defensor asignado al menor | RF4 |
| 59 | PUT | `/documentos/{documento_id}/devolver` | Devolver con motivo obligatorio (`en_revision` a `devuelto`) | Profesional o defensor asignado al menor | RF4 |
| 60 | POST | `/documentos/{documento_id}/version` | Subir versión nueva (solo en `borrador` o `devuelto`); snapshot y compresión de imágenes en el historial (ADR-0011) | Creador o quien tendría permiso de creación | RF3 |
| 61 | GET | `/documentos/{documento_id}/versiones` | Listar metadatos de versiones anteriores | Quien cumpla la regla de lectura | RF3 |
| 62 | GET | `/documentos/{documento_id}/versiones/{version}/contenido` | Descargar una versión anterior | Regla de lectura, excepto auditor | RF3, RF11 |

## Inventario del Hogar (15)

Autorización por hogar (ADR-0009 sección 0): lectura con `puede_ver_hogar` (admin, auditor, coordinador de la zona, madre del hogar, profesional o defensor con un NNA en ese hogar); escritura con `puede_gestionar_hogar` (igual, sin auditor). Pedido y recepción: ADR-0014.

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 63 | GET | `/inventario/_estado` | Diagnóstico del módulo | Público | Operación |
| 64 | POST | `/inventario/items` | Crear ítem: el coordinador crea un pedido (`recibido=false`); madre y admin registran algo ya presente (`recibido=true`) | Quien gestiona el hogar (coordinador de la zona, madre del hogar, admin; ver observación) | RF13 |
| 65 | GET | `/inventario/items` | Listar ítems de un hogar (`hogar_id` obligatorio) | Quien ve el hogar | RF13 |
| 66 | PUT | `/inventario/items/{item_id}` | Actualizar estado físico; tipo, descripción y cantidad solo del pedido no recibido | Quien gestiona el hogar; tipo, descripción y cantidad solo coordinador o admin | RF13 |
| 67 | PUT | `/inventario/items/{item_id}/recepcion` | Confirmar recepción del pedido con su estado físico (una sola vez) | madre del hogar, admin | RF13 |
| 68 | POST | `/inventario/items/{item_id}/fotos` | Subir foto de evidencia con declaración obligatoria de que no aparece ningún NNA | madre del hogar, admin | RF13 |
| 69 | GET | `/inventario/items/{item_id}/fotos` | Listar fotos de un ítem | madre del hogar, admin, auditor (las ocultas solo las ve admin) | RF13 |
| 70 | GET | `/inventario/items/{item_id}/fotos/{foto_id}` | Ver una foto de evidencia | madre del hogar, admin, auditor | RF13 |
| 71 | PUT | `/inventario/items/{item_id}/fotos/{foto_id}/ocultar` | Ocultar una foto (remediación, no se borra) | Solo admin | RF13, RF11 |
| 72 | POST | `/inventario/convivientes` | Registrar persona que vive en el hogar | Quien gestiona el hogar | RF13 |
| 73 | GET | `/inventario/convivientes` | Listar convivientes de un hogar | Quien ve el hogar | RF13 |
| 74 | PUT | `/inventario/convivientes/{conviviente_id}` | Actualizar o desactivar conviviente | Quien gestiona el hogar | RF13 |
| 75 | POST | `/inventario/red-apoyo` | Registrar contacto de la red de apoyo | Quien gestiona el hogar | RF13 |
| 76 | GET | `/inventario/red-apoyo` | Listar red de apoyo de un hogar | Quien ve el hogar | RF13 |
| 77 | PUT | `/inventario/red-apoyo/{contacto_id}` | Actualizar o desactivar contacto | Quien gestiona el hogar | RF13 |

Observación: `puede_gestionar_hogar` incluye al profesional o defensor con un NNA en el hogar, así que esa condición también les permite escribir inventario, convivientes y red de apoyo. ADR-0009 lo prevé "sin excepción por tipo"; ADR-0015 restringió alimentos y citas pero no tocó inventario. Pregunta para `arquitecto` y `seguridad`: ¿se mantiene esa escritura para profesionales?

## Control de Alimentos (9)

Escritura exclusiva de madre del hogar y admin; coordinador, profesional, defensor y auditor solo leen (ADR-0015).

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 78 | GET | `/alimentos/_estado` | Diagnóstico del módulo | Público | Operación |
| 79 | POST | `/alimentos` | Registrar ingreso de alimento (perecedero exige fecha de vencimiento) | madre del hogar, admin | RF14 |
| 80 | GET | `/alimentos` | Listar alimentos de un hogar (filtros: perecedero, consumido, vencidos) | Quien ve el hogar (lectura) | RF14 |
| 81 | POST | `/alimentos/checklist` | Crear producto reutilizable del mercado | madre del hogar, admin | RF14 |
| 82 | GET | `/alimentos/checklist` | Listar el checklist de un hogar | Quien ve el hogar (lectura) | RF14 |
| 83 | PUT | `/alimentos/checklist/{checklist_item_id}` | Actualizar o desactivar producto del checklist | madre del hogar, admin | RF14 |
| 84 | POST | `/alimentos/checklist/{checklist_item_id}/comprar` | Registrar una compra nueva a partir de un producto del checklist | madre del hogar, admin | RF14 |
| 85 | PUT | `/alimentos/{item_id}` | Actualizar alimento | madre del hogar, admin | RF14 |
| 86 | PUT | `/alimentos/{item_id}/consumido` | Marcar como consumido (no se borra) | madre del hogar, admin | RF14 |

## Citas y Recordatorios (7)

El sistema no asigna citas, solo recuerda (CLAUDE.md). El campo `notas` se devuelve `null` si el solicitante no tiene permiso de sección para el tipo de cita (ADR-0009 sección 2). Con el expediente archivado no se crean citas.

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 87 | GET | `/citas/_estado` | Diagnóstico del módulo | Público | Operación |
| 88 | POST | `/citas` | Registrar cita | madre (tipos `medica`, `psicosocial`, `otro`) o defensor (tipo `reunion_familia`), siempre que vean al menor; admin (ADR-0015) | RF15 |
| 89 | GET | `/citas` | Listar citas con filtros (menor, tipo, estado) | Autenticado, filtrado por quien ve el menor | RF15 |
| 90 | GET | `/citas/proximas` | Próximas citas pendientes | Autenticado, filtrado por quien ve el menor | RF15, RF9 |
| 91 | GET | `/citas/{cita_id}` | Obtener cita | Quien ve el menor | RF15 |
| 92 | PUT | `/citas/{cita_id}` | Reprogramar (fecha, lugar, notas) | Dueño según el tipo (madre o defensor) con visibilidad del menor; admin | RF15 |
| 93 | PUT | `/citas/{cita_id}/estado` | Cambiar estado (`pendiente`, `cumplida`, `no_asistio`) | Igual que reprogramar | RF15 |

## Alertas y Evasiones (9)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 94 | GET | `/alertas/_estado` | Diagnóstico del módulo | Público | Operación |
| 95 | POST | `/alertas/evasion` | Reportar evasión: crea la alerta, la envía al defensor y a la psicosocial asignados (respaldo: coordinador de zona, luego admin) y devuelve los números de emergencia | Todo rol que vea al menor, excepto auditor (madre, profesional, defensor, coordinador, admin) | RF9 |
| 96 | GET | `/alertas/mis-pendientes` | Alertas pendientes del usuario como destinatario | Cualquier autenticado | RF9 |
| 97 | GET | `/alertas/panel` | Panel de alertas activas; dispara además el barrido automático | admin (todas); coordinador (su zona); profesional o defensor (sus menores); otros roles reciben lista vacía | RF9 |
| 98 | POST | `/alertas/generar-automaticas` | Generar alertas automáticas (visita vencida, documento faltante, indexación pendiente) | coordinador, admin | RF9 |
| 99 | GET | `/alertas` | Listar alertas con filtros (menor, tipo, estado) | Destinatario, quien la generó, coordinador de la zona, admin; auditor solo metadatos | RF9, RF11 |
| 100 | GET | `/alertas/{alerta_id}` | Obtener alerta con destinatarios y quién la vio | Igual que el listado | RF9, RF11 |
| 101 | PUT | `/alertas/{alerta_id}/visto` | Marcar como vista (registra quién y cuándo) | Solo un destinatario de esa alerta | RF9 |
| 102 | PUT | `/alertas/{alerta_id}/cerrar` | Cerrar alerta | admin; coordinador de la zona; quien la generó; profesional o defensor asignado | RF9 |

## Configuración administrable (10)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 103 | GET | `/configuracion/_estado` | Diagnóstico del módulo | Público | Operación |
| 104 | GET | `/configuracion/catalogos` | Listar grupos de catálogo | admin | M12 (T4, ADR-0013) |
| 105 | GET | `/configuracion/catalogos/{grupo}` | Opciones activas de un catálogo (por ejemplo categorías documentales) | Cualquier autenticado | M12, RF2 |
| 106 | POST | `/configuracion/catalogos/{grupo}` | Crear opción de catálogo (exige `seccion_acceso` explícita en categorías documentales) | admin | M12 |
| 107 | GET | `/configuracion/catalogos/{grupo}/admin` | Opciones incluidas las inactivas | admin | M12 |
| 108 | PUT | `/configuracion/catalogos/{grupo}/{valor}` | Editar o desactivar una opción (no se borra) | admin | M12 |
| 109 | GET | `/configuracion/parametros` | Listar parámetros del sistema | admin | M12 |
| 110 | GET | `/configuracion/parametros/{clave}` | Detalle de un parámetro | admin | M12 |
| 111 | PUT | `/configuracion/parametros/{clave}` | Actualizar un parámetro (por ejemplo el teléfono de la Policía de Infancia) | admin | M12, RF9 |
| 112 | GET | `/configuracion/publica` | Parámetros públicos para la interfaz | Cualquier autenticado | M12 |

## Reportes (8)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 113 | GET | `/reportes/_estado` | Diagnóstico del módulo | Público | Operación |
| 114 | GET | `/reportes/general` | Reporte general agregado | admin, auditor, coordinador (recibe el agregado de su zona) | RF16 |
| 115 | GET | `/reportes/zona/{zona_id}` | Reporte por zona | admin, auditor; coordinador solo de su zona | RF16 |
| 116 | GET | `/reportes/menor/{menor_id}` | Reporte por menor (documentos, alertas, citas; indica las secciones sin acceso) | Quien puede ver el menor; las secciones sensibles según permiso | RF16 |
| 117 | GET | `/reportes/madre/{madre_id}` | Reporte por madre | admin; madre (solo la propia); coordinador (madre con hogar en su zona); auditor solo agregado | RF16 |
| 118 | POST | `/reportes/exportar` | Exportar un reporte (JSON, PDF o CSV) como archivo cifrado con traza | Las mismas reglas del nivel pedido | RF16 |
| 119 | GET | `/reportes/exportados` | Listar informes exportados | El propio usuario; admin y auditor ven todos | RF16, RF11 |
| 120 | GET | `/reportes/exportados/{informe_id}/contenido` | Descargar el informe, revalidando los permisos vigentes ahora | Quien siga autorizado para ese nivel; auditor nunca | RF16, RF11 |

## Asistente de IA (10)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 121 | GET | `/ia/_estado` | Diagnóstico del módulo | Público | Operación |
| 122 | GET | `/ia/estado` | Configuración activa del asistente (proveedor, modelo, anonimizado) | Solo admin (la validación está en el caso de uso) | RF12 |
| 123 | POST | `/ia/consultas` | Pregunta en lenguaje natural con RAG: solo recupera lo que el usuario puede ver, cita la fuente y la versión, o responde que no encontró información | Todo rol excepto auditor, con el alcance de sus permisos | RF12 |
| 124 | GET | `/ia/consultas` | Historial de consultas | El propio usuario; admin todas completas; auditor todas solo metadatos | RF12, RF11 |
| 125 | GET | `/ia/consultas/{consulta_id}` | Detalle de una consulta (revalida si el acceso sigue vigente) | El autor; admin; auditor solo metadatos | RF12, RF11 |
| 126 | GET | `/ia/menores/{menor_id}/resumen` | Resumen del expediente con citas | Quien puede ver el menor, excepto auditor | RF12 |
| 127 | GET | `/ia/documentos/{documento_id}/resumen` | Resumen de un documento o informe | Quien puede ver ese documento o informe. Hallazgo para `seguridad`: el caso de uso no excluye explícitamente al auditor (ver nota abajo) | RF12 |
| 128 | POST | `/ia/redaccion/apoyo` | Borrador de informe con apoyo de IA | profesional, defensor | RF12 |
| 129 | POST | `/ia/mantenimiento/reindexar-pendientes` | Reintentar la indexación de documentos e informes sin fragmentos | Solo admin | RF12 |
| 130 | POST | `/ia/documentos/clasificar` | Sugerir la categoría de un archivo antes de crear el documento (no persiste nada) | Cualquier autenticado | RF12, RF2 |

Nota de seguridad sobre la fila 127 (a revisar con `seguridad`, no se modificó código): `consultar` y `resumen_menor` rechazan al auditor de forma explícita, pero `resumen_documento` no. Reutiliza `obtener_documento` y `obtener_reporte` (que dejan pasar al auditor para metadatos) y luego `_fragmento_autorizado_y_vigente`, que para categorías sin sección sensible usa `puede_ver_menor` (verdadero para el auditor) y para documentos de hogar `puede_ver_hogar` (también verdadero). Resultado probable: un auditor podría obtener un resumen generado a partir del contenido de un documento no sensible (por ejemplo identidad o educación), contra la regla "el auditor nunca ve contenido" de ADR-0007 punto 3, ADR-0008 sección 4 y ADR-0010. Falta confirmarlo con una prueba de autorización.

## Auditoría (2)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 131 | GET | `/auditoria/_estado` | Diagnóstico del módulo | Público | Operación |
| 132 | GET | `/auditoria` | Listar accesos auditados (filtros usuario, acción, fechas; paginación `limit` hasta 500 y `offset`) | auditor, admin | RF11 |

## Archivo y Cierre (5)

| # | Método | Ruta | Descripción | Roles autorizados | RF |
|---|---|---|---|---|---|
| 133 | GET | `/archivo/_estado` | Diagnóstico del módulo | Público | Operación |
| 134 | GET | `/archivo` | Listar expedientes archivados (filtros zona y fechas) | admin; coordinador de su zona | RF8 |
| 135 | POST | `/archivo/menores/{menor_id}/cerrar` | Archivar el expediente: manifiesto, paquete ZIP cifrado y bloqueo de escrituras | admin; coordinador de la zona del expediente | RF8 |
| 136 | GET | `/archivo/menores/{menor_id}` | Estado de archivo de un menor | admin, auditor; coordinador de la zona | RF8 |
| 137 | GET | `/archivo/menores/{menor_id}/paquete` | Descargar el paquete cifrado del expediente archivado | admin; coordinador de la zona; auditor nunca | RF8 |

## Verificación de conteos

| Módulo | Operaciones |
|---|---|
| Sistema | 1 |
| Autenticación | 3 |
| Zonas y Hogares | 9 |
| Madres Sustitutas | 7 |
| Profesionales | 5 |
| Menores y Expedientes | 13 |
| Asignaciones y Traslados | 7 |
| Gestión Documental | 17 |
| Inventario del Hogar | 15 |
| Control de Alimentos | 9 |
| Citas y Recordatorios | 7 |
| Alertas y Evasiones | 9 |
| Configuración administrable | 10 |
| Reportes | 8 |
| Asistente de IA | 10 |
| Auditoría | 2 |
| Archivo y Cierre | 5 |
| Total | 137 (111 rutas) |

De las 137 operaciones, 17 son diagnósticos `_estado` o `health` (públicos) y 120 son de negocio.

## Diferencias con `docs/guia-api.md`

La guía se declara "un mapa para orientarse"; frente a `openapi.json` está desactualizada en:
- Lista `GET/PUT /alertas/configuracion/telefono-policia-infancia`, que ya no existe en el contrato: ADR-0013 lo reemplazó por `/configuracion/parametros/{clave}` (la migración `0009` retiró la tabla `configuracion_alertas`).
- Dice que no hay visor embebido; existe `GET /documentos/{id}/vista` desde ADR-0011.
- Omite `/configuracion/*`, `/inventario/items/{id}/recepcion` y las fotos, `/alimentos/checklist*`, `GET /asignaciones/{id}`, `GET /alertas/{id}` y `GET /ia/estado`.
- Sigue marcando el sufijo `/_estado` como diagnóstico de cada módulo, que es correcto.
