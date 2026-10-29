# Registro de decisiones del 29/10/2026

Fuente: llamada de voz con Diego y sesión de texto posterior. Complementa el documento publicado durante la llamada.

## Alcance y negocio
1. El operador de Florencia es la Fundación Fundar; las madres sustitutas son voluntarias afiliadas. La norma permite hasta 13 NNA por hogar; en la práctica son 5 o 6.
2. Información que genera el hogar: carpeta por NNA (datos personales, identidad, padre y madre, historial médico y psicosocial, defensor a cargo, actas de traslado), inventario de camas y muebles, personas que viven, red de apoyo, alimentos (fecha de ingreso, perecedero, vencimiento) y reportes de la madre.
3. Módulos planeados: 12 de negocio más Asistente de IA, Auditoría y Archivo y Cierre (`docs/modulos.md`).
4. Zonas: los hogares se agrupan en zonas; los permisos se pueden agrupar por zona.
5. Reportes: general, por zona, por menor y por madre.
6. Citas: el sistema no las asigna, solo recuerda.
7. Evasión: la alerta llega por la aplicación al defensor y a la profesional psicosocial asignados; la pantalla muestra los números de emergencia; se registra quién la recibió y cuándo la vio. Aviso adicional por notificación al celular o SMS: por evaluar. Lo llamado "módulo de evaluaciones" se interpretó como este módulo.
8. Profesionales: el defensor ve solo los NNA que tiene asignados, con un panel propio (opción 1 aprobada); no es un módulo aparte. Se agrega el módulo Profesionales.
9. Seguridad e integridad de los datos: requisito básico.
10. Consentimiento y base legal para tratar datos de menores, incidentes del hogar, capacitaciones de las madres, contacto con la familia biológica y lo escolar: consideraciones planteadas, sin decisión.

## Arquitectura
11. Backend: monolito modular. Frontend: desacoplado, estáticos servidos por Nginx, se despliega sin tumbar el backend (ADR-0005).
12. Contrato entre ambos: API `/api/v1` y archivo OpenAPI; configuración del frontend en `config.json` en tiempo de ejecución.
13. Repositorios: Carpeta_Viva es la carpeta padre y el repositorio de gobierno; backend y frontend son repositorios independientes dentro de ella, ignorados en Carpeta_Viva y clonados aparte con un script de arranque (sin submódulos).
14. Contexto entre repositorios (aprobado): OpenAPI como contrato, `CLAUDE.md` en cada repositorio apuntando a Carpeta_Viva, sesión abierta en Carpeta_Viva, Graphify sobre los tres, cambios cruzados registrados en ADR.
15. Web semántica (ADR-0006): ontología núcleo de 8 clases; Fuseki guarda identificadores y relaciones; la IA es un módulo aparte que consulta por la capa de aplicación; inventario, alimentos y citas se quedan en PostgreSQL por ahora.
16. Graphify (no "GraphFL"): grafo de contexto para desarrollar, distinto de Fuseki; solo sobre código, documentos de diseño y datos sintéticos.
17. Agentes de desarrollo: backend, frontend, datos-infra e ia, además de los cuatro existentes. Diego se encarga del modelo de negocio.
18. Orden de construcción en cinco fases (`docs/plan-por-fases.md`).

## Cambios al implementar
- Volumen recalculado con 5 a 6 NNA por hogar: 175 a 210 NNA simultáneos y 35 000 a 42 000 documentos por año.
- Imagen de Fuseki: `secoresearch/fuseki:6.2.0` (la imagen `stain/jena-fuseki` no se actualiza desde julio de 2024).
- `openapi-typescript` se ejecuta con `npx` y no como dependencia, porque exige TypeScript 5 y Angular 22 usa TypeScript 6.
- Pruebas del backend con `httpx2`, que es lo que recomienda la versión actual de Starlette.
