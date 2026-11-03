# ADR-0008 Gestión documental: almacenamiento cifrado, categorías y flujo de versionado/aprobación

Estado: Aceptada, revisada por seguridad, con dos correcciones obligatorias antes de construir (fuga de contenido a auditor por categoría no sensible — sección 4/6 — y falta de verificación en arranque para `ARCHIVOS_CLAVE_MAESTRA` en producción — sección 1) y una aclaración menor (registro de intentos denegados de lectura/descarga). Detalle de la revisión al final del documento, antes de "Consecuencias".

## Contexto

Fase 3 (`docs/plan-por-fases.md`) construye el módulo 7 (Gestión Documental) sobre lo ya migrado en Fases 1 y 2. Las tablas `documentos` y `reportes` existen desde la migración `0001` (`backend/app/modules/documentos/models.py`) pero no se usan: `api.py`/`application.py` son un stub. El frontend ya tiene placeholders en las secciones "Salud" y "Psicosocial" del expediente que dicen literalmente que llegarán con esta fase.

Decisiones previas que esta ADR no puede contradecir, solo completar:
- ADR-0004: "Flujo de documento: borrador, enviado, en revisión, aprobado o devuelto" y "los documentos se versionan y no se sobrescriben". "Firma: imagen de firma cargada una vez por usuario... el valor legal se valida en seguridad" (punto abierto 5 de `CLAUDE.md`, no se resuelve aquí).
- ADR-0007: `permisos_expediente` con `seccion IN ('familia', 'salud', 'psicosocial')`, otorgados por el defensor asignado; visibilidad de fila por rol en `menores/application.py` (`_puede_ver_menor`, `_tiene_permiso_seccion`, ambas privadas hoy).
- `CLAUDE.md`: "La madre crea los documentos; los profesionales revisan y aprueban." "El profesional encargado de cada NNA define qué parte del expediente ve cada persona." "Cuando el NNA sale del hogar, el expediente se oculta a la madre; nunca se elimina." Punto abierto 1 (destino final/tabla de retención) sigue sin resolver — no es objeto de esta ADR.
- Sin presupuesto de nube (punto abierto 8): filesystem local, sin S3 ni KMS.

No se resuelve aquí (quedan como puntos abiertos, igual que antes): destino final del archivo al cierre (punto abierto 1), tabla de retención documental, valor legal de la firma (punto abierto 5), rotación de la clave maestra de cifrado.

## Decisión

### 1. Almacenamiento y cifrado en reposo

**Cifrado**: por archivo, con `Fernet` (`cryptography.fernet`, AES-128-CBC + HMAC-SHA256, autenticado). Se elige Fernet y no AES-GCM manual porque el token que produce ya incluye IV y HMAC embebidos en un solo blob — no hace falta una columna de IV/nonce separada ni gestionar el ensamblado, lo cual es más simple de implementar y auditar para dos desarrolladores. Para el volumen y amenaza de este prototipo (filesystem local, sin HSM) es suficiente; no es una decisión para producción con mayor escala sin revisión de `seguridad`.

**Clave**: una sola clave maestra Fernet (32 bytes, base64 urlsafe) en variable de entorno `ARCHIVOS_CLAVE_MAESTRA`, nunca en el repo. Se agrega a `.env.example` (sin valor real) y a `Settings` (`app/core/config.py`) con una constante `ARCHIVOS_CLAVE_POR_DEFECTO` de solo-desarrollo, siguiendo el mismo patrón ya usado para `JWT_SECRET_POR_DEFECTO`. No hay derivación por archivo ni por menor en esta fase (un KMS o derivación HKDF por documento es sobre-ingeniería para el alcance actual); rotación de clave queda como punto abierto nuevo, a cargo de `seguridad` cuando haya más de un ambiente real.

**Corrección obligatoria de seguridad (bloqueante):** no basta con que exista la constante de desarrollo; `app/main.py::create_app` ya falla explícitamente si `environment == "production"` y `jwt_secret == JWT_SECRET_POR_DEFECTO` (línea 12). `backend` debe agregar la misma verificación para `ARCHIVOS_CLAVE_MAESTRA`: `if settings.environment == "production" and settings.archivos_clave_maestra == ARCHIVOS_CLAVE_POR_DEFECTO: raise RuntimeError(...)`. Sin esto, un despliegue en producción sin configurar la variable cifraría documentos de identidad/salud/psicosocial de NNA con una clave pública (la del repositorio), lo que equivale a no cifrar. Es el mismo patrón que ya protege `JWT_SECRET`; omitirlo aquí sería inconsistente y es el riesgo más alto de esta ADR.

