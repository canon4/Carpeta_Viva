# Matriz de trazabilidad

Relaciona cada historia de usuario con su requisito, módulo, endpoints (`/api/v1`, `backend/openapi.json`) y archivo de prueba (`backend/tests/`). Las historias pendientes llevan el endpoint **propuesto** (marcado así) y la prueba que deberá escribirse.
Cobertura verificada por script: las 95 rutas de negocio del contrato (112 en total, menos `health` y los 16 `_estado`) aparecen en esta matriz y cada requisito funcional tiene al menos una historia.

| HU | RF | Módulo | Endpoints | Prueba |
|---|---|---|---|---|
| HU01 | RF0.1, RF0.3 | 1 Auth | `POST /auth/login` | test_auth.py |
| HU02 | RF0.2 | 1 Auth | `GET /auth/me` | test_auth.py |
| HU03 | RF0.4 | 1 Auth | `PUT /auth/contrasena` | test_seguridad_correcciones.py |
| HU04 | RF0.5 | 1 Auth | `POST /auth/login` | test_seguridad_correcciones.py |
| HU05 | RF0.6 | 1 Auth | Propuesto: `POST/GET /auth/usuarios`, `PUT /auth/usuarios/{usuario_id}` | Por escribir: test_usuarios.py |
| HU06 | RF0.7 | 1 Auth | Propuesto: campo `debe_cambiar_contrasena` en `GET /auth/me`; `PUT /auth/contrasena` | Por escribir: test_usuarios.py |
| HU07 | RF0.8 | 1 Auth | Propuesto: `POST /auth/2fa/activar`, `POST /auth/2fa/confirmar`, `POST /auth/login/2fa` | Por escribir: test_2fa.py |
| HU08 | RF17.1 | 2 Zonas | `POST/GET /zonas-hogares/zonas`, `GET/PUT /zonas-hogares/zonas/{zona_id}` | test_zonas_hogares.py, test_seguridad_correcciones.py |
| HU09, HU10 | RF17.2 | 2 Zonas | `POST/GET /zonas-hogares/hogares`, `GET/PUT /zonas-hogares/hogares/{hogar_id}` | test_zonas_hogares.py, test_seguridad_correcciones.py |
| HU11 | RF17.3 | 3 Madres | `POST/GET /madres`, `GET/PUT /madres/{madre_id}` | test_madres.py, test_seguridad_correcciones.py |
| HU12 | RF0.2 | 3 Madres | `GET /madres/yo` | test_madres.py |
| HU13 | RF5.1 | 3 Madres | `PUT /madres/yo/firma` | test_madres.py |
| HU14 | RF5.2 | 7 Documentos | Propuesto: `PUT /documentos/{documento_id}/firmar` | Por escribir: test_documentos.py |
| HU15 | RF17.4, RF9.10 | 3 Madres | Propuesto: `POST/GET /madres/{madre_id}/capacitaciones`, `PUT /madres/capacitaciones/{capacitacion_id}` | Por escribir: test_madres.py |
| HU16 | RF17.5 | 4 Profesionales | `POST/GET /profesionales`, `GET/PUT /profesionales/{profesional_id}` | test_profesionales.py |
| HU17 | RF17.6 | 4 Profesionales | Propuesto: `PUT /profesionales/{profesional_id}/zonas` | Por escribir: test_profesionales.py |
| HU18 | RF1.6 | 4 Profesionales | Propuesto: `POST/GET /menores/{menor_id}/profesionales`, `PUT /menores/{menor_id}/profesionales/{asignacion_id}/finalizar` | Por escribir: test_profesionales.py |
| HU19 | RF1.1 | 5 Menores | `POST/GET /menores`, `GET /menores/{menor_id}` | test_menores.py |
| HU20 | RF1.3, RF3.2, RF7.2 | 5 Menores | `PUT /menores/{menor_id}`, `GET /menores/{menor_id}/historial` | test_menores.py |
| HU21 | RF1.2 | 5 Menores | `GET/POST /menores/{menor_id}/familiares` | test_menores.py |
| HU22 | RF1.4 | 5 Menores | `GET /menores/panel/profesional` | test_menores.py |
| HU23 | RF1.5 | 5 Menores | `GET /menores/panel/zona` | test_menores.py |
| HU24 | RF6.2 | 5 Menores | `GET/POST /menores/{menor_id}/permisos`, `DELETE /menores/{menor_id}/permisos/{permiso_id}` | test_menores.py |
| HU25 | RF6.1, RF7.1 | 5 Menores | `GET /menores` | test_menores.py, test_asignaciones.py |
| HU26 | RF6.5 | 5 Menores | `GET /menores`, `GET /menores/{menor_id}` (respuesta minimizada para auditor) | Por escribir: test_menores.py |
| HU27 | RF1.7 | 6 Asignaciones | `POST/GET /asignaciones`, `GET /asignaciones/{asignacion_id}` | test_asignaciones.py |
| HU28 | RF1.8 | 6 Asignaciones | `POST /asignaciones` (traslado), `GET /asignaciones/menor/{menor_id}/vigente` | test_asignaciones.py, test_seguridad_correcciones.py |
| HU29 | RF1.9, RF7.1 | 6 Asignaciones | `PUT /asignaciones/{asignacion_id}/cerrar` | test_asignaciones.py |
| HU30 | RF3.2 | 6 Asignaciones | `GET /asignaciones/{asignacion_id}/historial` | test_asignaciones.py |
| HU31 | RF2.1, RF2.2, RF2.3, RF4.1 | 7 Documentos | `POST /documentos` | test_documentos.py, test_seguridad_correcciones.py |
| HU32 | RF4.1 | 7 Documentos | `PUT /documentos/{documento_id}/enviar` | test_documentos.py |
| HU33 | RF4.2 | 7 Documentos | `GET /documentos`, `PUT /documentos/{documento_id}/aprobar`, `PUT /documentos/{documento_id}/devolver` | test_documentos.py |
| HU34 | RF4.5 | 7 Documentos | `PUT /documentos/{documento_id}/aprobar`, `PUT /documentos/{documento_id}/devolver` (ampliar a documentos de hogar) | Por escribir: test_documentos.py |
| HU35 | RF3.1 | 7 Documentos | `POST /documentos/{documento_id}/version` | test_documentos.py |
| HU36 | RF3.2, RF3.3 | 7 Documentos | `GET /documentos/{documento_id}/versiones`, `GET /documentos/{documento_id}/versiones/{version}/contenido` | test_documentos.py |
| HU37 | RF2.4 | 7 Documentos | `GET /documentos/{documento_id}/vista`, `GET /documentos/{documento_id}/contenido`, `GET /documentos/{documento_id}` | test_documentos.py |
| HU38 | RF6.1 | 7 Documentos | `GET /documentos/menor/{menor_id}/seccion/{seccion}` | test_documentos.py |
| HU39 | RF4.3, RF4.4 | 7 Documentos | `POST/GET /documentos/reportes`, `GET /documentos/reportes/{reporte_id}` | test_documentos.py |
| HU40 | RF10.1 | 7 Documentos | `POST /documentos` (`migracion=true`) | test_documentos.py |
| HU41 | RF6.3, RF6.4 | 7 Documentos | `GET /documentos/auditor` | test_documentos.py |
| HU42 | RF13.1 | 8 Inventario | `POST/GET /inventario/items`, `GET/PUT /inventario/items/{item_id}` | test_inventario.py |
| HU43 | RF13.2 | 8 Inventario | `PUT /inventario/items/{item_id}/recepcion`, `POST/GET /inventario/items/{item_id}/fotos`, `GET /inventario/items/{item_id}/fotos/{foto_id}`, `PUT /inventario/items/{item_id}/fotos/{foto_id}/ocultar` | test_inventario.py, test_seguridad_correcciones.py |
| HU44 | RF13.3 | 8 Inventario | `POST /inventario/items` | test_inventario.py |
| HU45 | RF13.3 | 8 Inventario | `POST/GET /inventario/convivientes`, `PUT /inventario/convivientes/{conviviente_id}` | test_inventario.py |
| HU46 | RF13.4 | 8 Inventario | `POST/GET /inventario/red-apoyo`, `PUT /inventario/red-apoyo/{contacto_id}` | test_inventario.py |
| HU47 | RF13.5 | 8 Inventario | Mismos endpoints de inventario, con escritura denegada a profesionales | Por escribir: invertir `test_inventario.py::test_profesional_con_menor_en_el_hogar_puede_gestionar` |
| HU48 | RF14.1 | 9 Alimentos | `POST/GET /alimentos`, `PUT /alimentos/{item_id}` | test_alimentos.py |
| HU49 | RF14.2 | 9 Alimentos | `POST/GET /alimentos/checklist`, `PUT /alimentos/checklist/{checklist_item_id}`, `POST /alimentos/checklist/{checklist_item_id}/comprar` | test_alimentos.py |
| HU50 | RF14.3 | 9 Alimentos | `GET /alimentos?vencidos=true`, `PUT /alimentos/{item_id}/consumido` | test_alimentos.py |
| HU51 | RF14.4 | 9 Alimentos | `GET /alimentos` | test_alimentos.py |
| HU52, HU53 | RF15.1 | 10 Citas | `POST/GET /citas`, `GET/PUT /citas/{cita_id}` | test_citas.py |
| HU54 | RF15.2 | 10 Citas | `GET /citas/proximas` | test_citas.py |
| HU55 | RF15.3 | 10 Citas | `PUT /citas/{cita_id}/estado` | test_citas.py |
| HU56 | RF15.4 | 10 Citas | `GET /citas`, `GET /citas/{cita_id}` | test_citas.py |
| HU57 | RF9.1, RF9.2, RF9.3 | 11 Alertas | `POST /alertas/evasion` | test_alertas.py |
| HU58 | RF9.2, RF9.4 | 11 Alertas | `GET /alertas/{alerta_id}`, `PUT /alertas/{alerta_id}/visto` | test_alertas.py |
| HU59 | RF9.7 | 11 Alertas | Propuesto: `POST /alertas/suscripciones-push` | Por escribir: test_alertas.py |
| HU60 | RF9.4 | 11 Alertas | `GET /alertas/mis-pendientes`, `GET /alertas` | test_alertas.py |
| HU61 | RF9.5 | 11 Alertas | `POST /alertas/generar-automaticas`, `GET /alertas/panel` | test_alertas.py |
| HU62 | RF9.6 | 11 Alertas, T1 IA | `POST /alertas/generar-automaticas` | test_ia.py (regla de 60 días); por escribir el resto |
| HU63 | RF9.8, RF9.9 | 11 Alertas | `PUT /alertas/{alerta_id}/cerrar` | test_alertas.py |
| HU64 | RF9.10 | 11 Alertas | `POST /alertas/generar-automaticas` (tipo nuevo `capacitacion_por_vencer`) | Por escribir: test_alertas.py |
| HU65 | RF16.1 | 12 Reportes | `GET /reportes/general` | test_reportes.py |
| HU66 | RF16.2 | 12 Reportes | `GET /reportes/zona/{zona_id}` | test_reportes.py |
| HU67 | RF16.3 | 12 Reportes | `GET /reportes/menor/{menor_id}` | test_reportes.py |
| HU68 | RF16.4 | 12 Reportes | `GET /reportes/madre/{madre_id}` | test_reportes.py |
| HU69 | RF16.5 | 12 Reportes | `POST /reportes/exportar`, `GET /reportes/exportados`, `GET /reportes/exportados/{informe_id}/contenido` | test_reportes.py |
| HU70 | RF16.6 | 12 Reportes | Propuesto: `GET /reportes/indicadores` | Por escribir: test_reportes.py |
| HU71 | RF12.1 | T1 IA | `POST /ia/consultas` | test_ia.py |
| HU72 | RF12.2 | T1 IA | `GET /ia/menores/{menor_id}/resumen`, `GET /ia/documentos/{documento_id}/resumen` | test_ia.py, test_seguridad_correcciones.py |
| HU73 | RF12.3 | T1 IA | `POST /ia/documentos/clasificar` | test_ia.py |
| HU74 | RF12.4 | T1 IA | `POST /ia/mantenimiento/reindexar-pendientes` (OCR e indexado en segundo plano) | test_ia.py |
| HU75 | RF12.5 | T1 IA | Propuesto: `GET /ia/menores/{menor_id}/inconsistencias` | Por escribir: test_ia.py |
| HU76 | RF12.6 | T1 IA | `POST /ia/redaccion/apoyo` | test_ia.py |
| HU77 | RF12.8 | T1 IA | `GET /ia/consultas`, `GET /ia/consultas/{consulta_id}` | test_ia.py |
| HU78 | RF12.7 | T1 IA | `GET /ia/estado` | test_ia.py |
| HU79 | RF12.9 | T1 IA | `GET /ia/consultas` (respuesta minimizada para admin) | Por escribir: test_ia.py |
| HU80 | RF11.1 | T2 Auditoría | Todas (vía `core/audit.py`) | test_auditoria.py |
| HU81 | RF11.2 | T2 Auditoría | `GET /auditoria` | test_auditoria.py |
| HU82 | RF8.1, RF8.2 | T3 Archivo | `POST /archivo/menores/{menor_id}/cerrar`, `GET /archivo/menores/{menor_id}`, `GET /archivo` | test_archivo.py |
| HU83 | RF8.3 | T3 Archivo | `GET /archivo/menores/{menor_id}/paquete` | test_archivo.py |
| HU84 | RF8.4 | T3 Archivo | Propuesto: `POST /archivo/menores/{menor_id}/entrega` | Por escribir: test_archivo.py |
| HU85 | RF8.5 | T3 Archivo | Propuesto: `GET /archivo/retencion`, `POST /archivo/menores/{menor_id}/disposicion` | Por escribir: test_archivo.py |
| HU86 | RF18.1 | T4 Configuración | `GET /configuracion/catalogos`, `GET/POST /configuracion/catalogos/{grupo}`, `GET /configuracion/catalogos/{grupo}/admin`, `PUT /configuracion/catalogos/{grupo}/{valor}` | test_configuracion.py |
| HU87 | RF18.2 | T4 Configuración | `GET /configuracion/parametros`, `PUT /configuracion/parametros/{clave}`, `GET /configuracion/publica` | test_configuracion.py |
| HU88, HU89, HU90 | RNF15, RNF16, RNF18 | Frontend | N/A | Specs del frontend y prueba de usabilidad (S24) |

Rutas técnicas sin historia propia: `GET /health` y `GET /<módulo>/_estado` (16), usadas por monitoreo (`test_sistema.py`).

## Cobertura
- Cada requisito funcional de [requisitos-funcionales.md](requisitos-funcionales.md) tiene al menos una historia.
- Cada historia tiene criterios de aceptación y, si está hecha, un archivo de prueba.
- Las 27 historias parciales o pendientes tienen definido el endpoint propuesto y la prueba que debe escribirse.
