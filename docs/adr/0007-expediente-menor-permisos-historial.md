# ADR-0007 Expediente del menor: modelo de datos, permisos por sección e historial

Estado: Aceptada por seguridad en los 3 puntos que quedaron abiertos (coordinador, auditor, quién otorga permiso a la madre — ver sección "Permisos por expediente", puntos 2, 3 y 5). El punto 5 (quién otorga el permiso) requiere además validación jurídica (marcado abajo); el resto del ADR, incluido el modelo de datos y el patrón `*_History`, sigue a cargo de arquitecto/backend sin cambios.

## Contexto
Fase 2 (`docs/plan-por-fases.md`) construye los módulos 5 (Menores y Expedientes) y 6 (Asignaciones y Traslados) sobre lo ya migrado en Fase 1: tablas `menores` y `asignaciones` mínimas, `menores_profesionales` (quién atiende a cada menor, de donde salen permisos y alertas según `docs/modulos.md`), y las tablas `documentos`/`reportes` ya creadas en la migración `0001` para el módulo de Fase 3.

Reglas de negocio que aplican (`CLAUDE.md`, `CUESTIONARIO.md` E4): el profesional encargado de cada NNA define qué parte del expediente ve cada persona; los datos sensibles (salud, psicosocial) son para los profesionales y para la madre asignada solo si el profesional la habilita; al salir el NNA del hogar el expediente se oculta a la madre pero nunca se elimina (RF7); no hay tabla de retención documental definida todavía (punto abierto 2).

No fue posible renderizar `Contexto/ICBF.pdf` en este entorno (falta `poppler-utils`), así que el patrón `*_History` del modelo previo se interpreta a partir de lo ya anotado en ADR-0004 y en `.claude/agents/backend.md` ("sin borrado físico; cambios en tablas `*_History`"), no de una lectura directa del PDF. Si el PDF tiene un detalle distinto (por ejemplo historial por campo en vez de por fila), hay que revisar y ajustar esta ADR.

## Decisión

### 1. Modelo de datos
Se ALTERan `menores` y `asignaciones` y se agregan cuatro tablas nuevas. Migración Alembic `0002`, a cargo de `backend`/`datos-infra`.

**`menores`** (ya existe; se agregan columnas)
- `tipo_documento` (str, nullable): enum de dominio `registro_civil | tarjeta_identidad | cedula | pasaporte | sin_documento`.
- `numero_documento` (str, nullable, único cuando no es nulo): muchos NNA no tienen documento al ingresar.
- `estado_actual` (ya existe): se valida contra enum de dominio `activo | egresado | evadido | fallecido`. "Archivado" es un estado del *expediente* (módulo Archivo y Cierre, Fase 5), no del menor; no se agrega columna todavía.
- `version` (ya existe): se incrementa en cada cambio trackeado.

**`menores_history`** (nueva): snapshot de la fila anterior de `menores` cada vez que cambian datos personales o `estado_actual`.
- `id`, `menor_id` (FK), `version` (la que queda reemplazada), snapshot de `nombres, apellidos, fecha_nacimiento, genero, tipo_documento, numero_documento, estado_actual`, `cambiado_por` (FK `usuarios.id`, nullable), `motivo` (str, nullable), `created_at` (momento del cambio).

**`menores_familiares`** (nueva): información de padre, madre u otro familiar relevante. No se modela como columnas planas en `menores` porque la cardinalidad varía (puede faltar el padre, haber solo la madre, o un tercero con patria potestad).
- `id`, `menor_id` (FK, index), `parentesco` (`padre | madre | otro`), `nombres` (nullable, puede ser desconocido), `numero_identificacion` (nullable), `telefono` (nullable), `direccion` (nullable), `estado_vital` (`vivo | fallecido | desconocido`), `observaciones` (text, nullable), `created_at`/`updated_at`.
- Sección siempre sensible ("familia"). Sin `_History` propia en esta fase: sus escrituras ya quedan en `auditoria_accesos`; si el operador pide trazar valores anteriores de contacto familiar, se agrega después.

