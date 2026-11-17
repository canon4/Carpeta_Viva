# Plan de pruebas

Proyecto: Sistema de gestión documental para hogares sustitutos (Carpeta Viva).
Fecha de la última ejecución registrada: 2026-11-17.
Datos: solo sintéticos. Nunca datos reales de menores, madres sustitutas o profesionales.

## 1. Alcance y estrategia

Alcance: backend (FastAPI, 112 rutas, 138 operaciones, `backend/openapi.json`), frontend (Angular) y los flujos de integración automatizados con pytest. Sin Postman en esta entrega.

Pirámide de pruebas:

| Nivel | Qué se prueba | Herramienta | Estado |
|---|---|---|---|
| Unitarias | Reglas de dominio puras (permisos, estados de flujo, cálculo de vencimientos) | pytest | Escasas hoy: la mayoría de pruebas del backend son de integración. Pendiente aislar reglas de dominio. |
| Integración de API | Endpoint + capa de aplicación + ORM, con permisos por rol | pytest + `TestClient` (SQLite en memoria) | 218 pruebas, ejecutadas |
| Contrato | `openapi.json` coincide con la app; el frontend genera tipos desde él | pytest (`test_contrato_openapi_esta_actualizado`) y `api:types` | Activo |
| Componentes frontend | Vistas, servicios y guardas | Vitest (`@angular/build:unit-test`) | 19 pruebas, ejecutadas |
| End-to-end (flujos) | Recorridos completos madre → profesional → alerta | pytest + `TestClient` (sección 5) | Automatizados y ejecutados |
| Accesibilidad básica | Contraste, foco, lectura asistida, baja visión | Revisión manual + axe-core (pendiente) | Pendiente |
| Carga | 1000 usuarios simultáneos | k6 (propuesta, sección 7) | Pendiente (Fase 5) |

Prioridad de la estrategia: permisos por rol, historial y versionado, auditoría, IA limitada a lo que el usuario puede ver, y carga de archivos maliciosos o mal formados. Estos casos son obligatorios; cualquier fallo en ellos bloquea la salida de la fase.

## 2. Entorno

- Backend: Python 3.14.4, venv del proyecto en `backend/.venv` (pytest 9.2.0).
- Base de datos en pruebas: SQLite en memoria con `StaticPool` (`backend/tests/conftest.py`). Las pruebas aíslan `ARCHIVOS_DIR` en un directorio temporal.
- PostgreSQL real: pendiente. Según `docs/plan-por-fases.md` (Fase 0), la migración y las pruebas aún no se han ejecutado contra PostgreSQL. Hasta cerrar esa tarea, la cobertura de dialecto (tipos, restricciones, índices) no está verificada.
- Frontend: Angular 22, Vitest 5.0.5, con `jsdom` como entorno.
- Configuración: `backend/.env` existe en la máquina de desarrollo y define `JWT_SECRET`, `ENVIRONMENT` y otras variables. Varias pruebas dependen de que el entorno no tenga esas variables (ver hallazgo H1).

## 3. Inventario de pruebas del backend

Total recolectado: 218 (`pytest --collect-only`, después de ADR-0016). El número por archivo incluye pruebas parametrizadas.

