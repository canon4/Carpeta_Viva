# Cuestionario previo al proyecto

Instrucciones: marca con `[x]` la opción y escribe en `Respuesta:` lo que falte. Si no sabes, escribe "no sé" y el arquitecto propondrá un supuesto que quedará registrado. Lo ya conocido está en `CLAUDE.md` y `Contexto/`, por eso no se pregunta de nuevo.

## A. Alcance y propósito

**A1. ¿Qué tipo de proyecto es?**

- [ x] Trabajo de grado / académico
- [ x] Prototipo para presentar al ICBF u otra entidad
- [ ] Producto para operar en producción real
- [ ] Otro
      Respuesta:

**A2. ¿Quién es el cliente o beneficiario principal y existe un contacto para validar requisitos?**
Respuesta:es el contratista que contrata a las madres sustitutas, son fundaciones que manejan en las ciudades los hogares sustitutos(hs), son los operadores con los que el icbf contrata para el funcionamiento regional de los hs

**A3. ¿Cuál es el resultado mínimo (MVP) que daría por exitoso el proyecto?**
Respuesta:que perimita usarse para la gestion de documentos en los hagares y que la ia ayude a las madres y a los operadores

**A4. ¿Fecha límite o hitos importantes?**
Respuesta: hay que tener un avance el 30 / 10 / 2026 para presentar al docente

**A5. ¿Qué queda fuera del alcance?** (por ejemplo: expediente judicial completo, nómina, contratos)
Respuesta: solo es la oformacion que se genera en los horages sustitutos, informacion de las madres y la informacion de los niños, hay que tener en cuenta que al final del proceso de los niños las la informacion se archiva y se envia a otra parte (aun no esta definicdo como se va hacer)

## B. Documentos y datos

**B1. ¿Qué tipos de documento se gestionarán?**

- [ x] Informes de seguimiento (psicosocial, nutricional, pedagógico)
- [x ] Historias clínicas y salud
- [ x] Documentos de identidad y registro civil
- [ x] Actas de visita, asignación y traslado
- [ x] Documentos de la madre sustituta (habilitación, certificaciones)
- [ x] Fotos y evidencias
- [ x] Otros:
  Respuesta:

**B2. ¿En qué formato llegan hoy?**

- [ x] Papel (requiere digitalización)
- [ x] PDF escaneado
- [ x] PDF con texto
- [ x] Word / Excel
- [ x] Fotos desde el celular
- [ x] Formularios del ICBF (cuáles):
  Respuesta:

**B3. Volumen estimado:** hogares, NNA activos, documentos por NNA y por año.
Respuesta: se estima que hay 35 hogares en floreneica una madre por hogar y 4 a 5 niños por hogar,los niños estan mas o menos 6 meses en promedio en los hogares se estima en pomedio 100 archivos por niño pueden ser mas.

**B4. ¿Hay historial en papel o digital que haya que migrar?**
Respuesta: si, el sistema que manejan actualmente es fisico

**B5. ¿Existe una tabla de retención documental o clasificación oficial que se deba seguir?**

- [ ] Sí (adjuntar o indicar nombre)
- [ ] No
- [ x] No sé
  Respuesta:

**B6. ¿Cuánto tiempo deben conservarse los documentos y cuándo deben eliminarse?**
Respuesta: hasta que se cumpla el proceso de restitucion de derechos, no se debe elimiar solo se oculta a las madres si el niño ya no esta en su hogar

## C. Procesos y usuarios

**C1. ¿Quiénes usarán el sistema?** (marca)

- [ x] Madre sustituta
- [ x] Profesional (psicosocial, nutrición, trabajo social)
- [ x] Defensor de familia
- [ x] Coordinador / administrador
- [ x] Auditor o control interno
- [ ] Otros:
      Respuesta:

**C2. ¿Cuántos usuarios simultáneos aproximados?**
Respuesta: con capacidad de 1000 usuario al mismo tiempo

**C3. ¿Qué flujo de aprobación o revisión tiene un documento hoy?** (quién lo crea, quién revisa, quién firma)
Respuesta:lo crea la madre, los revisasn y aprueban los profesionales

**C4. ¿Se requiere firma (electrónica o digital) o solo registro de aprobación?**

- [ ] Firma electrónica con validez legal
- [ ] Registro de aprobación interno
- [ ] No por ahora
      Respuesta: firma de quien lo presenta (una forma de que ala mdre cargue la firma una sola vez) y los profesionales, cada persona se hace responsabel de la validez de su firma

**C5. ¿Qué alertas son críticas?** (visitas vencidas, documentos faltantes, vencimiento de habilitación)
Respuesta: visitas vencidas, documentos faltantes, citas medicas, visitas, reportes de evasion

## D. Inteligencia artificial y base semántica

**D1. ¿Para qué casos de uso quiere IA?** (marca)

