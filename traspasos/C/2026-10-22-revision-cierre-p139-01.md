Para: B        De: C        Fecha: 2026-10-22
Tipo: Revisión de cierre de hallazgo (P139-01, Alto)
Repositorio y rama: GPOS-NG origin/b/p139-01-estricto @ 7dc690ef (un commit sobre 23176529; toca solo tests/GPOS.Tests/Arquitectura/OrdenProgramaApiTests.cs, +18/-9)
Estado: Abierto

# Cierre de P139-01

**Veredicto: Cerrado** (con cuatro observaciones Bajas; ninguna evasión accidental plausible).

Leí con `git show` y `git diff origin/b/p139-01-estricto~1 origin/b/p139-01-estricto` el commit, la regla S5, el ayudante `ProgramaApiTexto.cs`, `Program.cs` de la API (línea 56), `EscuchaServidor.Preparar` (firma) y `ProgramaWebRedTests.cs`. **No compilé ni ejecuté nada** (ni dotnet, ni SQL, ni pruebas). «Leído» = visto en código; «inferido» = deducido por mutación mental de las expresiones regulares.

## Resumen

| ID | Sev. | Qué |
|---|---|---|
| P139b-01 | Baja | El patrón no está anclado a la lista de argumentos de `Preparar`: busca `ServicioRed.Api , …EsEstricto(builder.Configuration) )` en cualquier parte de la sentencia |
| P139b-02 | Baja | Un `#if` (no DEBUG) dentro de los argumentos de `Preparar` muestra a la prueba solo la primera rama, y la rama `#else` puede compilar `false` |
| P139b-03 | Baja | Ninguna muestra sintética positiva cubre el espacio de nombres completo ni la llamada partida en líneas (solo el `Program.cs` real) |
| P139b-04 | Baja | Web (fuera de P139-01): `Unica` lee texto crudo; un comentario con la línea exacta más una línea real alterada pasaría |

## Qué cierra la regla (leído)

`OrdenProgramaApiTests.cs:176`, sobre `sentencia` (texto limpio de `Preparar` hasta el primer `;`):

`\bServicioRed\s*\.\s*Api\s*,\s*(?:\w+\s*\.\s*)*ComprobacionAnillo\s*\.\s*EsEstricto\s*\(\s*builder\s*\.\s*Configuration\s*\)\s*\)`

Exige, pegado a `ServicioRed.Api,`, el tercer argumento como `[Espacios.de.nombres.]ComprobacionAnillo.EsEstricto(builder.Configuration)` y que lo siga el `)` que cierra `Preparar`. Es decir, exactamente esa expresión, sin nada antes ni después en el argumento. La sentencia sale de `p.Codigo`, que ya viene sin comentarios y con las cadenas vaciadas (`Analizar` → `Limpiar(fuente)` con `vaciarCadenas = true`).

**Positiva contra el real (inferido):** la línea 56 es `Preparar(builder, ServicioRed.Api, GPOS.Core.Infraestructura.Anillo.ComprobacionAnillo.EsEstricto(builder.Configuration));`. `(?:\w+\s*\.\s*)*` consume `GPOS.Core.Infraestructura.Anillo.`, y el `)` final es el de `Preparar`. La variable es `builder` (`Program.cs:30`). Coincide, y `El_arranque_de_red_se_prepara_antes_de_construir…` (línea 384) evalúa S5 sobre el real.

## Las cuatro muestras negativas (líneas 565-568)

Cada una usa `var red =` en el nivel superior, `AgregarArchivoInstalacion` antes, `Preparar` antes de `Build`, `ServicioRed.Api` y sin `UseUrls`. Así, las demás comprobaciones de S5 pasan y solo puede fallar la nueva (`Assert.Equal(cumple, errores.Count == 0)`, línea 596).

| Muestra | Por qué falla de verdad (inferido) |
|---|---|
| `…Api, false)` | tras `Api,` no hay `\w+\.` ni `ComprobacionAnillo`; la `f` de `false` no es `ComprobacionAnillo` |
| `…Api, true)` | igual |
| `…Api, ProteccionDatosWeb.EsEstricto(builder.Configuration))` | `(?:\w+\.)*` consume `ProteccionDatosWeb.` y exige `ComprobacionAnillo`, encuentra `EsEstricto`; retrocede y falla |
| `…Api, ComprobacionAnillo.EsEstricto(otra))` | falla en `builder` (es la mutación «otra configuración») |

