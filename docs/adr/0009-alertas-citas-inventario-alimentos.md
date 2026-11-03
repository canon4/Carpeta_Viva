# ADR-0009 Fase 4: Alertas y Evasiones, Citas y Recordatorios, Inventario del Hogar, Control de Alimentos

Estado: Aceptada, revisada por seguridad, con una corrección obligatoria antes de construir (destinatarios de evasión sin cuenta de usuario — sección "Resolución de destinatarios") y una decisión explícita incorporada (campo `notas` de citas — sección 2). Detalle de la revisión al final del documento, antes de "Consecuencias".

## Contexto

Fase 4 (`docs/plan-por-fases.md`) construye los módulos 8 a 11 (`docs/modulos.md`) sobre lo ya migrado en Fases 1-3: `menores`, `asignaciones`, `menores_profesionales` (ADR-0007), `documentos`/`reportes` (ADR-0008). Hoy los cuatro módulos son stubs (`app/modules/{alertas,citas,inventario,alimentos}/` con `api.py` que solo expone `GET /_estado`; `application`, `domain`, `repository`, `schemas` vacíos).

Reglas de negocio que aplican (`CLAUDE.md`):
- Evasión: alerta a la aplicación del defensor y la psicosocial asignados; misma pantalla muestra números de emergencia; se registra quién la recibió y cuándo la vio; aviso adicional por SMS/push "a evaluar" (punto abierto 7, sin presupuesto ni proveedor — punto abierto 8).
- RF9: alertas de visitas vencidas y documentos faltantes, además de evasión.
- Citas: "el sistema no las asigna, solo recuerda" (médicas, psicosociales, reuniones con familia biológica).
- Inventario y alimentos son información del **hogar**, no del menor.

No existe hoy un helper de autorización por hogar reutilizable (solo `obtener_hogar` en `zonas_hogares/application.py`); esta ADR lo agrega ahí porque lo necesitan dos módulos hermanos (Inventario, Alimentos), igual que `menores/application.py` expone `puede_ver_menor`/`tiene_permiso_seccion` para sus hermanos.

## Decisión

### 0. Dos patrones de autorización, no cuatro

- **Alertas y Citas** pertenecen al menor → reutilizan `menores.application.puede_ver_menor` (visibilidad de fila ya resuelta en ADR-0007: admin/auditor, coordinador por zona vía asignación vigente, profesional/defensor asignado, madre con asignación vigente). Se define una regla de escritura simple: `puede_ver_menor(...) and usuario.rol != Rol.AUDITOR.value` (el auditor nunca escribe, solo lee metadatos — mismo patrón ya usado en `documentos`/ADR-0008 para excluirlo de acciones, no solo de contenido).
- **Inventario y Alimentos** pertenecen al hogar → se agrega un helper nuevo en `zonas_hogares/application.py`, reutilizado por ambos:

```
def puede_ver_hogar(session, usuario, hogar_id) -> bool
def puede_gestionar_hogar(session, usuario, hogar_id) -> bool   # = puede_ver_hogar sin auditor
```

Regla (`puede_ver_hogar`):
1. `admin`/`auditor` → true.
2. `coordinador` → `hogar.zona_id == usuario.zona_id`.
3. `madre` → `madre_de_usuario(session, usuario.id).id == hogar.madre_id` (reutiliza `madres.application.madre_de_usuario`).
4. `profesional`/`defensor` → asignado a algún menor cuya asignación **vigente** apunta a ese hogar: `menores_asignados_a_profesional(profesional.id)` (ya existe en `profesionales.application`) cruzado con `asignaciones.application.vigente_de_menor(menor_id).hogar_id == hogar_id`.

`puede_gestionar_hogar` = lo mismo, devolviendo `false` para `auditor` (nunca crea/edita, solo lee).

Importaciones de `madres`, `profesionales`, `asignaciones` dentro de la función (mismo patrón ya usado contra ciclos, ver `documentos.application._puede_ver_documento_hogar`, que queda obsoleto de hecho — puede refactorizarse para llamar a este helper nuevo en vez de repetir la lógica de coordinador/madre; se deja anotado como limpieza menor para `backend`, no bloqueante).