**`permisos_expediente`** (nueva): concreta la ACL de ADR-0004, acotada a lo que hoy se sabe con certeza — habilitar a la madre asignada a ver una sección sensible. No se modela como motor de permisos genérico.
- `id`, `menor_id` (FK, index), `seccion` (`familia | salud | psicosocial`), `usuario_id` (FK `usuarios.id`, index; debe ser un usuario con rol `madre`), `otorgado_por` (FK `usuarios.id`, **decisión de seguridad: debe ser el profesional con `cargo = defensor`** asignado a ese menor en `menores_profesionales`; la capa de aplicación valida esto antes de insertar, no solo la FK), `activo` (bool, default true), `notas` (str, nullable), `created_at`/`updated_at`.
- `UniqueConstraint(menor_id, seccion, usuario_id)`: revocar es `activo=false`, no se borra la fila (queda como registro de que existió el permiso).
- Otros profesionales asignados (psicosocial, nutrición, trabajo social) no escriben filas en esta tabla; si se necesita que puedan "solicitar" la habilitación para que el defensor decida, se modela después con un campo de estado o una tabla de solicitudes — no está en el alcance de esta fase.

**`asignaciones`** (ya existe; se agregan columnas)
- `version` (int, default 1) — por consistencia con `menores`/`documentos`/`reportes`.
- `tipo_movimiento` (`ingreso | traslado | egreso`).
- `acta_referencia` (str, nullable): hasta que exista el módulo Documentos (Fase 3) es solo texto/ruta; cuando exista, puede apuntar a un `Documento`.
- `motivo` (str, nullable).
- `registrado_por` (FK `usuarios.id`, nullable).

**`asignaciones_history`** (nueva): snapshot de la fila anterior de `asignaciones` en cada cambio sobre una asignación ya creada (cierre, traslado, corrección de fechas).
- `id`, `asignacion_id` (FK), `version`, snapshot de `menor_id, hogar_id, fecha_inicio, fecha_fin, estado, tipo_movimiento, acta_referencia, motivo`, `cambiado_por` (FK `usuarios.id`, nullable), `created_at`.

"Historial médico y psicosocial" (parte del alcance del módulo 5 en `docs/modulos.md`) **no** se modela con tablas nuevas en esta fase: se reutiliza `Reporte` (`documentos/models.py`, ya migrada en `0001`, con `tipo_reporte`, `autor_id`, `tipo_autor`, `contenido` JSON, `version`). El módulo `menores` solo expone el permiso de sección (`salud`, `psicosocial`) que filtrará esas entradas; la escritura y lectura de `Reporte` llega con el módulo Documentos en Fase 3. Evitar crear una tabla paralela de "historial clínico" que duplique `Reporte`.

### 2. Permisos por expediente
Regla de autorización, aplicada en la capa de aplicación de `menores` y `asignaciones` (y luego por la IA vía ADR-0002), denegar por defecto:

1. **Profesional** con fila en `menores_profesionales` para ese menor → lectura completa del expediente, incluidas las secciones sensibles. No se restringe entre profesionales en esta fase (por ejemplo, el nutricionista también vería psicosocial); si el operador lo pide, se añade un refinamiento sobre la misma tabla `permisos_expediente` (agregar `profesional` como tipo de sujeto) sin cambiar el diseño general.
2. **Coordinador** → datos básicos, estado y asignaciones de los menores cuyo hogar está en su zona (`usuario.zona_id`). No ve por defecto `familia`, `salud` ni `psicosocial` salvo que también esté en `menores_profesionales`.
   **Decisión de seguridad (confirmada):** se mantiene la propuesta del arquitecto — "no sensibles por defecto". El rol de coordinador es de gestión operativa de zona (hogares, madres, profesionales, alertas administrativas), no de atención clínica/psicosocial del caso; darle acceso amplio por defecto viola el principio de necesidad/minimización (Ley 1581/2012 art. 4; además agravado por tratarse de datos de NNA, art. 7, y de datos de salud, art. 5, categorías de especial protección). Si en producción surge un caso real donde el coordinador necesita ver una sección sensible (por ejemplo, para resolver una queja), se maneja como una habilitación puntual y auditada (mecanismo equivalente a `permisos_expediente`, sujeto a quien decide en el punto 5), nunca como visibilidad general del rol. No se construye ese mecanismo en esta fase; se deja anotado como refinamiento futuro.
