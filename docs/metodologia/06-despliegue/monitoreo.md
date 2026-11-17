# Monitoreo, respaldos e incidentes

Fecha: 2026-11-17.

Leyenda: [IMPLEMENTADO] existe en el repositorio (no probado en ejecución real); [PROPUESTA] no existe todavía. Pérdida de datos no es tolerable; caídas sí (CLAUDE.md).

## 1. Health checks

| Qué | Cómo | Estado |
|---|---|---|
| Backend | `GET /api/v1/health` (ruta definida en `app/main.py`); healthcheck de compose con `curl -f` cada 10 s, 10 reintentos | [IMPLEMENTADO] |
| PostgreSQL | `pg_isready` cada 10 s en compose | [IMPLEMENTADO] |
| Fuseki | Sin healthcheck; compose solo espera `service_started` | [PROPUESTA] probar `GET /$/ping` |
| Frontend | Sin healthcheck propio; probar `GET /config.json` | [PROPUESTA] |
| Dokploy | Healthcheck por app en el panel | [PROPUESTA] configurar |
| Disponibilidad externa | Monitor externo (por ejemplo, un servicio de ping gratuito) sobre `https://<dominio>/api/v1/health` | [PROPUESTA] |

Nota: el endpoint `health` devuelve solo el estado del proceso; no comprueba base de datos ni Fuseki. [PROPUESTA] agregar comprobación de dependencias (coordinar con el agente `backend`).

## 2. Logs

- Backend y demás servicios escriben a salida estándar: `docker compose logs -f <servicio>` (local) o pestaña de logs de la app en Dokploy [IMPLEMENTADO por defecto de Docker].
- Rotación: configurar `max-size`/`max-file` del driver de logs de Docker para no llenar el disco [PROPUESTA].
- Auditoría de accesos: tabla `auditoria_accesos` en PostgreSQL (RF11). Es registro funcional, no sustituye a los logs técnicos. No particionada por fecha [PENDIENTE].
- No registrar contenido de documentos ni datos de menores en los logs.

## 3. Métricas mínimas [PROPUESTA]

Ninguna métrica se recolecta hoy. Mínimo recomendado, revisable en el panel de Dokploy o con comandos:
- Disponibilidad y tiempo de respuesta de `/api/v1/health`.
- CPU, memoria y disco del VPS; disco del volumen de archivos (crecimiento esperado de 35 000 a 42 000 documentos por año).
- Tamaño de PostgreSQL y de `auditoria_accesos`.
- Conexiones activas a PostgreSQL (objetivo 1000 usuarios simultáneos, a validar con prueba de carga).
- Tasa de errores 5xx y de fallos de inicio de sesión.
- Cola de indexación de IA pendiente (umbral `IA_INDEXACION_PENDIENTE_UMBRAL_MINUTOS`, que ya genera una alerta funcional).
- Antigüedad del último respaldo exitoso.

## 4. Respaldos diarios [PROPUESTA: ningún respaldo está implementado]

El repositorio solo define volúmenes (`pgdata`, `fuseki_databases`, `fuseki_configuration`, `fuseki_backups`, `archivos`); no hay script ni tarea programada de respaldo. Los volúmenes por sí solos no son respaldo.

| Dato | Método propuesto | Frecuencia |
|---|---|---|
| PostgreSQL | `pg_dump -Fc` (por ejemplo `docker compose exec -T postgres pg_dump -U <POSTGRES_USER> -Fc <POSTGRES_DB> > respaldo.dump`) | Diario |
| Archivos cifrados | Copia incremental del volumen `archivos` (rsync o restic) | Diario |
| Fuseki | Endpoint de backup de Fuseki (`POST /$/backups/ds`, escribe en `/fuseki-base/backups`) o copia de `fuseki_databases`; el grafo es reconstruible desde PostgreSQL (sincronización por eventos y reconciliación, por implementar) | Diario |
| Secretos críticos | `ARCHIVOS_CLAVE_MAESTRA` y `JWT_SECRET` guardados aparte en un gestor de secretos | Al cambiar |