### 1. Módulo 11 — Alertas y Evasiones

**Modelo de datos** (migración `0004`):

- `alertas`: `id`, `tipo` (`evasion | visita_vencida | documento_faltante`, `CheckConstraint`, lista abierta a extender con nueva migración), `menor_id` (FK `menores.id`, index — toda alerta de esta fase está ligada a un menor, incluso documento_faltante/visita_vencida), `origen` (`manual | automatica`), `generada_por` (FK `usuarios.id`, nullable — null si `origen=automatica`), `descripcion` (str), `detalle` (JSON/JSONB, nullable — datos propios del tipo, p. ej. `{"categoria": "salud"}` para documento_faltante o `{"cita_id": "..."}` para visita_vencida; mismo patrón que `Reporte.contenido` en `documentos/models.py`, evita una tabla por tipo), `estado` (`activa | cerrada`, default `activa`), `creado_en`.
- `alertas_destinatarios`: `id`, `alerta_id` (FK, index), `usuario_id` (FK `usuarios.id`, index), `visto_en` (DateTime, nullable — se llena cuando ese destinatario la abre), `notificado_en` (DateTime, nullable, **no usado en esta fase**; reservado para el aviso adicional por SMS/push del punto abierto 7, sin construir integración), `UniqueConstraint(alerta_id, usuario_id)`.
  **Aclaración de seguridad (no bloqueante, para evitar falsa sensación de funcionalidad):** `notificado_en` queda siempre `NULL` en esta fase; ningún endpoint ni proceso lo escribe, porque no existe hoy integración de SMS/push (punto abierto 7/8 sin proveedor ni presupuesto). `backend` no debe exponer esta columna en los esquemas de respuesta de `GET /alertas*` como si fuera un indicador real ("notificado: no" se vería igual para todas las alertas, sin aportar información, y podría leerse por error como que el sistema ya intentó notificar y falló). Si se expone, debe ir acompañada de una nota explícita en el contrato OpenAPI ("reservado, no implementado") para que `frontend` no construya una UI que insinúe un canal de aviso que no existe.
- **No** es un campo único de "leída" en `alertas`: hay varios destinatarios y cada uno ve/lee en momentos distintos (requisito explícito de `CLAUDE.md`), de ahí la tabla aparte en vez de una columna.

**Números de emergencia**: constante en `Settings` (`app/core/config.py`), no tabla — mismo criterio que `ARCHIVOS_CLAVE_MAESTRA`: hoy hay un solo operador/municipio (Fundación Fundar, Florencia). Se agrega `policia_infancia_telefono: str` (y `.env.example`). Si el sistema crece a varios municipios con líneas distintas, se migra a una tabla `numeros_emergencia_zona`; no se construye ahora (no hay evidencia de esa necesidad todavía — no inventar).

Los números de **defensor y psicosocial** mostrados en la misma pantalla son los del profesional realmente asignado a ese menor (más útiles en una emergencia real que un número genérico), resueltos vía `menores_profesionales` (`rol_asignado IN ('defensor','psicosocial')`) → `Profesional`. **Falta un dato que no existe hoy**: `Profesional` no tiene columna `telefono` (sí la tiene `MadreSustituta`). Se agrega `telefono: str | None` a `profesionales` en la misma migración `0004`. Si un profesional asignado no tiene teléfono registrado, la pantalla debe decirlo explícitamente (no omitir el campo en silencio) — detalle de UX a coordinar con `ux-ui`.

**Resolución de destinatarios** (`_resolver_destinatarios(session, menor_id, tipo)`), pensada para que el tipo sea extensible:
- `evasion`: profesionales con `rol_asignado` en `{defensor, psicosocial}` asignados al menor (vía `profesionales.application.profesionales_asignados_a_menor`), filtrando los que tienen `usuario_id` no nulo (un profesional puede existir sin cuenta de usuario todavía).
- `visita_vencida` / `documento_faltante`: todos los profesionales asignados al menor + la madre con asignación vigente (si existe), para que quien debe actuar (subir el documento, agendar la visita) se entere. Es una decisión razonable por defecto, no una regla de negocio confirmada por el operador; si Fundación Fundar pide otra lista de destinatarios por tipo, se ajusta esta función sin tocar el modelo.

