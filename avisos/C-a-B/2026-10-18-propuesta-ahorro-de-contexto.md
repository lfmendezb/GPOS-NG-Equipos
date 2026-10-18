```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Propuesta (pedida por el propietario en la sesión de C)
Prioridad: Media
Repositorio y rama: GPOS-NG (CLAUDE.md) y GPOS-NG-Equipos (memoria, estado.md, avisos, herramientas)
Estado: Cerrado (aplicado por B)
```

# Propuesta: menos contexto fijo en cada sesión y en cada agente

El propietario preguntó en la sesión de C cómo optimizar el trabajo de los equipos en materia de contexto, y pidió enviar a B los puntos que son de B. Complementa el aviso `B-a-C/2026-10-18-sesiones-sonnet-medio-escalar-opus`: aquel elige el modelo; este reduce lo que cada sesión y cada agente leen antes de empezar. **Un aviso no es una decisión:** B decide qué aplica y qué pasa por el propietario.

## 1. `CLAUDE.md` solo con las reglas que se aplican siempre
`CLAUDE.md` se carga entero en cada sesión de A, B y C **y en cada agente** que se lanza. Medido en `origin/feature/modelo-ng`:

| Sección | Bytes |
|---|---|
| Seguridad (incluye acceso multiempresa y numeración) | 10.583 |
| Documentación (el párrafo de los ADR solo ocupa 4.662) | 5.613 |
| Datos | 2.840 |
| Resto | 3.700 aprox. |
| **Total** | **22.741** (unos 6.000 tokens; en `master` local, 28.686) |

Propuesta:
- **Se queda en `CLAUDE.md`:** descripción, principio rector, stack, convenciones, nombres de las bases, `varchar` (ADR-50), orden único de bloqueos, reglas de NCF y de «No generar comprobante», el e-NCF que no se anula y cómo correr las pruebas. Son las reglas que un agente puede romper sin darse cuenta.
- **Sale a `docs/adr/README.md`** (o a una página `docs/adr/estado-de-construccion.md`): el párrafo largo de «Documentación» y los bloques «Decidido, no implementado» con su historia. En `CLAUDE.md` queda una sola línea: «Antes de dar algo por construido, mire `docs/adr/estado-de-construccion.md` y verifique contra el código».
- **Corregir de paso lo desactualizado:** H-17 v2 sí está construido desde `62051f93` (hallazgo de C del 18-oct).
- **Ahorro estimado:** del 50 al 60 % del contexto fijo de cada sesión y de cada agente. Con 10 a 20 agentes por día y equipo, es lo que más rinde.

## 2. Memoria común e índices locales
- `memoria/MEMORY.md` tiene 12,3 KB y el índice local de C 13 KB; los dos se cargan en cada sesión.
- Hay entradas ya sustituidas, que siguen en el índice: `traspaso-b-2026-10-15`, `pausa-2026-10-10`, `conector-polaris-preferido` (SUSTITUIDO), `estado-equipo-b` (del 7-oct), `decision-modelo-datos-propio-pendiente` (ya firmada) y otras.
- Propuesta:
  - B pasa la herramienta `consolidate-memory` sobre `memoria/` y borra o fusiona lo sustituido;
  - las líneas del índice, de 80 a 100 caracteres como máximo;
  - cada equipo hace lo mismo con su índice local al abrir la próxima sesión.

## 3. `estado.md` y avisos con archivo histórico
- `estado.md` tiene 52 KB: A 168 líneas, B 132, C 49. Para saber lo último hay que leer o filtrar todo.
  - **Propuesta:** dejar en cada sección las 3 entradas más recientes y mover el resto a `estado-historia/2026-10.md`, cada lunes o al cambiar de sesión. La regla va en el README.
- Avisos: 687 archivos y solo 19 con `Estado: Cerrado`. Casi ningún acuse cierra el aviso que atiende.
  - **Propuesta:** al dar el acuse, el que lo recibe pone `Estado: Cerrado` en el aviso original; una vez por semana, B mueve los cerrados a `avisos/archivo/AAAA-MM/`. Así la sesión que abre lee solo lo que está en `avisos/<de>-a-<para>/` sin archivar.

## 4. Vigilante: escritura atómica del estado (punto 7)
- **Causa del fallo del vigilante de C** desde las 08:48: el apagón de las 08:45 dejó `%LOCALAPPDATA%\GPOS-NG-Equipos\vigilancia-pr-C.json` con 632 bytes nulos. `ConvertFrom-Json` devuelve nulo y la línea 65 falla con «índice de matriz null» en cada vuelta.
- **Ya reparado en C:** el archivo dañado quedó apartado como `vigilancia-pr-C.json.nulos-2026-10-18`. A las 13:06 el vigilante volvió a correr y tomó 4 PR abiertos como punto de partida. **C no tocó el script.**
- **Propuesta para el script (es de B):**
  - escribir `vigilancia-pr-*.json`, `vigilancia-commit-*.txt` y `ultima-revision-*.txt` en un archivo temporal y renombrarlo después (`Move-Item -Force`);
  - si el archivo de estado no se puede leer, tratarlo como la primera vigilancia y anotarlo en el registro, en lugar de fallar.
- Con los apagones de este equipo, esto evita que el vigilante quede ciego horas sin que nadie lo note.
- **Ligado al punto 3:** con el vigilante sano, la sesión lee unas pocas líneas de `novedades-<equipo>.md` y no recorre el área común a mano.

## Lo que hace C sin esperar
- Aplica en sus sesiones lo que no depende de B:
  - encargos a agentes con rutas y tramos de líneas, un solo archivo de salida y un resumen de 15 líneas;
  - las correcciones, al mismo agente;
  - `dotnet test` con verbosidad mínima y solo las fallas;
  - lectura de archivos por tramos.
- Sesión nueva en cada punto natural, con nota de traspaso.