| Archivo | Módulo | Pruebas | Qué cubre |
|---|---|---|---|
| `test_auth.py` | 1 Autenticación y Accesos | 10 | Login correcto e incorrecto, usuario inactivo, correo sin distinguir mayúsculas, `/me` con token válido, ausente o basura; login_ok y login_fallido quedan auditados; guardia de roles (403). |
| `test_zonas_hogares.py` | 2 Zonas y Hogares | 5 | Admin crea y lista zonas; 401 sin token; rol incorrecto 403; admin crea hogar y lo filtra por zona; capacidad inválida 422. |
| `test_madres.py` | 3 Madres Sustitutas | 6 | Coordinador crea, lista y actualiza; 401; rol incorrecto; la madre ve su perfil y carga su firma; `/madres/yo` incluye su hogar; madre sin perfil 404. |
| `test_profesionales.py` | 4 Profesionales | 3 | Coordinador crea, lista, filtra y actualiza; 401; rol incorrecto 403. |
| `test_menores.py` | 5 Menores y Expedientes | 10 | Crear y listar; el cambio genera historial; profesional asignado ve el menor y el coordinador no ve la familia; coordinador de otra zona no ve el menor; la madre necesita asignación vigente y permiso de sección; cerrar una asignación no quita a la madre el acceso a otro menor; solo el defensor otorga o revoca permisos. |
| `test_asignaciones.py` | 6 Asignaciones y Traslados | 11 | Ingreso y consulta vigente; ingreso duplicado 422; traslado cierra la anterior y revoca permisos de la madre saliente; cerrar asignación egresa al menor y oculta el expediente a la madre; profesional no asignado no crea asignaciones; filtros; lectura ajena denegada a madre, profesional y coordinador de otra zona; la madre no ve el historial de asignaciones. |
| `test_documentos.py` | 7 Gestión Documental | 14 | Permiso de sección para crear documentos de salud; borrador de la madre frente a alta directa aprobada del profesional; enviar y aprobar; enviar y devolver; versionado con snapshot; auditor sin contenido pero con metadatos; descarga denegada sin permiso de sección; visor solo para PDF e imagen; compresión de imagen al reemplazar; agregador por sección; categoría desconocida 422; admin agrega categoría. |
| `test_inventario.py` | 8 Inventario del Hogar | 30 | CRUD por hogar; otros hogares denegados; coordinador de zona lista; profesional con menor en el hogar gestiona (comportamiento que SEG-04 pide revertir); "eliminar" retira y no borra; convivientes y red de apoyo; pedido y recepción (solo la madre confirma); fotos: válida, tipo inválido, tamaño excedido, más de 6, sin declaración o con declaración falsa; lectura de fotos restringida a madre, admin y auditor; ocultar foto. |
| `test_alimentos.py` | 9 Control de Alimentos | 16 | CRUD; fecha de vencimiento sin perecedero 422; filtro de vencidos; marcar consumido sin borrar; permisos de madre, coordinador, defensor, profesional y auditor; checklist y compra con validación de perecedero. |
| `test_citas.py` | 10 Citas y Recordatorios | 14 | Crear y obtener; notas ocultas sin permiso de sección (el resto de la fila sigue visible); permisos de escritura por tipo (la madre escribe citas médicas; el defensor, reuniones con familia); coordinador y profesional no escriben; próximas citas; reprogramar; madre de otro hogar no escribe. |
| `test_alertas.py` | 11 Alertas y Evasiones | 13 | Evasión: destinatarios y contactos de emergencia; sin teléfono registrado se dice explícitamente; solo el destinatario marca visto; usuario sin relación no ve la alerta; madre sin asignación vigente no reporta; auditor no reporta; respaldo a coordinador y admin; generación automática de visitas vencidas sin duplicados; auditor ve la alerta sin descripción ni detalle. |
| `test_reportes.py` | 12 Reportes | 13 | Reporte general limitado a la zona del coordinador; zona ajena denegada; reporte de menor sin acceso de sección; reporte de madre propia frente a ajena; exportar en JSON, CSV y PDF; revalidación al descargar tras perder asignación, permiso o archivo; auditor nunca descarga contenido; alcance de exportados por usuario. |
| `test_archivo.py` | Transversal: Archivo y Cierre | 9 | Cierre con condición no cumplida 409; admin cierra y queda archivado; coordinador fuera de zona no cierra ni consulta; estado sin archivar no crea fila; auditor ve estado pero no descarga el paquete; listado de archivados acotado a la zona; bloqueo de escritura tras archivar. |
| `test_ia.py` | Transversal: Asistente de IA | 4 | Profesional no asignado no recupera fragmentos de un menor ajeno (ni con el id en la pregunta); sin fragmentos no se llama al proveedor LLM; auditor nunca ve pregunta ni respuesta; revalidación del historial si el acceso ya no está vigente. |
| `test_auditoria.py` | Transversal: Auditoría | 4 | Auditor lista accesos; filtro por acción y paginación; 401 sin token; rol incorrecto no ve la auditoría. |
| `test_configuracion.py` | Configuración administrable (ADR-0013; no está entre los 12+3 de `CLAUDE.md`) | 21 | Catálogos y parámetros solo para admin; lectura pública sin datos de administración; al crear opción en grupo con sección se exige `seccion_acceso`; sección fuera del conjunto cerrado 400; el PUT no cambia la sección; desactivar opción; teléfono de la Policía llega a alertas de evasión. |
| `test_seguridad_correcciones.py` | Correcciones de seguridad (ADR-0016) | 15 | Solo admin crea zonas; coordinador limitado a su zona en zonas, hogares, madres y traslados; madre ya vinculada no se reasigna; tipo de archivo por bytes en documentos y fotos; auditor sin resumen de IA; bloqueo por intentos; cambio de contraseña y revocación de tokens; `login_fallido` sin el texto escrito. |
| `test_sistema.py` | Sistema | 20 | Health; los 16 módulos responden `_estado` (16 casos parametrizados); conteo de módulos; contrato OpenAPI actualizado; producción exige `JWT_SECRET` (falla, ver H1). |

