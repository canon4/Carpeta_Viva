# Requisitos funcionales

Fase 1, paso 2. Base: RF1 a RF17 de `CLAUDE.md`, desglosados con las decisiones de las ADR 0004 a 0016. Donde falta información del operador o jurídica, el requisito se completa con un supuesto de [supuestos.md](supuestos.md) (columna Fuente, código S).

Prioridad MoSCoW: **M** (debe), **S** (debería), **C** (podría), **W** (no en esta versión).
Todos los requisitos tienen especificación completa. La columna Estado indica la **implementación** en el código al 17-11-2026: **Implementado**, **Parcial** o **Pendiente**.

## RF0. Autenticación y cuentas (módulo 1)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF0.1 | Iniciar sesión con usuario y contraseña y recibir un JWT con expiración | M | Credenciales válidas devuelven un token de 60 minutos; inválidas devuelven 401 con un mensaje que no revela cuál dato falló, y queda evento en auditoría | ADR-0004 | Implementado |
| RF0.2 | Consultar el perfil del usuario autenticado | M | `GET /auth/me` devuelve correo, rol y zona | ADR-0004 | Implementado |
| RF0.3 | Seis roles: madre, profesional, defensor, coordinador, auditor, admin | M | Cada endpoint valida rol y alcance; un rol no previsto recibe 403 | ADR-0004 | Implementado |
| RF0.4 | Cambiar la contraseña propia | M | Exige la contraseña actual; la nueva tiene al menos 10 caracteres y es distinta de la actual y del correo; las sesiones anteriores dejan de valer y se entrega un token nuevo | ADR-0016 | Parcial (API lista; falta pantalla) |
| RF0.5 | Bloquear la cuenta tras intentos fallidos | M | Tras 5 intentos fallidos seguidos la cuenta queda bloqueada 15 minutos (429), incluso con la clave correcta; el contador se reinicia al entrar | ADR-0016 | Implementado (falta mensaje propio en pantalla) |
| RF0.6 | Administrar cuentas de usuario | M | El admin crea cuentas con correo, rol y zona; las desactiva sin borrarlas; un usuario desactivado no entra; todo queda en auditoría | Plan Fase 1 | Pendiente |
| RF0.7 | Contraseña temporal en cuentas nuevas | M | La cuenta nueva recibe una contraseña temporal; al primer ingreso el sistema obliga a cambiarla antes de mostrar el panel | S21 | Pendiente |
| RF0.8 | Segundo factor para roles con acceso amplio | S | Admin, auditor, coordinador, defensor y profesionales activan un código TOTP; sin él no completan el ingreso; reciben 10 códigos de recuperación de un solo uso; la madre no lo usa | S06, punto abierto 6 | Pendiente |

## RF17. Organización: zonas, hogares, madres y profesionales (módulos 2, 3 y 4)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF17.1 | Crear, consultar y editar zonas | M | Solo el admin crea y renombra zonas; el coordinador ve únicamente la suya | ADR-0016 | Implementado |
| RF17.2 | Crear, consultar y editar hogares (capacidad, habilitación, estado, madre) | M | Capacidad entre 1 y 13; el coordinador gestiona solo hogares de su zona; una madre solo puede estar vinculada a un hogar | ADR-0016 | Implementado |
| RF17.3 | Registrar madres sustitutas | M | Datos de identificación únicos; el coordinador ve las madres de su zona y las que aún no tienen hogar | ADR-0016 | Implementado |
| RF17.4 | Registrar capacitaciones de la madre con vencimiento | S | Tipo, entidad, fecha y vencimiento; alerta al coordinador 30 días antes de vencer | S22, `docs/modulos.md` módulo 3 | Pendiente |
| RF17.5 | Registrar profesionales con cargo y teléfono | M | Cargos: defensor, psicosocial, nutrición, trabajo social | ADR-0009 | Implementado |
| RF17.6 | Asociar profesionales a zonas | S | Un profesional pertenece a una o varias zonas; el coordinador ve y edita solo los de su zona | S07 | Pendiente |

