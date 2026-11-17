# Historias de usuario

Fase 1, paso 4. Formato: "Como <rol> quiero <acción> para <beneficio>". Criterios de aceptación en Dado / Cuando / Entonces.
Estimación en puntos de historia (1, 2, 3, 5, 8). Todas las historias tienen especificación completa; donde faltaba información se usa un supuesto de [supuestos.md](supuestos.md) (código S).
El estado indica la **implementación** en el código al 17-11-2026: **Hecha**, **Parcial** o **Pendiente**.
Roles: madre, profesional (psicosocial, nutrición, trabajo social), defensor, coordinador, auditor, admin.
Trazabilidad completa en [matriz-trazabilidad.md](matriz-trazabilidad.md).

## Épica E01. Autenticación y accesos (módulo 1)

**HU01. Iniciar sesión** (todos, 3 pts, RF0.1, RF0.3, Hecha)
Como usuario quiero entrar con mi correo y contraseña para usar el sistema según mi rol.
- Dado un usuario activo, cuando ingresa credenciales correctas, entonces recibe un token y ve su panel.
- Dado credenciales incorrectas, cuando intenta entrar, entonces ve "Usuario o contraseña incorrectos" sin saber cuál falló, y queda registrado en auditoría.
- Dado un token vencido (60 minutos), cuando hace una petición, entonces vuelve a la pantalla de inicio de sesión.

**HU02. Ver mi perfil** (todos, 1 pt, RF0.2, Hecha)
Como usuario quiero ver mi rol y mi zona para saber qué puedo hacer.
- Dado un usuario autenticado, cuando abre su perfil, entonces ve correo, rol y zona.
- Dado un usuario sin zona (madre, admin), entonces la zona aparece vacía sin error.

**HU03. Cambiar mi contraseña** (todos, 2 pts, RF0.4, Parcial)
Como usuario quiero cambiar mi contraseña para mantener segura mi cuenta.
- Dado la contraseña actual correcta y una nueva de al menos 10 caracteres, cuando la guardo, entonces la anterior deja de funcionar y mis otras sesiones se cierran.
- Dado una contraseña actual incorrecta, cuando guardo, entonces veo el error sin que se cierre mi sesión.
- Dado una nueva igual a la actual o a mi correo, entonces se rechaza.
- Implementación: API lista (`PUT /auth/contrasena`); falta la pantalla.

**HU04. Bloqueo por intentos fallidos** (seguridad, 3 pts, RF0.5, Hecha)
Como admin quiero que una cuenta se bloquee temporalmente tras varios intentos fallidos para evitar ataques de adivinación.
- Dado 5 intentos fallidos seguidos, cuando se intenta de nuevo, entonces se rechaza durante 15 minutos con un mensaje de espera, incluso con la clave correcta.
- Dado un ingreso correcto antes del quinto intento, entonces el contador vuelve a cero.
- Entonces cada bloqueo queda en auditoría.

**HU05. Administrar usuarios** (admin, 5 pts, RF0.6, Pendiente)
Como admin quiero crear, desactivar y asignar rol y zona a los usuarios para dar acceso sin tocar la base de datos.
- Dado un correo nuevo, un rol y (para coordinador) una zona, cuando creo la cuenta, entonces el sistema genera una contraseña temporal que veo una sola vez.
- Dado un correo ya registrado, entonces se rechaza.
- Dado un usuario desactivado, cuando intenta entrar, entonces se le niega el acceso y sus tokens dejan de valer; la cuenta no se borra.
- Dado un coordinador sin zona, entonces no se puede guardar.

**HU06. Cambiar la contraseña temporal al primer ingreso** (todos, 2 pts, RF0.7, Pendiente, S21)
Como usuario nuevo quiero que el sistema me pida cambiar la contraseña temporal para que solo yo la conozca.
- Dado una cuenta con contraseña temporal, cuando entro, entonces solo veo la pantalla de cambio de contraseña hasta completarla.
- Dado que la cambio, entonces entro a mi panel con normalidad.

**HU07. Segundo factor de autenticación** (admin, auditor, coordinador, defensor, profesional, 5 pts, RF0.8, Pendiente, S06)
Como profesional quiero confirmar mi ingreso con un código de mi celular para que nadie entre con solo mi contraseña.
- Dado un rol con segundo factor y sin activarlo, cuando entro, entonces el sistema me muestra un código QR para registrar la aplicación autenticadora y 10 códigos de recuperación.
- Dado el segundo factor activo, cuando ingreso la contraseña correcta, entonces debo escribir el código de 6 dígitos; un código incorrecto cuenta como intento fallido.
- Dado un código de recuperación, cuando lo uso, entonces entro y ese código deja de servir.
- Dado una madre, entonces no se le pide segundo factor.

## Épica E02. Zonas y hogares (módulo 2)