Resumen por tipo: integración de API y permisos 198 (todos los archivos salvo `test_sistema.py`); sistema y contrato 20 (una falla); pruebas unitarias de dominio aisladas: 0.

### Frontend (Vitest)

| Spec | Pruebas | Qué cubre |
|---|---|---|
| `src/app/app.spec.ts` | 1 | Componente raíz. |
| `src/app/core/auth/auth.spec.ts` | 2 | Servicio de autenticación. |
| `src/app/core/navegacion.spec.ts` | 6 | Navegación y rutas por rol. |
| `src/app/features/login/login.spec.ts` | 2 | Inicio de sesión y accesos rápidos de desarrollo (una falla, ver H2). |
| `src/app/modules/archivo/archivo-menor.spec.ts` | 2 | Vista de archivo del menor. |
| `src/app/modules/ia/ia-consulta.spec.ts` | 3 | Consulta de IA. |
| `src/app/modules/reportes/reportes-panel.spec.ts` | 3 | Panel de reportes. |

Total: 7 archivos, 19 pruebas. El documento `docs/plan-por-fases.md` aún indica "29 pruebas" en backend y "6 pruebas" en frontend; esas cifras están desactualizadas.

## 4. Resultado de la ejecución (2026-11-17)

### Backend

Comando: `backend/.venv/Scripts/python.exe -m pytest -q` (desde `backend/`).

- Recolectadas: 218.
- Pasan: 217.
- Fallan: 1.
- Tiempo: 204 s (cerca de 4 minutos; conviene paralelizar o separar la suite lenta en CI).
- Avisos: 11 `StarletteDeprecationWarning` por el uso de `HTTP_422_UNPROCESSABLE_ENTITY` (deprecado en favor de `HTTP_422_UNPROCESSABLE_CONTENT`). No afectan el resultado.

Fallo:

- `tests/test_sistema.py::test_produccion_exige_jwt_secret`: esperaba `RuntimeError` y no se lanzó.
- Causa (H1): `Settings` lee `backend/.env` (`env_file=".env"`), que define un `JWT_SECRET` distinto del valor por defecto. El `monkeypatch.delenv("JWT_SECRET")` no lo elimina porque el valor sale del archivo. La validación de `app/main.py` no se dispara. Es un fallo del entorno local, no de la lógica de producción. En un clon limpio sin `.env` la prueba pasaría.
- Corrección propuesta (no aplicada, la tarea prohíbe cambiar código): en la prueba, fijar explícitamente `JWT_SECRET` al valor por defecto (`JWT_SECRET_POR_DEFECTO` de `app/core/config.py`) con `monkeypatch.setenv`, o aislar `Settings` con `env_file=None` en la prueba.

### Frontend

Comando: `npx ng test --watch=false` (desde `frontend/`).

- Archivos: 7. Pruebas: 19. Pasan: 18. Fallan: 1. Tiempo: 36,6 s.
- Fallo (H2): `src/app/features/login/login.spec.ts` > "muestra accesos rápidos y dispara el login real si el flag es true". `expectOne('/api/v1/auth/me')` no encuentra la petición.
- Causa: `AuthService.login()` es `async`. La llamada a `/auth/me` se emite después de un `await` de `firstValueFrom`, así que en el momento del `expectOne` aún no existe. Es un fallo de temporización del spec. Corrección propuesta (no aplicada): esperar antes de `expectOne`, por ejemplo con `await fixture.whenStable()` o `await new Promise(r => setTimeout(r))`.

