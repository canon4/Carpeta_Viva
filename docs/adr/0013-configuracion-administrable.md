# ADR-0013 Módulo transversal de configuración administrable

Estado: Propuesta.

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

### 1. Dos mecanismos, no uno solo

No todo lo de la lista anterior es del mismo tipo de riesgo. Se separan en dos grupos:

**(a) Catálogo genérico de valores** — para listas de opciones que no tienen lógica de negocio
atada al valor exacto en código (categorías documentales, parentescos, tipos de inventario,
niveles de informe). Se implementan con una sola tabla nueva en vez de una tabla por lista:

```
tabla catalogos_opciones
  id            uuid
  grupo         string   -- p.ej. "categoria_documento_menor", "parentesco"
  valor         string   -- clave estable usada en el resto del sistema
  etiqueta      string   -- texto mostrado en pantalla
  orden         int
  activo        bool     -- se desactiva, nunca se borra (por integridad referencial e historial)
  creado_en, actualizado_en, actualizado_por
  unique(grupo, valor)
```

El admin agrega, renombra la etiqueta, reordena o desactiva opciones de un `grupo` desde una
pantalla de "Configuración" en el frontend. Desactivar una opción no borra los documentos que ya
la usan (el valor histórico se sigue mostrando por su `etiqueta` aunque ya no esté disponible
para elegir en formularios nuevos); eliminar valores que ya están en uso no se permite.

**(b) Configuración de parámetros con fila única** — para valores sueltos sin estructura de
lista (umbrales, textos, datos institucionales, parámetros técnicos). Se generaliza el patrón de
`configuracion_alertas` a una sola tabla de configuración general en vez de una tabla por grupo
de parámetros:

```
tabla configuracion_sistema
  clave          string PK   -- p.ej. "umbral_dias_visita_vencida", "nombre_operador"
  valor          string      -- se guarda como texto; cada lector interpreta su tipo
  actualizado_en, actualizado_por
```

Un único endpoint `GET/PUT /configuracion/{clave}` (y `GET /configuracion` para listar todo lo
editable) sirve a todos los parámetros de este grupo, en vez de un endpoint por parámetro como
hizo ADR-0009. Cada módulo que necesite un valor configurable lee su `clave` con una función de
ayuda que cae a un valor por defecto (variable de entorno o constante) si la fila no existe o
está vacía — mismo mecanismo de respaldo que ya probó ADR-0009.

### 2. Qué NO entra en este mecanismo

Valores con lógica de negocio directamente atada al texto exacto en el código (estados del flujo
documental: `borrador`/`en_revision`/`aprobado`/`devuelto`; tipos de alerta: `evasion`/
`visita_vencida`/`documento_faltante`) se quedan fijos en código. Abrirlos a edición libre
rompería las transiciones de estado y las reglas de alerta que dependen de comparar esos valores
exactos. Si en el futuro se necesita flexibilidad ahí, es un cambio de modelo (una tabla de
estados con metadatos de transición), no una fila de configuración — se trataría en una ADR
aparte si llega a hacer falta.

Zonas, hogares, usuarios y profesionales no son "configuración": ya son entidades con su propio
CRUD (módulos 2-4). No se duplican aquí.

### 3. Permisos

Solo el rol `admin` puede ver y editar `/configuracion/*` (reutiliza el control de acceso por rol
ya existente, como el resto del sistema). Cambios quedan en auditoría (`registrar_acceso`), igual
que cualquier otra escritura sensible.

### 4. Migración de lo ya hardcodeado

No se migra todo de una vez. Primero se construye el módulo con los dos mecanismos y un grupo de
ejemplo de cada tipo (categorías documentales como catálogo, y 1-2 umbrales de alerta como
parámetro), y se valida con el usuario. Los demás catálogos/parámetros de la lista del contexto
se migran de forma incremental, módulo por módulo, sin bloquear el resto del plan de fases.

## Consecuencias

- Nueva tabla `catalogos_opciones` y nueva tabla `configuracion_sistema` (migraciones Alembic).
- `configuracion_alertas` (ADR-0009) puede migrarse más adelante a `configuracion_sistema` para
  no mantener dos patrones distintos, pero no es urgente — queda como limpieza futura, no bloquea
  esta ADR.
- El frontend necesita una pantalla nueva de "Configuración" (solo rol `admin`) y que los
  formularios que hoy usan listas fijas (`categorias.ts`, etc.) pasen a leer sus opciones desde
  `GET /configuracion/catalogos/{grupo}` en vez de un arreglo en el código — cambio progresivo,
  no requiere rehacer esos formularios de una vez.
- Mitiga directamente el riesgo que señaló el usuario: con este módulo, el administrador cambia
  catálogos y parámetros desde la aplicación al entregar el sistema, sin depender del equipo de
  desarrollo ni de un redespliegue.
