# Reglas de negocio

Fase 1, paso 4. Reglas acordadas en `CLAUDE.md`, `docs/registro-decisiones-2026-10-29.md` y las ADR. Las marcadas "provisional" o con un código S son supuestos de [supuestos.md](supuestos.md) que requieren validación del operador o jurídica. Las marcadas "diferencia" no coinciden con el código actual (revisión de seguridad del 17-11-2026) y se detallan en `04-desarrollo/control-de-acceso.md` sección 6.

## Organización
- **RN01.** Los hogares se agrupan en zonas. Cada hogar tiene una sola madre sustituta.
- **RN02.** La norma permite hasta 13 NNA por hogar; la capacidad registrada del hogar es el límite operativo (en la práctica 5 o 6).
- **RN03.** El coordinador solo actúa sobre su zona (`usuario.zona_id`). (ADR-0007, ADR-0010) ADR-0016 lo aplicó también a zonas, hogares, madres y traslados (origen y destino). Solo el admin crea zonas. Diferencia: los profesionales aún no tienen zona (S07).

## Visibilidad del expediente
- **RN04.** Se deniega por defecto. Un usuario ve un NNA solo si tiene relación con él: profesional asignado, madre con asignación vigente, coordinador de la zona, admin o auditor. El auditor lee los datos básicos y nunca recibe bytes de documentos. (ADR-0004, ADR-0007)
- **RN05.** Los profesionales asignados ven el expediente completo, incluidas las secciones sensibles. (ADR-0007 §2.1)
- **RN06.** Las secciones familia, salud y psicosocial son sensibles. La madre las ve solo si el defensor asignado se lo habilita. (ADR-0007 §2.4)
- **RN07.** Solo el defensor asignado al NNA otorga o revoca permisos a la madre. Provisional: requiere validación jurídica. (ADR-0007 §2.5)
- **RN08.** El coordinador y el auditor no ven secciones sensibles por defecto; en el código tampoco las ve el admin. El auditor ve metadatos de documentos y nunca recibe sus bytes; la excepción son las fotos de inventario (ADR-0014 §2.1). (ADR-0007 §2.2-2.3, ADR-0008 §4) El resumen de IA tampoco está disponible para el auditor (ADR-0016). Del NNA, el auditor ve solo iniciales, edad, estado, hogar y zona (S17).
- **RN09.** No hay módulo aparte por rol: cada rol tiene una vista distinta del mismo sistema.

## Ciclo de vida
- **RN10.** Un NNA tiene a lo sumo una asignación vigente. Un traslado cierra la anterior y abre la nueva en la misma operación. (ADR-0007 §4)
- **RN11.** Cuando el NNA sale del hogar, el expediente se oculta a la madre y se revocan sus permisos; nunca se elimina. (RF7, ADR-0007 §2.6)
- **RN12.** No existe borrado físico. Los cambios se guardan como historial en menores y asignaciones (`*_history`) y en documentos (versiones); las demás entidades se desactivan, se retiran o se cierran, y sus cambios quedan en la auditoría. (ADR-0004, ADR-0007 §3)
- **RN13.** El expediente se archiva cuando el NNA está egresado o fallecido y no tiene asignación vigente. La evasión no archiva. Provisional. (ADR-0010 §3.1)
- **RN14.** En un expediente archivado no se crean documentos, versiones, informes, citas ni alertas. Ningún proceso automático borra el paquete archivado. La retención y su base legal siguen sin definirse (punto abierto 2). (ADR-0010 §3.2, §3.4)

## Documentos
- **RN15.** La madre crea los documentos; los profesionales asignados revisan y aprueban o devuelven con motivo. (ADR-0008 §3)
- **RN16.** Estados del documento: borrador, en revisión, aprobado, devuelto. Una versión nueva vuelve a revisión. (ADR-0008 §3)
- **RN17.** Un documento creado por un profesional asignado queda aprobado. La migración del historial físico la hacen coordinador o admin con motivo obligatorio. (ADR-0008 §3)
- **RN18.** Una versión nunca sobrescribe a la anterior. (ADR-0004)
- **RN19.** La madre carga su firma una sola vez; cada persona responde por la validez de su firma. (`CLAUDE.md`) La firma se trata como firma electrónica simple: al firmar se guarda quién, cuándo, el hash del documento y la aceptación expresa de responsabilidad (S08). Diferencia: hoy `firma_ref` es una cadena de texto sin cifrar y no se aplica a los documentos.
- **RN20.** Al crear una categoría documental el admin declara de forma explícita su sección de acceso (básica, familia, salud o psicosocial); sin ella se rechaza, y no se puede cambiar después. (ADR-0013 §5.1)