## 5. Pruebas de integración de flujos (pytest)

En esta entrega no se usa Postman. Los flujos de punta a punta se prueban con pytest y `TestClient` de FastAPI: cada prueba levanta la aplicación completa (API, capa de aplicación, ORM y base SQLite en memoria), crea sus datos sintéticos y recorre el flujo con los tokens de cada rol. Así quedan automatizados y corren en cada cambio.

| Flujo | Pasos | Prueba |
|---|---|---|
| Ingreso de un NNA | Admin crea menor, coordinador lo asigna a un hogar de su zona, la madre lo ve | `test_asignaciones.py::test_crear_ingreso_y_consultar_vigente` |
| Traslado | Traslado entre hogares cierra la asignación anterior y revoca permisos de la madre saliente | `test_asignaciones.py::test_traslado_cierra_anterior_y_revoca_permisos_de_madre` |
| Ciclo de un documento | La madre sube y envía a revisión; el profesional asignado aprueba o devuelve con motivo; la madre sube versión | `test_documentos.py::test_flujo_enviar_y_aprobar`, `::test_flujo_enviar_y_devolver`, `::test_versionado_snapshotea_y_sube_version` |
| Permiso de sección | El defensor habilita salud a la madre; la madre ve los documentos de salud; al revocar deja de verlos | `test_menores.py`, `test_documentos.py` |
| Evasión | La madre reporta; recibe números de emergencia; el defensor ve la alerta en pendientes y la marca vista | `test_alertas.py` |
| Cierre del caso | Egreso, archivo del expediente, paquete verificable y bloqueo de escritura | `test_archivo.py` |
| IA con permisos | Consulta con cita; un documento sin permiso nunca aparece; el historial se oculta al perder acceso | `test_ia.py` |
| Seguridad de cuentas y zonas | Bloqueo por intentos, cambio de contraseña, coordinador limitado a su zona, tipo de archivo por bytes | `test_seguridad_correcciones.py` |

Límite conocido: la asignación de profesionales a un NNA no tiene endpoint (HU18), así que las pruebas la crean directamente en la base con `tests/_helpers.py::asignar_profesional_a_menor`.

Pendiente: repetir la suite contra PostgreSQL real (criterio de salida de la fase).

## 6. Pruebas de seguridad

Leyenda: Sí = prueba automatizada que falla si se rompe la regla. Parcial = cubre una parte. No = sin prueba.