**Corrección obligatoria de seguridad (bloqueante) — evasión sin destinatario resoluble:** tal como está escrita la regla de `evasion`, si el defensor y el profesional psicosocial asignados a ese menor no tienen `usuario_id` (cuenta de usuario todavía no creada, algo plausible en un despliegue en curso), `_resolver_destinatarios` devuelve una lista vacía: la alerta se crea pero `alertas_destinatarios` queda sin filas, y la regla de negocio más sensible de esta fase ("la alerta llega... al defensor y a la profesional psicosocial asignados") falla en silencio — nadie en la aplicación la ve, y ni `alertas` ni la respuesta del endpoint lo advierten. Quien reporta sigue viendo los números de emergencia en la misma pantalla (eso no depende de los destinatarios), pero el circuito interno de "alguien con el caso se entera por la app" queda roto sin que el sistema lo señale. Corrección: si el filtrado por `rol_asignado ∈ {defensor, psicosocial}` con `usuario_id` no nulo devuelve una lista vacía para `tipo=evasion`, `_resolver_destinatarios` debe además incluir como destinatario de respaldo al/los `coordinador` cuya `zona_id` coincide con la zona del hogar vigente del menor (resuelto igual que `puede_ver_hogar` punto 2); si tampoco hay coordinador resoluble (zona sin coordinador asignado), incluir a todos los usuarios con rol `admin`. Nunca debe quedar una alerta de evasión con cero destinatarios. Esta misma regla de respaldo no aplica a `visita_vencida`/`documento_faltante` (menor urgencia, no bloqueante).

**Autorización**:
- Reportar evasión (`POST /alertas/evasion`): `puede_ver_menor(session, usuario, menor_id) and usuario.rol != Rol.AUDITOR.value` (cubre madre con asignación vigente, profesional/defensor asignado, coordinador de la zona, admin — tal como pide la tarea: "madre del hogar, cualquier profesional asignado, coordinador").
- Ver una alerta (`GET /alertas/{id}`, listar): destinatario (fila propia en `alertas_destinatarios`) **o** quien la generó **o** coordinador de la zona del hogar vigente del menor **o** admin **o** auditor (solo metadatos: tipo, menor, fecha, estado, destinatarios y si cada uno la vio — nunca necesita más para auditar el proceso, mismo criterio que ADR-0007 punto 3).
- Marcar como vista (`PUT /alertas/{id}/visto`): solo el propio destinatario, sobre su propia fila.

**Generación automática (RF9, visitas vencidas y documentos faltantes)**: sin cola/scheduler (no hay esa infraestructura ni se justifica para un prototipo). Se expone `POST /alertas/generar-automaticas` (coordinador/admin), idempotente — no duplica una alerta `activa` ya abierta para el mismo `(menor_id, tipo, detalle)` — y además se invoca internamente al construir `GET /alertas/panel` (el panel que ve el profesional/defensor/coordinador al entrar). Así funciona sin job en background; más adelante `datos-infra` puede programar una tarea (cron/Windows Task Scheduler) que llame este mismo endpoint una vez al día, sin cambiar el contrato.

- `visita_vencida`: recorre citas (módulo 10) con `estado = 'pendiente'` y `fecha_hora` pasada.
- `documento_faltante`: **falta información para implementarlo** — qué categorías documentales son obligatorias por expediente y en qué plazo no está definido (ADR-0008 ya deja las categorías como "provisionales, pendientes de validar con el operador"). No se inventa esta lista. Queda como punto abierto nuevo: **preguntar a Fundación Fundar/ICBF (o decidir con Diego como dueño del modelo de negocio) qué documentos son obligatorios y en qué plazo desde el ingreso**. El mecanismo (`_resolver_destinatarios`, tabla `alertas`, endpoint de generación) queda listo; solo falta la constante `CATEGORIAS_OBLIGATORIAS` para activarlo.