## Alertas y citas
- **RN21.** La alerta de evasión llega por la aplicación al defensor y a la psicosocial asignados; si no tienen cuenta, al coordinador de la zona y, si no hay, a los admin. Nunca queda sin destinatarios. (ADR-0009 §1)
- **RN22.** La pantalla de evasión muestra los números de emergencia: Policía de Infancia y Adolescencia, defensor y psicosocial. (`CLAUDE.md`)
- **RN23.** Se registra quién recibió cada alerta y cuándo la vio. (`CLAUDE.md`)
- **RN24.** El sistema no asigna citas; solo las recuerda. (`CLAUDE.md`)
- **RN25.** Citas médicas, psicosociales y otras son de la madre; las reuniones con familia biológica son del defensor. El tipo no cambia después de creada. (ADR-0015 §2)
- **RN26.** Las notas de una cita son para logística, no para contenido clínico; se ocultan a quien no tenga permiso de la sección. (ADR-0009 §2)

## Vida del hogar
- **RN27.** El coordinador hace pedidos de inventario; la madre confirma la recepción con su estado, una sola vez, y puede adjuntar hasta 6 fotos con la declaración de que no muestran a ningún NNA. Solo madre, admin y auditor ven las fotos. (ADR-0014 §1, §2.1) Profesionales y defensores solo consultan inventario, convivientes y red de apoyo (S14). Diferencia: hoy pueden escribir.
- **RN28.** Solo la madre (o admin) registra alimentos; coordinador, profesionales y auditor consultan. (ADR-0015 §1)
- **RN29.** Un alimento perecedero exige fecha de vencimiento y uno no perecedero no la admite. Cada compra es un registro nuevo. (ADR-0009 §4, ADR-0014 §4, S05) Diferencia: hoy un perecedero sin fecha se acepta.

## IA
- **RN30.** La IA solo recupera y resume con cita a la fuente; no propone decisiones. (`CUESTIONARIO.md` D4)
- **RN31.** La IA solo ve lo que el usuario puede ver y consulta por la capa de aplicación, nunca directo al grafo. (ADR-0002, ADR-0006)
- **RN32.** Nada identificable sale hacia una IA externa: se seudonimizan los nombres conocidos y los patrones (correo, teléfono, fecha, documento) antes de la llamada. Enviar datos reales solo con contrato de tratamiento, habilitación explícita y NER de personas activo; el NER no está implementado y sigue bloqueando esa opción. Los documentos cargados se tratan como datos, nunca como instrucciones. (ADR-0002, ADR-0010 §1.4 y §1.6) La transferencia a un proveedor en el exterior requiere validación jurídica (punto abierto 4).

## Reportes
- **RN33.** Reportes en cuatro niveles: general, zona, NNA y madre, con el mismo control de acceso que la pantalla. Un reporte exportado revalida permisos al descargar. (ADR-0010 §2)

## Reglas adoptadas como supuesto (17-11-2026)
- **RN34.** Cuentas: solo el admin crea cuentas, con contraseña temporal que se cambia al primer ingreso; las cuentas se desactivan, no se borran. Tras 5 intentos fallidos la cuenta se bloquea 15 minutos. (S21, ADR-0016)
- **RN35.** Admin, auditor, coordinador, defensor y profesionales entran con segundo factor (código TOTP); la madre no. (S06)
- **RN36.** Cada NNA activo tiene asignados un defensor y una psicosocial. Los asigna el coordinador de la zona; la asignación termina con fecha de fin y no se borra. (S20)
- **RN37.** Documentos obligatorios: al ingreso, en 5 días hábiles, identidad, acta de ingreso y valoración de salud; en 30 días, valoración psicosocial, valoración nutricional y certificado escolar (de 5 a 17 años); informe psicosocial cada 60 días, seguimiento nutricional cada 90 días y reporte mensual de la madre cada 30 días. Si un plazo vence sin el documento, se genera una alerta de documento faltante. Los plazos son parámetros. (S04)
- **RN38.** Los documentos del hogar que envía la madre los revisa el coordinador de la zona. (S13)
- **RN39.** Solo los profesionales asignados registran familiares del NNA. (S19)
- **RN40.** La alerta de evasión la cierran el defensor o la psicosocial asignados, el coordinador de la zona o el admin, no la madre. Además del aviso en la aplicación, se envía una notificación push con hasta 3 reintentos cada 5 minutos mientras no la vean. (S12, S18)
- **RN41.** Las capacitaciones de la madre tienen fecha de vencimiento; el coordinador recibe aviso 30 días antes. (S22)
- **RN42.** Al cerrar el caso, el coordinador entrega el paquete al archivo central del operador y registra un acta con fecha, receptor y hash. El coordinador descarga el paquete sin secciones sensibles; el completo, solo el admin con motivo. (S09, S15)
- **RN43.** El expediente archivado se conserva 10 años desde el cierre; después se señala para revisión y su eliminación o anonimización exige aprobación de admin y auditor. Nunca hay borrado automático. (S10)
- **RN44.** El admin ve solo metadatos de las consultas de IA de otros usuarios. (S16)
