# ADR-0015: Alimentos y Citas son tareas de la madre; coordinador, profesional y defensor solo registran/consultan

Fecha: 2026-11-14
Estado: Aceptada

## Contexto

El usuario reportó confusión real de tareas, detectada al usar el sistema: en Control de Alimentos y en
Citas y Recordatorios, coordinador podía crear/editar exactamente lo mismo que la madre (ambos usaban
`puede_gestionar_hogar`/`puede_ver_menor` sin distinguir rol), lo que permite que dos personas modifiquen
el mismo dato sin que ninguna sepa cuál es el estado real del hogar o del menor.

Cita del usuario, verbatim, que fija la regla de negocio:

> "el coordinador no debería poder crear la lista de alimentos del hogar, tampoco las citas, esas son
> tareas de las madres únicamente. A los coordinadores, defensores y profesionales, solo ven la
> información como registro y modifican únicamente lo que les corresponde [...] al coordinador no le
> interesa crear las citas, solo ver si se están cumpliendo o no los procesos de los menores, los
> profesionales solo cumplen como si fueran auditor [...] en la vida real la madre gestiona todo lo del
> menor: citas médicas, procesos de educación. El defensor define qué día va a haber cita con la familia
> biológica, y esa notificación le llega a la madre."

Esto es distinto de Inventario (ADR-0014): ahí sí hay una tarea real del coordinador (pedir lo que falta),
separada de la de la madre (confirmar que llegó). En Alimentos y Citas no existe esa tarea del
coordinador: su único interés es de **auditoría** (¿se compró el mercado?, ¿se cumplió la cita?), igual
que profesional y defensor, con una única excepción puntual (la cita con familia biológica).

## Decisión

### 1. Control de Alimentos: escritura exclusiva de madre/admin

`alimentos.application` deja de usar `puede_gestionar_hogar` (que incluye coordinador) para escribir.
Se agrega `_puede_gestionar_alimentos(usuario)`: `rol in (MADRE, ADMIN)`. Afecta `crear_alimento`,
`actualizar_alimento`, `marcar_consumido`, `crear_checklist_item`, `actualizar_checklist_item`,
`comprar_de_checklist`. La lectura (`listar_alimentos`, `listar_checklist_items`) sigue con
`puede_ver_hogar` sin cambios: coordinador (su zona), profesional/defensor (si tienen un menor asignado
en ese hogar) y auditor siguen viendo el registro completo, que es exactamente lo que necesitan para
verificar que el proceso se cumple.

No toca Inventario (convivientes, red de apoyo, pedido/recepción): esa división de tareas ya quedó
resuelta en ADR-0014 y no fue parte de la queja.

### 2. Citas y Recordatorios: escritura por tipo de cita, un solo dueño

Hoy `_puede_escribir` = cualquier rol no auditor que vea al menor (madre, coordinador, profesional,
defensor, admin) puede crear, editar y cambiar el estado de **cualquier** cita. Pasa a depender del
`tipo` de la cita, con un único rol dueño por tipo (además de admin, que conserva acceso total):

| Tipo de cita | Quién la crea / edita / cambia estado |
|---|---|
| `medica`, `psicosocial`, `otro` | Madre (y admin). Son su agenda: ella lleva al menor a las citas. |
| `reunion_familia` | Defensor (y admin). Es quien decide la fecha de la visita con la familia biológica. |

Coordinador y profesional (salvo el caso `reunion_familia` del defensor) pierden toda escritura sobre
citas: ya no crean, editan ni cambian estado de ninguna. Su rol pasa a ser estrictamente de lectura
— `_puede_ver` no cambia — para verificar si el proceso del menor se está cumpliendo, que es el caso de
uso real que describió el usuario ("al coordinador no le interesa crear las citas, solo ver si se están
cumpliendo").

La "notificación a la madre" que menciona el usuario no requiere una funcionalidad nueva: la madre ya
puede ver, con `puede_ver_menor`, cualquier cita de sus menores (incluida `reunion_familia` creada por el
defensor) en `GET /citas` y `GET /citas/proximas` — eso ya cumple RF15 ("el sistema no asigna, solo
recuerda"). Un aviso push/SMS adicional sigue siendo el punto abierto 7 de `CLAUDE.md`, sin cambios.

El `tipo` de una cita es inmutable tras crearla (`CitaUpdate` no lo incluye), así que el dueño de una cita
no cambia después de creada: no hay caso de "se crea como médica y alguien intenta convertirla en
reunión familiar para tomar el control".

### 3. Consecuencia para el frontend

`citas-lista.ts`: el formulario "Registrar cita" se muestra solo a madre/admin, con el `<select>` de tipo
limitado a `medica`/`psicosocial`/`otro`; a defensor/admin se les muestra un formulario separado y más
simple, limitado a `reunion_familia` (sin selector de tipo, porque solo pueden crear ese). Coordinador y
profesional no ven ningún formulario de creación, solo la lista (ya lo que necesitan). El botón
"Marcar cumplida"/"Marcar no asistió" se muestra solo al dueño del tipo de esa cita en concreto (madre
para médica/psicosocial/otro, defensor para reunión_familia), nunca a quien solo lee.

`alimentos.ts`: el formulario "Registrar ingreso", "Registrar producto habitual", "Comprar de nuevo" y
los botones "Marcar como consumido"/"Ya no compro este producto" se muestran solo a madre/admin.
Coordinador/profesional/defensor/auditor ven la lista completa (alimentos y checklist) sin ningún control
de escritura, apoyándose en el 403 genérico ya existente como respaldo si de todas formas llega una
petición (defensa en profundidad, igual que en ADR-0013/0014).

Esto es un cambio de permisos, no de datos de menores (Citas sí referencia `menor_id` y campos
sensibles vía `notas`, por lo que pasa de todas formas por `seguridad` antes de cerrarse, siguiendo la
regla de `CLAUDE.md`).

## Consecuencias

- Elimina la doble edición sin visibilidad del estado real que reportó el usuario: en Alimentos y Citas
  hay exactamente un rol que escribe cada dato, el resto solo lee.
- Coordinador, profesional y defensor (salvo su única tarea propia) quedan en un rol de auditoría de
  facto sobre estos dos módulos, consistente con cómo ya se comportan en Menores y Expedientes.
- Si en el futuro aparece una tarea real adicional de coordinador/profesional en estos módulos (como
  "pedido" en Inventario), se añade igual que ahí: un caso explícito, no una ampliación general del
  permiso de escritura.
- Las pruebas existentes de `alimentos`/`citas` que crean datos como coordinador o profesional deben
  ajustarse a madre/admin (o defensor para `reunion_familia`), y se agregan pruebas 403 para los roles
  que pierden escritura.
