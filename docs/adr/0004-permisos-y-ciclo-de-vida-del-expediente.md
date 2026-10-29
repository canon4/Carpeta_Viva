# ADR-0004 Permisos y ciclo de vida del expediente

Estado: Propuesta (requiere revisión del agente de seguridad)

## Contexto
E4: el profesional encargado del NNA define qué información ve cada persona. B6: no se elimina; si el NNA ya no está en el hogar, se oculta a la madre. A5: al cierre el expediente se archiva y se envía a un destino aún no definido. E5: se audita todo acceso.

## Decisión
- Control de acceso por rol más lista de acceso por expediente (ACL), administrada por el profesional encargado. Denegar por defecto.
- Los datos sensibles (salud, psicología) tienen una etiqueta propia; solo los ven profesionales y la madre asignada si el profesional lo habilita.
- Estados del expediente: activo, cerrado, archivado. La madre solo ve expedientes con Asignación vigente; al registrar `fecha_fin` pierde acceso automáticamente.
- Sin borrado físico. Los cambios generan filas en las tablas `*_History`; los documentos se versionan y no se sobrescriben.
- Auditoría de lectura y escritura en tabla de solo inserción (usuario, expediente, acción, fecha, IP).
- Flujo de documento: borrador, enviado, en revisión, aprobado o devuelto. Cada aprobación guarda usuario, fecha y huella (hash) del archivo.
- Firma: imagen de firma cargada una vez por usuario, aplicada con registro de quién y cuándo; el valor legal se valida en seguridad.
- Archivo al cierre: módulo de exportación con paquete verificable (documentos, metadatos e historial). El destino se define con el operador.

## Consecuencias
- Cada consulta de IA y de búsqueda debe aplicar la ACL; se prueba con casos de acceso denegado.
- El volumen de la tabla de auditoría crece rápido; se particiona por fecha.
- Respaldos diarios deben cubrir base relacional, triple store y archivos, con prueba de restauración.