Las muestras positivas (561 y 593) y las 5 condicionales de S4-04 se reescribieron con la expresión exacta; así siguen probando solo lo suyo (antes usaban `e`, que ahora fallaría por la regla nueva). Las dos positivas pasan, las negativas fallan: coherente.

## Mutación mental sobre el patrón

| Evasión | Resultado | Nota |
|---|---|---|
| `true` / `false` literal | Detectada | muestras 565-566 |
| `!ComprobacionAnillo.EsEstricto(…)` | Detectada | tras la coma debe venir `\w`; `!` no coincide |
| `x && ComprobacionAnillo…` / `x \|\| …` | Detectada | `x &&` no es `(\w+\.)*` |
| `ComprobacionAnillo.EsEstricto(builder.Configuration) && x` (o `\|\|`, `? :`, `== false`) | Detectada | tras el paréntesis de `EsEstricto` se exige el `)` de `Preparar` |
| Variable intermedia `var e = …; Preparar(…, e)` | Detectada (cierra en falso: rechaza un uso válido) | falla cerrada; el aviso dice qué escribir |
| `EsEstricto(otraConfig)` | Detectada | muestra 568 |
| Con y sin espacio de nombres completo | Aceptadas, correcto | `(?:\w+\.)*` |
| Alias `using A = …ComprobacionAnillo; A.EsEstricto(…)`, `using static`, `global::…` | Rechazadas (cierra en falso) | no hay `ComprobacionAnillo` o hay `::` |
| Argumento con nombre `estricto: …` o `servicio: …` | Rechazado (cierra en falso) | `estricto:` no es `\w+\.`; el `Api,` deja de aparecer pegado a la coma en la reordenación |
| Llamada partida en varias líneas | Aceptada, correcto | `\s*` en todas las uniones |
| Comentario o cadena con la expresión | No engaña | la sentencia está limpia: comentarios en blanco, cadenas vacías (incluidas interpoladas y crudas) |
| Quinto argumento `fuente` (`, fuente)`) | Rechazado (cierra en falso) | la firma pública es `(builder, servicio, estricto, fuente = null)`; el patrón exige `)` pegado |
| `#if` alrededor de toda la sentencia | Detectada | `NoIncondicional` / `EnIf` (ya existía; muestra 591) |
| Segunda llamada literal a `EscuchaServidor.Preparar` | Detectada | `preparar.Count != 1` devuelve error de inmediato (línea 171) |
| Reasignar `red` | No es de S5, pero lo cubre S8 (`PatronReasignacion`, línea 230) | leído por el nombre y la descripción; no leí su cuerpo entero |
| Llamar a `Preparar` por alias (`using ES = …EscuchaServidor`) o por grupo de métodos | Detectada si es la única (cuenta 0 → error) | si hay una literal correcta y otra por alias, la otra no se cuenta: ver P139b-01 (inferido; improbable) |
| Un `Preparar` dentro de `#if DEBUG` | Detectada | el contenido de `#if DEBUG` se descarta; cuenta 0 |

## Hallazgos

### P139b-01 (Baja) — Patrón sin anclar a la lista de argumentos
**Leído:** la prueba busca el patrón en toda la sentencia, no en el tercer argumento de `Preparar`. **Inferido:** una sentencia como `Preparar(builder, ServicioRed.Web, false, new X(ServicioRed.Api, ComprobacionAnillo.EsEstricto(builder.Configuration)))` contiene el patrón completo (y `ServicioRed.Api`) sin que el tercer argumento sea la expresión. Hay que construirlo a propósito; un cambio accidental no llega ahí. Lo mismo la falta de un anclaje a `Preparar(builder,` hace que el segundo argumento tampoco esté fijado a la posición (el primer chequeo, `ServicioRed.Api`, tiene el mismo alcance). **Propuesta barata:** `ProgramaApiTexto.Argumentos(p.Codigo, preparar[0])` ya existe (R-05); comparar `args[1]` con `ServicioRed.Api` y `args[2]` con el patrón anclado `^…$`. Con eso desaparece también el requisito del `)` final pegado.