| Caso | Prueba automatizada | Estado | Referencia |
|---|---|---|---|
| Madre no ve NNA de otro hogar | Sí | Cubierto | `test_menores.py::test_madre_necesita_asignacion_vigente_y_permiso_de_seccion`; `test_asignaciones.py::test_madre_sin_relacion_no_ve_lectura_de_asignaciones_de_otro_menor`; `test_inventario.py::test_madre_de_otro_hogar_no_lista_convivientes`; `test_alimentos.py::test_madre_de_otro_hogar_no_puede_gestionar` |
| Madre pierde acceso al cerrar la asignación | Sí | Cubierto | `test_asignaciones.py::test_cerrar_asignacion_egresa_al_menor_y_oculta_expediente_a_la_madre`; `test_reportes.py::test_revalidacion_al_descargar_tras_perder_la_asignacion`; complementaria: `test_menores.py::test_madre_conserva_acceso_a_otro_menor_tras_cerrar_asignacion_de_uno` |
| Auditor no ve contenido sensible | Parcial | Parcial, con hallazgo SEG-02 | `test_documentos.py::test_auditor_sin_acceso_a_contenido_pero_si_a_metadatos`; `test_reportes.py::test_auditor_nunca_descarga_contenido_exportado`; `test_archivo.py::test_auditor_ve_estado_pero_nunca_descarga_el_paquete`; `test_ia.py::test_auditor_nunca_ve_pregunta_ni_respuesta`. No cubierto: resumen de IA de un documento (SEG-02). El auditor sí puede leer las fotos de inventario por decisión de ADR-0014 §2.1 (`test_inventario.py`); ratificar. |
| Coordinador limitado a su zona | Parcial | Parcial, con hallazgos SEG-03 y SEG-05 | `test_menores.py::test_coordinador_de_otra_zona_no_ve_el_menor`; `test_reportes.py::test_reporte_general_coordinador_limitado_a_su_zona`; `test_archivo.py::test_coordinador_fuera_de_zona_no_puede_cerrar_ni_consultar`; `test_asignaciones.py::test_coordinador_de_otra_zona_no_ve_lectura_de_asignacion_ajena`. No cubierto: zonas, hogares, madres y profesionales (SEG-03) ni el traslado desde otra zona (SEG-05). |
| JWT inválido | Sí | Cubierto | `test_auth.py::test_me_con_token_basura_es_401`; `test_auth.py::test_me_sin_token_es_401` |
| JWT expirado | No | Pendiente | `jwt_expire_minutes = 60` en `app/core/config.py`; no hay prueba que genere un token vencido. |
| Límite de intentos de login | No | No implementado | No existe en el código (Fase 1 del plan). Sin prueba; crearla al implementarlo. |
| IA solo cita lo que el usuario puede ver | Sí | Cubierto | `test_ia.py::test_profesional_no_asignado_no_recupera_fragmentos_de_menor_ajeno`; `test_ia.py::test_revalidacion_historial_redacta_si_acceso_ya_no_vigente` |
| Auditoría registra accesos | Parcial | Parcial | Automatizado: login_ok y login_fallido (`test_auth.py::test_login_queda_auditado`) y listado (`test_auditoria.py`). No hay prueba de que la lectura de un expediente, documento, alerta o descarga deje registro, aunque 15 módulos llaman a `registrar_acceso`. |
| Archivos maliciosos o mal formados | Parcial | Parcial, con hallazgo H3 (SEG-01) | Cubierto: foto de tipo inválido, tamaño excedido, más de 6 fotos, declaración ausente o falsa (`test_inventario.py`); categoría desconocida (`test_documentos.py`). No cubierto: validación del contenido real (ver H3). |

Hallazgos de seguridad abiertos:

- H3. Validación de contenido de archivos (alto). `POST /documentos` y `POST /documentos/{id}/version` no validan el tipo: aceptan cualquier `content_type` que declare el cliente y solo controlan tamaño y que no esté vacío (`app/modules/documentos/api.py`, `app/modules/documentos/application.py`). Las fotos de inventario (`app/modules/inventario/application.py`) validan el tipo declarado contra JPEG, PNG y WEBP, pero no los bytes. Una sonda ejecutada fuera del repositorio con datos sintéticos confirmó que el sistema acepta:
  - contenido con cabecera de ejecutable Windows (`MZ`) declarado como `image/jpeg`: 201;
  - contenido de PDF declarado como `image/jpeg`: 201.
  La sonda no se incorpora al repositorio. Mitigantes existentes: cifrado en reposo, `nosniff`, `no-store` y visor solo para tipos del navegador. Corrección: lista de tipos permitidos y validación de firma (magic bytes) en documentos, versiones, fotos y `/ia/documentos/clasificar`. El arreglo cambia la política de carga (RF2 pide multiformato), así que se devuelve a seguridad y backend (ADR de carga de archivos) antes de corregir.
- H4. La auditoría de lecturas no tiene pruebas (ver tabla).

Otros hallazgos:

- H1 y H2 (sección 4): fallos de entorno y de temporización, con causa identificada.
- La API no tiene límite de intentos de login ni expiración probada del token.

### Casos de seguridad pendientes

Cada caso se escribe primero como prueba que falla, y se corrige después. Cuando se corrija SEG-04, hay que invertir la prueba existente `test_inventario.py::test_profesional_con_menor_en_el_hogar_puede_gestionar`, que hoy da por bueno el permiso. Detalle de cada diferencia: `04-desarrollo/control-de-acceso.md` sección 6.