**Nota sobre rotación (mitigación mínima, no construir ahora):** a diferencia de `JWT_SECRET` (rotarlo solo invalida sesiones), perder o rotar `ARCHIVOS_CLAVE_MAESTRA` sin plan hace irrecuperables todos los archivos ya cifrados — no hay `key_id` por archivo ni `MultiFernet`. No se exige implementar rotación en esta fase (punto abierto nuevo, confirmado), pero el equipo debe saber que el día que se rote la clave hace falta un script de migración que descifre con la clave vieja y re-cifre con la nueva para cada archivo existente, y que la clave debe respaldarse por un canal distinto al respaldo del volumen `archivos` (si se pierden juntos, backup y clave, el respaldo no sirve para nada).

**Dónde viven los archivos**: directorio local configurable por `ARCHIVOS_DIR`.
- En `docker-compose.yml` el volumen `archivos` ya está declarado y montado en `/data/archivos` del contenedor backend; falta agregar `ARCHIVOS_DIR: /data/archivos` y `ARCHIVOS_CLAVE_MAESTRA: ${ARCHIVOS_CLAVE_MAESTRA}` a `environment` del servicio `backend` (tarea de `datos-infra`, no de esta ADR).
- En desarrollo local sin Docker (Postgres nativo), `ARCHIVOS_DIR` por defecto `./data/archivos` relativo a la raíz de `backend/`. `datos-infra` debe añadir `data/` al `.gitignore` de `backend/` (hoy no está).

**Estructura de rutas** (relativas a `ARCHIVOS_DIR`, nunca absolutas en la base de datos): `{menor_id|hogar_id}/{documento_id}/{version}.enc`. Esa ruta relativa es lo que se guarda en `Documento.referencia_archivo` / `Reporte.referencia_archivo`.

**Integridad**: `hash_sha256` (columna ya existente) se calcula sobre el archivo en claro (antes de cifrar), no sobre el blob cifrado — sirve para auditar integridad real del contenido y para detectar duplicados. Se recalcula y compara al descifrar para leer.

**Reutilización**: un único módulo de almacenamiento (p. ej. `app/core/almacenamiento.py`, a implementar por `backend`) con `guardar(bytes) -> ruta_relativa, hash` y `leer(ruta_relativa) -> bytes`, usado tanto por `Documento.referencia_archivo` como por `Reporte.referencia_archivo` y reutilizable por `actualizar_mi_firma` de `madres` si luego se decide cifrar también la firma (hoy se guarda en texto plano según su propio comentario "ADR futuro" — esta ADR no lo resuelve, pero deja listo el módulo para que `madres` lo adopte sin rediseñar nada).

### 2. Categorías documentales (provisional, pendiente de validar con el operador)

Lista inicial, basada en `Contexto/` y `CUESTIONARIO.md` B1, **no es definitiva**:

| Categoría | `menor_id` o `hogar_id` | Sección de permiso (ADR-0007) |
|---|---|---|
| `identidad` | menor | ninguna (visibilidad básica) |
| `salud` | menor | `salud` |
| `psicosocial` | menor | `psicosocial` |
| `educacion` | menor | ninguna (visibilidad básica) |
| `familia_red_apoyo` | menor | `familia` |
| `actas_traslados` | menor | ninguna (visibilidad básica; ligado a `asignaciones`) |
| `madre_habilitacion` | hogar | n/a (ver autorización de hogar, 2.1) |
| `otros` | menor u hogar | ninguna por defecto; se puede forzar `sensible=true` manualmente |

Mapeo `categoria → seccion` como constante en `app/modules/documentos/domain.py` (`SECCION_POR_CATEGORIA: dict[str, str | None]`), no duplicado en otros módulos. Se agrega `CheckConstraint` en la migración para que `categoria` solo acepte estos valores (controla errores de carga, no impide extender la lista después).