**Endpoints** (`/api/v1/alertas`):
- `POST /alertas/evasion` `{menor_id, descripcion}` → crea alerta, resuelve y crea destinatarios, registra auditoría (`evasion_reportada` / `evasion_reporte_denegado`), responde con la alerta **y** el bloque de contactos de emergencia (policía estática + defensor/psicosocial resueltos) en la misma respuesta.
- `GET /alertas?menor_id=&tipo=&estado=` — filtrada por visibilidad.
- `GET /alertas/{id}` — detalle con destinatarios y su `visto_en`.
- `PUT /alertas/{id}/visto` — marca la fila del destinatario autenticado.
- `GET /alertas/mis-pendientes` — destinatario autenticado, `visto_en IS NULL` (para el panel "alertas pendientes" de `docs/modulos.md`).
- `GET /alertas/panel` — dispara la generación automática y devuelve alertas visibles agrupadas (profesional: sus menores; coordinador: su zona).
- `POST /alertas/generar-automaticas` — coordinador/admin, ejecución manual del barrido.
- `PUT /alertas/{id}/cerrar` — coordinador/admin o quien la generó; `estado = cerrada` (nunca se borra).

### 2. Módulo 10 — Citas y Recordatorios

**Modelo** (migración `0004`): `citas` — `id`, `menor_id` (FK, index), `tipo` (`medica | psicosocial | reunion_familia | otro`, `CheckConstraint` extensible), `fecha_hora` (DateTime), `lugar` (str, nullable), `notas` (str, nullable), `estado` (`pendiente | cumplida | no_asistio`, default `pendiente`), `registrado_por` (FK `usuarios.id`), `Timestamps`. Sin tabla `_History`: trazabilidad de cambios ya la cubre `auditoria_accesos` (mismo razonamiento que ADR-0007 §3 aplicó a `menores_familiares`); el riesgo de perder el valor anterior de una fecha de cita es bajo frente a complicar el modelo.

**Decisión de seguridad (confirmada):** se acepta que la fila completa de `citas` (tipo, fecha, lugar, estado) use la visibilidad básica de `puede_ver_menor` y no el filtro `tiene_permiso_seccion` de ADR-0007 — son metadatos de agenda (hay una cita médica tal día, en tal lugar), no contenido clínico, y el propio `CLAUDE.md` describe este módulo como "el sistema no las asigna, solo recuerda". Exigir `tiene_permiso_seccion` sobre toda la fila sería sobre-diseño para lo que es, en esencia, un recordatorio, y dejaría al coordinador sin poder ver siquiera que existe una cita vencida (necesario para RF9).

**Corrección incorporada (no bloqueante, pero exigida antes de construir) — el campo `notas` sí debe filtrarse:** a diferencia de `tipo`/`fecha_hora`/`lugar`/`estado`, `notas` es texto libre sin control de contenido; nada impide que un profesional escriba ahí detalle clínico o psicosocial real (p. ej. "sospecha de maltrato, citar a valoración" en una cita `psicosocial`), que de otro modo solo podría entrar al sistema a través del flujo con permiso de sección de `documentos`/`reportes` (ADR-0008). Si `notas` se devuelve sin filtro a cualquiera que tenga `puede_ver_menor` (incluye coordinador y, en el expediente del hogar, cualquiera con visibilidad básica), se abre una vía lateral para fugar contenido sensible sin pasar por `permisos_expediente`. Decisión: el backend debe omitir (`null`) el campo `notas` en la respuesta de `GET /citas`, `GET /citas/{id}` y `GET /citas/proximas` cuando el solicitante no tenga `tiene_permiso_seccion(session, usuario, menor_id, seccion)` para la sección mapeada de ese `tipo` (`medica→salud`, `psicosocial→psicosocial`, `reunion_familia→familia`, `otro→` sin sección, visible a quien tenga `puede_ver_menor`), reutilizando el mismo mapeo `categoria/tipo_reporte → sección` ya usado en ADR-0008 (constante nueva y pequeña, `SECCION_POR_TIPO_CITA`, no un diseño nuevo). El resto de la fila (tipo, fecha, lugar, estado) se sigue mostrando a quien tenga `puede_ver_menor`, sin cambios. `ux-ui` debe comunicar además, como norma de uso, que `notas` es para logística (ej. "traer carné de vacunas", "consultorio 3"), no para contenido clínico — eso se registra como `Documento`/`Reporte` con su propio control de sección.

