# ADR-0002 IA y datos de menores

Estado: Propuesta (requiere revisión del agente de seguridad)

## Contexto
Respuestas D1 a D4: la IA busca, resume, clasifica, extrae por OCR, detecta faltantes y apoya la redacción; solo recupera y resume con cita; solo ve lo que el usuario puede ver. D2 permite API externa con datos anonimizados y con datos reales bajo contrato. No hay GPU declarada.

## Decisión
1. Flujo RAG: se filtra por permisos del usuario en PostgreSQL antes de recuperar; solo los fragmentos permitidos llegan al modelo.
2. Toda respuesta incluye cita al documento y versión; sin fuente recuperada, el sistema responde que no encontró información.
3. Por defecto, nada identificable sale a una API externa: nombres, documentos de identidad, direcciones y teléfonos se sustituyen por seudónimos antes de la llamada y se restituyen al responder.
4. Enviar datos reales solo es posible con contrato de tratamiento firmado y habilitación explícita por configuración; cada llamada queda en auditoría.
5. Los documentos cargados se tratan como datos, nunca como instrucciones (defensa contra inyección de prompts).
6. La IA no propone decisiones sobre el NNA; solo resume y señala faltantes e inconsistencias.
7. Se guarda por respuesta: modelo, versión, fuentes usadas y usuario.

## Consecuencias
- Costo y latencia adicionales por la anonimización.
- El OCR sobre documentos escaneados con datos reales requiere una decisión de ejecución local o con contrato; mientras tanto se usan documentos sintéticos.
