# ADR-0019: perfil editable con foto para todos los roles; foto también en red de apoyo

Fecha: 2026-11-24
Estado: Aceptada

## Contexto

Pedido del usuario, verbatim:

> "el perfil de la madre tiene que ser editable, y poder poner la foto, haz un perfil con la
> información y que los datos de la madre los puede editar ella, para actualizar la información,
> los datos básicos de la madre y de su hogar como la red de apoyo, la red de apoyo también debe
> tener foto de perfil, todos los roles tienen que tener perfil con foto y en el frontend debe
> aparecer estilo perfil."

Estado actual (verificado en código antes de diseñar esto):
- `GET /madres/yo` ya existe (la madre ve su propio perfil), pero no hay `PUT /madres/yo`: solo
  coordinador/admin pueden editar `direccion`/`telefono`/`estado_certificacion` vía
  `PUT /madres/{id}`. La madre no puede actualizar ni su propia dirección/teléfono ni subir una
  foto.
- `profesionales` (cubre también defensor) no tiene ningún endpoint "yo": solo coordinador/admin
  crean/editan, el profesional/defensor no puede ver ni tocar su propio registro desde la API.
- Coordinador, admin y auditor no tienen ninguna tabla de perfil: `Usuario` solo guarda
  `email`/`rol`/`zona_id`, sin nombre ni foto.
- No existe ningún campo de foto para personas en todo el sistema (solo hay fotos de evidencia de
  ítems de inventario, ADR-0014, que son de cosas, no de personas).
- `HogarRedApoyo` (contactos de red de apoyo del hogar) no tiene foto.

## Decisión

### 1. Foto de perfil: genérica, una por usuario, para los 6 roles

Nueva columna `Usuario.foto_ref: str | None`. Se sube y se lee igual que cualquier otro archivo
del sistema: cifrada con `app/core/almacenamiento.py` (mismo mecanismo que documentos e
inventario), `propietario_id = usuario.id`, siempre versión 1 (se sobrescribe al reemplazar, sin
historial — una foto de perfil no necesita versionado).

Nuevos endpoints en `auth`:
- `PUT /auth/yo/foto` (multipart, cualquier rol autenticado): sube o reemplaza su propia foto.
  Mismas validaciones que ya existen para fotos de inventario (ADR-0014): tipo detectado por los
  bytes (no por el `Content-Type` del cliente) limitado a JPEG/PNG/WEBP, tamaño máximo 5 MB.
- `GET /auth/yo/foto`: la propia.
- `GET /usuarios/{usuario_id}/foto`: la de cualquier otro usuario. Decisión de alcance: **visible
  a cualquier usuario autenticado**, no restringida por rol ni por hogar/zona. Es un directorio de
  identificación de personal (quién es quién), no un dato sensible de un NNA ni de la sección de
  un expediente — no aplica el modelo de permisos de `menores`/`documentos`. 404 si el usuario no
  tiene foto.

### 2. Nombre para los roles sin tabla propia (coordinador, admin, auditor)

Nuevas columnas `Usuario.nombres`, `Usuario.apellidos` (nulas). Nuevo `PUT /auth/yo` (solo
nombres/apellidos) restringido server-side a coordinador/admin/auditor — madre y
profesional/defensor ya tienen su nombre en su propia tabla (`MadreSustituta`/`Profesional`) y no
deben tener una segunda fuente de verdad para lo mismo; si llaman este endpoint, 403.

### 3. Madre edita sus propios datos básicos

Nuevo `PUT /madres/yo`, con un esquema propio `MadreAutoUpdate` (**no** el `MadreUpdate` que ya
usa coordinador/admin): solo `direccion`/`telefono`. Deliberadamente **no** incluye
`estado_certificacion` (sigue siendo una decisión de coordinador/admin, no de la madre sobre sí
misma) ni `nombres`/`apellidos`/`numero_identificacion` (identidad legal, se fija al crear el
registro y solo coordinador/admin la toca hoy — este ADR no cambia eso). `GET /madres/yo` no
cambia.

### 4. Profesional/defensor edita sus propios datos de contacto