**HU08. Crear y editar zonas** (admin, 2 pts, RF17.1, Hecha)
Como admin quiero registrar las zonas para organizar los hogares.
- Dado un nombre de zona nuevo, cuando lo guardo, entonces aparece en el listado.
- Dado un coordinador, cuando intenta crear una zona, entonces recibe 403 y no ve el formulario.

**HU09. Registrar un hogar** (admin, coordinador, 3 pts, RF17.2, Hecha)
Como coordinador quiero registrar un hogar con capacidad, habilitación y madre para tener el mapa de mi zona.
- Dado una capacidad fuera de 1 a 13, entonces se rechaza.
- Dado un hogar de otra zona, cuando intento crearlo, verlo o editarlo, entonces recibo 403 y queda en auditoría.
- Dado una madre ya vinculada a otro hogar, cuando la vinculo, entonces se rechaza.

**HU10. Consultar hogares de mi zona** (coordinador, 1 pt, RF17.2, Hecha)
Como coordinador quiero listar los hogares de mi zona para conocer su ocupación.
- Dado que soy coordinador, cuando abro la lista, entonces solo veo hogares de mi zona con capacidad y estado.
- Dado que pido otra zona, entonces recibo 403.

## Épica E03. Madres sustitutas (módulo 3)

**HU11. Registrar una madre sustituta** (coordinador, admin, 3 pts, RF17.3, Hecha)
Como coordinador quiero registrar los datos de una madre para vincularla a un hogar.
- Dado un número de identificación repetido, entonces se rechaza.
- Dado que soy coordinador, entonces solo veo madres de hogares de mi zona y madres aún sin hogar.

**HU12. Ver mi perfil de madre** (madre, 1 pt, RF0.2, Hecha)
Como madre quiero ver mis datos y mi hogar para confirmar que están correctos.
- Dado que tengo hogar, cuando abro mi perfil, entonces veo mis datos y el identificador de mi hogar.
- Dado un usuario madre sin perfil, entonces veo un aviso de que mi perfil no está creado.

**HU13. Cargar mi firma una sola vez** (madre, 3 pts, RF5.1, Parcial)
Como madre quiero subir la imagen de mi firma una vez para no firmar cada documento a mano.
- Dado una imagen PNG o JPEG de mi firma, cuando la guardo, entonces queda en mi perfil, cifrada, y se reutiliza al firmar.
- Dado que la reemplazo, entonces la anterior queda en el historial y el cambio en auditoría.
- Implementación: hoy se guarda una referencia de texto sin cifrar.

**HU14. Firmar un documento** (madre, profesional, 5 pts, RF5.2, Pendiente, S08)
Como madre quiero firmar mi documento con la firma que ya cargué para presentarlo sin imprimirlo.
- Dado un documento en borrador, cuando elijo "Firmar y enviar", entonces veo el texto "Declaro que este documento es veraz y lo firmo bajo mi responsabilidad" y debo aceptarlo.
- Entonces el sistema guarda quién firmó, cuándo y el hash del documento, y muestra la firma en el visor.
- Dado que el documento cambia después (nueva versión), entonces la firma anterior no vale para la versión nueva.

**HU15. Registrar capacitaciones con vencimiento** (coordinador, 5 pts, RF17.4, RF9.10, Pendiente, S22)
Como coordinador quiero registrar las capacitaciones de cada madre con fecha de vencimiento para saber cuándo renovarlas.
- Dado tipo, entidad, fecha y vencimiento, cuando la guardo, entonces aparece en el perfil de la madre.
- Dado una capacitación que vence en 30 días o menos, entonces recibo una alerta.
- Dado una madre, entonces ve sus capacitaciones pero no las edita.

## Épica E04. Profesionales (módulo 4)

**HU16. Registrar profesionales** (coordinador, admin, 2 pts, RF17.5, Hecha)
Como coordinador quiero registrar defensores y profesionales con cargo y teléfono para asignarlos a los NNA.
- Dado un cargo distinto de defensor, psicosocial, nutrición o trabajo social, entonces se rechaza.
- Dado un profesional sin teléfono, entonces se guarda y la pantalla de evasión lo señala.

**HU17. Asociar profesionales a zonas** (coordinador, admin, 3 pts, RF17.6, Pendiente, S07)
Como admin quiero indicar en qué zonas trabaja cada profesional para que cada coordinador administre solo su equipo.
- Dado un profesional con una o varias zonas, cuando un coordinador lista profesionales, entonces solo ve los de su zona.
- Dado un profesional de otra zona, cuando el coordinador intenta editarlo, entonces recibe 403.