**2.1 Autorización para documentos de hogar** (`hogar_id` sin `menor_id`, hoy solo `madre_habilitacion`): visible y editable por la madre de ese hogar, el coordinador de la zona del hogar y admin/auditor (solo lectura de metadatos para auditor, igual que en ADR-0007 punto 3).

### 3. Flujo de versionado y aprobación

**Estados** (`Documento.estado_flujo`, ya `String(30)` default `"borrador"`): `borrador → en_revision → aprobado | devuelto`. Se simplifican los cinco estados de ADR-0004 ("borrador, enviado, en revisión, aprobado o devuelto") a cuatro: "enviado" y "en revisión" se funden en un solo estado `en_revision`, porque en este flujo nadie actúa entre que la madre envía y el profesional empieza a revisar — mantener dos estados ahí es complejidad sin beneficio para un equipo de dos personas. Si `devuelto`, el documento vuelve a ser editable por su creador (no hay estado `borrador` nuevo automático: se reutiliza `devuelto` como "pendiente de corrección" hasta que se suba una nueva versión, momento en que pasa a `en_revision` otra vez).

**Quién crea** (`POST /documentos`):
- Rol `madre`: solo si tiene una `Asignacion` vigente con ese `menor_id` (vía `puede_ver_menor` de `menores.application`); si la categoría mapea a sección sensible, además necesita `tiene_permiso_seccion` (ver sección 4). Crea en `borrador`.
- Rol `profesional`/`defensor` asignado al menor (`esta_asignado_a_menor`): crea directamente en `aprobado` (es la autoridad que de todas formas tendría que aprobarlo; pedirle que se autoapruebe es ceremonia sin valor). Queda registrado igual en auditoría con su propio `usuario_id` como `creado_por`.
- Rol `coordinador`/`admin` con `migracion=true` en el payload (RF10, digitalización del historial físico): crea directamente en `aprobado`, `motivo="migración histórica"` obligatorio. No es un endpoint distinto, es un parámetro de `POST /documentos` restringido a esos roles.
- Ningún otro rol crea documentos.

**Transiciones**:
- `PUT /documentos/{id}/enviar`: `borrador → en_revision`. Solo el `creado_por` (o quien tenga su mismo permiso de edición sobre el menor).
- `PUT /documentos/{id}/aprobar`: `en_revision → aprobado`. Solo un profesional/defensor con `esta_asignado_a_menor(menor_id)` verdadero — no se restringe a defensor como en ADR-0007 punto 5 (eso es para *otorgar acceso a la madre*, un permiso distinto de *aprobar un documento*). Guarda `revisado_por`, `revisado_en`. **Revisión de seguridad (no bloqueante):** coherente con `CLAUDE.md` ("los profesionales revisan y aprueban", sin distinguir cuál) y con ADR-0007 punto 1, que ya decidió no restringir lectura entre tipos de profesional asignado por la misma razón de simplicidad para un equipo de dos personas. No es una vulnerabilidad de acceso (el conjunto de personas ya podía leer la sección completa); es un riesgo de *calidad/responsabilidad profesional* — un nutricionista podría aprobar un informe psicosocial sin el criterio clínico correspondiente — que `CLAUDE.md` no resuelve hoy. Se deja anotado como el mismo refinamiento futuro ya previsto en ADR-0007 ("si el operador pide granularidad entre profesionales, se extiende `permisos_expediente`"); no requiere cambio de diseño en esta fase.
- `PUT /documentos/{id}/devolver`: `en_revision → devuelto`, con `motivo` obligatorio (string). Misma autorización que aprobar.
- Nunca hay borrado físico ni lógico de `Documento` ni de archivo cifrado, ni siquiera en `borrador` (coherente con "nunca se elimina"); si la madre se equivocó de archivo, sube una nueva versión, no borra.

**Versionado — no se sobrescribe (ADR-0004)**: cuando se sube un archivo nuevo para un `Documento` ya existente (`POST /documentos/{id}/version`, permitido en `borrador` o `devuelto`), la aplicación:
1. Inserta en `documentos_versiones` (tabla nueva) un snapshot de la fila actual: `version`, `referencia_archivo`, `hash_sha256`, `nombre_original`, `mime_type`, `tamanio_bytes`, `estado_flujo`, `creado_por`, `revisado_por`, `motivo_devolucion`, `created_at` del snapshot.
2. Actualiza la fila `Documento`: nuevo `referencia_archivo`/`hash_sha256`/metadatos de archivo, `version += 1`, `estado_flujo = en_revision` (se reenvía directo, sin pasar otra vez por `borrador`).