Nuevo `GET /profesionales/yo` y `PUT /profesionales/yo`, con un esquema propio
`ProfesionalAutoUpdate`: solo `telefono`/`especialidad`. Igual que con la madre, deliberadamente
**no** incluye `nombres`/`apellidos`/`cargo`/`numero_registro` (identidad y rol profesional,
siguen siendo de coordinador/admin vía `PUT /profesionales/{id}`, sin cambios ahí).

### 5. Red de apoyo con foto de perfil

Nueva columna `HogarRedApoyo.foto_ref: str | None` (una sola foto por contacto, no una galería
como la evidencia de inventario). Nuevos `PUT /inventario/red-apoyo/{id}/foto` (multipart) y
`GET /inventario/red-apoyo/{id}/foto`, con exactamente el mismo permiso que ya tiene el resto de
red de apoyo (`puede_gestionar_hogar` para subir, `puede_ver_hogar` para leer — sin cambios, este
ADR no toca esa división de tareas). Mismas validaciones de tipo/tamaño que la foto de perfil de
usuario. No hace falta la declaración "no muestra NNA" de ADR-0014: un contacto de red de apoyo es
un adulto por definición, no hay riesgo de capturar a un menor por accidente en su propia foto de
perfil.

### 6. Frontend: página de perfil para los 6 roles

Nueva pantalla `/perfil` (enlace en la barra superior, visible a cualquier rol autenticado, junto
a "Cerrar sesión"): avatar circular (foto o ícono genérico si no tiene), nombre completo, rol,
correo, y un formulario con los campos editables según el rol:
- Madre: dirección, teléfono (vía `PUT /madres/yo`).
- Profesional/defensor: teléfono, especialidad (vía `PUT /profesionales/yo`).
- Coordinador/admin/auditor: nombres, apellidos (vía `PUT /auth/yo`).
- Los 6 roles: subir/reemplazar foto (vía `PUT /auth/yo/foto`).

En Inventario del Hogar, la sección de "Red de apoyo" gana una miniatura/figura y un control para
subir foto por contacto, con el mismo patrón ya usado para las fotos de evidencia de ítems
(`<details>`, carga bajo demanda del blob, mismo mensaje de error 403 genérico).

## Consecuencias

- No toca datos de menores directamente (nombres/fotos de adultos del sistema, no de NNA), pero
  sí introduce almacenamiento cifrado de fotos de personas reales del staff — pasa por `seguridad`
  por precaución, igual que se hizo con las fotos de inventario en ADR-0014.
- La decisión de que la foto de perfil sea visible a cualquier usuario autenticado (punto 1) es la
  que más vale que `seguridad` confirme o corrija explícitamente.
- Identidad legal (nombres, apellidos, número de identificación, cargo, número de registro,
  estado de certificación) sigue siendo exclusiva de coordinador/admin en los tres módulos
  (`madres`, `profesionales`, y ahora los nuevos campos de `Usuario`): este ADR solo abre
  autoedición de datos de contacto y la foto, nunca de identidad.
- Migración: nuevas columnas nulas (`Usuario.nombres`, `Usuario.apellidos`, `Usuario.foto_ref`,
  `HogarRedApoyo.foto_ref`), sin dato que migrar.
- Revisión de `seguridad` (2026-11-24): confirma el alcance de `GET /usuarios/{id}/foto` (punto 1)
  como correcto — requiere sesión activa, el `usuario_id` es un UUID no enumerable y no hay
  listado público de usuarios. Añade como punto abierto de cumplimiento (ver `CLAUDE.md`, "Puntos
  abiertos"): la foto de una madre sustituta o profesional es un dato personal de un adulto bajo
  la Ley 1581/2012; falta documentar la base legal/autorización para tratarla (p. ej. cláusula en
  el convenio con la fundación/ICBF o consentimiento informado al crear el usuario). También
  añadió cabeceras `X-Content-Type-Options`/`Content-Disposition` a las respuestas de foto de
  `auth`, igualando el patrón ya usado en `inventario` (ADR-0014).
