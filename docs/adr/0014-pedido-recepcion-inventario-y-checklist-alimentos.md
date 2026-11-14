# ADR-0014 Separa pedido y recepción en Inventario; checklist reutilizable en Alimentos

Estado: Propuesta.

## Contexto

El usuario señaló que el diseño actual de Inventario del Hogar (ADR-0009, sección 3) trata a la
madre y al coordinador igual: cualquiera de los dos (más admin) puede crear y editar un
`InventarioItem` por igual (`puede_gestionar_hogar`, sin distinción de rol). Eso no refleja el
flujo real:

> El que gestiona el **estado** del inventario es la madre. El coordinador ve el hogar — por
> ejemplo, tiene 5 niños pero solo 4 camas y 3 cajones — y decide reponer lo necesario (5 camas,
> 5 cajones). La madre recibe esos elementos, marca en qué estado llegaron y puede adjuntar fotos.

Es decir: **pedir** (decidir qué hace falta) es del coordinador; **confirmar la llegada y su
estado físico** es de la madre. Hoy no existe esa distinción: un solo `estado` sirve para todo y
no hay forma de adjuntar fotos.

El mismo comentario incluyó una segunda idea, para Control de Alimentos (ADR-0009, sección 4):

> Para los alimentos se registra el alimento que compraron, la fecha de compra y la caducidad, y
> se guarda con checklist; si se vuelve a comprar el producto solo habría que cambiar las fechas.

Hoy cada compra es un `AlimentoItem` independiente: comprar de nuevo el mismo producto obliga a
volver a escribir descripción, si es perecedero, unidad, etc. No hay un "producto reutilizable"
del que solo cambien fecha de ingreso/vencimiento y cantidad al volver a comprarlo.

## Decisión

### 1. Inventario: `InventarioItem` gana una fase de pedido/recepción

Nueva columna `recibido: bool` (default según quién lo crea, ver abajo). No se separa en dos
tablas: es el mismo ítem, que pasa de "pedido, no ha llegado" a "recibido, con su estado físico
y evidencia fotográfica" — igual criterio que ya usa el resto del sistema (un documento pasa de
borrador a aprobado sin volverse una entidad distinta).

- `POST /inventario/items` (crear): el `recibido` resultante depende de quién crea el ítem, no
  de un campo que el cliente pueda mandar (para que no se pueda crear ya "recibido" fingiendo
  una entrega que no pasó por la madre):
  - Coordinador: `recibido=false` — es un pedido, no ha llegado nada todavía. El campo `estado`
    (condición física) se ignora en la creación: no tiene sentido antes de que exista el objeto.
  - Madre: `recibido=true` directo — cubre registrar algo que ya está físicamente en el hogar
    (inventario inicial, algo que llegó por fuera de un pedido formal). Puede fijar `estado` de
    una vez.
  - Admin: igual que madre (`recibido=true`), por ser el caso de uso típico de admin aquí
    (corrección/carga manual), no porque sea "como la madre" en general.
  - Esto solo aplica a la **creación**; no cambia nada de `puede_gestionar_hogar` para lectura.
- `PUT /inventario/items/{id}` (editar tipo/descripción/cantidad del pedido): solo coordinador o
  admin, y solo mientras `recibido=false`. Una vez recibido, el pedido ya se cumplió: cambiar
  tipo/cantidad después no tiene sentido (si sobró o faltó, se registra como un ítem nuevo o se
  retira, no se reescribe el pedido original).
- `PUT /inventario/items/{id}/recepcion` (**nuevo**): solo madre (del hogar) o admin. Body:
  `{estado: "bueno"|"regular"|"malo"}`. Pone `recibido=true` y fija el estado físico. Rechaza con
  422 si el ítem ya estaba `recibido=true` (confirmar recepción es un evento que pasa una sola
  vez; un cambio de estado posterior —p. ej. se dañó con el uso— sigue el `PUT` general de
  cambiar `estado`, que no toca `recibido`).
- El estado físico (`bueno`/`regular`/`malo`/`retirado`) se sigue pudiendo cambiar después por
  quien gestiona el hogar (madre/coordinador/admin), como hoy: esta ADR no restringe eso, solo
  separa la creación del pedido de su confirmación inicial de llegada.

### 2. Fotos de recepción

Tabla nueva `inventario_item_fotos`: `id`, `item_id` (FK), `referencia_archivo` (cifrado con
Fernet, reutilizando `app/core/almacenamiento.py`, mismo mecanismo que `documentos` — ADR-0008),
`mime_type`, `tamanio_bytes`, `subido_por`, `creado_en`. Sin versionado: una foto no se
reemplaza, se sube otra si hace falta (son evidencia de un hecho puntual, no un documento que se
corrige). Solo `image/jpeg`, `image/png`, `image/webp`; tamaño máximo 5 MB por foto, máximo 6
fotos por ítem (suficiente para dejar constancia sin convertir esto en otro módulo documental).

- `POST /inventario/items/{id}/fotos` (multipart, una foto por llamada): madre (del hogar) o
  admin. Solo tiene sentido junto con o después de confirmar la recepción — se permite subir
  fotos aunque el ítem ya esté `recibido=true` (puede que la madre suba la foto un rato después
  de marcar el estado).
