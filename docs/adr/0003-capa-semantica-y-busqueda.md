# ADR-0003 Capa semántica y búsqueda

Estado: Propuesta

## Contexto
El diagrama define PostgreSQL y Apache Jena Fuseki (triple store, SPARQL). La búsqueda en lenguaje natural requiere además embeddings, que el diagrama no contempla. La ontología aún no está definida; existe `Contexto/SistemaICBF.rdf` como punto de partida.

## Decisión
- Jena Fuseki guarda el grafo de conocimiento: Menor, Madre, Hogar, Asignación, Profesional, Reporte y Documento, con sus relaciones y metadatos. Contiene identificadores y relaciones, no el contenido de los documentos ni datos sensibles en texto.
- PostgreSQL guarda datos transaccionales, historial, permisos, auditoría y los embeddings (extensión pgvector). Así se mantiene un solo motor relacional y no se añade otra base.
- Los archivos originales viven en almacenamiento de objetos cifrado, referenciados por `referencia_archivo`.
- Consultas combinadas: SPARQL resuelve relaciones ("documentos del NNA asignado a este hogar"), pgvector resuelve similitud semántica; el resultado se intersecta con los permisos del usuario antes de llegar a la IA.
- La ontología se construye a partir del RDF existente, con una versión numerada en el repositorio.

## Consecuencias
- Dos almacenes que sincronizar: cada alta o cambio de documento publica un evento interno que actualiza Postgres y Fuseki; se necesita reconciliación periódica.
- Fuseki queda detrás de la API; nunca expuesto a la red pública.
- Pendiente: elegir modelo de embeddings (multilingüe, español) y validar rendimiento con 32 000 documentos por año.
