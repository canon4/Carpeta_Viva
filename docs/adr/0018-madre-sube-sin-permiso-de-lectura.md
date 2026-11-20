# ADR-0018 La madre sube documentos a secciones sensibles sin poder leerlas

Estado: Aceptada e implementada (20-11-2026). Pendiente: revisión de cierre del agente `seguridad`. Modifica ADR-0008, sección 4.

## Contexto
ADR-0008 exigía que la madre tuviera permiso de lectura de la sección (concedido por el profesional) para crear un documento en una categoría sensible (salud, psicosocial, etc.). En el servidor, una madre sin ese permiso recibía 403 al subir, lo que contradice la regla de negocio "la madre crea los documentos; los profesionales revisan y aprueban". Ella es quien recibe en el hogar las órdenes médicas, los resultados y los soportes.

## Decisión
1. **Escribir no implica leer.** La madre puede subir documentos de cualquier categoría para un menor asignado a su hogar vigente. Si el menor no está en su hogar o el expediente está archivado, sigue recibiendo 403.
2. **Con permiso de lectura de la sección**, el documento nace en `borrador`, como antes.
3. **Sin permiso de lectura**, el documento nace directamente `en_revision`. Ella no puede abrirlo, así que no tendría cómo enviarlo a revisión. En su lista aparece con `reservado: true`: solo ve título, categoría, estado y fecha, que son datos que ella misma escribió. No tiene enlace y no puede ver ni descargar el contenido. Si el menor sale de su hogar, también se le oculta (RF7).
4. **No hay acceso a documentos ajenos.** Sin permiso de lectura, la madre no puede versionar ni enviar documentos de esa sección creados por otra persona (por ejemplo, el borrador de una madre anterior del mismo hogar).
5. Si el profesional lo devuelve, la corrección la gestiona el profesional. La madre solo puede corregir lo que puede leer.

## Consecuencias
- La respuesta de `POST /documentos` devuelve a la madre los metadatos del documento que acaba de subir (título, categoría, estado), pero nunca el contenido.
- El profesional asignado recibe en revisión documentos que la madre no puede ver; la aprobación no cambia.
- Pruebas: `tests/test_documentos.py` (sube sin leer, no sube de menores ajenos, no versiona documentos sensibles ajenos).