**HU18. Asignar profesionales a un NNA** (coordinador, 3 pts, RF1.6, Pendiente, S20)
Como coordinador quiero indicar el defensor, la psicosocial y demás profesionales de cada NNA para que reciban permisos y alertas.
- Dado un NNA de mi zona y un profesional de mi zona, cuando lo asigno con un rol, entonces el profesional ve ese NNA en su panel.
- Dado un NNA activo sin defensor o sin psicosocial, entonces aparece señalado en el panel de zona.
- Dado que termino una asignación con fecha de fin, entonces el profesional pierde el acceso y la asignación queda en el historial.

## Épica E05. Menores y expedientes (módulo 5)

**HU19. Crear expediente de un NNA** (coordinador, defensor, admin, 5 pts, RF1.1, Hecha)
Como coordinador quiero crear la carpeta digital de un NNA al ingresar para reemplazar la carpeta física.
- Dado un NNA sin documento de identidad, cuando lo registro, entonces se acepta con tipo `sin_documento`.
- Dado un número de documento repetido, cuando lo guardo, entonces se rechaza.

**HU20. Editar datos del NNA con historial** (coordinador, defensor, 3 pts, RF1.3, RF3.2, RF7.2, Hecha)
Como defensor quiero corregir datos del NNA sin perder los valores anteriores para tener trazabilidad.
- Dado un cambio, cuando se guarda, entonces la versión anterior queda en el historial con quién y cuándo.
- Dado un usuario sin relación con el NNA, cuando intenta editar, entonces recibe 403.

**HU21. Registrar familia biológica** (profesional, defensor, 3 pts, RF1.2, Parcial, S19)
Como profesional quiero registrar padre, madre u otros familiares para tener sus datos de contacto.
- Dado que soy profesional asignado, cuando registro un familiar, entonces queda en la sección familia.
- Dado una madre sin permiso de la sección familia, cuando abre el expediente, entonces no ve la sección.
- Dado un coordinador o admin, cuando intenta registrar un familiar, entonces recibe 403 (hoy se permite).

**HU22. Panel del profesional** (profesional, defensor, 5 pts, RF1.4, Hecha)
Como profesional quiero ver mis NNA agrupados por hogar y zona, con alertas, documentos por revisar y próximas citas, para organizar mi trabajo.
- Dado un NNA no asignado a mí, cuando abro el panel, entonces no aparece.
- Dado un documento en revisión de mi NNA, entonces aparece en "por revisar".

**HU23. Panel del coordinador** (coordinador, 3 pts, RF1.5, Hecha)
Como coordinador quiero ver los NNA de mi zona para supervisar ocupación y alertas.
- Dado que soy coordinador, entonces veo solo los NNA con asignación vigente en hogares de mi zona.
- Dado un coordinador sin zona, entonces el panel aparece vacío.

**HU24. Habilitar secciones sensibles a la madre** (defensor, 5 pts, RF6.2, Hecha)
Como defensor quiero habilitar o revocar a la madre las secciones familia, salud o psicosocial para que vea solo lo necesario.
- Dado que soy el defensor asignado, cuando habilito "salud", entonces la madre ve los documentos de salud.
- Dado un psicosocial asignado (no defensor), cuando intenta habilitar, entonces recibe 403.
- Dado un permiso revocado, entonces queda inactivo, no se borra.

**HU25. Ver solo mis NNA como madre** (madre, 3 pts, RF6.1, RF7.1, Hecha)
Como madre quiero ver solo los NNA que viven en mi hogar para concentrarme en ellos.
- Dado un NNA de otro hogar, cuando intento abrirlo, entonces no lo veo.
- Dado un NNA que sale de mi hogar, entonces deja de aparecer en mi lista.

**HU26. Ver datos minimizados como auditor** (auditor, 2 pts, RF6.5, Pendiente, S17)
Como auditor quiero ver el estado de los expedientes sin datos personales completos para controlar el proceso sin exponer al NNA.
- Dado un NNA, cuando lo consulto, entonces veo iniciales, edad, estado, hogar y zona.
- Entonces no veo número de documento, nombre completo ni secciones sensibles.

## Épica E06. Asignaciones y traslados (módulo 6)

**HU27. Asignar NNA a un hogar** (coordinador, 3 pts, RF1.7, Hecha)
Como coordinador quiero registrar el ingreso de un NNA a un hogar con fecha de inicio para que la madre empiece a gestionar su expediente.
- Dado un NNA con asignación vigente, cuando creo otra de tipo ingreso, entonces se rechaza.
- Dado un hogar de otra zona, entonces recibo 403.

**HU28. Trasladar un NNA** (coordinador, 5 pts, RF1.8, Hecha)
Como coordinador quiero trasladar un NNA a otro hogar con acta y motivo para que el cambio quede documentado.
- Dado un traslado, cuando se guarda, entonces se cierra la asignación anterior y se abre la nueva en una sola operación, y la madre anterior deja de ver el expediente.
- Dado un NNA que está en un hogar de otra zona, cuando intento traerlo a mi zona, entonces recibo 403.