Esto sigue exactamente el mismo patrón `*_History` que `menores_history`/`asignaciones_history` (snapshot completo antes de pisar la fila), no uno nuevo.

**Reporte** (informes estructurados de profesionales) **no** sigue este flujo de aprobación: el profesional que lo crea ya es la autoridad sobre su propio informe (`autor_id`, `tipo_autor`). Es un registro append-only: cada informe nuevo (ej. seguimiento psicosocial mensual) es una fila `Reporte` nueva con `version=1`; si hay que corregir uno ya creado, se emite una fila nueva con `version` incrementada y, si backend lo necesita para enlazar la corrección con el original, puede agregarse una columna `reporte_anterior_id` (autorreferencia, nullable) — no obligatoria para esta fase, se deja como extensión simple si surge la necesidad. No se crea tabla `reportes_history`: la lista completa de `Reporte` por menor y tipo ya es el historial.

### 4. Relación con las secciones sensibles del expediente (ADR-0007)

No se duplica lógica de autorización. `menores/application.py` expone hoy `puede_ver_menor` (público) pero `_tiene_permiso_seccion` es privada. **Se requiere que `backend` agregue un wrapper público** `tiene_permiso_seccion(session, usuario, menor, seccion) -> bool` en `menores/application.py`, mismo patrón que ya existe para `puede_ver_menor` (son ~3 líneas, no un rediseño). `documentos/application.py` importa y llama a ambos (`puede_ver_menor`, `tiene_permiso_seccion`) dentro de cada función, igual que ya hacen `asignaciones` y otros módulos hermanos (import local, no al cargar el módulo, para evitar ciclos).

Regla de autorización de lectura de un `Documento` o `Reporte`:
1. Resolver `seccion = SECCION_POR_CATEGORIA[categoria]` (o `SECCION_POR_TIPO_REPORTE[tipo_reporte]` para `Reporte`, mismo mapeo salud/psicosocial).
2. Si `seccion is None`: autorización = `puede_ver_menor(session, usuario, menor_id)` (visibilidad básica de fila, ya cubre profesional asignado, madre con asignación vigente, coordinador de zona, admin/auditor).
3. Si `seccion` no es `None`: autorización = `tiene_permiso_seccion(session, usuario, menor, seccion)` — para profesional/defensor asignado es automáticamente `true` (ADR-0007, regla 1); para madre exige el permiso activo otorgado por el defensor; coordinador y auditor quedan fuera salvo lo ya decidido en ADR-0007 (auditor ve metadatos, nunca contenido sensible — ver endpoint de auditor abajo).

**Corrección obligatoria de seguridad (bloqueante) — hueco de auditor en categorías no sensibles:** la regla 2, tal como está escrita, usa `puede_ver_menor` para `seccion is None` (`identidad`, `educacion`, `actas_traslados`), y `puede_ver_menor` devuelve `true` para `admin` **y para `auditor`** sin más condición (`menores/application.py::_puede_ver_menor`, líneas 38-39). Aplicada tal cual a `GET /documentos/{id}/contenido` y `GET /documentos/{id}/versiones/{version}/contenido`, esto le da al auditor **descarga del archivo descifrado** (p. ej. imagen de cédula/registro civil, acta de traslado) por la ruta genérica, lo que contradice ADR-0007 punto 3 ("el auditor nunca ve contenido, solo metadatos") y el propio endpoint `GET /documentos/auditor` de esta ADR ("nunca contenido"). El criterio de necesidad de la Ley 1581/2012 art. 4 aplica igual a documentos no catalogados como "sensibles" en este diseño (identidad de un NNA no es un dato trivial). Corrección: las rutas que devuelven **contenido** (`/contenido` del documento vigente y de versiones anteriores) deben excluir explícitamente al rol `auditor` sin pasar por la regla 2 general — `auditor` solo accede a metadatos (`GET /documentos/{id}`, `GET /documentos`, `GET /documentos/auditor`), nunca a bytes de archivo, sea la categoría sensible o no. `admin` puede conservar acceso a contenido (rol de administración del sistema, ya con acceso amplio en ADR-0007), pero cada descarga de `admin` debe quedar auditada igual que cualquier otra (ya cubierto por `registrar_acceso`).