**Autorización**: ver = `puede_ver_menor`; crear/editar/cambiar estado = `puede_ver_menor(...) and rol != auditor` (mismo patrón que alertas).

**Endpoints** (`/api/v1/citas`):
- `POST /citas` `{menor_id, tipo, fecha_hora, lugar, notas}`.
- `GET /citas?menor_id=&tipo=&estado=`.
- `GET /citas/{id}`.
- `PUT /citas/{id}` — reprogramar (`fecha_hora`, `lugar`, `notas`).
- `PUT /citas/{id}/estado` `{estado: cumplida|no_asistio}`.
- `GET /citas/proximas` — pendientes futuras visibles para el usuario autenticado (alimenta "próximas citas" del panel, `docs/modulos.md`).

Sin integración de notificación push/SMS (mismo punto abierto 7 que alertas); el sistema "solo recuerda" mostrando la lista, como ya indica `CLAUDE.md`.

### 3. Módulo 8 — Inventario del Hogar

**Modelo** (migración `0004`), las tres tablas con `hogar_id` (FK `hogares_sustitutos.id`, index) y sin borrado físico (se desactiva, no se elimina):

- `inventario_items`: `id`, `hogar_id`, `tipo` (`cama | mueble | otro`, `CheckConstraint`), `descripcion` (str), `cantidad` (int, default 1), `estado` (`bueno | regular | malo | retirado`, `CheckConstraint` — `retirado` sustituye al `DELETE`), `registrado_por` (FK usuarios), `Timestamps`.
- `hogar_convivientes` (personas que viven en el hogar, distintas de los NNA asignados y la madre): `id`, `hogar_id`, `nombres`, `relacion_con_madre` (str), `fecha_desde` (Date, nullable), `observaciones` (str, nullable), `activo` (bool, default true — se desactiva cuando la persona deja de vivir ahí), `Timestamps`.
- `hogar_red_apoyo`: `id`, `hogar_id`, `nombres`, `relacion` (str), `telefono` (str, nullable), `observaciones` (str, nullable), `activo` (bool, default true), `Timestamps`.

**Autorización**: `puede_ver_hogar`/`puede_gestionar_hogar` (sección 0) para las tres sub-entidades, sin excepción por tipo.

**Endpoints** (`/api/v1/inventario`):
- `POST /inventario/items`, `GET /inventario/items?hogar_id=`, `PUT /inventario/items/{id}`.
- `POST /inventario/convivientes`, `GET /inventario/convivientes?hogar_id=`, `PUT /inventario/convivientes/{id}` (incluye desactivar).
- `POST /inventario/red-apoyo`, `GET /inventario/red-apoyo?hogar_id=`, `PUT /inventario/red-apoyo/{id}`.

### 4. Módulo 9 — Control de Alimentos

**Modelo** (migración `0004`): `alimentos_items` — `id`, `hogar_id` (FK, index), `descripcion` (str), `fecha_ingreso` (Date), `perecedero` (bool), `fecha_vencimiento` (Date, nullable — solo tiene sentido si `perecedero=true`; se valida en `domain.py`, no en constraint SQL por simplicidad), `cantidad` (float), `unidad` (str, nullable), `consumido` (bool, default false), `registrado_por` (FK usuarios), `Timestamps`.

**Autorización**: igual que Inventario, `puede_ver_hogar`/`puede_gestionar_hogar`.

