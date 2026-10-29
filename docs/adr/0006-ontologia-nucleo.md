# ADR-0006 Ontología núcleo

Estado: Aceptada para el avance del 30/10/2026; se amplía por fases

## Contexto
La ontología completa aún no está definida. Se parte del modelo ER (`Contexto/ICBF.pdf`) y de `Contexto/SistemaICBF.rdf`. Diego pidió solo lo principal y básico por ahora.

## Decisión
- Ocho clases: Menor, Madre_sustituta, Hogar_sustituto, Zona, Asignacion, Profesional, Reporte, Documento (`ontologia/core.ttl`, espacio de nombres `http://www.sistemaicbf#`).
- Relaciones: la madre tiene un hogar; el hogar pertenece a una zona; el menor se asigna a un hogar mediante una asignación; el profesional atiende al menor; el reporte y el documento tratan sobre el menor y fueron escritos por alguien; el documento lo revisa un profesional.
- El grafo guarda solo identificadores, relaciones y metadatos (estado, fechas, categoría, versión, bandera de sensibilidad). Nunca nombres, documentos de identidad, direcciones, teléfonos, fechas de nacimiento ni contenido.
- Inventario, alimentos y citas permanecen en PostgreSQL por ahora.
- `ontologia/validar.py` valida la ontología y cuatro consultas de competencia sobre datos sintéticos; se ejecuta en cada cambio de la ontología.
- Más adelante: reglas en la ontología, por ejemplo menor sin informe psicosocial en 60 días genera alerta de documento faltante (consulta de ejemplo en `ontologia/consultas.rq`).
- La IA consulta el grafo solo por la capa de aplicación, para que los permisos siempre se apliquen (ver ADR-0002 y ADR-0003).

## Consecuencias
- Mantener sincronizados PostgreSQL y Fuseki (evento por cambio y reconciliación periódica, ADR-0003).
- Los nombres de propiedades difieren de los del RDF original (por ejemplo `escritoPor` en vez de `Escrito_por`); se conservan los nombres de clase.