Esto responde directamente el problema original: las secciones "Salud" y "Psicosocial" del expediente en el frontend dejan de ser un placeholder y se resuelven con `GET /documentos/menor/{menor_id}/seccion/{seccion}` (ver endpoints), que agrega tanto `Documento` (archivos) como `Reporte` (informes) de esa sección, aplicando esta misma regla.

### 5. Esquema de datos — cambios necesarios (migración `0003`, a cargo de `datos-infra`/`backend`)

La tabla `documentos` actual **no alcanza**; faltan metadatos de archivo que RF2 (multiformato) y la UI necesitan, y no hay tabla de versiones. Cambios:

**ALTER `documentos`** (agregar columnas):
- `nombre_original` (`String(255)`, not null) — nombre del archivo subido, para mostrarlo y para inferir tipo si falta `mime_type`.
- `mime_type` (`String(100)`, not null).
- `tamanio_bytes` (`Integer`, not null).
- `revisado_por` (`Uuid`, FK `usuarios.id`, nullable).
- `revisado_en` (`DateTime`, nullable).
- `motivo_devolucion` (`String(255)`, nullable).
- `CheckConstraint` nuevo: `categoria IN (...)` (lista de la sección 2).
- `CheckConstraint` nuevo: `estado_flujo IN ('borrador', 'en_revision', 'aprobado', 'devuelto')`.
- Índice compuesto `(menor_id, categoria)` para los listados filtrados (opcional pero recomendado, bajo costo).

**No se agrega columna de IV/nonce**: Fernet la embebe en el propio token almacenado en el archivo `.enc`; no hace falta persistirla aparte.

**Nueva tabla `documentos_versiones`**:
- `id` (uuid pk), `documento_id` (FK `documentos.id`, index), `version` (int, la que queda reemplazada), `referencia_archivo`, `hash_sha256`, `nombre_original`, `mime_type`, `tamanio_bytes`, `estado_flujo` (snapshot), `creado_por` (FK `usuarios.id`), `revisado_por` (FK `usuarios.id`, nullable), `motivo_devolucion` (nullable), `created_at` (momento del snapshot, `server_default=func.now()`).

**`reportes`**: sin cambios obligatorios en esta fase. Opcional, no bloqueante: columna `reporte_anterior_id` autorreferenciada si backend decide enlazar correcciones (sección 3).

### 6. Contrato de endpoints (alto nivel, bajo `/api/v1/documentos`)

- `POST /documentos` (multipart: `archivo`, `menor_id` o `hogar_id`, `categoria`, `titulo`, `migracion` opcional bool) — crea documento; aplica autorización de creación (sección 3) y de sección si corresponde (sección 4); cifra, calcula hash/metadatos, registra auditoría (`documento_creado` / `documento_creacion_denegada`).
- `GET /documentos?menor_id=&hogar_id=&categoria=&estado=` — lista filtrada; cada fila pasa por la regla de autorización de lectura (sección 4); nunca se filtra solo por rol sin pasar por esa regla.
- `GET /documentos/{id}` — metadatos de un documento (sin contenido).
- `GET /documentos/{id}/contenido` — descarga/stream del archivo descifrado; misma autorización que el metadato **salvo que el solicitante tenga rol `auditor`, caso en el que se deniega siempre (403)**, independientemente de la categoría (ver corrección de sección 4); registra `documento_descargado` si se concede o `documento_descarga_denegada` si no, con `usuario_id` y `recurso` igual en ambos casos (mismo patrón que `menores/application.py`, que registra tanto el acceso concedido como el denegado, nunca solo el positivo).
- `PUT /documentos/{id}/enviar` — `borrador → en_revision`.
- `PUT /documentos/{id}/aprobar` — `en_revision → aprobado`.
- `PUT /documentos/{id}/devolver` (body: `motivo`) — `en_revision → devuelto`.
- `POST /documentos/{id}/version` (multipart: `archivo`) — nueva versión; snapshot a `documentos_versiones`; solo en estado `borrador` o `devuelto`.
- `GET /documentos/{id}/versiones` — metadatos de versiones anteriores.
- `GET /documentos/{id}/versiones/{version}/contenido` — descarga de una versión anterior (misma autorización que el documento vigente, incluida la exclusión de `auditor`).
- `POST /documentos/reportes` (body: `menor_id`, `tipo_reporte`, `contenido` JSON, `referencia_archivo` opcional) — solo profesional/defensor asignado; crea en estado implícito "definitivo" (sin flujo de aprobación, sección 3).
- `GET /documentos/reportes?menor_id=&tipo_reporte=` — lista filtrada por la misma regla de sección.
- `GET /documentos/reportes/{id}` — detalle.
- `GET /documentos/menor/{menor_id}/seccion/{seccion}` (`seccion ∈ familia|salud|psicosocial`) — agrega `Documento` (por `categoria` mapeada) + `Reporte` (por `tipo_reporte` mapeado) de esa sección; aplica `tiene_permiso_seccion`; **este es el endpoint que reemplaza el placeholder de Salud/Psicosocial en el frontend**.
- `GET /documentos/auditor` (o filtro `?solo_metadatos=true` sobre `GET /documentos`) — para rol auditor: metadatos de todos los documentos/reportes (tipo, autor, fecha, estado, versión, hash), nunca contenido ni archivos marcados `sensible` (ADR-0007 punto 3).

