# Requisitos no funcionales

Fase 1, paso 3. Fuentes: `CLAUDE.md` (requisitos no funcionales), `CUESTIONARIO.md` (C2, E, F, G, H) y ADR.
Cada requisito tiene una métrica verificable. Donde faltaba información se completa con un supuesto de [supuestos.md](supuestos.md) (código S). La columna Estado indica si ya está implementado o verificado.

| ID | Categoría | Requisito | Métrica o verificación | Fuente | Estado |
|---|---|---|---|---|---|
| RNF01 | Rendimiento | Soportar 1000 usuarios simultáneos | Prueba de carga con k6: 1000 usuarios virtuales durante 10 minutos, 80 % lecturas y 20 % escrituras; p95 menor a 2 s en lectura y menor a 4 s en carga de documentos; 0 % de errores 5xx | `CLAUDE.md`, C2, S25 | Pendiente (Fase 5) |
| RNF02 | Rendimiento | Búsqueda de un documento más rápida que en papel | Tiempo medio de búsqueda menor a 1 minuto frente a 15 minutos en papel; revisión de un documento en 2 días hábiles o menos frente a 5; 70 % menos papel a los 3 meses | H4, S02, S03 | Pendiente de medir |
| RNF03 | Capacidad | 35 000 a 42 000 documentos por año, unos 100 por NNA | Almacenamiento dimensionado; versiones viejas comprimidas | `CLAUDE.md`, ADR-0011 | Diseñado |
| RNF04 | Disponibilidad | Caídas tolerables; sin requisito de alta disponibilidad | Reinicio automático de contenedores (`restart: unless-stopped`) | H2, ADR-0012 | Implementado |
| RNF05 | Integridad | Pérdida de datos no tolerable | Respaldo diario de PostgreSQL, archivos y Fuseki, cifrado, con prueba de restauración mensual; la clave `ARCHIVOS_CLAVE_MAESTRA` se respalda por un canal distinto; sin borrado físico | H1, H2, ADR-0004, ADR-0008 §1 | Parcial (sin borrado físico implementado; respaldos pendientes) |
| RNF06 | Integridad | Detectar alteración de archivos | Hash SHA-256 verificado al leer documentos y versiones. Las fotos de inventario y los informes exportados se leen sin verificar hash (ADR-0014 lo acepta) | ADR-0008 §1 | Implementado para documentos |
| RNF07 | Seguridad | Autenticación con usuario y contraseña y JWT con expiración | Token de 60 minutos; contraseña con hash Argon2; el rol se lee de la base en cada petición; bloqueo por intentos y revocación al cambiar la contraseña (ADR-0016); segundo factor en RNF25 | E3, `core/security.py` | Implementado |
| RNF08 | Seguridad | Secretos fuera del repositorio; el sistema no arranca en producción con claves por defecto | `create_app` falla si `JWT_SECRET` o `ARCHIVOS_CLAVE_MAESTRA` son las de desarrollo | ADR-0008 §1 | Implementado |
| RNF09 | Seguridad | Cifrado de archivos en reposo y HTTPS en tránsito | Fernet (AES-128-CBC con HMAC-SHA256) en archivos; TLS lo da Traefik de Dokploy con certificado Let's Encrypt, por confirmar en el panel antes de anunciar la URL. Las columnas de texto de la base no se cifran (ver RNF26) | ADR-0008, ADR-0012 | Parcial |
| RNF10 | Seguridad | Mínimo privilegio y denegar por defecto | Pruebas de permisos por rol pasan. ADR-0016 corrigió la zona del coordinador en zonas, hogares, madres y traslados, y el resumen de IA del auditor. Quedan: profesionales por zona (S07), escritura de profesionales en inventario (S14), historial de IA para admin (S16) y datos del NNA para el auditor (S17) | ADR-0004, ADR-0007, ADR-0016 | Parcial |
| RNF11 | Trazabilidad | Auditoría de todo acceso, incluidos los denegados | Lecturas y escrituras de expediente, documentos, alertas, citas, inventario y alimentos generan fila, también las denegadas. Faltan: listado de menores, lecturas de zonas, hogares, madres y profesionales, la IP fuera del login y una prueba de las lecturas. La tabla es de solo inserción por convención (ver RNF27) | E5, RF11 | Parcial |
| RNF12 | Privacidad y legal | Cumplir Ley 1581/2012, Decreto 1377/2013 (compilado en el Decreto 1074/2015), Ley 1098/2006 y Ley 594/2000. Las Res. 1619/2017 y 2634/2019 que cita `CLAUDE.md` no se pudieron verificar (ver notas legales) | Revisión de seguridad al cierre de cada fase; base legal adoptada como supuesto S11 y normas según S26, ambas a validar por un abogado | `CLAUDE.md`, S11, S26 | Parcial (validación jurídica pendiente) |
| RNF13 | Privacidad | Solo datos sintéticos en desarrollo y pruebas | Ningún dato real en repositorios; la regla se cumple por práctica, sin escaneo automático | `CLAUDE.md` | Parcial |
| RNF14 | Privacidad | La IA externa recibe datos seudonimizados por defecto y solo lo que el usuario puede ver | Antes de cada llamada se seudonimizan los nombres conocidos (menores, familiares, madres, profesionales) y los patrones de correo, teléfono, fecha y documento; los fragmentos se filtran por permiso fila por fila; OCR y embeddings corren en local. Faltan: NER de personas (un tercero sin ficha en el sistema pasa en texto claro), contrato con el proveedor, prueba de inyección de prompts (solo hay instrucción de sistema). `anonimizado` solo se registra; ningún camino envía datos reales | ADR-0002, ADR-0010 | Parcial |
| RNF15 | Usabilidad | Usable por personas con alfabetización digital baja a media | Tareas de la madre en 3 pasos o menos; textos sencillos; prueba con 5 madres y 5 tareas: 80 % completadas sin ayuda y puntaje SUS de 68 o más | G2, S24 | Parcial (falta ejecutar la prueba) |
| RNF16 | Accesibilidad | Apta para baja visión | WCAG 2.1 AA: contraste 4.5:1, texto ampliable a 200 %, objetivos táctiles de 44 px | G4 | Parcial |
| RNF17 | Accesibilidad | Lectura asistida opcional | Compatible con lector de pantalla (etiquetas ARIA) | G4 | Opcional |
| RNF18 | Portabilidad | Android y computador | Diseño adaptable desde 360 px de ancho | G1 | Implementado |
| RNF19 | Conectividad | Se asume conectividad buena; sin modo fuera de línea | N/A | F3 | Aceptado |
| RNF20 | Mantenibilidad | Monolito modular; módulos se comunican solo por la capa de aplicación | Revisión de imports entre módulos | ADR-0001 | Implementado |
| RNF21 | Mantenibilidad | Contrato OpenAPI versionado; el frontend genera sus tipos | Prueba que falla si `openapi.json` está desactualizado | ADR-0005 | Implementado |
| RNF22 | Despliegue | Frontend se despliega sin detener el backend | Apps separadas en Dokploy | ADR-0005, ADR-0012 | Implementado |
| RNF23 | Configurabilidad | Catálogos y parámetros editables sin redesplegar | Módulo de configuración | ADR-0013 | Implementado |
| RNF24 | Calidad | Pruebas automatizadas por módulo y revisión cruzada | Suite del backend y frontend en verde antes de integrar | Metodología fase 5 | Implementado |
| RNF25 | Seguridad | Protección de la cuenta: bloqueo por intentos fallidos, cambio de contraseña, revocación de sesión y segundo factor para roles con acceso amplio (coordinador, admin, auditor, profesionales) | Pruebas de bloqueo y de caducidad de token | `CLAUDE.md` punto abierto 6, HU03, HU04, ADR-0016 | Parcial (bloqueo, cambio de contraseña y revocación hechos; falta segundo factor) |
| RNF26 | Seguridad | Cifrado en reposo de datos sensibles en la base (texto de fragmentos, informes, historial de IA, familiares, firma) y respaldos cifrados | Cifrado por columna de contacto de familiares, firma, contenido de informes y pregunta y respuesta de IA; fragmentos de búsqueda seudonimizados; revisión de esquema y prueba de lectura | ADR-0008 §1, S23 | Pendiente (hoy solo cifrado de archivos) |
| RNF27 | Trazabilidad | Auditoría inmutable, con IP en todas las filas | Trigger o permisos de base que impidan `UPDATE` y `DELETE`; prueba | ADR-0004, ADR-0016 | Parcial (triggers en migración 0011, sin probar en PostgreSQL; falta IP en todas las filas) |
| RNF28 | Seguridad | Validación del archivo cargado por su firma (bytes) y lista de tipos permitidos | Pruebas con ejecutable declarado como imagen (plan de pruebas, SEG-01) | RF2, H3, ADR-0016 | Parcial (documentos, versiones y fotos; falta `/ia/documentos/clasificar`) |
| RNF29 | Privacidad y legal | Retención y eliminación documentadas: tabla de retención y base legal para datos de menores | Conservación de 10 años desde el cierre, sin borrado automático; eliminación o anonimización con aprobación de admin y auditor (S10); base legal S11. A validar por abogado y operador | Ley 594/2000, S10, S11 | Especificado como supuesto; validación pendiente |


