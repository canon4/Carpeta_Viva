# ADR-0017 Configuración del proveedor de IA desde el panel de administración

Estado: Aceptada e implementada. Pendiente: revisión de cierre del agente `seguridad`.

## Contexto
ADR-0010 §1.6 fijó el proveedor, el modelo y la clave de API del asistente por variables de entorno (`IA_LLM_PROVEEDOR`, `IA_LLM_MODELO`, `ANTHROPIC_API_KEY`, `GROQ_API_KEY`). Cambiar la clave exigía editar el entorno del servidor y reiniciarlo, algo que el administrador del operador no puede hacer. Al revisar el módulo (20-11-2026) el asistente no respondía: no había clave configurada y los documentos no estaban indexados.

## Decisión
1. **Tabla `ia_configuracion`** (una fila, migración 0012): proveedor, modelo, clave cifrada, últimos 4 caracteres de la clave, quién la cambió y cuándo.
2. **La clave se cifra** con la clave maestra de archivos (`ARCHIVOS_CLAVE_MAESTRA`, Fernet, `app/core/secretos.py`). Quien obtenga una copia de la base sin esa clave no puede leerla.
3. **La clave nunca sale del servidor:** `GET /ia/configuracion` devuelve solo el origen (`panel`, `entorno` o `ninguna`) y los últimos 4 caracteres. `PUT` la recibe una sola vez; enviar `""` la borra y se vuelve a la del entorno.
4. **Prioridad:** panel sobre entorno. Si la clave del panel no se puede descifrar (por ejemplo, porque cambió la clave maestra), se ignora y se usa la del entorno.
5. **Aplicación inmediata:** el proveedor se construye en cada llamada con la configuración vigente, sin reiniciar.
6. **Solo admin.** Cada consulta, cambio, prueba o intento denegado queda en auditoría, sin la clave.
7. **Prueba de conexión:** `POST /ia/configuracion/probar` hace una llamada mínima sin datos de expedientes.
8. **Cambiar de proveedor sin enviar clave descarta la clave anterior**, porque una clave pertenece a un proveedor.
9. **Modelos consultados al proveedor:** `GET /ia/configuracion/modelos` devuelve los modelos que la cuenta de la clave puede usar (sin modelos de voz ni moderación). El panel los ofrece en una lista; no hay nombres de modelo escritos a mano.
10. **Auditoría:** la acción es `ia_configuracion_actualizada` y el detalle (proveedor, modelo, si la clave cambió) va en `recurso`, porque `accion` admite 60 caracteres.

## Consecuencias
- Rotar `ARCHIVOS_CLAVE_MAESTRA` deja ilegible la clave guardada: el admin debe volver a ingresarla (se cae al entorno mientras tanto).
- La clave queda en memoria del proceso durante cada llamada; no se registra en logs ni en auditoría.
- Un admin con acceso al panel puede apuntar el asistente a otro proveedor: la seudonimización de ADR-0002 y ADR-0010 sigue aplicando igual a cualquier proveedor.
- Groq requiere el paquete `groq` (en `requirements.txt`); si falta, la prueba y la lista de modelos lo informan.