Todas las rutas de lectura y escritura pasan por `registrar_acceso` (ya existente en `app/core/audit.py`), igual que `menores`/`asignaciones`. **Aclaración (no bloqueante):** esto incluye los intentos denegados, no solo los concedidos — `menores/application.py` registra siempre ambos casos con acciones distintas (p. ej. `menor_consultado` / `menor_consulta_denegada`); `documentos/application.py` debe seguir el mismo patrón en cada endpoint de lectura y descarga (no solo en creación, donde el ADR ya lo deja explícito con `documento_creacion_denegada`), para que la auditoría pueda detectar intentos de acceso no autorizado a expedientes de NNA, no solo accesos exitosos.

## Revisión de seguridad (2026-11-03)

Validación solicitada por el arquitecto antes de que `backend` construya. Resultado: **Aceptada, con 2 correcciones obligatorias ya incorporadas arriba** (marcadas "Corrección obligatoria de seguridad (bloqueante)" en secciones 1 y 4) y 2 aclaraciones no bloqueantes incorporadas (sección 3, flujo de aprobación; sección 6, registro de intentos denegados).

1. **Cifrado (Fernet + clave única en `.env`)**: razonable para este prototipo sin presupuesto de nube (punto abierto 8). El patrón de clave de desarrollo marcada como insegura, igual a `JWT_SECRET_POR_DEFECTO`, está bien pensado — pero faltaba el chequeo de arranque que ya existe para `JWT_SECRET` (`app/main.py` línea 12); se exige el mismo para `ARCHIVOS_CLAVE_MAESTRA` (sección 1, corrección obligatoria). Sin esa verificación, el riesgo no es teórico: un despliegue descuidado en producción cifraría datos de identidad/salud/psicosocial de NNA con una clave pública del repositorio.
2. **Autorización por sección reutilizada**: el mapeo `categoria → sección` (sección 2 del ADR) es coherente con ADR-0007 y el wrapper público `tiene_permiso_seccion` propuesto es el patrón correcto (ya existe el precedente con `puede_ver_menor`). Las categorías sin sección sensible (`identidad`, `educacion`, `actas_traslados`) quedan correctamente gobernadas por `puede_ver_menor` para visibilidad de fila (quién puede ver que el documento existe y sus metadatos, y crear/editar según sección 3) — **pero esa misma regla, aplicada sin ajuste a los endpoints que devuelven contenido descifrado, le daba al rol `auditor` acceso a archivos (no solo metadatos) de esas categorías**, contradiciendo ADR-0007 punto 3. Corregido en sección 4/6: `auditor` nunca accede a `/contenido`, en ninguna categoría. No quedan otros huecos visibles en el mapeo.
3. **Flujo de aprobación** ("cualquier profesional/defensor asignado, no solo el defensor"): coherente con `CLAUDE.md` y con el precedente ya aceptado en ADR-0007 punto 1. No es un hueco de seguridad — es, cuando mucho, un riesgo de calidad profesional ya anotado como refinamiento futuro, no bloqueante.
4. **Descarga de contenido por `registrar_acceso`**: el ADR ya lo dejaba explícito para el caso de éxito (`documento_descargado`); se completó exigiendo también el registro del intento denegado (`documento_descarga_denegada`), siguiendo el mismo patrón ya usado en `menores/application.py`. No bloqueante, pero necesario para que la auditoría sirva para detectar intentos indebidos, no solo accesos concedidos.
5. **Puntos abiertos (rotación de clave, valor legal de la firma)**: ambos se dejan anotados como estaban, sin requerir diseño adicional en esta fase. Para rotación se agregó una nota de mitigación mínima (sección 1): documentar que rotar la clave exige un script de re-cifrado por lote y que la clave debe respaldarse por un canal distinto al del volumen de archivos — no construir nada ahora, solo que el equipo lo sepa antes de que ocurra. El valor legal de la firma sigue sin resolución de seguridad posible (requiere abogado, punto abierto 5 de `CLAUDE.md`); no hay mitigación técnica adicional que agregar en esta fase.