3. **Auditor** → metadatos y eventos de auditoría (quién accedió, cuándo, qué acción) más metadatos de documentos y reportes (tipo, autor, fecha, estado del flujo de revisión/aprobación, versión, hash) en solo lectura. No ve por defecto el contenido de `familia`, `salud` ni `psicosocial`, ni el cuerpo de documentos/reportes marcados como sensibles.
   **Decisión de seguridad (confirmada):** la frase de `docs/modulos.md` ("Auditor: auditoría, documentos y reportes en solo lectura") se interpreta como acceso de solo lectura al *listado y metadatos* de documentos/reportes — necesario para auditar integridad del proceso (quién creó, quién aprobó, si hay huella/hash, si hay versiones faltantes) — y no como acceso al contenido clínico/psicosocial. La función del auditor es control y trazabilidad del proceso, no atención del caso; el contenido sensible no es necesario para esa función (principio de necesidad, Ley 1581/2012 art. 4; ver también Ley 594/2000 sobre gestión documental y control, que habla de control del proceso archivístico, no de acceso al contenido). Si se requiere auditar contenido sensible (ej. investigación disciplinaria puntual), se modela como una habilitación temporal y justificada, registrada en `auditoria_accesos` con el motivo — no construida en esta fase. Se recomienda aclarar esta lectura en `docs/modulos.md` para evitar ambigüedad.
4. **Madre** → datos básicos y estado del menor solo si existe una `Asignacion` vigente entre ese menor y el hogar de la madre (`hogares_sustitutos.madre_id`). Pierde el acceso automáticamente al registrarse `fecha_fin` (RF7, ya decidido en ADR-0004). Para `familia`, `salud` o `psicosocial` necesita además una fila `activo=true` en `permisos_expediente` para esa sección y ese menor.
5. Quién otorga el permiso a la madre: **decisión de seguridad (confirmada, con validación jurídica pendiente)** — únicamente el profesional con `cargo = defensor` asignado al menor en `menores_profesionales` puede crear o revocar filas de `permisos_expediente`. Los demás profesionales asignados (psicosocial, nutrición, trabajo social) producen y revisan el contenido de su sección, pero no conceden acceso de terceros a datos sensibles de salud/psicosociales del NNA.
   **Justificación:** el Defensor de Familia es la autoridad administrativa que, por Ley 1098/2006 (art. 82), concentra la responsabilidad legal del caso de restablecimiento de derechos ante el ICBF, incluida la representación del interés del NNA cuando este no puede decidir por sí mismo; el NNA tampoco puede autorizar el tratamiento de sus propios datos sensibles (Ley 1581/2012 art. 7; Decreto 1377/2013 art. 12, hoy compilado en el Decreto Único Reglamentario 1074/2015 art. 2.2.2.25.2.3). Concentrar en una sola figura con responsabilidad legal sobre el caso la decisión de habilitar a la madre a ver salud/psicosocial/familia reduce el riesgo de que cualquier profesional conceda acceso sin una visión completa del caso, y es más defendible en una auditoría.
   **Requiere validación jurídica** (no es una conclusión de seguridad sino un supuesto a confirmar por un abogado o por lineamiento ICBF): que, en el esquema de operador tercerizado (Fundación Fundar) y hogares sustitutos, sea efectivamente el Defensor de Familia —y no otro profesional del equipo interdisciplinario— quien deba autorizar este acceso puntual, y si existe un lineamiento ICBF explícito al respecto. Mientras no se confirme, el sistema debe exigir `cargo = defensor` como mínimo (postura más restrictiva, coherente con minimización) y nunca relajarlo a "cualquier profesional" sin esa confirmación.
6. Al cerrar una asignación (`PUT /asignaciones/{id}/cerrar`) se desactivan en la misma transacción todos los `permisos_expediente` activos de esa madre sobre ese menor (coherente con "nunca elimina, siempre oculta").
7. Toda lectura y escritura de expediente pasa por `app/core/audit.py::registrar_acceso` (ya existente), incluidos los paneles agregados.

### 3. Patrón `*_History`
Snapshot completo de la fila anterior, no diff por campo: más simple de implementar y de auditar para un equipo de dos personas. En la misma transacción de una actualización relevante: insertar la fila vieja completa en `<tabla>_history` con su `version`, luego aplicar los cambios y subir `version` en la fila principal. Se aplica a `menores` (cambios de datos personales o de `estado_actual`) y a `asignaciones` (cualquier cambio posterior a la creación: cierre, traslado, corrección de fechas). No se aplica a `menores_familiares` ni a `permisos_expediente`: su trazabilidad de "quién hizo qué y cuándo" ya la cubre `auditoria_accesos` (tabla de solo inserción de eventos); `*_History` es para reconstruir "qué valores tenía esta fila antes", no para el registro de acceso. Nunca hay borrado físico en ninguna de las tablas de este módulo.