**Endpoints** (`/api/v1/alimentos`):
- `POST /alimentos` `{hogar_id, descripcion, fecha_ingreso, perecedero, fecha_vencimiento, cantidad, unidad}`.
- `GET /alimentos?hogar_id=&vencidos=true` (filtro: `perecedero and fecha_vencimiento < hoy and not consumido`).
- `PUT /alimentos/{id}`.
- `PUT /alimentos/{id}/consumido`.

No se agrega alerta automática de "alimento vencido" en esta fase: RF9/`docs/modulos.md` solo pide visitas vencidas y documentos faltantes para el módulo de Alertas; queda anotado como extensión natural futura del mismo mecanismo (`tipo` adicional en `alertas`), no construida por falta de alcance confirmado.

## División de trabajo sugerida (para los dos agentes `backend` en paralelo)

- **Agente A — Alertas + Citas** (toca menores, pasa por `seguridad`): modelos, migración (porción `alertas`, `alertas_destinatarios`, `citas`), `domain/repository/application/schemas/api` de ambos módulos, `_resolver_destinatarios`, endpoint de generación automática de `visita_vencida` (no de `documento_faltante`, bloqueado por punto abierto de categorías obligatorias), columna `telefono` en `profesionales` + actualizar sus schemas.
- **Agente B — Inventario + Alimentos**: helper `puede_ver_hogar`/`puede_gestionar_hogar` en `zonas_hogares/application.py` (lo necesitan ambos, hacerlo primero), modelos, migración (porción `inventario_items`, `hogar_convivientes`, `hogar_red_apoyo`, `alimentos_items`), `domain/repository/application/schemas/api` de ambos módulos.
- `datos-infra`: una sola migración Alembic `0004` que cubra las siete tablas nuevas + el `ALTER` de `profesionales`, antes de que A o B escriban código (regla ya vigente del plan por fases); agregar `POLICIA_INFANCIA_TELEFONO` a `.env.example`.
- `seguridad`: revisión completada antes de construir (ver sección "Revisión de seguridad" abajo). Queda pendiente de `test` validar en pruebas de autorización que la corrección de destinatarios de respaldo (evasión) y el filtrado de `notas` (citas) quedan implementados tal como se decidió aquí.
- `ux-ui`: pantalla de reporte de evasión con números de emergencia visibles de inmediato (sin clics adicionales), paneles de "alertas pendientes" y "próximas citas", pantallas de inventario/alimentos del hogar; comunicar que `notas` de citas es solo logística, no contenido clínico.
- `test`: casos de autorización (destinatario ve y no-destinatario no ve: alertas/citas; madre de otro hogar no gestiona inventario/alimentos ajenos) y de generación automática idempotente; **casos nuevos exigidos por la revisión de seguridad**: (a) evasión de un menor cuyo defensor y psicosocial asignados no tienen `usuario_id` → la alerta debe tener al menos un destinatario (coordinador de zona o admin de respaldo), nunca cero; (b) `GET /citas` para un usuario sin `tiene_permiso_seccion` en una cita `medica`/`psicosocial` → `notas` debe llegar `null`, el resto de la fila visible.

## Revisión de seguridad (2026-11-03)

Validación solicitada por el arquitecto antes de que `backend` construya. Resultado: **Aceptada, con 1 corrección obligatoria ya incorporada** (destinatarios de respaldo en evasión, sección "Resolución de destinatarios") **y 1 decisión explícita incorporada** (filtrado del campo `notas` en citas, sección 2), ambas ya integradas en el texto de la decisión arriba.