Reglas propuestas:
- Destino fuera del VPS (otro proveedor o almacenamiento de objetos) con cifrado; retención por ejemplo 7 diarios, 4 semanales, 6 mensuales.
- Respaldar la clave maestra: sin ella los archivos cifrados respaldados no se pueden leer.
- Los respaldos contienen datos de menores: mismo nivel de protección y acceso restringido (revisión de `seguridad`).
- Alerta si un respaldo falla o no se ejecuta.

### Prueba de restauración [PROPUESTA, no ejecutada]
Hacerla en un entorno aparte con datos sintéticos, al menos antes del primer uso real y luego cada trimestre:
1. Levantar un stack limpio (`docker compose` en otra carpeta o máquina).
2. PostgreSQL: crear la base y ejecutar `pg_restore -d <POSTGRES_DB> --clean --if-exists respaldo.dump`; comprobar `alembic current` = head y conteo de filas de tablas clave.
3. Archivos: restaurar el volumen; abrir un documento sintético desde la aplicación (valida clave maestra y descifrado).
4. Fuseki: restaurar la base o reconstruir el grafo desde PostgreSQL; ejecutar las consultas de competencia (`ontologia/validar.py`).
5. Registrar fecha, duración, tamaño, resultado y responsable en un acta; medir el tiempo de recuperación obtenido.

## 5. Incidentes y corrección

Procedimiento [PROPUESTA]:
1. Detectar: alerta del monitor, reporte de usuario o logs.
2. Clasificar: disponibilidad (caída), integridad/pérdida de datos, o seguridad/privacidad. Cualquier incidente con datos de menores se notifica de inmediato a `seguridad` (posible obligación de reporte bajo la Ley 1581; la base legal sigue abierta en CLAUDE.md).
3. Contener: si es seguridad, rotar `JWT_SECRET` (invalida sesiones) y claves de API; si es despliegue defectuoso, revertir (ver `manual-instalacion.md`, sección 4).
4. Diagnosticar: `docker compose ps`, logs del servicio, espacio en disco, estado de PostgreSQL y de las migraciones (`alembic current`).
5. Corregir: arreglo en `backend`/`frontend` con prueba que reproduzca el fallo; migraciones primero; desplegar por la vía normal.
6. Recuperar datos si hubo pérdida: restaurar el último respaldo (sección 4).
7. Cerrar: registro del incidente (causa, impacto, línea de tiempo, acción preventiva) y, si cambia una decisión, ADR en `docs/adr/`.

Fallas frecuentes previstas:
- Backend no arranca en producción: `JWT_SECRET` o `ARCHIVOS_CLAVE_MAESTRA` con valor de desarrollo.
- Backend no arranca: fallo de migración o PostgreSQL sin extensión `vector`.
- Frontend sin conexión a la API: `CORS_ORIGINS` incorrecto o regla `Path` `/api` mal configurada en Traefik.
- Frontend muestra accesos rápidos de desarrollo: `ACCESOS_RAPIDOS_DESARROLLO` en `true`.

## 6. Checklist posterior al despliegue

- [ ] `https://<dominio>/` carga y el certificado HTTPS es válido.
- [ ] `https://<dominio>/api/v1/health` responde correcto.
- [ ] `https://<dominio>/config.json` muestra `apiUrl` `/api/v1` y `accesosRapidosDesarrollo` en `false`.
- [ ] Inicio de sesión funciona; el token expira según lo previsto.
- [ ] `alembic current` coincide con la revisión head esperada.
- [ ] PostgreSQL (5432) y Fuseki (3030) NO responden desde internet (probar desde fuera).
- [ ] Volumen de archivos persistente: subir un documento sintético, redesplegar el backend y comprobar que sigue accesible.
- [ ] `ENVIRONMENT=production`; no se ejecutó el seed de demo; sin credenciales de demo.
- [ ] Un respaldo de PostgreSQL y de archivos se ejecutó y se probó su restauración.
- [ ] El webhook `DOKPLOY_DEPLOY_WEBHOOK` está configurado y un push a `main` redespliega solo la app correspondiente.
- [ ] Las cabeceras de seguridad de Nginx están presentes (`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`).
- [ ] Alerta de monitor externo activa.