**HU29. Cerrar asignación (egreso)** (coordinador, 3 pts, RF1.9, RF7.1, Hecha)
Como coordinador quiero cerrar la asignación con fecha de fin y motivo para reflejar la salida del NNA.
- Entonces se revocan los permisos de la madre sobre ese NNA y queda historial.
- Dado una asignación ya cerrada, cuando intento cerrarla de nuevo, entonces se rechaza.

**HU30. Ver historial de asignaciones** (coordinador, profesional, 2 pts, RF3.2, Hecha)
Como profesional quiero ver por qué hogares ha pasado un NNA para conocer su recorrido.
- Dado un NNA con traslados, entonces veo cada asignación con fechas, tipo de movimiento y motivo.
- Dado una madre, entonces no ve el historial de asignaciones.

## Épica E07. Gestión documental (módulo 7)

**HU31. Subir un documento desde el celular** (madre, 5 pts, RF2.1, RF2.2, RF2.3, RF4.1, Hecha)
Como madre quiero tomar una foto o elegir un archivo y subirlo al expediente para no guardar papel.
- Dado un PDF, Word, Excel, foto o texto, cuando lo subo con categoría y título, entonces queda en borrador, cifrado y con su hash.
- Dado un archivo que no es lo que dice ser (por ejemplo, un ejecutable con extensión .jpg), entonces se rechaza.
- Dado una categoría sensible sin permiso, cuando intento subir, entonces se rechaza.

**HU32. Enviar a revisión** (madre, 1 pt, RF4.1, Hecha)
Como madre quiero enviar mi documento a revisión para que el profesional lo apruebe.
- Dado un documento en borrador, cuando lo envío, entonces pasa a "en revisión" y aparece en el panel de los profesionales asignados.
- Dado un documento ya aprobado, entonces no se puede enviar de nuevo.

**HU33. Revisar, aprobar o devolver** (profesional, defensor, 5 pts, RF4.2, Hecha)
Como profesional quiero ver los documentos pendientes de mis NNA y aprobarlos o devolverlos con motivo para reducir el tiempo de revisión.
- Dado un documento devuelto sin motivo, cuando intento guardar, entonces se exige el motivo.
- Dado un profesional no asignado al NNA, cuando intenta aprobar, entonces recibe 403.

**HU34. Revisar documentos del hogar** (coordinador, 3 pts, RF4.5, Pendiente, S13)
Como coordinador quiero aprobar o devolver los documentos del hogar que envía la madre para que no queden sin revisor.
- Dado un documento del hogar en revisión de mi zona, cuando lo apruebo o devuelvo con motivo, entonces cambia de estado.
- Dado un hogar de otra zona, entonces recibo 403.

**HU35. Corregir con nueva versión** (madre, 3 pts, RF3.1, Hecha)
Como madre quiero subir una versión corregida de un documento devuelto para que vuelva a revisión sin perder la anterior.
- Dado un documento devuelto, cuando subo la nueva versión, entonces pasa a "en revisión" y la anterior queda en el historial.
- Dado un documento aprobado, entonces no admite versión nueva.

**HU36. Consultar versiones anteriores** (profesional, coordinador, 2 pts, RF3.2, RF3.3, Hecha)
Como profesional quiero ver y descargar versiones anteriores para comparar cambios.
- Dado un documento con versiones, entonces veo cada una con autor, fecha y estado.
- Dado un auditor, entonces ve la lista pero no descarga el contenido.

**HU37. Ver un documento en pantalla** (todos con permiso, 3 pts, RF2.4, Hecha)
Como usuario quiero ver el documento dentro de la aplicación para no descargarlo al celular.
- Dado un PDF o una imagen, entonces se abre en el visor.
- Dado otro tipo (Word, Excel), entonces el sistema ofrece descargarlo.

**HU38. Ver documentos por sección del expediente** (profesional, madre con permiso, 3 pts, RF6.1, Hecha)
Como profesional quiero ver juntos los documentos e informes de salud o psicosocial de un NNA para tener el panorama completo.
- Dado que tengo permiso de la sección, entonces veo documentos e informes juntos, ordenados por fecha.
- Dado que no tengo permiso, entonces recibo 403.

**HU39. Registrar informe profesional** (profesional, 3 pts, RF4.3, RF4.4, Hecha)
Como psicosocial quiero registrar mis informes de seguimiento para que queden en el expediente sin pasar por aprobación.
- Dado un informe nuevo, entonces queda guardado con autor y fecha.
- Dado una corrección, entonces se registra como informe nuevo y el anterior se conserva.

**HU40. Digitalizar el historial físico** (coordinador, admin, 5 pts, RF10.1, Hecha)
Como coordinador quiero cargar los documentos de las carpetas físicas marcados como migración para completar el expediente digital.
- Dado `migracion=true` sin motivo, entonces se rechaza.
- Dado un documento de migración con motivo, entonces queda aprobado.