1. **Flujo de evasión (modelo `alertas`/`alertas_destinatarios`, `visto_en` por destinatario)**: cumple lo exigido por `CLAUDE.md` — alcanza al defensor y a la psicosocial asignados, muestra en la misma respuesta los números de emergencia (policía estática + defensor/psicosocial resueltos) y registra por separado quién es destinatario y cuándo cada uno la vio (tabla aparte en vez de un campo único "leída", correcto dado que hay varios destinatarios). El único hueco real es el caso borde donde ningún destinatario calculado tiene cuenta de usuario todavía: la alerta se crearía sin nadie a quien notificar dentro de la app, exactamente en el flujo más crítico de todo el sistema. Corregido con el destinatario de respaldo (coordinador de zona, luego admin) — no se acepta que una alerta de evasión quede con cero destinatarios.
2. **Quién puede reportar una evasión** (`puede_ver_menor(...) and rol != auditor`, cubre madre con asignación vigente, profesional/defensor asignado, coordinador de zona, admin): es razonable y no debe ampliarse a "cualquier usuario autenticado". La urgencia física real (llamar a la Policía de Infancia y Adolescencia) no depende de crear la alerta en el sistema — ese número ya es información pública/institucional, no algo que el sistema deba desbloquear. Lo que el umbral de `puede_ver_menor` protege es el *flujo interno* (quién puede abrir un caso de evasión en el expediente de un menor específico, que dispara destinatarios, auditoría y paneles), y para eso basta con exigir una relación legítima ya existente con ese menor (igual que para verlo). Bajar el umbral (p. ej. a "cualquier coordinador, de cualquier zona" o "cualquier profesional, sin importar si está asignado") no agrega valor de seguridad física y sí agrega ruido/abuso potencial sobre expedientes ajenos. No se requiere cambio.
3. **Autorización por hogar (`puede_ver_hogar`/`puede_gestionar_hogar`)**: la regla para profesional/defensor usa explícitamente la asignación **vigente** del menor (`vigente_de_menor(menor_id).hogar_id == hogar_id`, ya implementado así en `asignaciones.application.vigente_de_menor`, que filtra por `estado == 'vigente'`). Un profesional que fue defensor de un menor ya trasladado de ese hogar no conserva acceso al hogar anterior: su `vigente_de_menor` apunta ahora al hogar nuevo (o a `None` si el menor egresó), por lo que la comparación contra el `hogar_id` original falla. No hay hueco aquí — confirmado contra el código real de `asignaciones/application.py` y `menores/application.py::_puede_ver_menor`, que ya usan el mismo patrón. El criterio de coordinador por `hogar.zona_id == usuario.zona_id` es, además, más directo y consistente que el usado en `menores.panel_zona` (que llega a la zona indirectamente vía asignaciones): aquí se compara directo contra `HogarSustituto.zona_id`, sin pasar por el menor — mismo resultado, menos pasos. Correcto.
4. **Citas sin `tiene_permiso_seccion` sobre toda la fila**: aceptable para tipo/fecha/lugar/estado (son metadatos de agenda, consistentes con "el sistema solo recuerda"), pero no para `notas`, campo de texto libre sin control de contenido que puede convertirse en una vía lateral para fugar contenido clínico/psicosocial sin pasar por `permisos_expediente` (ADR-0007) ni por el flujo de documentos con sección (ADR-0008). Decisión incorporada: `notas` se oculta (`null`) a quien no tenga `tiene_permiso_seccion` para la sección mapeada del `tipo` de la cita; el resto de la fila sigue visible con `puede_ver_menor`. Cambio acotado (un mapeo nuevo pequeño, reutilizando el patrón de ADR-0008), no rediseño.
5. **Teléfono de profesionales** (`profesionales.telefono` nuevo): no se encontró exposición indebida que corregir. `GET /profesionales`/`GET /profesionales/{id}` (donde se vería en `ProfesionalOut`) ya están acotados hoy a `coordinador`/`admin` (`requiere_roles`, `profesionales/api.py`), el mismo nivel de confianza con el que ya se expone `numero_registro` y los datos de contacto profesional existentes — no se amplía el universo de quién puede leer el teléfono por esta vía, solo el tipo de dato. Fuera de esa vía administrativa, el teléfono de un profesional solo se expone a través del bloque de contactos de emergencia de `POST /alertas/evasion`/`GET /alertas/{id}`, que ya está acotado por `puede_ver_menor` sobre el menor concreto del caso (madre de ese hogar, profesional/defensor asignado a ese menor, coordinador de esa zona, admin) — no es un dato "abierto" a cualquier coordinador de cualquier zona por esa ruta. Esto es coherente con el principio de necesidad (Ley 1581/2012 art. 4): el teléfono se revela ampliamente solo a quien ya administra el personal (coordinador/admin) y, puntualmente, a quien ya tiene una relación de caso con ese menor. No se requiere cambio; si en el futuro se abre `GET /profesionales*` a más roles, debe reevaluarse si `telefono` se excluye de esa respuesta.
6. **`notificado_en` reservado sin usar**: confirmado que el ADR ya documenta que no se envía nada fuera de la app en esta fase; se agregó una aclaración explícita en el modelo (no solo en "Consecuencias") para que quede claro antes de implementar, y la recomendación de no exponerlo en el contrato OpenAPI como si fuera una señal real, o marcarlo explícitamente como "reservado, no implementado" si se expone. No bloqueante.
7. **Duplicación `documentos.application._puede_ver_documento_hogar` vs `puede_ver_hogar` nuevo**: confirmado el hallazgo del arquitecto. Vale la pena el refactor (reutilizar el helper nuevo en vez de repetir coordinador/madre, y de paso ganar la rama de profesional/defensor que `_puede_ver_documento_hogar` no tiene hoy para documentos de hogar como `madre_habilitacion`), pero no es bloqueante para esta fase ni para Documentos (ya aceptado en ADR-0008): se anota como tarea de limpieza para `backend` cuando toque ese módulo de nuevo, sin reabrir ADR-0008.

