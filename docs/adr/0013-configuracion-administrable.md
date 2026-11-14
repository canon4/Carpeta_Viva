# ADR-0013 Módulo transversal de configuración administrable

Estado: Aceptada, con el cambio de la sección 5.1 (revisión de `seguridad`, 2026-11-14)
incorporado a la decisión. `backend` puede construir el módulo completo, incluida la migración
de categorías documentales (sección 7, punto 1), sin punto pendiente adicional.

## Contexto

Varios catálogos de valores y parámetros de negocio están hoy fijos en el código (listas en
Python, duplicadas en TypeScript, y algunos con `CheckConstraint` en la base de datos):

- Categorías documentales por NNA y por hogar (`frontend/.../documentos/categorias.ts`,
  `app/modules/documentos/domain.py`) — ya marcadas en el código como "provisionales" (ADR-0008
  sección 2).
- Tipos de alerta, origen y estado (`app/modules/alertas/domain.py`).
- Roles de profesional que reciben alerta de evasión (`ROLES_DESTINATARIOS_EVASION`, hoy fijo:
  `defensor`, `psicosocial`).
- Tipos de cita y sus estados (`app/modules/citas/models.py`).
- Tipos de ítem de inventario (`app/modules/inventario/models.py`).
- Niveles de informe (`app/modules/reportes/models.py`).
- Parentescos / tipos de relación familiar del expediente del menor.
- Umbrales de alerta (días para "visita vencida", días sin informe psicosocial, frecuencia de
  recordatorio de citas) — ninguno implementado todavía; quedarían fijos en código si no se
  decide esto ahora.
- Datos institucionales (nombre del operador, logo, contacto) y textos de ayuda en pantalla.
- Parámetros técnicos hoy en variables de entorno: tamaño máximo de archivo, formatos aceptados,
  dimensión/calidad de compresión de imágenes (`app/core/compresion.py`), tiempo de expiración
  de sesión.

Ya existe un precedente de cómo volver editable un valor así: ADR-0009 agregó
`configuracion_alertas`, una tabla de fila única editable por `admin`
(`PUT /alertas/configuracion/telefono-policia-infancia`), con la variable de entorno como
respaldo si queda en `NULL`. El usuario pidió generalizar este patrón: que el administrador
pueda cambiar estos datos sin que el equipo de desarrollo tenga que tocar código ni redesplegar
cuando el sistema ya esté entregado.

## Decisión

### 0. Módulo nuevo, transversal, no una extensión de `alertas`

Vive en un módulo propio `configuracion` — decimosexto módulo del sistema, transversal T4 en
`docs/modulos.md` (`backend/app/modules/configuracion/`, `frontend/src/app/modules/configuracion/`,
registrado en `app/modules/registry.py`). No se cuelga de `alertas` (que ya tiene su propia
tabla por el precedente de ADR-0009) ni de ningún otro módulo de negocio: lo necesitan
`documentos`, `alertas`, `citas`, `inventario`, `reportes` y `menores` por igual, y la regla ya
vigente es que los módulos se comunican solo por la capa de aplicación. Cada módulo que quiera
un catálogo o un parámetro configurable importa funciones de `configuracion.application`
(`obtener_opciones_catalogo`, `valor_valido_en_catalogo`, `obtener_parametro`) — nunca toca
`catalogos_opciones` ni `configuracion_sistema` directamente. Es transversal porque no tiene una
vista propia por rol (solo `admin` la usa) y porque su función es servir a los demás módulos, no
modelar una entidad de negocio — mismo criterio ya usado para `Auditoría` y `Archivo y Cierre`.

### 1. Esquema de datos

```
tabla catalogos_opciones
  id              uuid PK
  grupo           string(60)   index           -- p.ej. "categoria_documento_menor"
  valor           string(100)                   -- clave estable usada en el resto del sistema
  etiqueta        string(200)                   -- texto mostrado en pantalla
  orden           integer      default 0
  activo          bool         default true     -- se desactiva, nunca se borra
  creado_en       datetime     server_default now()
  actualizado_en  datetime     nullable
  actualizado_por uuid FK usuarios, nullable
  UniqueConstraint(grupo, valor)

tabla configuracion_sistema
  clave           string(100) PK                -- p.ej. "telefono_policia_infancia"
  valor           text        nullable           -- se guarda como texto; cada lector lo castea
  actualizado_en  datetime    nullable
  actualizado_por uuid FK usuarios, nullable
```

Sin cambio de fondo respecto a la versión Propuesta; se precisan tipos y longitudes concretas
para la migración Alembic.

### 2. Registro en código de qué existe para administrar

