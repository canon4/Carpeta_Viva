# Estrategia de almacenamiento

Fuentes: ADR-0003, ADR-0004, ADR-0006, ADR-0007, ADR-0008, ADR-0010, ADR-0011, ADR-0012, ADR-0014, `docker-compose.yml`, `backend/app/core/*.py`, `backend/app/modules/*/models.py`. Solo datos sintéticos.

## 1. Resumen: tres almacenes y una regla

| Almacén | Qué guarda | Estado real |
|---|---|---|
| PostgreSQL 16 con pgvector | Todo dato transaccional, historial, permisos, auditoría, configuración, texto de fragmentos y embeddings | Implementado: 31 tablas, migraciones `0001` a `0010` |
| Archivos cifrados en disco | El contenido binario de documentos, fotos de inventario, informes exportados y paquetes de archivo | Implementado (Fernet, volumen `archivos`) |
| Apache Jena Fuseki | Solo identificadores y relaciones (grafo) | Previsto (ADR-0003, ADR-0006); contenedor y `ontologia/core.ttl` existen, el backend no escribe ni consulta triples |

Regla (ADR-0003): los dos almacenes de datos (Postgres y Fuseki) se mantienen sincronizados por evento y reconciliación periódica. Ese mecanismo no está implementado (`backend/app/modules/ia/application.py`, docstring: "no existe ningún módulo que escriba triples hoy"). Fuseki queda detrás de la API y nunca expuesto a la red pública (ADR-0003); `docker-compose.yml` lo publica solo en `127.0.0.1:3030`.

## 2. PostgreSQL

### 2.1 Qué contiene y por qué

- Transaccional y de identidad: `usuarios`, `zonas`, `hogares_sustitutos`, `madres_sustitutas`, `profesionales`, `menores`, `asignaciones`, `menores_profesionales`, `permisos_expediente`, `documentos`, `reportes`, citas, alertas, inventario, alimentos, `informes_generados`, `expedientes_archivo`, `ia_consultas`. Razón: un solo motor relacional con integridad referencial y transacciones (ADR-0003).
- Catálogos y parámetros editables: `catalogos_opciones`, `configuracion_sistema` (ADR-0013, migración `0009`), para cambiar valores sin redesplegar.
- Auditoría: `auditoria_accesos`. Se escribe con `core/audit.registrar_acceso`, que inserta y hace `commit` de la sesión. ADR-0004 la define de solo inserción y particionada por fecha. Hallazgo: la inserción única es una convención de código (no hay trigger ni permisos que impidan UPDATE/DELETE) y el particionado por fecha no está hecho (`docs/metodologia/03-diseno/script-bd.sql`, cabecera). `menor_id` en esta tabla no tiene clave foránea (ningún documento explica por qué; es una referencia lógica).
- Semántica vectorial: `fragmentos_documento` con columna `embedding vector(384)` e índice HNSW por distancia coseno (migración `0005`, ADR-0010). El modelo de embeddings es local (`intfloat/multilingual-e5-small`, `core/config.py`), por lo que ningún texto sale al calcular embeddings.
- Extensiones: `vector` y `pgcrypto` (`infra/postgres/init/001-extensiones.sql`). `pgcrypto` está instalada, pero ninguna tabla la usa hoy.

### 2.2 Patrón `*_History`

Heredado del modelo previo `Contexto/ICBF.pdf` (CLAUDE.md). Antes de cambiar una fila relevante, la aplicación inserta un snapshot de la fila anterior y sube `version`.

| Tabla viva | Tabla de historia | Cuándo se escribe | Fuente |
|---|---|---|---|
| `menores` | `menores_history` | Cambia un campo trackeado (nombres, apellidos, fecha de nacimiento, género, documento, estado) | ADR-0007; `menores/domain.py` `CAMPOS_TRACKEADOS` |
| `asignaciones` | `asignaciones_history` | Cierre, traslado, corrección de fechas | ADR-0007; `asignaciones/application.py` |
| `documentos` | `documentos_versiones` | Se sube una versión nueva (`POST /documentos/{id}/version`) | ADR-0008 sección 3 |

Tablas sin historia por decisión explícita: `menores_familiares` (ADR-0007 sección 3, la cubre la auditoría), `citas` (ADR-0009 sección 2, la cubre la auditoría), `reportes` (append-only: una corrección es una fila nueva, ADR-0008 sección 3), `alertas` (no se edita, solo se cierra).

### 2.3 Sin borrado físico