**HU41. Auditar metadatos de documentos** (auditor, 2 pts, RF6.3, RF6.4, Hecha)
Como auditor quiero ver quién creó, revisó y aprobó cada documento, sin ver su contenido, para verificar el proceso.
- Dado un auditor, cuando pide el contenido de un archivo, entonces recibe 403.
- Dado un auditor, entonces ve autor, revisor, fechas, estado, versión y hash.

## Épica E08. Inventario del hogar (módulo 8)

**HU42. Pedir camas y muebles** (coordinador, 3 pts, RF13.1, Hecha)
Como coordinador quiero registrar un pedido de inventario para un hogar para hacer seguimiento a la entrega.
- Dado un pedido, entonces nace como "no recibido".
- Dado un pedido no recibido, entonces puedo editar tipo y cantidad; ya recibido, no.

**HU43. Confirmar recepción con foto** (madre, 3 pts, RF13.2, Hecha)
Como madre quiero confirmar que llegó lo pedido, indicar su estado y tomar una foto para dejar evidencia.
- Dado un ítem ya recibido, cuando intento confirmar de nuevo, entonces se rechaza.
- Dado una foto, cuando la subo, entonces debo aceptar la declaración de que no muestra a los NNA, y debe ser una imagen JPEG, PNG o WEBP real.

**HU44. Registrar inventario existente** (madre, 2 pts, RF13.3, Hecha)
Como madre quiero registrar lo que ya hay en mi hogar para tener el inventario inicial.
- Dado un ítem que registro yo, entonces nace como recibido con su estado.
- Dado un ítem dañado, cuando lo retiro, entonces queda como "retirado", no se borra.

**HU45. Registrar convivientes** (madre, coordinador, 2 pts, RF13.3, Hecha)
Como coordinador quiero saber qué personas viven en el hogar para evaluar el entorno del NNA.
- Dado una persona que deja de vivir en el hogar, entonces se desactiva y se conserva.

**HU46. Registrar red de apoyo** (madre, coordinador, 2 pts, RF13.4, Hecha)
Como madre quiero registrar mis contactos de apoyo para tenerlos a mano.
- Dado un contacto, entonces queda con nombre, relación y teléfono.
- Dado un contacto que ya no aplica, entonces se desactiva.

**HU47. Consultar el inventario sin modificarlo** (profesional, defensor, 2 pts, RF13.5, Parcial, S14)
Como psicosocial quiero consultar el inventario, los convivientes y la red de apoyo del hogar de mis NNA para evaluar el entorno, sin poder modificarlos.
- Dado un hogar con un NNA asignado a mí, entonces veo inventario, convivientes y red de apoyo.
- Dado que intento crear o editar, entonces recibo 403 (hoy se permite).

## Épica E09. Control de alimentos (módulo 9)

**HU48. Registrar una compra de alimentos** (madre, 2 pts, RF14.1, Parcial, S05)
Como madre quiero registrar lo que compro con fecha de ingreso y vencimiento para no dejar que se dañe.
- Dado un producto no perecedero con fecha de vencimiento, entonces se rechaza.
- Dado un producto perecedero sin fecha de vencimiento, entonces se rechaza (hoy se acepta).

**HU49. Usar mi lista de productos** (madre, 3 pts, RF14.2, Hecha)
Como madre quiero tener una lista de productos frecuentes y solo escribir fecha y cantidad al comprar para ahorrar tiempo.
- Dado un producto de la lista, cuando elijo "comprar", entonces solo escribo fecha, vencimiento y cantidad.
- Entonces cada compra queda como registro nuevo.

**HU50. Ver productos vencidos y marcar consumidos** (madre, 2 pts, RF14.3, Hecha)
Como madre quiero ver qué está vencido y marcar lo consumido para mantener la despensa al día.
- Dado el filtro de vencidos, entonces veo solo perecederos vencidos y no consumidos.

**HU51. Supervisar alimentos de un hogar** (coordinador, nutrición, 1 pt, RF14.4, Hecha)
Como nutricionista quiero consultar el registro de alimentos del hogar de mis NNA para verificar la alimentación, sin poder modificarlo.
- Dado que intento registrar o editar, entonces recibo 403.

## Épica E10. Citas y recordatorios (módulo 10)

**HU52. Registrar citas del NNA** (madre, 2 pts, RF15.1, Hecha)
Como madre quiero anotar las citas médicas y psicosociales de mis NNA para que el sistema me las recuerde.
- Dado tipo, fecha y lugar, entonces la cita queda pendiente.
- Dado un coordinador o profesional, cuando intenta crear una cita médica, entonces recibe 403.