Una tabla genérica no le dice al administrador qué grupos de catálogo o qué claves de parámetro
existen — eso no puede vivir en la base de datos porque cada grupo/clave solo tiene sentido si
algún módulo de negocio lo lee. Se agrega un registro **en código**, en
`configuracion/domain.py`, análogo a cómo hoy `CATEGORIAS_MENOR` vive en `documentos/domain.py`,
pero centralizado:

```python
GRUPOS_CATALOGO: dict[str, GrupoCatalogoDef]      # grupo -> {etiqueta, descripcion}
REGISTRO_PARAMETROS: dict[str, ParametroDef]       # clave -> {tipo, valor_por_defecto, descripcion, publico, grupo}
```

Cada módulo que migre un catálogo o un parámetro agrega su entrada aquí (una línea), sin que
`configuracion` necesite saber nada del dominio de ese módulo. `GET /configuracion/catalogos` y
`GET /configuracion/parametros` leen este registro para mostrar al admin qué puede administrar,
cruzado con lo que ya hay guardado en las dos tablas. Esto no estaba en la versión Propuesta del
ADR y es la única pieza nueva de diseño: sin él, el admin tendría que adivinar el nombre exacto
de un `grupo` o una `clave` para poder editarlo, lo que en la práctica haría el mecanismo inútil
sin ayuda del equipo de desarrollo — justo lo que se quiere evitar.

### 3. Endpoints (`/api/v1/configuracion`)

**Catálogos:**
- `GET /configuracion/catalogos` — admin. Lista los grupos registrados (`GRUPOS_CATALOGO`) con
  conteo de opciones activas.
- `GET /configuracion/catalogos/{grupo}` — cualquier usuario autenticado. Solo opciones
  `activo=true`, ordenadas por `orden` → `[{valor, etiqueta, orden}]`. La usan los formularios
  (p.ej. la madre eligiendo categoría al subir un documento): no puede ser solo para `admin`.
- `GET /configuracion/catalogos/{grupo}/admin` — admin. Incluye inactivas, con metadatos
  completos (`id`, `activo`, `actualizado_en`, `actualizado_por`) para la pantalla de gestión.
- `POST /configuracion/catalogos/{grupo}` `{valor, etiqueta, orden}` — admin. Crea opción.
- `PUT /configuracion/catalogos/{grupo}/{valor}` `{etiqueta?, orden?, activo?}` — admin. Edita o
  desactiva. Sin `DELETE`: nunca se borra una opción (coherente con "no borrado físico" ya usado
  en el resto del sistema); si ya no se usa, se desactiva.

**Parámetros:**
- `GET /configuracion/parametros` — admin. Lista todas las claves de `REGISTRO_PARAMETROS` con
  `{clave, etiqueta, descripcion, tipo, grupo, publico, valor_actual, valor_por_defecto,
  editado_por_admin}`.
- `GET /configuracion/parametros/{clave}` — admin. Detalle de una clave.
- `PUT /configuracion/parametros/{clave}` `{valor}` — admin. Hace *upsert* en
  `configuracion_sistema`; valida el tipo declarado en el registro antes de guardar (p.ej. que
  un umbral en días sea un entero); registra auditoría.
- `GET /configuracion/publica` — cualquier usuario autenticado. Solo las claves con
  `publico=true` (p.ej. nombre del operador, datos de contacto institucional) → `[{clave,
  valor}]`, para que cualquier pantalla pueda mostrarlas sin requerir rol `admin`.

Esto cambia el contrato plano `GET/PUT /configuracion/{clave}` de la versión Propuesta: con dos
mecanismos bajo el mismo prefijo hacía falta separar `catalogos/` de `parametros/` para no
chocar rutas, y la necesidad real de lectura pública/no-admin de catálogos y de algunos
parámetros institucionales no estaba resuelta en la versión original (decía "solo `admin` ve y
edita `/configuracion/*`", lo que habría impedido que la madre viera las categorías documentales
al subir un documento). Queda corregido aquí.

### 4. Permisos

- Todas las rutas de escritura (`POST`/`PUT`) y las de listado completo para `admin`
  (`/catalogos`, `/catalogos/{grupo}/admin`, `/parametros*`) exigen rol `admin`
  (`requiere_roles(Rol.ADMIN)`, mismo patrón que `zonas_hogares`/`madres`/`auditoria`).
- `GET /configuracion/catalogos/{grupo}` (solo activas) y `GET /configuracion/publica` exigen
  solo estar autenticado (`usuario_actual`), cualquier rol.
- Toda escritura queda en auditoría (`registrar_acceso`), igual que `configuracion_alertas`
  (ADR-0009).

