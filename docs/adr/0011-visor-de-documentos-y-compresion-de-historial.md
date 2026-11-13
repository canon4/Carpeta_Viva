# ADR-0011 Visor de documentos en pantalla y compresión de versiones reemplazadas

Estado: Aceptada e implementada.

## Contexto

ADR-0008 ya implementó carga, cifrado, versionado y flujo de aprobación de documentos, pero no
había forma de ver el contenido dentro de la aplicación: `GET /documentos/{id}/contenido` siempre
fuerza la descarga (`Content-Disposition: attachment`). El usuario pidió un visor en pantalla,
dejando explícito que **no es un editor**: para corregir un documento, el flujo sigue siendo
descargarlo, editarlo fuera del sistema y subir una nueva versión (ya existía vía
`POST /documentos/{id}/version`, sin cambios). También pidió que, al reemplazarse una versión,
quede un registro en el historial con una copia de baja compresión, para no acumular espacio en
disco con versiones viejas que nadie vuelve a necesitar en calidad completa.

## Decisión

### 1. Visor: solo PDF e imágenes

El navegador puede mostrar PDF e imágenes de forma nativa (`<iframe>`/`<img>`), sin instalar nada
en el backend. Mostrar Word/Excel exigiría convertirlos a PDF en el servidor (LibreOffice headless
u otra herramienta de sistema) — infraestructura adicional que se descarta por ahora (decisión
confirmada con el usuario). Para esos formatos, y cualquier otro no listado, el visor no está
disponible y el usuario sigue usando "Descargar archivo" para verlos fuera del sistema.

`MIME_VISUALIZABLES` en `app/modules/documentos/domain.py`: `application/pdf`, `image/jpeg`,
`image/png`, `image/gif`, `image/webp`.

### 2. Nuevo endpoint `GET /documentos/{id}/vista`

Misma autorización que `GET /documentos/{id}/contenido` (`_puede_descargar_contenido`: nunca el
rol auditor, igual que ADR-0008 sección 4/6), pero:
- Si el `mime_type` no está en `MIME_VISUALIZABLES`, devuelve 422 (el frontend ni siquiera ofrece
  el botón para esos casos; el backend lo rechaza igual por defensa en profundidad).
- `Content-Disposition: inline` en vez de `attachment`, para que el navegador lo muestre en vez de
  descargarlo. Mismas cabeceras de protección que la descarga (`nosniff`, `no-store`: nunca
  cachear contenido de expedientes de NNA).
- Registra `documento_visualizado` / `documento_visualizacion_denegada` en auditoría, igual patrón
  que el resto de accesos a contenido.

No hay endpoint de visor para versiones anteriores: verlas en pantalla no es un caso de uso real
(son historial, no el documento vigente); seguir ofreciendo solo su descarga ya cubre la
necesidad de auditoría/consulta puntual.

### 3. Editar = descargar + subir nueva versión (sin cambios de flujo)

No se construye ningún editor en pantalla. El botón "Descargar archivo" y el formulario "Subir
nueva versión" que ya existían en `documento-detalle.ts` son todo el flujo de edición: se aclara
en la interfaz que así es como se corrige un documento.

### 4. Compresión de la versión reemplazada (historial liviano)

Cuando se sube una nueva versión (`crear_version`), la versión que queda reemplazada ya no vuelve
a ser el archivo vigente — solo sirve como registro histórico de qué se subió y cuándo. Si esa
versión es una imagen, se recomprime antes de guardarla como historial:

- `app/core/compresion.py::comprimir_si_es_imagen`: si `mime_type` empieza con `image/`, reescala
  a un máximo de 1280px por lado y reencoda como JPEG calidad 60 (Pillow, ya era dependencia del
  proyecto para OCR). Si no es imagen, o la recompresión por alguna razón no reduce el tamaño, se
  conserva el contenido original sin cambios — nunca se arriesga a perder o corromper un
  documento del expediente por ahorrar espacio.
- `app/core/almacenamiento.py::sobrescribir`: cifra la copia comprimida y la escribe en la misma
  ruta donde ya estaba el archivo de esa versión (no se crea un archivo nuevo ni se duplica
  espacio), y devuelve el nuevo hash para que el snapshot quede consistente con el contenido real
  en disco.
- `DocumentoVersion` (tabla `documentos_versiones`) gana la columna `comprimida: bool` (migración
  `0007`), para que el historial muestre con transparencia si esa copia es la original o una
  recompresión. El documento vigente (fila `Documento`) nunca se comprime — solo las versiones ya
  reemplazadas.
- PDF y otros formatos no listados se conservan tal cual en el historial: no hay una forma simple
  y confiable de recomprimirlos sin librerías de sistema adicionales (mismo motivo que la decisión
  de la sección 1). Queda como mejora futura si el volumen de PDFs grandes lo justifica.

### 5. Reutilizable por rol

El visor es un componente de Angular aparte (`frontend/src/app/shared/visor-documento/`), usado
desde `documento-detalle.ts` — la misma pantalla de detalle que ya usan madre, profesional,
defensor, coordinador y admin (el auditor no ve el botón de descarga ni el visor, igual que hoy).
No se duplica lógica por rol: el componente solo decide qué mostrar según el `mime_type`; la
autorización de quién puede ver el contenido la sigue resolviendo el backend, como siempre.

## Consecuencias

- Nueva dependencia de hecho (ya estaba en `requirements.txt` por OCR): `Pillow`. No se agrega
  ninguna dependencia de sistema nueva (nada de LibreOffice/Ghostscript).
- Migración `0007`: agrega `documentos_versiones.comprimida` (`boolean`, default `false`).
- El ahorro de espacio aplica solo a versiones reemplazadas que sean imágenes; PDFs y Word/Excel
  en el historial siguen ocupando su tamaño original. Si eso resulta ser el grueso del volumen
  real, se puede revisar en una ADR futura (p. ej. recompresión de PDF con una librería adicional).
- No cambia ninguna regla de autorización de ADR-0007/ADR-0008: el visor reutiliza exactamente la
  misma función (`_puede_descargar_contenido`) que ya gobierna la descarga, así que no abre ningún
  acceso nuevo a contenido sensible de NNA — es la misma superficie de acceso, solo que servida
  `inline` en vez de forzar la descarga.
