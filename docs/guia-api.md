# Guía de la API

Referencia rápida de los endpoints del backend. El contrato completo y autoritativo es
`backend/openapi.json`; con el backend corriendo, la documentación interactiva está en
`http://localhost:8000/docs`. Esta guía es un mapa para orientarse, no reemplaza esos dos.

## Base y autenticación

- Todo bajo `/api/v1`.
- Autenticación: `POST /api/v1/auth/login` con `email` y `password` devuelve un `access_token`
  (JWT). Se envía en cada petición siguiente como `Authorization: Bearer <token>`.
- El token vive solo en memoria en el frontend (nunca `localStorage`); al recargar la página hay
  que iniciar sesión de nuevo (decisión de seguridad, ver `frontend/CLAUDE.md`).
- `GET /api/v1/auth/me` devuelve el usuario autenticado (email, rol, zona/hogar si aplica).

## Permisos

Cada módulo filtra por rol y, en los que aplica, por la asignación real del usuario (su zona, su
hogar, los menores que tiene a cargo). Un acceso no autorizado responde `403`, nunca se oculta con
un `404`. Casi todo queda auditado (módulo de Auditoría, RF11).

## Errores comunes

| Código | Significa |
|---|---|
| 401 | Falta el token o no es válido. |
| 403 | El rol o la asignación del usuario no da permiso para esto. |
| 404 | El recurso no existe (o el usuario no debería saber que existe). |
| 422 | Datos de entrada inválidos; el cuerpo trae el detalle en `detail`. |

## Endpoints por módulo

Cada módulo tiene además un `GET /api/v1/<módulo>/_estado` de diagnóstico (no es de negocio).

### Autenticación y Accesos
- `POST /auth/login` — iniciar sesión.
- `GET /auth/me` — usuario autenticado.

### Zonas y Hogares
- `GET/POST /zonas-hogares/zonas`, `GET/PUT /zonas-hogares/zonas/{id}`
- `GET/POST /zonas-hogares/hogares`, `GET/PUT /zonas-hogares/hogares/{id}`

### Madres Sustitutas
- `GET/POST /madres`, `GET/PUT /madres/{id}`
- `GET /madres/yo` — perfil de la madre autenticada.
- `PUT /madres/yo/firma` — cargar la firma única.

### Profesionales
- `GET/POST /profesionales`, `GET/PUT /profesionales/{id}`

### Menores y Expedientes
- `GET/POST /menores`, `GET/PUT /menores/{id}`
- `GET/POST /menores/{id}/familiares`
- `GET /menores/{id}/historial`
- `GET/POST /menores/{id}/permisos`, `DELETE /menores/{id}/permisos/{permiso_id}` — qué parte del
  expediente ve cada persona (lo define el profesional a cargo).
- `GET /menores/panel/profesional`, `GET /menores/panel/zona` — paneles agrupados.

### Asignaciones y Traslados
- `POST /asignaciones` — vincula menor y hogar.
- `PUT /asignaciones/{id}/cerrar`
- `GET /asignaciones/menor/{menor_id}/vigente`
- `GET /asignaciones/{id}/historial`

### Gestión Documental
- `POST /documentos` — subir (la madre crea).
- `POST /documentos/{id}/version` — nueva versión.
- `PUT /documentos/{id}/enviar|aprobar|devolver` — flujo de revisión.
- `GET /documentos/{id}/contenido`, `GET /documentos/{id}/versiones/{version}/contenido` —
  descarga (el backend fuerza descarga, no hay visor embebido).
- `GET /documentos/menor/{menor_id}/seccion/{seccion}` — por sección del expediente.
- `GET /documentos/auditor` — vista de solo metadatos para auditoría.
- `POST/GET /documentos/reportes` — informes clínicos adjuntos (no confundir con el módulo
  Reportes, que es otra cosa).

### Inventario del Hogar
- `GET/POST/PUT /inventario/items`
- `GET/POST/PUT /inventario/convivientes`
- `GET/POST/PUT /inventario/red-apoyo`

### Control de Alimentos
- `GET/POST /alimentos`
- `PUT /alimentos/{id}` y `PUT /alimentos/{id}/consumido`

### Citas y Recordatorios
- `GET/POST /citas`, `PUT /citas/{id}`, `PUT /citas/{id}/estado`
- `GET /citas/proximas`

### Alertas y Evasiones
- `POST /alertas/evasion` — dispara la alerta al defensor y a la psicosocial.
- `GET /alertas`, `GET /alertas/panel`, `GET /alertas/mis-pendientes`
- `PUT /alertas/{id}/visto`, `PUT /alertas/{id}/cerrar`
- `POST /alertas/generar-automaticas` — tarea interna (visitas vencidas, documentos faltantes).
- `GET/PUT /alertas/configuracion/telefono-policia-infancia` — solo `admin`; cambia el número
  mostrado en la pantalla de emergencia sin redesplegar (reemplaza a `POLICIA_INFANCIA_TELEFONO`
  como valor por defecto si nunca se edita).

### Asistente de IA (ADR-0010)
- `POST /ia/consultas` — pregunta en lenguaje natural; cita la fuente o avisa que no sabe (nunca
  llama al LLM externo sin una fuente confiable).
- `GET /ia/consultas`, `GET /ia/consultas/{id}` — historial.
- `GET /ia/menores/{menor_id}/resumen`, `GET /ia/documentos/{id}/resumen`
- `POST /ia/redaccion/apoyo` — apoyo a la redacción de un informe.
- `POST /ia/documentos/clasificar` — clasificación automática al cargar.
- `POST /ia/mantenimiento/reindexar-pendientes`, `GET /ia/estado` — solo admin.

### Reportes
- `GET /reportes/general`, `GET /reportes/zona/{id}`, `GET /reportes/menor/{id}`,
  `GET /reportes/madre/{id}`
- `POST /reportes/exportar`, `GET /reportes/exportados`,
  `GET /reportes/exportados/{id}/contenido` — generar y descargar un informe exportado.

### Archivo y Cierre
- `POST /archivo/menores/{menor_id}/cerrar` — archiva el expediente al egreso (bloquea escritura).
- `GET /archivo`, `GET /archivo/menores/{menor_id}`
- `GET /archivo/menores/{menor_id}/paquete` — descarga del expediente cifrado.

### Auditoría
- `GET /auditoria` — registro de accesos y cambios.

### Sistema
- `GET /health`

## Mantener el contrato al día

Tras cambiar cualquier endpoint del backend:

```
cd backend
python scripts/export_openapi.py
```

y en el frontend:

```
cd frontend
npm run api:types
```

Los tipos del cliente (`frontend/src/app/core/api/schema.d.ts`) se generan siempre desde ahí; no
se editan a mano.