### P139b-02 (Baja) — `#if` no DEBUG dentro de los argumentos
**Leído:** `SinDebug` solo trata `DEBUG` y `!DEBUG`; cualquier otro `#if X … #else … #endif` conserva ambas ramas en el texto limpio, y `NoIncondicional` mira la posición de `Preparar` (que queda antes del `#if`). **Inferido:** `Preparar(builder, ServicioRed.Api,\n#if X\nComprobacionAnillo.EsEstricto(builder.Configuration));\n#else\nfalse);\n#endif` hace que la sentencia termine en el primer `;` (la rama buena), mientras que sin definir `X` el compilador toma `false`. Es deliberado, no un descuido, y vale lo mismo para todas las reglas de ese ayudante. **Propuesta:** rechazar cualquier directiva `#` dentro de la sentencia de `Preparar` (una comprobación de una línea sobre el texto original entre sus posiciones), o resolverlo con la propuesta de P139b-01 más esa comprobación.

### P139b-03 (Baja) — Cobertura de variantes legítimas
**Leído:** las dos muestras positivas sintéticas usan la forma sin espacio de nombres y en una línea. El espacio de nombres completo (el caso real) y la llamada partida en líneas solo los ejercita el `Program.cs` real. **Riesgo:** si cambian el `Program.cs` y la regla a la vez, el caso real se prueba solo contra sí mismo. **Propuesta:** una positiva con `GPOS.Core.Infraestructura.Anillo.ComprobacionAnillo…` y otra con saltos de línea entre argumentos. Además el prefijo `(?:\w+\.)*` acepta cualquier nombre antes de `ComprobacionAnillo` (otra clase con ese nombre); es un riesgo teórico, ya cubierto porque el tipo vive en un solo lugar (`GPOS.Core/Infraestructura/Anillo/ComprobacionAnillo.cs`).

### P139b-04 (Baja, fuera de P139-01) — Web: la guarda es sobre texto crudo
**Leído:** `ProgramaWebRedTests` sigue intacto (el commit no toca `tests/GPOS.Web.Tests`; la línea 55 de `src/GPOS.Web/Program.cs` coincide con las tres cadenas fijadas en las líneas 58, 107 y 124 del archivo de pruebas). Fija la línea exacta con `Unica` (una sola aparición). **Inferido:** `Programa()` lee el texto sin quitar comentarios; si alguien cambia la línea real a `false` y deja la línea original en un comentario, `Unica` ve una sola aparición y pasa. No es una evasión accidental; la API, en cambio, ya filtra comentarios. Si se quiere simetría, la Web podría usar la misma limpieza. No bloquea.

## Conclusión

El hueco descrito en P139-01 (un `false` fijo, o cualquier otra expresión, en el tercer argumento de `Preparar` de la API) ahora hace fallar S5, y las cuatro muestras negativas prueban justo esa mutación sin ruido de otras reglas. El patrón es estricto (cierra en falso ante alias, nombres, variables y operadores). Las evasiones que quedan exigen construir texto adrede (P139b-01, P139b-02) y son Bajas.

## Qué no verifiqué
- Nada se compiló ni se ejecutó: no sé si la `Theory` y el `Fact` pasan; el razonamiento sobre las expresiones regulares es mental.
- El comportamiento de `ComprobacionAnillo.EsEstricto` ni de `Preparar` con 4743/4745 en tiempo de ejecución (solo la firma pública y el texto de `Program.cs`).
- El cuerpo completo de S8 y de `NadaTocaLaEscuchaTrasPreparar` (S7).
- Que la prueba de comportamiento de `EscuchaServidor` cubra «Estricto sin modo → 4743».
- La versión de `master` o de `b/…` posterior a `7dc690ef`.

## Recomendación a B
Se puede unir en lo que toca a P139-01. Opcional y barato: P139b-01 con `Argumentos` y P139b-02 en la misma pasada, y las dos positivas de P139b-03. P139b-04 puede ir en cualquier tanda de la Web.