## RF1. Expedientes por NNA (módulo 5)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF1.1 | Crear expediente del NNA con datos personales y documento de identidad | M | Acepta NNA sin documento (`sin_documento`); el número es único cuando existe | ADR-0007 §1 | Implementado |
| RF1.2 | Registrar información de padre, madre u otro familiar | M | Sección `familia`; solo la registran los profesionales asignados; solo la leen ellos y la madre con permiso | ADR-0007 §1, S19 | Parcial (hoy también coordinador y admin pueden registrar) |
| RF1.3 | Estado del NNA: activo, egresado, evadido, fallecido | M | Cada cambio guarda la versión anterior con quién y cuándo | ADR-0007 §1 | Implementado |
| RF1.4 | Panel del profesional con sus NNA por hogar y zona | M | Solo NNA asignados, con alertas, documentos por revisar y próximas citas | ADR-0007 §4 | Implementado |
| RF1.5 | Panel del coordinador con los NNA de su zona | M | Solo su zona | ADR-0007 §4 | Implementado |
| RF1.6 | Asignar profesionales a cada NNA | M | El coordinador de la zona asigna; cada NNA activo tiene un defensor y una psicosocial; la asignación termina con fecha de fin y no se borra; el profesional desasignado pierde el acceso | S20 | Parcial (modelo y reglas listos; falta endpoint y pantalla) |

## RF1/RF6. Asignaciones y traslados (módulo 6)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF1.7 | Asignar NNA a hogar con fecha de inicio (ingreso) | M | Un NNA tiene a lo sumo una asignación vigente | ADR-0007 §4 | Implementado |
| RF1.8 | Trasladar NNA | M | Cierra la anterior y abre la nueva en una sola operación, con acta y motivo; el coordinador debe administrar la zona de origen y la de destino | ADR-0007 §4, ADR-0016 | Implementado |
| RF1.9 | Cerrar asignación con fecha de fin y motivo | M | Guarda la versión anterior y revoca los permisos de la madre | ADR-0007 §4 | Implementado |

## RF2 a RF5 y RF10. Gestión documental (módulo 7)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF2.1 | Cargar PDF, Word, Excel, PowerPoint, imágenes del celular y texto | M | El tipo se detecta por el contenido, no por lo que declara el cliente; se rechazan ejecutables y documentos con macros; máximo 25 MB; se guarda nombre, tipo, tamaño y hash SHA-256 | ADR-0008, ADR-0016 | Implementado |
| RF2.2 | Cifrar cada archivo en reposo | M | Archivo `.enc` con Fernet; el hash se verifica al leer | ADR-0008 §1 | Implementado |
| RF2.3 | Clasificar por categoría administrable | M | Identidad, salud, psicosocial, educación, familia, actas, habilitación, otros; las nuevas quedan con la visibilidad mínima | ADR-0008 §2, ADR-0013 | Implementado |
| RF2.4 | Ver el documento en pantalla sin descargarlo | S | PDF e imágenes se ven en la aplicación; no es un editor | ADR-0011 | Implementado |
| RF3.1 | Subir nueva versión sin sobrescribir la anterior | M | La versión previa queda en el historial y el documento vuelve a revisión | ADR-0008 §3 | Implementado |
| RF3.2 | Consultar y descargar versiones anteriores | M | Lista con autor, fecha y estado de cada versión | ADR-0008 §6 | Implementado |
| RF3.3 | Comprimir imágenes de versiones reemplazadas | C | Solo imágenes; la versión vigente nunca se comprime | ADR-0011 | Implementado |
| RF4.1 | La madre crea en borrador y envía a revisión | M | Estado `borrador` a `en_revision` | ADR-0008 §3 | Implementado |
| RF4.2 | El profesional asignado aprueba o devuelve con motivo | M | Estado `aprobado` o `devuelto`; el motivo es obligatorio al devolver | ADR-0008 §3 | Implementado |
| RF4.3 | Lo que crea un profesional asignado queda aprobado | S | No pasa por revisión propia | ADR-0008 §3 | Implementado |
| RF4.4 | Informes de profesionales como registro solo de inserción | M | Cada corrección es un informe nuevo | ADR-0008 §3 | Implementado |
| RF4.5 | Revisión de documentos del hogar | M | Los documentos del hogar que envía la madre los aprueba o devuelve el coordinador de la zona | S13 | Pendiente |
| RF5.1 | La madre carga su firma una sola vez | M | Imagen PNG o JPEG; reemplazarla queda en auditoría | `CLAUDE.md` | Parcial (hoy se guarda una referencia de texto) |
| RF5.2 | Firmar un documento con evidencia | S | Al firmar se guarda usuario, fecha, hash del documento y aceptación expresa del texto de responsabilidad; la firma se muestra en el documento | S08, punto abierto 5 | Pendiente |
| RF10.1 | Digitalizar el historial físico | M | Coordinador o admin cargan con `migracion=true` y motivo obligatorio; queda aprobado | ADR-0008 §3 | Implementado |

