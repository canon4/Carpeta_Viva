# Brief de diseño para Google Stitch

Insumo para generar mockups con Google Stitch. Copiar las secciones que necesites como prompt; cada pantalla trae su propia descripción lista para pegar.

## 1. Producto

Sistema de gestión documental para hogares sustitutos (ICBF / operador Fundación Fundar, Florencia). Digitaliza el expediente físico de cada niño, niña o adolescente (NNA) y la información propia de cada hogar (inventario, alimentos, citas), con permisos por rol y por expediente. Nombre de marca: por definir.

## 2. Usuarios y roles

| Rol | Quién es | Qué necesita ver |
|---|---|---|
| Madre sustituta | Cuida a los NNA en su hogar | Sus NNA asignados, documentos propios por cargar, inventario, alimentos, citas, alertas |
| Profesional (psicosocial, nutrición, trabajo social) | Atiende a los NNA que tiene asignados | Panel con sus NNA agrupados por hogar y zona, documentos por revisar/aprobar, alertas, próximas citas |
| Defensor de familia | Responsable legal del proceso de cada NNA | Igual que profesional, más alertas de evasión con números de emergencia |
| Coordinador | Administra una zona | Lo mismo que profesional para su zona, más hogares, madres y profesionales |
| Auditor | Control interno | Auditoría, documentos y reportes, solo lectura |

No hay una app distinta por rol: es la misma aplicación, cada rol ve un subconjunto de menú y datos.

## 3. Principios y restricciones de diseño

- **Móvil primero.** La madre sustituta usa celular; el resto puede usar computador.
- **Alfabetización digital baja a media.** Textos claros y cortos, poca jerga, pasos guiados, confirmaciones explícitas antes de acciones importantes.
- **Accesibilidad WCAG 2.1 AA.** Contraste alto, tamaños de texto grandes, soporte para baja visión, opción de lectura asistida.
- **Sin emojis. Íconos SVG simples**, con significado claro sin depender solo del color (ej. alertas no solo en rojo).
- **Tono institucional, cálido y sobrio** — es información sensible de menores, no debe verse como una app de consumo.
- **Paleta:** aún no definida; usar colores neutros (grises, azul institucional) y un color de alerta reservado solo para evasiones y vencimientos.
- **Datos de ejemplo:** siempre sintéticos (nombres ficticios), nunca datos reales de menores en los mockups.

## 4. Estructura de navegación

Login → Shell con menú lateral/inferior según rol → Panel (inicio) → módulos. Carga diferida por módulo, cada uno con su propia sección.

Módulos visibles por rol (de `frontend/src/app/core/navegacion.ts`):

1. Zonas y Hogares — coordinador, admin
2. Madres Sustitutas — coordinador, admin
3. Profesionales — coordinador, admin
4. Menores y Expedientes — madre, profesional, defensor, coordinador
5. Asignaciones y Traslados — profesional, defensor, coordinador
6. Gestión Documental — madre, profesional, defensor, coordinador, auditor
7. Inventario del Hogar — madre, profesional, coordinador
8. Control de Alimentos — madre, profesional, coordinador
9. Citas y Recordatorios — madre, profesional, defensor, coordinador
10. Alertas y Evasiones — madre, profesional, defensor, coordinador
11. Reportes — profesional, defensor, coordinador, auditor, admin
12. Asistente de IA — madre, profesional, defensor, coordinador
13. Archivo y Cierre — profesional, coordinador, admin
14. Auditoría — auditor, admin

## 5. Pantallas a diseñar (prompts por pantalla)

### 5.1 Inicio de sesión
"Pantalla de login institucional, móvil primero, para una app de gestión documental de hogares sustitutos. Campos de usuario y contraseña, botón grande 'Iniciar sesión', texto de ayuda para quien olvidó su contraseña, sin logo definido todavía (usar un espacio reservado). Tono cálido y sobrio, alto contraste."

### 5.2 Panel de inicio (madre sustituta)
"Panel de inicio para una madre sustituta en celular. Muestra tarjetas grandes con los NNA que tiene a cargo (nombre, foto genérica, edad), alertas pendientes arriba de todo, accesos directos a 'Documentos por cargar', 'Inventario', 'Alimentos', 'Próximas citas'. Texto claro, pocos pasos, íconos simples sin emojis."