### 5. Valores nuevos sin mapeo de lógica — regla de seguridad explícita

Cuando un módulo de negocio asocia un valor de catálogo a una regla (p.ej.
`SECCION_POR_CATEGORIA` en `documentos/domain.py`, que decide si una categoría documental exige
permiso de sección `salud`/`psicosocial`/`familia`), agregar una opción nueva al catálogo desde
`admin` **no crea automáticamente esa asociación**. Esa asociación sigue fija en código (es
lógica de negocio, igual que los estados del flujo documental — ver sección 6). Regla obligatoria
para quien implemente: el lector de la asociación (`SECCION_POR_CATEGORIA.get(valor)`, patrón ya
usado) debe devolver `None` (visibilidad básica, nunca una sección sensible) cuando el valor no
tiene entrada explícita, para que una categoría nueva sin mapear quede en el nivel de
visibilidad **menos** privilegiado, no en uno más abierto por accidente.

### 5.1 Revisión de `seguridad` (2026-11-14) y corrección incorporada

Revisión hecha sobre `documentos/domain.py` y `documentos/application.py`
(`SECCION_POR_CATEGORIA`, `_puede_ver_documento`, `_puede_descargar_contenido`,
`listar_para_auditor`, ADR-0007/0008/0011). Conclusión: el fallback a `None` es correcto como
*mecanismo de respaldo*, pero **no es seguro dejarlo como único mecanismo**, porque "visibilidad
básica" no equivale a "nadie la ve": hoy incluye automáticamente a la madre asignada al menor
(sin que el profesional habilite nada — `_tiene_permiso_seccion` no se evalúa cuando
`seccion_de_categoria` devuelve `None`), al coordinador de toda la zona, y al auditor en bloque
sobre todos los menores (`listar_para_auditor` incluye todo documento con
`documento.sensible = False`, que es exactamente lo que resulta cuando la categoría no tiene
mapeo). Esto contradice la regla de negocio ya acordada ("el profesional define qué ve cada
persona; datos sensibles solo para profesionales y la madre si el profesional lo habilita") si un
admin crea una categoría que en la práctica es sensible (p.ej. "antecedentes_judiciales" o
similar) y nadie la mapea a tiempo: queda expuesta por defecto a madre y auditoría de forma
amplia, no restringida, mientras nadie note la falta de mapeo en código.

Además, el diseño de la sección 6 (la asociación sección-categoría permanece fija en código) deja
una contradicción con el objetivo central de este ADR ("el admin administra sin depender de
desarrollo ni de redespliegue"): toda categoría nueva que cree el admin queda **permanentemente**
en básica hasta que un desarrollador edite `SECCION_POR_CATEGORIA` y redespliegue — justo la
dependencia que el módulo busca eliminar, aplicada al único catálogo donde el error es más
costoso.

**Corrección incorporada a la decisión** (no queda como pendiente):

- Los grupos de catálogo que un módulo de negocio asocia a una regla de permisos (hoy
  `categoria_documento_menor`; `categoria_documento_hogar` no lo necesita porque sus dos valores
  actuales son ambos básicos) se marcan en el registro de código `GRUPOS_CATALOGO` con un
  atributo `con_seccion_acceso: true`.
- Para esos grupos, `catalogos_opciones` gana una columna `seccion_acceso` (string, nullable,
  valores permitidos limitados al conjunto cerrado ya definido en código —
  `SECCIONES_VALIDAS = ("familia", "salud", "psicosocial")` más `None`/básica — nunca texto
  libre).
- `POST /configuracion/catalogos/{grupo}` exige el campo `seccion_acceso` (puede ser explícitamente
  básica) cuando el grupo tiene `con_seccion_acceso: true`; la pantalla de "nueva categoría" en el
  frontend obliga a elegirlo en el momento de crear la opción, no después. Rechaza con 400 si el
  valor no está en el conjunto cerrado o si el grupo no existe en `GRUPOS_CATALOGO`.
- `seccion_acceso` es **inmutable tras la creación**: `PUT /configuracion/catalogos/{grupo}/{valor}`
  solo admite `{etiqueta?, orden?, activo?}`, igual que ya decía la sección 3, y explícitamente
  **no** admite cambiar `seccion_acceso`. Razón: `Documento.sensible` se calcula una sola vez al
  crear el documento (`seccion_de_categoria(categoria) is not None`) y no se recalcula
  retroactivamente; permitir reclasificar una categoría cambiaría en silencio la visibilidad de
  documentos históricos ya guardados sin dejar rastro claro de qué cambió. Si una categoría quedó
  mal clasificada, se desactiva (`activo=false`) y se crea una categoría nueva con la sección
  correcta; los documentos existentes conservan su clasificación original.
- `documentos/domain.py` sigue leyendo `SECCION_POR_CATEGORIA` como respaldo estático (compatibilidad
  con las categorías ya fijas: `identidad`, `salud`, `psicosocial`, etc.), pero
  `seccion_de_categoria` se vuelve: primero busca en el diccionario fijo; si no está, consulta
  `configuracion.application.seccion_acceso_de_opcion(session, "categoria_documento_menor", valor)`
  y usa ese valor (validado contra `SECCIONES_VALIDAS`, cualquier valor no reconocido en runtime
  —fila corrupta, migración manual— cae a `None`, nunca a una sección sensible; este es el
  *backstop* defensivo, ya no el mecanismo principal). Así una categoría nueva queda clasificada
  por decisión explícita del admin al crearla, no por omisión de un desarrollador.
- Auditoría: la creación de una opción de catálogo con `con_seccion_acceso: true` registra el
  `seccion_acceso` elegido dentro del mismo evento de creación (`registrar_acceso`, acción
  específica, p.ej. `catalogo_categoria_documental_creada`, con la sección en el detalle) — distinta
  de la acción genérica de creación de opciones en catálogos sin lógica de permisos. Al ser
  inmutable, no existe un evento separado de "cambio de sección" que auditar; si esto cambia en el
  futuro (se permite reclasificar), esa reclasificación debe quedar en una acción de auditoría
  propia y distinta de "se editó una etiqueta" (p.ej. `catalogo_categoria_documental_reclasificada`
  con valor anterior y nuevo), precisamente porque afecta visibilidad retroactiva de documentos ya
  existentes, no solo el nombre mostrado en pantalla.
- `GET /configuracion/catalogos/{grupo}` (lectura pública para cualquier autenticado): confirmado
  que las etiquetas de categorías documentales, por sí solas, no son dato personal de un NNA
  específico ni información sensible — son metadatos de clasificación del sistema que de todas
  formas necesitan ver todos los roles para poblar formularios de carga. Se mantiene abierto a
  cualquier autenticado. Nota para el futuro: si algún módulo llega a registrar un grupo de
  catálogo cuyas etiquetas revelen por sí mismas lógica de control interno no destinada a todos los
  roles (p.ej. un catálogo que listara literalmente los roles destinatarios de una alerta de
  evasión), ese grupo específico no debe exponerse por este endpoint genérico sin evaluación
  puntual; no aplica a los catálogos previstos hoy (categorías documentales, parentescos, tipos de
  inventario, niveles de informe).
- Riesgo adicional fuera del alcance de `seccion_acceso`, dejado como nota y no como bloqueo: el
  valor `telefono_policia_infancia` y otros parámetros de seguridad operativa quedan editables por
  `admin` sin segundo factor (punto abierto 6 de `CLAUDE.md`: "segundo factor para profesionales;
  hoy solo usuario y contraseña"). Un error o una cuenta de `admin` comprometida puede alterar un
  número de emergencia usado en una alerta de evasión. No se resuelve en este ADR, pero debe
  priorizarse MFA para `admin` antes de producción, no solo para roles profesionales.

Con esta corrección, la regla de seguridad de este ADR deja de depender únicamente de que un
desarrollador recuerde actualizar un diccionario en código: el admin no puede crear una categoría
documental sin decidir, en ese mismo momento, su nivel de acceso dentro de un conjunto cerrado ya
validado por `seguridad`.

### 6. Qué NO entra en este mecanismo

Valores con lógica de negocio directamente atada al texto exacto en el código (estados del flujo
documental: `borrador`/`en_revision`/`aprobado`/`devuelto`; tipos de alerta: `evasion`/
`visita_vencida`/`documento_faltante`) se quedan fijos en código. Abrirlos a edición libre
rompería las transiciones de estado y las reglas de alerta que dependen de comparar esos valores
exactos. Si en el futuro se necesita flexibilidad ahí, es un cambio de modelo (una tabla de
estados con metadatos de transición), no una fila de configuración — se trataría en una ADR
aparte si llega a hacer falta.

Zonas, hogares, usuarios y profesionales no son "configuración": ya son entidades con su propio
CRUD (módulos 2-4). No se duplican aquí.

### 7. Migración de lo ya hardcodeado — orden concreto, no solo "incremental"

No se migra todo de una vez. Orden de construcción:

1. **Categorías documentales de menor y de hogar** → catálogos `categoria_documento_menor` y
   `categoria_documento_hogar` (seed con los valores/etiquetas actuales de
   `CATEGORIAS_MENOR`/`CATEGORIAS_HOGAR` y de `categorias.ts`). Primero porque ADR-0008 ya las
   marca como "provisionales, pendientes de validar con el operador": es el caso real que más
   pronto va a necesitar cambiar sin redespliegue. Incluye el campo `seccion_acceso` de la
   sección 5.1 (revisión de `seguridad` ya incorporada) desde la primera migración de este
   catálogo, no como un paso posterior.
2. **`telefono_policia_infancia`** → parámetro en `configuracion_sistema`, migrando el valor que
   hoy esté en `configuracion_alertas` (ADR-0009) y retirando esa tabla. No se deja "para
   después": es el caso que motivó esta ADR, y dejarlo en su tabla propia mientras el resto usa
   el mecanismo nuevo mantendría dos patrones en paralelo desde el primer día del módulo —
   justo lo que ADR-0009 ya anotó como limpieza pendiente. Se hace en la misma migración que crea
   las tablas nuevas.
3. **Datos institucionales** (`nombre_operador`, `contacto_operador`) → parámetros con
   `publico=true`, sin lógica asociada. Segundo ejemplo de parámetro, distinto de un umbral,
   para validar el camino de lectura pública (`GET /configuracion/publica`).
4. El resto de la lista del Contexto (parentescos, tipos de inventario, niveles de informe,
   umbrales de alerta como "días para visita vencida" si Fundación Fundar confirma que hace
   falta) se migra de forma incremental, módulo por módulo, sin bloquear el plan de fases. Cada
   módulo que migre deja su constante actual como `valor_por_defecto` en el registro (no la
   borra), para que si la fila en `configuracion_sistema` está vacía el sistema siga funcionando
   igual que hoy.

## Consecuencias

- Nuevo módulo `app/modules/configuracion/` (16º módulo del backend) y
  `frontend/src/app/modules/configuracion/`; nueva fila T4 en `docs/modulos.md`.
- Nuevas tablas `catalogos_opciones` y `configuracion_sistema` (próxima migración Alembic,
  `0009`), con seed de los dos catálogos de categorías documentales y del parámetro
  `telefono_policia_infancia` (migrado desde `configuracion_alertas`, que esta misma migración
  elimina — `alertas/models.py`, `alertas/repository.py`, `alertas/application.py` y
  `alertas/api.py` pierden el código específico de `ConfiguracionAlertas` y pasan a llamar
  `configuracion.application.obtener_parametro(session, "telefono_policia_infancia")`).
- `documentos/domain.py` conserva `SECCION_POR_CATEGORIA`/`SECCION_POR_TIPO_REPORTE` como
  respaldo fijo en código para las categorías ya existentes (sección 6), pero
  `CATEGORIAS_MENOR`/`CATEGORIAS_HOGAR` dejan de ser la fuente de verdad de qué categorías
  existen: `documentos/application.py` valida la categoría recibida contra
  `configuracion.application.valor_valido_en_catalogo(session,
  "categoria_documento_menor"/"categoria_documento_hogar", valor)` antes de aceptar la carga. Para
  categorías nuevas creadas por `admin`, `seccion_de_categoria` resuelve contra el campo
  `seccion_acceso` del catálogo (sección 5.1), fijado obligatoriamente por el admin al crear la
  opción, con `None`/básica solo como respaldo defensivo ante datos corruptos, nunca como
  mecanismo principal de clasificación.
- El frontend necesita una pantalla nueva de "Configuración" (solo rol `admin`, dos vistas:
  catálogos y parámetros) y que los formularios que hoy usan listas fijas (`categorias.ts`)
  lean sus opciones desde `GET /configuracion/catalogos/{grupo}` en vez de un arreglo en el
  código — cambio progresivo, con el arreglo actual como valor por defecto embebido si la
  llamada falla (mismo criterio de respaldo que el resto del sistema), no se rehace todo de una
  vez.
- Revisión de `seguridad` completada (sección 5.1, 2026-11-14): se incorpora `seccion_acceso`
  como campo obligatorio e inmutable al crear una opción en catálogos con lógica de permisos
  asociada (`categoria_documento_menor`), con conjunto cerrado de valores validados y el fallback
  a básica como respaldo defensivo, no como mecanismo principal. Sin punto pendiente para que
  `backend` construya el punto 1 de la sección 7.
- Mitiga directamente el riesgo que señaló el usuario: con este módulo, el administrador cambia
  catálogos y parámetros desde la aplicación al entregar el sistema, sin depender del equipo de
  desarrollo ni de un redespliegue.