### 4. Endpoints (contrato de alto nivel, bajo `/api/v1`)

`menores`:
- `POST /menores` — crear expediente (coordinador, admin, profesional-defensor).
- `GET /menores` — listar con filtros `zona_id`, `hogar_id`, `estado`; el filtro de visibilidad depende del rol (regla de autorización arriba).
- `GET /menores/{menor_id}` — expediente resumen; aplica permisos por sección.
- `PUT /menores/{menor_id}` — actualizar datos básicos/estado; dispara `menores_history`.
- `GET /menores/{menor_id}/historial` — versiones anteriores.
- `GET /menores/{menor_id}/familiares` / `POST /menores/{menor_id}/familiares` — información de padre/madre (sección `familia`).
- `GET /menores/{menor_id}/permisos`, `POST /menores/{menor_id}/permisos`, `DELETE /menores/{menor_id}/permisos/{permiso_id}` — administrar accesos de la madre a secciones sensibles. `POST`/`DELETE` exigen que el usuario autenticado sea el profesional con `cargo = defensor` asignado a ese menor (403 en cualquier otro caso, incluidos otros profesionales asignados); queda registrado en `auditoria_accesos`.
- `GET /menores/panel/profesional` — menores a cargo del profesional autenticado, agrupados por hogar y zona (join `menores_profesionales` + asignación vigente + `hogares_sustitutos` + `zonas`).
- `GET /menores/panel/zona` — equivalente para coordinador, filtrado por `usuario.zona_id`.

`asignaciones`:
- `POST /asignaciones` — crear (ingreso o traslado); si `tipo_movimiento=traslado`, cierra en la misma transacción la asignación vigente anterior del menor.
- `GET /asignaciones` — listar con filtros `menor_id`, `hogar_id`, `zona_id`, `estado`.
- `GET /asignaciones/{id}` — detalle.
- `PUT /asignaciones/{id}/cerrar` — `fecha_fin`, `motivo`; dispara `asignaciones_history`; revoca permisos de sección de la madre saliente; actualiza `Menor.estado_actual` si corresponde (llamando al caso de uso de `menores`, nunca a su repositorio directamente, igual que ya hace `zonas_hogares` con `madres`).
- `GET /asignaciones/{id}/historial` — versiones anteriores.
- `GET /asignaciones/menor/{menor_id}/vigente` — asignación vigente de un menor.

El panel del profesional (`docs/modulos.md`, "Vistas por rol") no es un módulo nuevo: se sirve con los endpoints anteriores de `menores`, combinados en el frontend con alertas y citas cuando esos módulos existan (Fase 4).

## Consecuencias
- El esquema está listo para que el módulo Documentos (Fase 3) cuelgue `Documento`/`Reporte` de `menor_id` sin tocar `menores`/`asignaciones`.
- `permisos_expediente` queda deliberadamente angosto (solo el caso madre-sección); si el operador pide granularidad entre profesionales, se extiende la misma tabla en vez de rediseñarla.
- Toda consulta de IA (ADR-0002) y de búsqueda debe filtrar también por `permisos_expediente`, no solo por rol y asignación.
- El volumen de `*_history` crece con cada corrección y cada traslado; a 175-210 NNA con 6 meses de estancia promedio el volumen es bajo, no requiere partición en esta fase (a diferencia de `auditoria_accesos`, ver ADR-0004).
- Resuelto por `seguridad` (ver puntos 2, 3 y 5 de la decisión de permisos): coordinador y auditor sin acceso a secciones sensibles por defecto; solo el defensor asignado otorga/revoca el acceso de la madre a `familia`/`salud`/`psicosocial`. El punto 5 queda marcado para validación jurídica (confirmar con abogado o lineamiento ICBF que corresponde al Defensor de Familia y no a otro profesional del equipo interdisciplinario).
- Pendiente de `ux-ui`: pantalla para que el defensor otorgue/revoque permisos a la madre (y, si se decide un flujo de "solicitud" de otros profesionales, su visualización), y el panel agrupado por hogar y zona.
- Antes de pasar a producción con datos reales, confirmar con un abogado la base legal de tratamiento de datos sensibles de NNA en este esquema (operador tercerizado) y si el lineamiento ICBF exige algo distinto a lo decidido aquí para coordinador, auditor o la figura que autoriza el acceso de la madre.