**No requiere validación jurídica** nada de lo corregido en esta revisión (son correcciones de implementación/autorización, no de base legal). El punto abierto de la firma sigue marcado para abogado, como ya estaba.

## Consecuencias

- Backend debe: agregar `cryptography` a `requirements.txt` (Fernet) y `python-multipart` si no está ya instalado (necesario para `UploadFile` de FastAPI); implementar `app/core/almacenamiento.py`; agregar el wrapper público `tiene_permiso_seccion` en `menores/application.py`; implementar `documentos/{domain,repository,application,api,schemas}.py` sobre este contrato.
- `datos-infra` debe: generar la migración `0003` (columnas nuevas + `documentos_versiones` + constraints), agregar `ARCHIVOS_DIR`/`ARCHIVOS_CLAVE_MAESTRA` a `docker-compose.yml` (servicio `backend`) y a `.env.example`, y agregar `data/` al `.gitignore` de `backend/`.
- Respaldos diarios (ya anotado en ADR-0004) deben cubrir también el volumen `archivos`/`ARCHIVOS_DIR`, no solo Postgres; sin esto, perder el volumen pierde todos los archivos aunque la clave esté a salvo.
- Toda consulta de IA (ADR-0002) sobre contenido de documentos debe pasar por esta misma regla de autorización de sección, nunca leer `referencia_archivo` directo del repositorio.
- Resuelto por `seguridad` (ver "Revisión de seguridad" arriba): (a) Fernet con una sola clave maestra sin rotación **es aceptable para este prototipo académico** (sin HSM, sin presupuesto de nube, equipo de dos personas), con la condición obligatoria del chequeo de arranque en producción (sección 1). Para producción real con datos reales de NNA se exigiría, antes de ese paso: gestión de la clave fuera del `.env` plano (KMS/HSM o al menos un secreto montado, no variable de entorno visible en `docker inspect`/logs de proceso), capacidad de rotación (p. ej. `key_id` por archivo + `MultiFernet`, hoy no implementado a propósito), y separación física del respaldo de la clave respecto del respaldo del volumen de archivos. (b) Confirmado: "nunca se elimina" aplica igual a los archivos cifrados en disco, no solo a las filas — ni el `.enc` vigente ni los `.enc` de versiones reemplazadas (referenciados desde `documentos_versiones`) se borran físicamente nunca, coherente con RF7/ADR-0004; si se necesita liberar espacio alguna vez, es una decisión de retención documental (punto abierto 2), no de esta ADR.
- Punto abierto existente sin resolver aquí: destino final del expediente al cierre (punto abierto 1 de `CLAUDE.md`) — cuando se defina, el módulo de Archivo y Cierre (T3, Fase 5) deberá exportar también los archivos cifrados de este módulo, no solo metadatos.
- Categorías documentales marcadas explícitamente como provisionales: si el operador (Fundación Fundar / ICBF) define una tabla de retención o clasificación oficial (punto abierto 2), esta ADR se actualiza o se reemplaza, y el `CheckConstraint` de `categoria` se migra de nuevo.