**HU53. Programar reunión con familia biológica** (defensor, 2 pts, RF15.1, Hecha)
Como defensor quiero registrar la fecha de la visita con la familia biológica para que la madre la vea.
- Dado una madre, cuando intenta crear una cita de tipo reunión con familia, entonces recibe 403.
- Dado la reunión creada, entonces la madre la ve en sus próximas citas.

**HU54. Ver próximas citas** (todos con relación al NNA, 2 pts, RF15.2, Hecha)
Como madre quiero ver en mi panel las próximas citas para no olvidarlas.
- Entonces veo solo citas pendientes futuras de mis NNA, ordenadas por fecha.

**HU55. Marcar cita cumplida o no asistida** (dueño de la cita, 1 pt, RF15.3, Hecha)
Como madre quiero marcar si asistimos a la cita para que el profesional lo sepa.
- Dado una cita que no es mía (por ejemplo, reunión del defensor), entonces no puedo cambiar su estado.

**HU56. Proteger notas de citas** (seguridad, 2 pts, RF15.4, Hecha)
Como defensor quiero que las notas de una cita médica no las vea quien no tiene permiso de salud para proteger datos sensibles.
- Dado un usuario sin permiso de la sección, entonces ve la cita con las notas vacías.

## Épica E11. Alertas y evasiones (módulo 11)

**HU57. Reportar una evasión** (madre, profesional, coordinador, 5 pts, RF9.1, RF9.2, RF9.3, Hecha)
Como madre quiero reportar que un NNA se evadió y ver de inmediato los números de emergencia para actuar rápido.
- Dado el reporte, cuando lo envío, entonces en la misma pantalla veo Policía de Infancia y Adolescencia, defensor y psicosocial.
- Dado un profesional sin teléfono registrado, entonces la pantalla lo indica.

**HU58. Recibir la alerta de evasión** (defensor, psicosocial, 3 pts, RF9.2, RF9.4, Hecha)
Como defensor quiero recibir la alerta en la aplicación y que quede registrado cuándo la vi para responder y dejar constancia.
- Dado que defensor y psicosocial no tienen cuenta, entonces la alerta llega al coordinador de la zona o, si no hay, al admin.
- Dado que abro la alerta, entonces queda registrada la fecha en que la vi.

**HU59. Recibir aviso en el celular** (defensor, psicosocial, 8 pts, RF9.7, Pendiente, S12)
Como defensor quiero recibir una notificación en el celular cuando hay una evasión para enterarme aunque no tenga la aplicación abierta.
- Dado que acepté notificaciones, cuando se reporta una evasión de mi NNA, entonces recibo una notificación push.
- Dado que no la veo, entonces se repite cada 5 minutos hasta 3 veces.
- Entonces queda la fecha de cada envío.

**HU60. Ver mis alertas pendientes** (profesional, coordinador, 2 pts, RF9.4, Hecha)
Como profesional quiero ver las alertas que no he leído para no perder ninguna.
- Entonces veo solo las alertas donde soy destinatario y no las he visto.

**HU61. Alertas automáticas de visitas vencidas** (sistema, coordinador, 3 pts, RF9.5, Hecha)
Como coordinador quiero que el sistema genere alertas de citas vencidas sin duplicarlas para hacer seguimiento.
- Dado una cita pendiente con fecha pasada, entonces se genera una alerta.
- Dado que ya existe una alerta activa para esa cita, entonces no se duplica.

**HU62. Alertas de documentos faltantes** (profesional, madre, 5 pts, RF9.6, Parcial, S04)
Como psicosocial quiero recibir una alerta cuando falta un documento obligatorio del NNA para cumplir los plazos.
- Dado un NNA que ingresó hace 5 días hábiles sin identidad, acta de ingreso o valoración de salud, entonces se genera una alerta por cada documento faltante.
- Dado un NNA con 30 días sin valoración psicosocial, nutricional o certificado escolar (de 5 a 17 años), entonces se genera la alerta.
- Dado un NNA sin informe psicosocial en 60 días, sin seguimiento nutricional en 90 o sin reporte mensual de la madre en 30, entonces se genera la alerta.
- Implementación: hoy solo existe la regla de 60 días.

**HU63. Cerrar una alerta** (defensor, psicosocial, coordinador, admin, 1 pt, RF9.8, RF9.9, Parcial, S18)
Como coordinador quiero cerrar una alerta atendida para que no siga en pendientes, sin borrarla.
- Dado una alerta, cuando la cierro, entonces queda en estado cerrada y se conserva.
- Dado una madre que reportó una evasión, cuando intenta cerrarla, entonces recibe 403 (hoy se permite).

**HU64. Alerta de capacitación por vencer** (coordinador, 2 pts, RF9.10, Pendiente, S22)
Como coordinador quiero recibir una alerta cuando la capacitación de una madre está por vencer para programar la renovación.
- Dado una capacitación que vence en 30 días o menos, entonces recibo una alerta, una sola vez.

## Épica E12. Reportes (módulo 12)

