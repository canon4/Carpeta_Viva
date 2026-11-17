# ADR-0016 Correcciones de la revisión de seguridad del 17-11-2026

Estado: Aceptada e implementada (backend y frontend). Pendiente: revisión de cierre del agente `seguridad`.

## Contexto
Al documentar la metodología (`docs/metodologia/`) la revisión de seguridad encontró diferencias entre el código y las ADR 0004, 0007, 0008 y 0010 (`docs/metodologia/04-desarrollo/control-de-acceso.md`, sección 6). Esta ADR corrige las que no requieren una decisión de negocio ni jurídica.

## Decisión
1. **Coordinador acotado a su zona** (ADR-0007 §2.2, RN03).
   - Crear y renombrar zonas pasa a ser solo de `admin`. El coordinador lista y ve únicamente su zona.
   - Hogares: el coordinador crea, lista, ve y edita solo los de su zona; si pide otra zona recibe 403 y queda en auditoría (`*_denegado`).
   - Una madre ya vinculada a un hogar no puede vincularse a otro (422). Evita que un coordinador traiga a su hogar una madre de otra zona.
   - Madres: el coordinador ve y edita las madres de hogares de su zona y las que aún no tienen hogar.
   - Traslados: el coordinador debe administrar la zona de origen y la de destino.
2. **Tipo de archivo por contenido** (`app/core/tipos_archivo.py`). El tipo se detecta por la firma de bytes y se guarda el detectado; el `Content-Type` del cliente se ignora. Se aceptan PDF, JPEG, PNG, GIF, WEBP, HEIC, Office abierto sin macros (docx, xlsx, pptx), Office antiguo (doc, xls) y texto (HTML, Markdown y JSON se guardan como `text/plain`). Se rechazan ejecutables, scripts y ZIP que no sean Office. Fotos de inventario: solo JPEG, PNG o WEBP reales. Sin dependencias nuevas.
3. **Auditor sin resumen de IA de documentos** (ADR-0007 §2.3, ADR-0008 §4): `GET /ia/documentos/{id}/resumen` responde 403 al auditor, igual que el resumen del menor.
4. **Cuentas** (RF0.4, RF0.5):
   - Bloqueo de 15 minutos tras 5 intentos fallidos (`LOGIN_MAX_INTENTOS`, `LOGIN_BLOQUEO_MINUTOS`). Durante el bloqueo, el inicio de sesión responde 429 incluso con la clave correcta. El contador se reinicia al entrar.
   - `PUT /auth/contrasena` cambia la contraseña propia: mínimo 10 caracteres (`PASSWORD_LONGITUD_MINIMA`), distinta de la actual y del correo. Invalida los tokens emitidos antes (`usuarios.credenciales_cambiadas_en`) y devuelve uno nuevo. Una contraseña actual incorrecta da 422, no 401, para que el frontend no cierre la sesión.
5. **Auditoría**:
   - `login_fallido` ya no guarda el texto escrito en el campo de correo (podía ser una contraseña tecleada por error). Si la cuenta existe, se registra su `usuario_id`.
   - En PostgreSQL, triggers impiden UPDATE, DELETE y TRUNCATE sobre `auditoria_accesos`.

Migración `0011_bloqueo_login_y_auditoria_inmutable`.

## Consecuencias
- El bloqueo revela que una cuenta existe después de 5 intentos (429 frente a 401). Se acepta: el volumen de usuarios es bajo y la alternativa (bloqueo por IP) perjudica a hogares que comparten conexión.
- Un token emitido en el mismo segundo del cambio de contraseña sigue valiendo hasta su vencimiento (precisión de `iat` en segundos).
- Los triggers solo existen en PostgreSQL; las pruebas en SQLite no los cubren.
- El frontend aún no tiene pantalla para cambiar la contraseña ni mensaje propio para el 429.

## Quedan abiertas (requieren decisión, no se tocaron)
- Profesionales sin zona: `/profesionales` no se puede acotar sin decidir si un profesional pertenece a una zona.
- Cifrado en la base de `reportes.contenido`, `fragmentos_documento.texto`, `ia_consultas.respuesta`, familiares y firma: requiere diseño de claves y búsqueda (pgvector necesita el texto).
- Admin lee preguntas y respuestas de IA de otros usuarios (lo permite ADR-0010 §1.4).
- Paquete de archivo con secciones sensibles para coordinador y admin (ADR-0010 §3, en tensión con ADR-0007 §2.2).
- Escritura de profesionales en inventario (ADR-0015 no lo cubrió).
- Segundo factor (punto abierto 6), NER antes de datos reales, citas legales de `CLAUDE.md` (Res. 1619/2017, Res. 2634/2019, artículo del Decreto 1074/2015) a validar con abogado.