| ID | Severidad | Caso | Resultado esperado | Estado |
|---|---|---|---|---|
| SEG-01 | Alta | Subir ejecutable (`MZ`) declarado como `image/jpeg`; PDF declarado como imagen; tipo fuera de la lista (HTML, SVG, ejecutable) en documentos, versiones, fotos de inventario y `/ia/documentos/clasificar` | 422 y sin archivo guardado | Corregido en documentos, versiones y fotos (ADR-0016, `test_seguridad_correcciones.py`); falta `/ia/documentos/clasificar` |
| SEG-02 | Media | Auditor pide `GET /ia/documentos/{id}/resumen` de un documento no sensible, de un documento de hogar y de un reporte de seguimiento | 403 y fila de auditoría de denegación | Corregido (ADR-0016) |
| SEG-03 | Alta | Coordinador de la zona B lista, consulta y modifica zonas, hogares, madres y profesionales de la zona A, y reasigna `madre_id` de un hogar de la zona A | Listados solo de su zona; 403 al consultar o modificar lo ajeno | Corregido en zonas, hogares y madres (ADR-0016); profesionales pendiente de decisión (no tienen zona) |
| SEG-04 | Media | Profesional y defensor con un NNA en el hogar crean ítems de inventario, cambian el estado físico, y crean o editan convivientes y red de apoyo; el coordinador cambia el estado de un ítem | 403 en cada caso (la madre y el admin siguen pudiendo; el coordinador solo gestiona el pedido) | Pendiente |
| SEG-05 | Media | Coordinador de la zona B traslada a un hogar de su zona un NNA que está en la zona A | 403 | Corregido (ADR-0016) |
| SEG-06 | Media | Admin pide el historial de IA de otro usuario cuya respuesta contiene fragmentos de una sección sensible | Solo metadatos, sin pregunta ni respuesta | Pendiente |
| SEG-07 | Media | Token vencido y token con firma alterada en `/auth/me` y en un endpoint de expediente | 401 | Pendiente |
| SEG-08 | Alta | Varios `login` fallidos seguidos de la misma cuenta | Bloqueo temporal y fila de auditoría | Corregido: 429 tras 5 intentos durante 15 minutos (ADR-0016) |
| SEG-09 | Media | Leer un expediente, un documento, una alerta y descargar un archivo | Una fila de auditoría por lectura, con usuario, recurso y menor; las denegaciones también | Pendiente (H4) |
| SEG-10 | Media | Cargar un documento con texto que ordena ignorar las reglas, revelar otros expedientes o citar fuentes falsas y consultar a la IA con proveedor simulado | El texto llega al modelo como dato dentro del contexto; la respuesta solo cita fuentes recuperadas del ámbito permitido | Pendiente |
| SEG-11 | Alta | Ejecutar `UPDATE` y `DELETE` sobre `auditoria_accesos` con el usuario de la aplicación | Rechazo por la base (requiere PostgreSQL) | Implementado con triggers en la migración 0011; falta probar en PostgreSQL |
| SEG-12 | Baja | Madre que reportó una evasión intenta cerrar la alerta; coordinador o admin intentan crear familiares de un NNA | Según decisión del operador y de seguridad (control-de-acceso hallazgos 9 y 10) | Pendiente de decisión |

## 7. Prueba de carga: 1000 usuarios simultáneos (pendiente)

Herramienta propuesta: k6 (scripts en JavaScript, umbrales declarativos, salida para CI). Alternativa: Locust si el equipo prefiere Python.

Escenario propuesto:

- Entorno: réplica de staging con la misma configuración del VPS (Nginx, FastAPI, PostgreSQL). Nunca producción.
- Datos: seed masivo sintético de 35 hogares y 210 menores, más 1000 cuentas `@carga.local` creadas por script. Ninguna cuenta real.
- Perfil: 1000 usuarios virtuales concurrentes; rampa de 10 minutos, meseta de 20 minutos y bajada de 5 minutos. Pausa de 5 a 10 segundos entre acciones para modelar usuarios reales.
- Mezcla de acciones: 50 por ciento lecturas de paneles y listados (panel del profesional, menores por zona, citas próximas); 20 por ciento consultas de documentos y versiones; 15 por ciento alertas pendientes; 10 por ciento escrituras (crear cita, alimento, ítem de inventario); 5 por ciento subidas de documento de 1 a 5 MB.
- Umbrales (criterio de aceptación): p95 de lecturas menor a 500 ms; p95 de escrituras menor a 800 ms; p95 de subidas menor a 3 s; tasa de error menor a 1 por ciento; cero respuestas 5xx sostenidas.
- Métricas de servidor: CPU, memoria, conexiones de PostgreSQL y tiempo de respuesta de Nginx durante la meseta.
- Criterio de salida: umbrales cumplidos en dos corridas consecutivas. Antes de ejecutarla hay que completar la prueba de PostgreSQL real (sección 2).