## RF6, RF7 y RF11. Permisos, ocultamiento y auditoría
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF6.1 | Denegar por defecto; visibilidad por rol y relación con el NNA | M | Un usuario sin relación recibe 403 o no ve la fila | ADR-0004, ADR-0007 §2 | Implementado |
| RF6.2 | El defensor asignado habilita o revoca a la madre las secciones sensibles | M | Solo el defensor asignado; revocar desactiva el permiso sin borrarlo | ADR-0007 §2.5 | Implementado |
| RF6.3 | Coordinador y auditor no ven secciones sensibles | M | Contenido de familia, salud y psicosocial oculto | ADR-0007 §2.2-2.3 | Implementado |
| RF6.4 | El auditor nunca recibe contenido | M | Archivos, resúmenes de IA y paquetes responden 403 al auditor | ADR-0008 §4, ADR-0016 | Implementado |
| RF6.5 | El auditor ve datos minimizados del NNA | S | Iniciales, edad, estado, hogar y zona; sin número de documento ni nombre completo | S17 | Pendiente |
| RF7.1 | Al cerrar la asignación, la madre deja de ver el expediente | M | Sus permisos se revocan en la misma operación | ADR-0007 §2.6 | Implementado |
| RF7.2 | Nunca se borra información | M | No hay borrado de datos de negocio; se desactiva, se cierra o se versiona | ADR-0004 | Implementado |
| RF11.1 | Registrar todo acceso, incluidos los denegados | M | Fila con usuario, acción, recurso, NNA, fecha e IP; la base impide modificar o borrar filas | ADR-0004, ADR-0016 | Parcial (falta IP fuera del inicio de sesión y lecturas de listados) |
| RF11.2 | Consultar la auditoría con filtros | M | Auditor y admin filtran por usuario, acción, NNA y fechas | ADR-0004 | Implementado |

## RF8. Archivo y cierre (T3)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF8.1 | Archivar el expediente cuando el NNA egresa o fallece sin asignación vigente | M | Genera paquete ZIP cifrado con manifiesto y hash; la evasión no archiva | ADR-0010 §3 | Implementado |
| RF8.2 | El expediente archivado queda de solo lectura | M | Se rechaza crear documentos, alertas y citas | ADR-0010 §3.2 | Implementado |
| RF8.3 | Descargar el paquete | M | El coordinador de la zona lo descarga sin secciones sensibles; el completo solo el admin con motivo; el auditor solo metadatos | ADR-0010 §3.5, S15 | Parcial (hoy el coordinador recibe también las secciones sensibles) |
| RF8.4 | Registrar la entrega al destino final | S | El coordinador registra un acta de entrega con fecha, receptor y hash del paquete | S09, punto abierto 1 | Pendiente |
| RF8.5 | Señalar expedientes que cumplen el tiempo de retención | C | A los 10 años del cierre el sistema lo señala; eliminar o anonimizar exige aprobación de admin y auditor y queda auditado | S10, punto abierto 2 | Pendiente |