- `GET /inventario/items/{id}/fotos` (lista de metadatos) y
  `GET /inventario/items/{id}/fotos/{foto_id}` (`Content-Disposition: inline`, igual patrón que
  el visor de documentos, ADR-0011): cualquiera que pueda ver el hogar (`puede_ver_hogar`).
- Sin `DELETE`: una foto subida por error se queda (es evidencia), igual criterio de "nunca se
  borra" del resto del sistema.

### 3. Migración de ítems existentes

Los `InventarioItem` ya creados antes de esta ADR se migran con `recibido=true` (se asume que lo
que ya está registrado ya está físicamente en el hogar); no se les exige retroactivamente una
confirmación de recepción ni fotos.

### 4. Alimentos: checklist reutilizable

Tabla nueva `alimentos_checklist_items` (el "producto del mercado", reutilizable):
`id`, `hogar_id` (FK), `descripcion`, `perecedero` (bool, default true), `unidad_por_defecto`
(nullable), `activo` (bool, default true, se desactiva, nunca se borra), `creado_por`,
`creado_en`.

`AlimentoItem` (ya existente; sigue representando cada compra/lote individual, con su propia
`fecha_ingreso`/`fecha_vencimiento`/`cantidad`/`consumido`) gana columna nullable
`checklist_item_id` (FK a `alimentos_checklist_items`). Un `AlimentoItem` puede o no venir de un
producto del checklist; comprar algo puntual sin plantilla sigue siendo posible
(`POST /alimentos/items` sin cambios).

Endpoints nuevos bajo `/alimentos/checklist`, mismos permisos que ya tiene el módulo
(`puede_gestionar_hogar`/`puede_ver_hogar` — quien hoy puede registrar alimentos, principalmente
la madre, y admin/coordinador):

- `POST /alimentos/checklist` — crea un producto reutilizable (`descripcion`, `perecedero`,
  `unidad_por_defecto`).
- `GET /alimentos/checklist?hogar_id=` — lista los productos activos del hogar.
- `PUT /alimentos/checklist/{id}` — editar descripción/unidad o desactivar.
- `POST /alimentos/checklist/{id}/comprar` (**el atajo que pidió el usuario**) — body
  `{fecha_ingreso, fecha_vencimiento?, cantidad, unidad?}`. Crea un `AlimentoItem` nuevo con
  `descripcion`/`perecedero` tomados del checklist y `checklist_item_id` apuntando a él: la madre
  solo escribe fecha de compra, vencimiento y cantidad, no tiene que repetir el resto. Sigue
  creando un `AlimentoItem` nuevo por cada compra (no sobrescribe el anterior): el historial de
  compras de ese producto queda completo, coherente con que en todo el sistema "no se sobrescribe,
  se guarda historial" — lo que el usuario describió como "cambiar las fechas" se resuelve en la
  experiencia de uso (un formulario corto que reutiliza el resto de los datos), no borrando o
  reescribiendo la compra anterior.
- `validar_perecedero` (ya existe en `domain.py`) se reutiliza igual para la compra creada desde
  el checklist.

### 5. Qué no cambia

- Ningún dato de menores: esta ADR es sobre inventario físico y alimentos del hogar, no sobre el
  expediente del NNA. No se considera necesaria una revisión obligatoria de `seguridad` bajo la
  regla de CLAUDE.md ("todo cambio que toque datos de menores pasa por seguridad"), aunque las
  fotos de inventario sí son contenido sensible operativo del hogar y usan el mismo cifrado que
  documentos por eso.
- Autorización por hogar: se sigue usando `puede_ver_hogar`/`puede_gestionar_hogar` de
  `zonas_hogares.application` para lectura y gestión general; esta ADR solo añade chequeos de
  **rol** encima de esa base para las dos acciones nuevas (crear pedido vs. confirmar recepción).
- Reportes e inventario por zona/hogar (módulo 12) no cambian de alcance; el nuevo campo
  `recibido` queda disponible para un reporte futuro de "pedidos pendientes" si se necesita, pero
  no se construye ese reporte en esta ADR.

## Consecuencias

- Nueva migración Alembic: `InventarioItem.recibido`, tabla `inventario_item_fotos`, tabla
  `alimentos_checklist_items`, `AlimentoItem.checklist_item_id` (nullable). Ítems de inventario
  existentes se migran con `recibido=true`.
- `inventario/application.py` y `api.py`: `crear_item` deja de usar solo
  `puede_gestionar_hogar` para decidir el `recibido` resultante (aunque la autorización de fondo
  sigue siendo la misma); nuevo caso de uso `confirmar_recepcion_item` con chequeo de rol
  (madre/admin) además de `puede_gestionar_hogar`; nuevo módulo de fotos reutilizando
  `app/core/almacenamiento.py`.
- `alimentos/application.py` y `api.py`: nuevo conjunto de endpoints `checklist`, sin tocar los
  existentes.
- Frontend: `inventario.ts` separa visualmente "Pedido, aún no llega" de "Recibido", con un
  formulario de confirmación (estado + subir fotos) que solo aparece para madre/admin en los
  ítems pendientes; `alimentos.ts` (no revisado en detalle en esta ADR, pendiente al implementar)
  gana una sección de checklist con el atajo "Comprar de nuevo".
- Mitiga directamente lo que señaló el usuario: el coordinador deja de poder "hacerse pasar por
  madre" confirmando que algo llegó bien sin que ella lo haya visto, y comprar de nuevo un
  producto del mercado deja de exigir reescribir todo.