**HU65. Reporte general** (admin, auditor, coordinador, 3 pts, RF16.1, Hecha)
Como admin quiero ver indicadores generales (NNA por estado, ocupación, documentos pendientes, alertas, citas y alimentos vencidos) para tomar decisiones.
- Dado un coordinador, entonces recibe solo los datos de su zona.

**HU66. Reporte por zona** (coordinador, 2 pts, RF16.2, Hecha)
Como coordinador quiero un reporte de mi zona para presentarlo al operador.
- Dado otra zona, entonces recibo 403.

**HU67. Reporte por NNA** (profesional, 3 pts, RF16.3, Hecha)
Como profesional quiero un resumen del expediente de un NNA para preparar comités o audiencias.
- Dado que no tengo permiso de una sección sensible, entonces esa sección aparece solo como conteo.

**HU68. Reporte por madre** (madre, coordinador, 2 pts, RF16.4, Hecha)
Como madre quiero ver un resumen de mi hogar, mis NNA y mis documentos para saber qué tengo pendiente.
- Dado otra madre, entonces recibo 403.

**HU69. Exportar reportes** (coordinador, admin, 3 pts, RF16.5, Hecha)
Como coordinador quiero exportar un reporte en PDF o CSV para entregarlo al operador.
- Dado que perdí el permiso después de exportar, cuando intento descargar, entonces se niega.

**HU70. Ver indicadores de éxito** (admin, coordinador, 3 pts, RF16.6, Pendiente, S02, S03)
Como admin quiero ver el tiempo medio de búsqueda, el tiempo medio de revisión y los documentos digitalizados por mes para saber si el sistema cumple su objetivo.
- Entonces cada indicador se muestra junto a la línea base en papel y la meta.
- Dado un coordinador, entonces ve los indicadores de su zona.

## Épica E13. Asistente de IA (T1)

**HU71. Preguntar en lenguaje natural** (profesional, madre, 5 pts, RF12.1, Hecha)
Como profesional quiero preguntar "¿qué dijo el último informe nutricional de este NNA?" y recibir la respuesta con cita al documento para encontrar información rápido.
- Dado que no hay fuente, entonces responde que no encontró información.
- Dado un documento que no puedo ver, entonces nunca aparece en la respuesta.

**HU72. Resumir expediente o documento** (profesional, 3 pts, RF12.2, Hecha)
Como profesional quiero un resumen del expediente o de un documento largo para prepararme antes de una visita.
- Entonces el resumen cita cada documento usado.
- Dado un auditor, entonces recibe 403.

**HU73. Clasificación sugerida al subir** (madre, 3 pts, RF12.3, Hecha)
Como madre quiero que el sistema me sugiera la categoría del documento para no equivocarme.
- Entonces la sugerencia la puedo aceptar o cambiar antes de guardar.

**HU74. Extraer texto de escaneados (OCR)** (sistema, 5 pts, RF12.4, Hecha)
Como profesional quiero que los documentos escaneados se puedan buscar por su texto para encontrarlos con la IA.
- Dado un PDF escaneado o una foto, entonces el texto se extrae en el servidor, sin enviarlo a terceros.

**HU75. Detectar inconsistencias entre documentos** (profesional, 5 pts, RF12.5, Parcial, S04)
Como defensor quiero que el sistema me señale datos contradictorios entre documentos del NNA para corregirlos a tiempo.
- Dado dos documentos con fechas de nacimiento o números de identificación distintos, entonces el sistema los señala citando ambos.
- Entonces el sistema no corrige nada por su cuenta.

**HU76. Apoyo a la redacción** (madre, profesional, 3 pts, RF12.6, Hecha)
Como madre quiero ayuda para redactar mi reporte mensual para escribirlo con claridad.
- Entonces recibo un borrador que edito antes de guardar.

**HU77. Ver mi historial de consultas** (todos, 2 pts, RF12.8, Hecha)
Como usuario quiero ver mis consultas anteriores para no repetirlas.
- Dado que perdí acceso al NNA, entonces la consulta aparece sin el contenido.

**HU78. Proteger datos ante la IA externa** (seguridad, 5 pts, RF12.7, Hecha)
Como admin quiero que los nombres y documentos se reemplacen por seudónimos antes de llamar a la IA externa para cumplir la Ley 1581.
- Entonces el proveedor externo nunca recibe nombres, documentos ni teléfonos conocidos.

**HU79. Limitar el historial de IA para el admin** (admin, 2 pts, RF12.9, Pendiente, S16)
Como responsable de privacidad quiero que el admin vea solo metadatos de las consultas de otros usuarios para minimizar el acceso a datos sensibles.
- Dado una consulta de otro usuario, entonces el admin ve fecha, usuario y si hubo resultado, sin pregunta ni respuesta.

## Épica E14. Auditoría (T2)