## RF9. Alertas y evasiones (módulo 11)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF9.1 | Reportar evasión de un NNA | M | Madre, profesional asignado, coordinador de zona o admin | ADR-0009 §1 | Implementado |
| RF9.2 | Notificar en la aplicación al defensor y a la psicosocial asignados | M | Si no tienen cuenta, al coordinador de la zona o al admin; nunca cero destinatarios | ADR-0009 §1 | Implementado |
| RF9.3 | Mostrar números de emergencia en la misma pantalla | M | Policía de Infancia y Adolescencia, defensor y psicosocial; indica si falta un teléfono | ADR-0009 §1 | Implementado |
| RF9.4 | Registrar quién recibió y cuándo vio cada alerta | M | Fecha de visto por destinatario | ADR-0009 §1 | Implementado |
| RF9.5 | Alertas automáticas de visitas vencidas | M | Sin duplicados; se generan al abrir el panel o por tarea diaria | ADR-0009 §1 | Implementado |
| RF9.6 | Alertas de documentos faltantes | M | Según la lista de documentos obligatorios y plazos de S04, con plazos administrables; destinatarios: profesionales asignados y madre | S04 | Parcial (solo la regla de 60 días del informe psicosocial) |
| RF9.7 | Aviso adicional de evasión fuera de la aplicación | C | Notificación push al defensor y a la psicosocial, con reintento cada 5 minutos hasta 3 veces mientras no la vean; queda la fecha de envío | S12, punto abierto 7 | Pendiente |
| RF9.8 | Cerrar alertas sin borrarlas | M | Estado `cerrada` | ADR-0009 §1 | Implementado |
| RF9.9 | Quién cierra una evasión | M | Defensor o psicosocial asignados, coordinador de la zona o admin; la madre no | S18 | Parcial (hoy también la cierra quien la reportó) |
| RF9.10 | Alerta de capacitación por vencer | S | 30 días antes del vencimiento, al coordinador | S22 | Pendiente |

## RF12. Asistente de IA (T1)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF12.1 | Búsqueda en lenguaje natural con cita a documento y versión | M | Sin fuente responde "no encontré información" | ADR-0002, ADR-0010 §1.5 | Implementado |
| RF12.2 | Resumen del expediente y de un documento | M | Solo con lo que el usuario puede ver; el auditor no obtiene resúmenes | ADR-0010 §1.9, ADR-0016 | Implementado |
| RF12.3 | Clasificación sugerida al cargar | S | Local, sin llamada externa | ADR-0010 §1.2 | Implementado |
| RF12.4 | OCR de documentos escaneados | S | Local | ADR-0010 §1.1 | Implementado |
| RF12.5 | Detección de faltantes e inconsistencias | S | Aplica la lista de S04 y señala datos contradictorios entre documentos (por ejemplo, fechas de nacimiento distintas) con cita a ambos | S04, ADR-0010 §1.7 | Parcial (solo la regla de 60 días) |
| RF12.6 | Apoyo a la redacción | C | Propone un borrador que el usuario edita; nunca guarda por su cuenta | ADR-0010 §1.8 | Implementado |
| RF12.7 | Seudonimizar datos antes de la API externa | M | Activo por defecto; datos reales solo con contrato y NER | ADR-0002, ADR-0010 §1.4 | Implementado |
| RF12.8 | Historial de consultas propio, revalidando permisos al leer | M | Contenido oculto si se perdió el permiso | ADR-0010 §1.4 | Implementado |
| RF12.9 | El admin ve solo metadatos de consultas ajenas | S | Sin pregunta ni respuesta de otros usuarios | S16 | Pendiente |

