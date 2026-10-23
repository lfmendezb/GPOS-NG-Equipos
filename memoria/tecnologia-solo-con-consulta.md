---
name: tecnologia-solo-con-consulta
description: "No elegir ni cambiar una tecnología (framework, runtime, herramienta, versión mayor) sin preguntárselo al propietario; no inferir lo que él sabe o decidió; .NET 10 es su decisión categórica"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 6965fb50-50eb-4ff7-a665-f0391bbc4853
  modified: 2026-10-21T00:20:43.117Z
---

El 2026-10-20 el propietario dijo, tras ver `net472` en el plano del instalador y una respuesta mía que daba por buena la limitación de WiX: «a partir de ahora no se elegirá una tecnología sin consultármela. Puesto que inicialmente fui categórico en utilizar .NET 10. No debes inferir que yo sé algo sin preguntarme antes.» También: «mantendremos los instaladores tal como están» (WiX).

**Why:** los planos de los equipos (A) proponían un proyecto `net472` para una acción DTF de WiX sin pedir su decisión, y yo, al responder, no le pregunté si aceptaba apartarse de .NET 10; además supuse en mensajes anteriores que él conocía ciertos datos técnicos.

**How to apply:**
- Antes de proponer o aceptar un framework, runtime, versión, librería de peso, herramienta de empaquetado o lenguaje distinto de lo ya firmado, preguntarle con opciones, qué rompe y recomendación; esperar su decisión.
- Un default conocido es .NET 10 (la suite corre en `net10.0`): cualquier desvío (p. ej. `net472`, .NET Standard, otro motor) es una decisión suya, no del arquitecto ni mía.
- No dar por hecho que él sabe o ya decidió algo técnico: preguntar. Evitar frases como «como ya sabes» o «según lo firmado» si lo firmado no lo dice con esas palabras.
- Pasar esta regla a los equipos A y C y a los agentes (en sus encargos).
- Ver [[politica-actualizacion-paquetes]] y [[estrategia-acceso-datos-preferida]] para otras decisiones técnicas suyas.