**No requiere validación jurídica** nada de lo revisado aquí (son correcciones de implementación/autorización, no de base legal).

## Consecuencias

- `zonas_hogares/application.py` gana dos funciones públicas reutilizables (`puede_ver_hogar`, `puede_gestionar_hogar`); `documentos.application._puede_ver_documento_hogar` queda duplicando esa lógica (y de hecho le falta la rama profesional/defensor que el helper nuevo sí tiene) — se confirma como limpieza menor no bloqueante (ver revisión de seguridad, punto 7), no se hace en esta ADR para no reabrir un módulo ya aceptado sin necesidad.
- Queda un punto abierto nuevo y explícito: **lista de documentos obligatorios por expediente y plazo**, sin la cual `documento_faltante` no puede generarse automáticamente. Pendiente de Fundación Fundar/ICBF o de Diego (modelo de negocio). El resto de RF9 (visitas vencidas) no depende de esto y puede construirse ya.
- El aviso adicional por SMS/push (punto abierto 7) queda modelado (`alertas_destinatarios.notificado_en`) pero **no implementado y siempre `NULL`**: no hay proveedor ni presupuesto definido (punto abierto 8). Cuando se decida, se llena esa columna desde un nuevo caso de uso, sin tocar el esquema; mientras tanto no debe exponerse como si fuera una señal real (ver revisión de seguridad, punto 6).
- `Profesional` gana `telefono` (antes solo `MadreSustituta` lo tenía); si un profesional asignado no la ha diligenciado, la pantalla de emergencia debe decirlo explícitamente, no fallar ni omitirlo en silencio — a validar con `ux-ui`. Exposición revisada y aceptada sin cambios (ver revisión de seguridad, punto 5).
- Ningún borrado físico en los siete modelos nuevos: `alertas`/`citas` se cierran con estado; `inventario_items` se marca `retirado`; `hogar_convivientes`/`hogar_red_apoyo` se marcan `activo=false`; `alimentos_items` se marca `consumido`. Coherente con el criterio ya usado en ADR-0007/0008.
- Resuelto por `seguridad`: citas médicas/psicosociales no requieren `permisos_expediente` sobre toda la fila, pero sí sobre el campo `notas` (ver sección 2 y revisión de seguridad, punto 4) — decisión final, no punto abierto.
- Resuelto por `seguridad`: una alerta de `tipo=evasion` nunca puede quedar sin destinatarios resolubles; si el defensor/psicosocial asignados no tienen cuenta, se agrega como respaldo el coordinador de zona y, en su defecto, admin (ver sección "Resolución de destinatarios" y revisión de seguridad, punto 1) — decisión final, no punto abierto.