## RF13. Inventario del hogar (módulo 8)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF13.1 | El coordinador registra pedidos | M | Nacen como no recibidos | ADR-0014 §1 | Implementado |
| RF13.2 | La madre confirma la recepción con estado y foto | M | Una sola vez; la foto debe ser una imagen real y llevar la declaración de que no muestra NNA | ADR-0014, ADR-0016 | Implementado |
| RF13.3 | Registrar personas que viven en el hogar | M | Se desactivan, no se borran | ADR-0009 §3 | Implementado |
| RF13.4 | Registrar red de apoyo del hogar | M | Se desactivan, no se borran | ADR-0009 §3 | Implementado |
| RF13.5 | Profesionales y defensores solo consultan el inventario | M | Escriben la madre, el coordinador (pedidos) y el admin | S14 | Parcial (hoy profesionales con NNA en el hogar pueden escribir) |

## RF14. Control de alimentos (módulo 9)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF14.1 | Registrar cada compra con fecha de ingreso, perecedero y vencimiento | M | Vencimiento obligatorio si es perecedero y prohibido si no lo es | ADR-0009 §4, S05 | Parcial (falta exigir el vencimiento al perecedero) |
| RF14.2 | Checklist reutilizable de productos y atajo "comprar" | S | Solo fecha, vencimiento y cantidad | ADR-0014 §4 | Implementado |
| RF14.3 | Marcar consumido y filtrar vencidos | M | Filtro de vencidos no consumidos | ADR-0009 §4 | Implementado |
| RF14.4 | Coordinador, profesionales y auditor solo consultan | M | Escritura solo madre o admin | ADR-0015 §1 | Implementado |

## RF15. Citas y recordatorios (módulo 10)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF15.1 | Registrar citas | M | Médicas, psicosociales y otras: madre; reuniones con familia biológica: defensor; el tipo no cambia después | ADR-0015 §2 | Implementado |
| RF15.2 | Ver próximas citas en el panel | M | Solo citas pendientes futuras de NNA visibles | ADR-0009 §2 | Implementado |
| RF15.3 | Marcar cita cumplida o no asistió | M | Solo el dueño del tipo | ADR-0015 §2 | Implementado |
| RF15.4 | Ocultar las notas de la cita sin permiso de sección | M | Notas vacías para quien no tiene permiso | ADR-0009 §2 | Implementado |

## RF16. Reportes (módulo 12)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF16.1 | Reporte general | M | El coordinador recibe solo su zona | ADR-0010 §2 | Implementado |
| RF16.2 | Reporte por zona | M | Coordinador de esa zona, admin, auditor | ADR-0010 §2 | Implementado |
| RF16.3 | Reporte por NNA | M | Secciones sensibles reducidas a metadatos sin permiso | ADR-0010 §2 | Implementado |
| RF16.4 | Reporte por madre | M | La madre ve el suyo | ADR-0010 §2 | Implementado |
| RF16.5 | Exportar a PDF o CSV cifrado | S | Revalida permisos al descargar | ADR-0010 §2 | Implementado |
| RF16.6 | Reporte de indicadores de éxito | S | Tiempo medio de búsqueda, tiempo medio de revisión de documentos y documentos digitalizados por mes, comparados con la línea base de S02 | S02, S03 | Pendiente |

## RF18. Configuración administrable (T4)
| ID | Requisito | Prioridad | Criterio de aceptación | Fuente | Estado |
|---|---|---|---|---|---|
| RF18.1 | Administrar catálogos | S | Valores nuevos sin regla quedan con visibilidad mínima | ADR-0013 §5 | Implementado |
| RF18.2 | Administrar parámetros | S | Teléfono de policía, umbrales y plazos de alertas, datos del operador; sin redesplegar | ADR-0013 | Implementado |

## Resumen
| Estado de implementación | Requisitos |
|---|---|
| Implementado | 67 |
| Parcial | 11 |
| Pendiente | 14 |
| Total | 92 |

## Fuera de alcance
Expediente judicial completo, nómina, contratos de las madres e integraciones con sistemas del ICBF (`CUESTIONARIO.md` A5, F4).