**HU80. Registrar todo acceso** (sistema, 3 pts, RF11.1, Parcial)
Como auditor quiero que toda lectura, escritura e intento denegado quede registrado para reconstruir quién vio qué.
- Entonces cada fila tiene usuario, acción, recurso, NNA, fecha e IP.
- Dado un intento de modificar o borrar una fila de auditoría en la base, entonces se rechaza.
- Implementación: falta la IP fuera del inicio de sesión y el registro de lecturas de listados.

**HU81. Consultar la auditoría** (auditor, admin, 2 pts, RF11.2, Hecha)
Como auditor quiero filtrar los accesos por usuario, acción, NNA y fecha para hacer control interno.
- Dado otro rol, entonces recibe 403.

## Épica E15. Archivo y cierre (T3)

**HU82. Archivar expediente al cierre** (coordinador, admin, 5 pts, RF8.1, RF8.2, Hecha)
Como coordinador quiero archivar el expediente de un NNA egresado en un paquete verificable para cerrar el caso.
- Dado un NNA evadido o con asignación vigente, entonces no se puede archivar.
- Dado un expediente archivado, cuando alguien intenta crear un documento, entonces se rechaza.

**HU83. Descargar paquete archivado** (coordinador de la zona, admin, 2 pts, RF8.3, Parcial, S15)
Como coordinador quiero descargar el paquete archivado para entregarlo.
- Dado que soy coordinador de la zona, entonces descargo el paquete sin las secciones sensibles (hoy las incluye).
- Dado que soy admin, cuando indico un motivo, entonces descargo el paquete completo y queda en auditoría.
- Dado un auditor, entonces solo ve los metadatos.

**HU84. Registrar la entrega al destino final** (coordinador, 3 pts, RF8.4, Pendiente, S09)
Como coordinador quiero registrar a quién entregué el paquete del expediente cerrado para dejar constancia de la custodia.
- Dado un expediente archivado, cuando registro fecha, receptor y entidad, entonces queda un acta con el hash del paquete.
- Entonces el estado del archivo pasa a "entregado" y la copia del sistema se conserva.

**HU85. Señalar expedientes por tiempo de retención** (admin, auditor, 3 pts, RF8.5, Pendiente, S10)
Como admin quiero que el sistema me muestre los expedientes que cumplieron 10 años de archivo para decidir con el auditor qué hacer.
- Dado un expediente con 10 años desde el cierre, entonces aparece en la lista de revisión.
- Dado que se decide eliminar o anonimizar, entonces se exige la aprobación de admin y de auditor, y queda en auditoría.

## Épica E16. Configuración administrable (T4)

**HU86. Administrar catálogos** (admin, 3 pts, RF18.1, Hecha)
Como admin quiero agregar o desactivar categorías documentales y otras opciones sin programar para adaptar el sistema al operador.
- Dado una categoría nueva, entonces queda con la visibilidad menos privilegiada.

**HU87. Administrar parámetros** (admin, 2 pts, RF18.2, Hecha)
Como admin quiero cambiar el teléfono de la Policía de Infancia, umbrales y plazos de alertas y datos del operador sin redesplegar.
- Dado un valor nuevo, entonces la pantalla de evasión y las alertas lo usan de inmediato.

## Épica E17. Accesibilidad y uso móvil (transversal, RNF15 a RNF18)

**HU88. Usar el sistema desde un Android** (madre, 5 pts, RNF18, Hecha)
Como madre quiero usar el sistema en mi celular con botones grandes para trabajar desde el hogar.
- Dado una pantalla de 360 px de ancho, entonces no hay desplazamiento horizontal y los botones miden al menos 44 px.

**HU89. Textos grandes y alto contraste** (madre, 3 pts, RNF16, Parcial)
Como madre con baja visión quiero agrandar el texto y ver buen contraste para leer sin esfuerzo.
- Dado el texto ampliado al 200 %, entonces la pantalla sigue usable.
- Entonces todo texto tiene contraste de 4.5:1 o más (hoy fallan el blanco sobre turquesa y el botón Salir).

**HU90. Tareas de la madre en pocos pasos** (madre, 3 pts, RNF15, Parcial, S24)
Como madre quiero hacer mis tareas principales sin ayuda para no depender del profesional.
- Dado subir un documento, ver citas, registrar una compra o reportar una evasión, entonces lo hago en 3 pasos o menos.
- Dado la prueba con 5 madres, entonces el 80 % completa las tareas sin ayuda y el puntaje SUS es de 68 o más.

## Resumen
| Estado de implementación | Historias |
|---|---|
| Hecha | 63 |
| Parcial | 12 |
| Pendiente | 15 |
| Total | 90 historias en 17 épicas |

La numeración cambió respecto a la versión anterior (77 historias) al agregar las historias que salen de los supuestos; la matriz de trazabilidad usa la numeración nueva.
