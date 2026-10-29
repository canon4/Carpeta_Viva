# ADR-0001 Monolito modular

Estado: Aceptada (según `Contexto/arquitectura.jpeg`)

## Contexto
Equipo de 2 desarrolladores, proyecto académico con posible venta posterior, 35 hogares y capacidad objetivo de 1000 usuarios simultáneos. Stack definido: Angular, FastAPI, PostgreSQL, Apache Jena Fuseki (SPARQL).

## Decisión
Monolito modular de un solo despliegue, con cuatro capas (presentación, aplicación, dominio, persistencia) y módulos con fronteras claras: Madre, Menor, Asignación, Core/Auth. Se agregan como módulos Documento/Reporte, Profesional y Auditoría. Los módulos solo se comunican por casos de uso de la capa de aplicación o por interfaces de repositorio.

## Consecuencias
- Operación simple para un equipo pequeño; un solo despliegue en VPS.
- Escalado horizontal posible replicando el proceso detrás de un balanceador; la carga de IA y OCR se ejecuta como tareas en segundo plano para no bloquear la API.
- Si un módulo crece, puede extraerse después porque las fronteras ya están definidas.

Actualización 29/10/2026: los módulos vigentes están en `docs/modulos.md` (12 de negocio y 3 transversales).