"Nunca se elimina" (CLAUDE.md, ADR-0004). Se aplica con banderas: `inventario_items.estado = 'retirado'`, `activo = false` en convivientes, red de apoyo, checklist, catálogos y permisos, `consumido` en alimentos, `oculta` en fotos de inventario (ADR-0014), `estado = 'cerrada'` en alertas y asignaciones, y `expedientes_archivo.estado = 'archivado'`. El ADR-0008 extiende la regla a los archivos cifrados en disco.

### 2.4 Contenido sensible dentro de la base

Hallazgo para revisión de `seguridad`: el cifrado en reposo (sección 3) cubre solo archivos. Columnas con contenido de expediente en texto claro: `fragmentos_documento.texto`, `reportes.contenido` (JSONB), `ia_consultas.pregunta` y `respuesta` (la respuesta ya trae datos restituidos, `ia/models.py`), `menores_familiares.*`, `madres_sustitutas.firma_ref` (texto plano según el comentario de `actualizar_mi_firma`: "el almacenamiento cifrado de la firma queda pendiente"). No hay cifrado por columna en los modelos. Relacionado con el Punto abierto 2 (base legal y retención de datos de menores) y el Punto abierto 5 (valor legal de la firma como imagen).

## 3. Archivos cifrados

### 3.1 Mecanismo (ADR-0008 sección 1, `core/almacenamiento.py`)

- Cifrado por archivo con Fernet (AES-128-CBC más HMAC-SHA256, autenticado). El token incluye el IV, por eso no hay columna de nonce.
- Una sola clave maestra en la variable `ARCHIVOS_CLAVE_MAESTRA`; nunca en el repositorio. `main.py` impide arrancar en producción con la clave de desarrollo.
- `hash_sha256` se calcula sobre el contenido en claro; se recalcula al descifrar y se compara (`almacenamiento.leer`).
- La ruta relativa a `ARCHIVOS_DIR` es `{propietario_id}/{documento_id}/{version}.enc`, nunca absoluta en la base. Se valida que la ruta no escape de `ARCHIVOS_DIR` (`RutaFueraDeArchivosDir`).
- Límite de 25 MB por archivo (`archivos_tamanio_maximo_bytes`, RF2).
- Volumen `archivos` montado en `/data/archivos` en el compose de demo.

### 3.2 Qué archivos hay y dónde se referencian

| Contenido | Propietario en la ruta | Referencia en base | Fuente |
|---|---|---|---|
| Documentos y versiones | `menor_id` o `hogar_id` | `documentos.referencia_archivo`, `documentos_versiones.referencia_archivo` | ADR-0008 |
| Fotos de evidencia de recepción de inventario | `hogar_id` | `inventario_item_fotos.referencia_archivo` | ADR-0014 |
| Informes exportados (JSON, PDF, CSV) | `usuario_id` | `informes_generados.referencia_archivo` | ADR-0010 sección 2 |
| Paquete de archivo del expediente (ZIP con manifiesto) | `menor_id` | `expedientes_archivo.paquete_referencia`, `paquete_hash` | ADR-0010 sección 3 |
| Firma de la madre | no usa este módulo | `madres_sustitutas.firma_ref` (texto) | ADR-0008 (pendiente) |

### 3.3 Compresión de versiones reemplazadas (ADR-0011)

Al subir una versión nueva, si la versión que se reemplaza es una imagen, se recomprime (máximo 1280 px por lado, JPEG calidad 60) y se sobrescribe su `.enc` en la misma ruta; la columna `documentos_versiones.comprimida` lo registra (migración `0007`). PDF, Word y Excel se conservan sin cambio. El documento vigente nunca se comprime.

Tensión a resolver (hallazgo): ADR-0004 dice "los documentos se versionan y no se sobrescriben" y ADR-0008 dice que los `.enc` de versiones reemplazadas no se borran nunca. ADR-0011 sobrescribe el `.enc` histórico con una copia con pérdida. No se pierde el registro, pero sí la calidad original de la versión histórica. Decisión pendiente de `seguridad` y de la tabla de retención (Punto abierto 2).

## 4. Fuseki: solo identificadores y relaciones