## 8. Registro y gestión de errores

Plantilla de reporte de bug (un reporte por defecto):

```
ID: BUG-AAAA-NNN
Título: <comportamiento observado, en una línea>
Severidad: S1 bloqueante o de permisos/datos de menores | S2 mayor | S3 menor | S4 cosmética
Módulo: <número y nombre de módulo>
Rol usado: <admin | coordinador | madre | profesional | defensor | auditor>
Entorno: <commit, SQLite o PostgreSQL, fecha>
Pasos para reproducir: 1. ... 2. ... 3. ...
Esperado: ...
Obtenido: ... (código HTTP y cuerpo sin datos reales)
Prueba que lo reproduce: <archivo::función>
Causa raíz: ...
Corrección: ... (enlace a commit o PR)
Regresión: <prueba automatizada agregada o existente que lo cubre>
```

Flujo Kanban (columnas):

Nuevo → Confirmado (reproducido) → En corrección → En verificación (test) → Cerrado.
Columna adicional: Bloqueado (espera a arquitecto o seguridad).

Reglas:

- Un defecto S1 de permisos o de datos de menores no se cierra sin una prueba automatizada de regresión y revisión de seguridad.
- Un defecto que se corrige y vuelve a fallar dos veces se escala a sonnet (regla del proyecto).
- Un cambio de endpoint incompatible requiere versión nueva de la API y ADR; el defecto se devuelve al arquitecto.
- Los cambios que tocan datos de menores pasan por seguridad.

## 9. Criterios de entrada y de salida de la fase

Criterios de entrada (antes de ejecutar la suite de la fase):

- Migraciones de base de datos aplicadas antes que el código que las usa.
- `backend/openapi.json` regenerado y `test_contrato_openapi_esta_actualizado` en verde.
- Seed sintético disponible; ningún dato real en la base de pruebas.
- Entorno de prueba definido (SQLite para la suite rápida; PostgreSQL para la verificación de la fase).

Criterios de salida:

- Suite de backend en verde, o fallos documentados con ticket y decisión de arquitecto.
- Frontend en verde, o fallos documentados con causa.
- Cero defectos S1 o S2 abiertos.
- Los casos de seguridad obligatorios de la sección 6 con prueba automatizada y los casos SEG-01 a SEG-11 cerrados o aceptados por seguridad. Hoy de los 10 casos de la tabla: 4 completos, 4 parciales (auditor sin contenido, coordinador limitado a su zona, auditoría de lecturas y archivos mal formados) y 2 sin prueba (JWT expirado y límite de intentos, este último sin implementar).
- Flujos de la sección 5 en verde, también contra PostgreSQL.
- Revisión de seguridad al cierre de fase (regla del plan por fases).

Fase 0 (estado actual): el criterio de PostgreSQL real no se cumple. La suite está en rojo por un caso (H1) y el frontend por otro (H2).

## 10. Revisión cruzada por pares

- Quien escribe una prueba no es quien implementa la funcionalidad que prueba. Backend revisa las pruebas de frontend que dependen de su contrato, y viceversa.
- Las pruebas de permisos, menores, auditoría e IA las revisa también seguridad.
- Cada PR que cambia permisos incluye la prueba que falla antes del cambio y pasa después.
- Las correcciones de test (agente test, modelo haiku) se revisan con el mismo criterio; si fallan dos veces, se escalan a sonnet.
- Ningún PR se fusiona con la suite en rojo sin un ticket y la aprobación del arquitecto.