### 5.3 Panel de inicio (profesional / defensor)
"Panel de inicio para un profesional o defensor de familia. Lista de NNA asignados agrupados por hogar y zona, con indicador de alertas pendientes y documentos por revisar en cada uno. Filtro por zona y hogar. Próximas citas en una franja lateral o inferior."

### 5.4 Panel de inicio (coordinador)
"Panel de coordinador de zona: resumen de hogares y madres de su zona (ocupación, alertas activas), accesos a gestión de hogares, madres y profesionales, y un resumen de documentos pendientes de revisión en la zona."

### 5.5 Expediente de un NNA
"Vista de expediente de un niño, niña o adolescente: datos personales, foto genérica, datos de identidad, información de padre y madre, historial médico y psicosocial resumido, datos del defensor a cargo, pestañas o secciones para cada categoría. Indicador visible de si el expediente está activo o archivado. Sin mostrar dato sensible real, usar placeholders."

### 5.6 Gestión documental — lista y carga
"Lista de documentos de un expediente con estado (borrador, en revisión, aprobado, devuelto), fecha y quién lo subió. Botón para cargar nuevo documento con opciones: tomar foto, subir PDF, subir Word/Excel. Indicador de versión y de que falta aprobación."

### 5.7 Gestión documental — revisión (profesional)
"Pantalla de revisión de un documento para un profesional: vista previa del documento, metadatos (quién lo subió, cuándo, tipo), botones grandes 'Aprobar' y 'Devolver con comentario', campo de comentario obligatorio al devolver."

### 5.8 Firma única
"Pantalla donde la madre sustituta carga su firma una sola vez (dibujar en pantalla o subir imagen), con aviso claro de que esa firma se usará en todos sus documentos y que ella responde por su validez."

### 5.9 Inventario del hogar
"Lista de inventario del hogar (camas, muebles) con cantidad y estado, botón para agregar ítem, buscador simple. Vista secundaria con las personas que viven en el hogar y la red de apoyo."

### 5.10 Control de alimentos
"Registro de alimentos del hogar: tabla o tarjetas con producto, fecha de ingreso, si es perecedero, fecha de vencimiento, con alerta visual cuando está por vencer o ya venció."

### 5.11 Citas y recordatorios
"Calendario o lista de próximas citas (médicas, psicosociales, reuniones con familia biológica) por NNA, con recordatorio destacado para las citas de los próximos días. El sistema solo recuerda, no asigna horarios."

### 5.12 Alertas y evasión
"Pantalla de alerta de evasión: formulario simple para reportar (NNA, fecha, descripción breve), y pantalla de alerta recibida que muestra de forma muy visible los números de emergencia (Policía de Infancia y Adolescencia, defensor, psicosocial) y quién ya vio la alerta. Prioridad visual máxima, colores de alerta reservados solo para esta pantalla."

### 5.13 Reportes
"Pantalla de reportes con selector de nivel (general, por zona, por NNA, por madre), filtros de fecha, y un reporte mostrado como tabla o gráfico simple con botón de exportar."

### 5.14 Asistente de IA
"Interfaz de búsqueda conversacional dentro del expediente: campo de pregunta en lenguaje natural, respuesta con cita a la fuente (documento y fecha), aviso de que solo busca en lo que el usuario tiene permiso de ver."

### 5.15 Auditoría
"Tabla de auditoría de solo lectura: quién, qué acción, sobre qué expediente, cuándo. Filtros por usuario, fecha y tipo de acción."

## 6. Flujos clave para prototipar en Stitch

1. **Login → Panel según rol** (5 pantallas distintas de panel).
2. **Madre carga documento → Profesional revisa y aprueba o devuelve** (5.6 → 5.7).
3. **Reporte de evasión → Alerta al defensor y psicosocial con números de emergencia** (5.12, ambos lados).
4. **Cierre de caso:** expediente se oculta a la madre, pasa a archivo (pantalla de estado "Archivado").

## 7. Lo que falta decidir (no bloquea los mockups, pero afecta el estilo final)

- Nombre y marca del producto.
- Paleta de colores definitiva.
- Segundo factor de autenticación para profesionales (puede afectar la pantalla de login más adelante).