- Qué entra (ADR-0003, ADR-0006): las 8 clases de `ontologia/core.ttl` (Menor, MadreSustituta, HogarSustituto, Zona, Asignacion, Profesional, Reporte, Documento), sus relaciones y metadatos (estado, fechas, categoría, versión, bandera de sensibilidad).
- Qué nunca entra: nombres, documentos de identidad, direcciones, teléfonos, fechas de nacimiento ni contenido (ADR-0006).
- Qué queda fuera de la ontología por ahora: inventario, alimentos y citas, que permanecen en PostgreSQL (ADR-0006).
- Por qué un segundo almacén: SPARQL resuelve relaciones ("documentos del NNA asignado a este hogar") y habilita reglas futuras (por ejemplo, sin informe psicosocial en 60 días); pgvector resuelve similitud de texto libre. El resultado se intersecta con permisos antes de llegar a la IA (ADR-0003).
- Estado real: la regla de "documento faltante" se implementó de forma relacional (`ia.application.evaluar_documento_faltante`, plazo de 60 días) en vez de SPARQL, con la misma semántica que `ontologia/consultas.rq`; se puede migrar sin cambiar la firma (docstring de `ia/application.py`). La validación de la ontología corre con datos sintéticos (`ontologia/validar.py`).
- Riesgo (ADR-0003): dos almacenes que sincronizar. Pendiente: eventos de sincronización y reconciliación.

## 5. Qué dato va en cada almacén

| Dato | Almacén | Por qué |
|---|---|---|
| Datos personales del menor, familiares, asignaciones, permisos | PostgreSQL | Integridad, transacciones, historial |
| Contenido de un documento (PDF, imagen, Word, Excel) | Archivo cifrado | Binario voluminoso (unos 100 archivos por NNA, CLAUDE.md); cifrado individual |
| Metadatos del documento (categoría, versión, hash, estado de flujo) | PostgreSQL | Consulta y autorización |
| Texto extraído por OCR y embeddings | PostgreSQL (`fragmentos_documento`) | Búsqueda semántica con filtro de permisos antes de generar (ADR-0002) |
| Relaciones entre entidades (menor-hogar-zona-profesional-documento) | Fuseki (previsto) y PostgreSQL (vigente) | Consultas de relaciones y reglas futuras |
| Auditoría de accesos, consultas de IA | PostgreSQL | Solo inserción, consulta por usuario y fecha |
| Inventario, alimentos, citas, alertas | PostgreSQL | Fuera de la ontología núcleo (ADR-0006) |
| Parámetros y catálogos administrables | PostgreSQL | Editables por `admin` sin redespliegue (ADR-0013) |
| Claves y secretos (`ARCHIVOS_CLAVE_MAESTRA`, `JWT_SECRET`, claves de API del LLM) | Variables de entorno | Nunca en repositorios (CLAUDE.md) |

## 6. Proveedor LLM como destino externo de datos

El texto de los fragmentos recuperados puede salir hacia un LLM externo (Anthropic o Groq, `core/ia_llm.py`, `core/config.py`). Por defecto la llamada va seudonimizada (`ia_anonimizado_por_defecto = True`, ADR-0002 punto 3); los datos reales exigen contrato y habilitación explícita (ADR-0002 punto 4). Cada respuesta queda en `ia_consultas` con modelo, proveedor, fuentes y usuario (ADR-0002 punto 7). Punto abierto 3 y Punto abierto 4 (transferencia internacional).

## 7. Respaldos y recuperación

Punto abierto: respaldos. CLAUDE.md los lista como requisito no funcional "a evaluar" (CUESTIONARIO H2: "respaldos diarios (evaluar), caídas tolerables"); no es uno de los 10 puntos numerados, pero la pérdida de datos no es tolerable (CLAUDE.md).

Lo que dicen los ADR:
- ADR-0004: los respaldos diarios deben cubrir base relacional, triple store y archivos, con prueba de restauración.
- ADR-0008: deben cubrir también el volumen `archivos`; la clave maestra se respalda por un canal distinto al del volumen, porque si se pierden juntos el respaldo no sirve. Perder o rotar la clave sin plan deja irrecuperables todos los archivos (no hay `key_id` por archivo ni `MultiFernet`); la rotación es un punto abierto adicional de ADR-0008, fuera de los 10 de CLAUDE.md.
- ADR-0010: los respaldos y la prueba de carga a 1000 usuarios quedan como tarea de `datos-infra` y `test` en la Fase 5, sin diseño.

Estado real: ningún script ni tarea programada de respaldo existe en el repositorio. `docker-compose.yml` solo declara volúmenes (`pgdata`, `fuseki_databases`, `fuseki_configuration`, `fuseki_backups`, `archivos`), que por sí solos no son respaldo. Los pasos propuestos están en `docs/metodologia/06-despliegue/monitoreo.md`, marcados como propuesta.

Decisiones que faltan, con responsable sugerido:
- Frecuencia, retención y destino de los respaldos: `datos-infra` con Diego (presupuesto, Punto abierto 8).
- Ubicación y cifrado de los respaldos (contienen datos de menores) y su relación con la nube y la transferencia internacional (Punto abierto 4): `seguridad`.
- Plazo de conservación de los respaldos frente a la tabla de retención (Punto abierto 2): operador y asesoría jurídica.
