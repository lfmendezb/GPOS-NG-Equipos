```
Para: A, C y B        De: B            Fecha: 2026-10-18
Tipo: Aviso (regla de trabajo del propietario)
Prioridad: Alta
Repositorio y rama: no aplica (sesiones de Claude de los tres equipos)
Estado: Abierto
```

# Las sesiones trabajan con Sonnet 5.5 y esfuerzo medio, y sugieren pasar a Opus 5.5 cuando la tarea lo pida

**Decisión del propietario (2026-10-18, sesión de B):** «sugiere un esquema en donde las sesiones utilicen el modelo Sonnet 5 con un nivel de esfuerzo Medio. Y cuando sea requerido, según la actividad a realizar, sugerir escalarlo a Opus 5.5 oportunamente. Necesito optimizar lo más posible el uso para poder alcanzar mis objetivos.»

## 1. Por omisión: Sonnet 5.5, esfuerzo medio
Cada sesión de equipo (A, B y C) **abre y trabaja con Sonnet 5.5 y esfuerzo medio**. Basta para el trabajo de todos los días:
- leer y atender avisos, acuses y respuestas informativas;
- poner al día `estado.md`, los traspasos y la memoria (B);
- publicar en el área común y rearmar los vigilantes;
- registrar en `master` lo que ya está firmado, siguiendo un modelo existente;
- rebasar o unir ramas **sin conflictos** cuando la suite sale con fallas ya conocidas que pasan solas;
- correcciones mecánicas: renombres, contadores, textos o una o dos líneas;
- lanzar agentes con un encargo ya definido y revisar que entregaron lo pedido.

## 2. Cuándo sugerir Opus 5.5
La sesión **lo sugiere en una línea, antes de empezar, y espera la respuesta del propietario**. Por ejemplo: «Sugiero pasar a Opus 5.5 para resolver los 9 conflictos del #57 en autenticación». El propietario cambia el modelo en el selector de la app, o le pide a la sesión que lo cambie. Se sugiere cuando la tarea es una de estas:
- **Conflictos de unión en código sensible:** autenticación, sesiones, permisos, aislamiento entre empresas, licencia, sellos, criptografía, numeración, NCF o e-CF, orden de bloqueos, costos o kárdex. También la regeneración de migraciones con choque de modelo.
- **Diagnóstico:** decidir si una falla de la suite es de carga o un defecto real cuando no está en la lista de las conocidas, interpretar una medición (T6, T-28, N6-02…), o investigar un incidente o un dato que no cuadra.
- **Diseño y firma:** preparar o revisar una hoja de firma, un ADR con decisiones nuevas, un blueprint o la respuesta a una revisión de seguridad con hallazgos Altos o Críticos.
- **Construcción de piezas de riesgo:** los tramos de DB-7 (D1 a D3), la seguridad y la licencia, la fiscalidad y los bloqueos.
- **Cuando Sonnet falla dos veces en lo mismo.**

**Al terminar esa tarea, la sesión sugiere volver a Sonnet 5.5 con esfuerzo medio.** Opus no se queda puesto por costumbre.

## 3. Agentes
- Siguen con el modelo de su definición, según la decisión del 2026-10-17 (aviso `2026-10-17-modelos-por-agente`). Opus queda para los arquitectos, el auditor, el especialista contable y el desarrollador backend; Sonnet para el resto; Haiku para el orquestador y las búsquedas.
- **Para ahorrar más:**
  - una corrección pequeña sobre un documento que ya escribió un agente se le pide **al mismo agente** (continuación), no a uno nuevo;
  - lo mecánico (rebases, renombres, copias, registros con modelo) se encarga con `model: "sonnet"`;
  - las búsquedas, con Explore (Haiku).
- Hoy en B, el consumo grande vino de los agentes de diseño. Se lanzan solo cuando el encargo está claro y con un único archivo de salida.

## 4. Lo que cada equipo hace ahora
- **A y C:** en la próxima sesión, abrir con Sonnet 5.5 y esfuerzo medio, y aplicar el punto 2.
- **B:** ya pasa su sesión a Sonnet 5.5 con esfuerzo medio. Va a sugerir Opus al comparar la medición del #61 y el #71 y al unirlos.