## Notas legales y de privacidad (requieren validación jurídica)
Seguridad no es asesoría legal. Lo siguiente se verificó en fuentes públicas el 17-11-2026 y debe confirmarlo un abogado o el lineamiento del ICBF antes de citarlo como definitivo.
- **Datos de NNA.** La Ley 1581/2012 art. 7 prohíbe tratar datos de NNA salvo los de naturaleza pública; la Corte Constitucional lo condiciona a que responda al interés superior del niño y se respeten sus derechos prevalentes. Los requisitos especiales están hoy en el Decreto 1074/2015 art. 2.2.2.25.2.9 (origen: art. 12 del Decreto 1377/2013, según la Superintendencia de Industria y Comercio). ADR-0007 cita el art. 2.2.2.25.2.3 para lo mismo; conviene corregirlo tras la validación. Falta definir la base legal para este tratamiento (punto abierto 2).
- **Datos sensibles.** Salud y psicosocial son datos sensibles (Ley 1581/2012 art. 5 y 6). Quién autoriza el tratamiento por el NNA y por qué figura es un supuesto jurídico (ADR-0007 §2.5).
- **Responsable y encargado.** Quién es responsable (ICBF, el operador) y quién encargado (el sistema, el proveedor de hospedaje, el proveedor de IA) y el contrato de encargo no están definidos. También hay que validar si aplica el Registro Nacional de Bases de Datos.
- **IA externa y nube.** Enviar datos seudonimizados a un proveedor en el exterior, o alojar en una nube pública, puede ser una transmisión o transferencia internacional (Ley 1581/2012 art. 26). Punto abierto 4. La seudonimización reduce el riesgo pero no convierte los datos en anónimos.
- **Retención.** La Ley 594/2000 (Ley General de Archivos) exige tablas de retención documental. No hay tabla; el sistema no borra nada y el paquete de archivo no tiene destino definido (puntos abiertos 1 y 2).
- **Ley 1098/2006.** Garantiza la intimidad del NNA (art. 33) y fija las funciones del Defensor de Familia (art. 82). Validar si hay deberes de reserva o confidencialidad adicionales para el expediente.
- **Firma.** El valor legal de una firma cargada como imagen es el punto abierto 5. La normativa sobre firmas electrónicas y mensajes de datos (Ley 527/1999 y Decreto 2364/2012) debe revisarla el abogado.
- **Res. 1619/2017 y Res. 2634/2019.** No se encontró ninguna resolución con esos números relacionada con el ICBF ni con datos de NNA. La búsqueda de la 2634/2019 devuelve una resolución del Ministerio de Relaciones Exteriores sobre el Permiso Especial de Permanencia, ajena al proyecto; la de 1619 devuelve una de 2015 del Ministerio de Salud sobre laboratorios. Pedir al operador o al docente la entidad y el tema de cada una antes de citarlas; mientras tanto no se usan como base.

## Métricas de éxito del proyecto
Tiempo de búsqueda, reducción de papel y reducción del tiempo de revisión (`CUESTIONARIO.md` H4).

| Indicador | Línea base en papel (S02) | Meta (S03) | Cómo se mide |
|---|---|---|---|
| Tiempo de búsqueda de un documento | 15 minutos | Menos de 1 minuto | Cronometrar 10 búsquedas con madres antes y después |
| Tiempo de revisión de un documento | 5 días hábiles | 2 días hábiles o menos | Diferencia entre envío y aprobación registrada por el sistema |
| Papel por NNA | 100 hojas | 70 % menos a los 3 meses | Conteo de hojas archivadas por mes |

La línea base es una estimación del equipo; se reemplaza por la medición real en la primera visita a los hogares.