- [ x] Buscar en lenguaje natural ("¿qué dijo el último informe nutricional de X?")
- [ x] Resumir expedientes
- [ x] Clasificar y etiquetar documentos al cargarlos
- [ x] Extraer datos de documentos escaneados (OCR)
- [ x] Detectar documentos faltantes o inconsistencias
- [ x] Apoyar redacción de informes
- [ ] Otros:
      Respuesta:

**D2. ¿Dónde puede ejecutarse la IA?**

- [ ] Solo local / servidor propio (nada sale a terceros)
- [ x] API externa permitida solo con datos anonimizados
- [ x] API externa permitida con datos reales y contrato de tratamiento
- [ ] Aún no definido
      Respuesta:

**D3. ¿Debe la IA ver el expediente completo o solo lo que el usuario tiene permiso de ver?**

- [ x] Solo lo permitido al usuario (recomendado)
- [ ] Todo, con registro
      Respuesta:

**D4. ¿La IA puede proponer decisiones o solo recuperar y resumir con citas?**

- [ x] Solo recuperar y resumir con cita a la fuente
- [ ] También sugerir acciones, siempre con validación humana
      Respuesta:

**D5. ¿Hay recursos para GPU o servidor propio con capacidad para modelos locales?**
Respuesta:

**D6. ¿Cómo se usará el archivo `SistemaICBF.rdf`?** (ontología base de la capa semántica, o solo referencia)

- [ x] Base de la ontología, a extender
- [ x] Solo referencia
  Respuesta: aun no esta establcido, hay que construirlo correctamente

## E. Seguridad y cumplimiento

**E1. ¿Existe política de seguridad o de tratamiento de datos de la entidad que deba cumplirse?**
Respuesta: leyes colombianas

**E2. ¿Dónde deben residir los datos?**

- [ ] Servidor en Colombia
- [ ] Servidor institucional (Universidad / ICBF)
- [ x] Nube pública, región indiferente
- [ ] No definido
      Respuesta:

**E3. ¿Cómo deben autenticarse los usuarios?**

- [x ] Usuario y contraseña
- [ ] Usuario y contraseña + segundo factor
- [ ] Integración con directorio institucional
- [ ] No definido
      Respuesta:

**E4. ¿Quién puede ver datos sensibles (salud, psicología) y quién no?**
Respuesta: los profesionales, las madres, el profesional encargado del menor puede definir que informacion puede o no ver cada persona

**E5. ¿Se requiere trazabilidad de quién consultó cada expediente?**

- [ x] Sí, todo acceso
- [ ] Solo cambios
- [ ] No sé
      Respuesta:

## F. Técnico e infraestructura

**F1. ¿Stack preferido o prohibido?** (lenguajes, framework, base de datos)
Respuesta: fast api,sparkql,angular, postgres

**F2. ¿Dónde se desplegará?**

- [ x] VPS propio
- [ ] Servidor de la Universidad
- [ ] Nube (AWS / GCP / Azure)
- [ x] Local para demostración
  Respuesta:

**F3. ¿Conectividad de los usuarios?**

- [ x] Buena
- [ ] Intermitente (requiere modo sin conexión)
- [ ] Muy limitada
      Respuesta:

**F4. ¿Integraciones necesarias?** (sistemas del ICBF, correo, WhatsApp, firma, calendario)
Respuesta:

**F5. Presupuesto y equipo.** ¿Cuántas personas desarrollan, cuánto tiempo semanal y qué presupuesto mensual de infraestructura hay?
Respuesta: 2 personas, es un proyecto universitario, que dezpues se piede vender

## G. Experiencia de usuario

**G1. ¿Dispositivo principal de la madre sustituta?**

- [x ] Celular Android
- [ ] Celular iPhone
- [ x] Computador
- [ x] Mixto
  Respuesta:

**G2. ¿Nivel de alfabetización digital esperado?**

- [ x] Bajo (necesita guía paso a paso)
- [x ] Medio
- [ ] Alto
      Respuesta:

**G3. ¿Hay lineamientos de marca o imagen institucional que respetar?**
Respuesta: hay que crear una marca propia

**G4. ¿Necesidades de accesibilidad conocidas?** (baja visión, lectura asistida, voz)
Respuesta: baja vision, lectura asustida (opcional, no necesaria ahora)

**G5. ¿Se puede entrevistar o probar con madres sustitutas y profesionales durante el desarrollo?**
Respuesta: con madres ssutitutas, aun no se cuenta con el apoyo de profesionales

## H. Riesgos y calidad

**H1. ¿Cuál es el mayor riesgo que le preocupa?**
Respuesta: perdidad de datos, seguridad de la informacion

**H2. ¿Qué nivel de disponibilidad y respaldo se espera?** (caídas tolerables, frecuencia de copias)
Respuesta: se espera respaldos diarios (evaluar), caidas tolerables

**H3. ¿Hay datos de prueba disponibles o se generan sintéticos?** (por defecto: sintéticos)
Respuesta: sintecticos

**H4. ¿Cómo se medirá el éxito?** (tiempo de búsqueda, reducción de papel, adopción, errores)
Respuesta:tiempo de búsqueda, reducción de papel, reduccion de tiempo en la revision del tiempo
