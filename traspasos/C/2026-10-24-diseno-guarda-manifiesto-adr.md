# Diseño: validar cada columna de `docs/adr/estado.json` contra el árbol de su rama

- **Equipo:** C · **Fecha:** 2026-10-24 (trabajo del 2026-10-23, noche) · **Encargo:** tanda 8, punto 6 de B (`avisos/B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`)
- **Alcance:** solo diseño. No se tocó `tests/` ni el manifiesto, y no se hizo commit ni push.
- **Árboles leídos:** `origin/master` @ `fcb7b47b` y `origin/feature/modelo-ng` @ `1b310591`. Se leyeron con `git show` y `git archive`, sin cambiar el checkout de `GPOS-NG`. La ejecución se hizo en un worktree desechable del scratchpad, ya borrado.

## 1. Resumen

1. **La premisa del encargo no se cumple hoy.** En `master` @ `fcb7b47b` la guarda está **verde**. Lo ejecuté con `dotnet test tests/GPOS.Tests --filter FullyQualifiedName~ManifiestoAdr` y el resultado fue: **39 superadas, 0 con error**. Ese filtro cubre `ManifiestoAdrTests` y `ManifiestoAdrFirmasTests`.
2. **La guarda ya valida por rama.**
   - `RamaActual()` (`tests/GPOS.Tests/Arquitectura/ManifiestoAdrTests.cs:65`) deduce la rama según exista o no `src/GPOS.Criptografia`.
   - La existencia de las pruebas citadas solo se comprueba en la columna de esa rama (`:176`, `if (r == rama && conPruebas)`). La otra columna solo se comprueba en su formato.
   - Esto está así desde el commit que creó la guarda (`391ece86`, 2026-10-18; `git log -S RamaActual`).
   - En `master` no existe `src/GPOS.Criptografia`, así que se valida la columna `master` contra el árbol de `master`, con **0 citas faltantes**.
3. **El hueco real es otro:**
   - **Nadie valida la columna `feature/modelo-ng` contra su árbol.** El manifiesto y la guarda viven solo en `master` (GA-03), y `feature/modelo-ng` no tiene ninguno de los dos.
   - **Hoy hay 2 citas rotas en esa columna** (sección 2.2), que ninguna suite detecta.
4. **Recomendación:** la alternativa B (sección 3).
   - La guarda de `master` valida además la otra columna contra `origin/<rama>` leída con git.
   - Si la referencia no está disponible, avisa sin fallar. Con una variable de modo estricto, falla.
   - **No choca con ADR-89:**
     - no mueve el manifiesto (GA-03);
     - no cambia quién ni cuándo lo actualiza (regla 5.2);
     - cumple literalmente GA-04 («una prueba citada no existe»), que hoy se cumple a medias.
   - **Sí tiene un efecto en el flujo que el propietario debe conocer** (sección 4): un PR unido a `feature/modelo-ng` que renombra o borra una prueba citada pone en rojo la guarda de `master` hasta que se registre el cambio en el manifiesto.
   - Las alternativas C, D y E sí chocan con ADR-89 y requieren su firma.

## 2. Qué falla hoy, exactamente

Medí las citas con una réplica fiel de `ExistePrueba` (`:207`): la misma regla de clase y la misma regla de clase más método. La apliqué al texto de todos los `tests/**/*.cs` de cada árbol, sobre las cláusulas cargadas en estado Implementado o Verificado.

| Columna del manifiesto | Árbol de `master` | Árbol de `feature/modelo-ng` |
|---|---|---|
| `master` | **0 faltantes** (la que la guarda comprueba hoy) | 10 faltantes (no aplica: no es su rama) |
| `feature/modelo-ng` | 275 faltantes, 190 nombres distintos (no aplica: por diseño no se comprueban en `master`) | **2 faltantes** (no los comprueba nadie) |

### 2.1 Pruebas citadas que no existen en `master`

- **En la columna `master`:** ninguna. Ese es el único cruce que la guarda exige en `master`.
- **En la columna `feature/modelo-ng`:** 275 citas no existen en `master`. Es lo esperado, porque son pruebas del modelo nuevo; la guarda no las comprueba ahí y no deben comprobarse. Reparto por ADR:

  5(1), 8(1), 10(1), 11(4), 15(1), 16(2), 17(5), 18(1), 19(1), 26(1), 30(1), 35(1), 38(4), 40(2), 41(1), 45(1), 51(2), 54(2), 58(15), 59(14), 60(4), 62(8), 68(7), 69(5), 70(2), 71(3), 72(3), 77(4), 78(12), 79(4), 81(15), 82(26), 83(18), 84(3), 100(8), 101(3), 103(1), 104(1), 106(1), 109(20), 111(3), 112(2), 113(3), 114(6), 118(19), 119(13), 121(12), 126(8).

**Hipótesis sobre el origen del aviso de B (inferido, no verificado).** Si alguien ejecuta la guarda en un árbol que tiene el manifiesto y también `src/GPOS.Criptografia`, la guarda elige la columna `feature/modelo-ng` y fallaría con las 2 citas de la sección 2.2. Eso pasaría, por ejemplo, en una rama de `master` que incorpore `feature/modelo-ng`.

Hoy ninguna rama remota tiene esa combinación: `03c0afd0`, `origin/b/f1-anillo` y `1b310591` no tienen `estado.json` ni la guarda. Si B vio el fallo, conviene que diga en qué árbol y con qué sha.

### 2.2 Citas rotas en la columna `feature/modelo-ng` (hallazgo, severidad Media)

- **Dónde:** ADR-113, «Precisión de UF-05», `feature/modelo-ng`, Verificado, PR 7. En el manifiesto de `master`, `docs/adr/estado.json:16773-16774`:
  - `GPOS.Tests.ModeloNg.FactorUnidadCostoOrigenTests.La_factura_de_un_conduce_con_costos_distintos_por_linea_toma_el_promedio_del_kardex`
  - `GPOS.Tests.ModeloNg.FactorUnidadCostoOrigenTests.La_factura_desde_un_conduce_guarda_el_costo_del_conduce`
- **Causa:** `FactorUnidadCostoOrigenTests` es el **nombre del archivo**, no el de la clase. En `feature/modelo-ng`, `tests/GPOS.Tests/ModeloNg/FactorUnidadCostoOrigenTests.cs:13` declara `public partial class FactorUnidadAjustesTests`, y los métodos existen en `:31` y `:66`. La prueba existe, pero la cita no la localiza.
- **Remedio (B, como coordinador, en un PR de estado a `master`):** citar `GPOS.Tests.ModeloNg.FactorUnidadAjustesTests.<método>`. Hay que hacerlo **antes** de activar la alternativa B, porque si no, la nueva regla nace en rojo.

## 3. Alternativas

### A. Detección explícita de la rama, solo sobre la columna actual

- **Qué es:** sustituir la heurística de `src/GPOS.Criptografia` por una variable de entorno (por ejemplo, `GPOS_RAMA_MANIFIESTO`) o por un archivo marcador por rama (`docs/adr/.rama`), dejando la heurística como último recurso.
- **Efecto:** solo vuelve robusta la detección en casos raros, como una rama de `master` que incorpore `feature/modelo-ng` o el corte. **No resuelve el hueco:** la columna `feature/modelo-ng` sigue sin validarse, porque la guarda no corre en esa rama.
- **Choque con ADR-89:**
  - con la variable, ninguno;
  - con el archivo marcador, tampoco cambia reglas, pero el archivo marcador choca en cada unión entre ramas y hay que excluirlo a mano, así que lo descarto.
- **Esfuerzo:** 0,25 dp.

### B. Validar la otra columna contra `origin/<rama>` con git (recomendada)

- **Qué es:** la guarda de `master` comprueba su columna contra el árbol de trabajo, como hoy. Además, lee el texto de `tests/**/*.cs` de `origin/feature/modelo-ng` con git y valida contra él la columna de esa rama.
  - En general: para cada columna distinta de la actual, usa la referencia `origin/<columna>`.
  - Es simétrica: si algún día la guarda corriera en el otro lado, validaría `master` contra `origin/master`.
- **Coste:** `git archive origin/feature/modelo-ng tests` extrae 8,7 MB en **1,6 s** (medido). Con `git cat-file --batch`, sin extraer, el coste es parecido.
- **Sin la referencia** (clon sin `fetch`, copia sin `.git` o git ausente):
  - por omisión, **avisa sin fallar** con `ITestOutputHelper`. xUnit 2.9.3 no tiene omisión dinámica sin un paquete nuevo;
  - con `GPOS_MANIFIESTO_ESTRICTO=1`, **falla**. Quien une a `feature/modelo-ng` y registra el estado lo corre en modo estricto.
- **El mensaje de error debe decir** el sha de la referencia usada y «haga `git fetch origin feature/modelo-ng`». Así se distingue una cita rota de una referencia local vieja.
- **Choque con ADR-89:** ninguno en las reglas. El manifiesto sigue solo en `master` (GA-03), quien une lo actualiza en la columna de su rama (5.2), y la guarda pasa a cumplir completo el punto de GA-04 «una prueba citada no existe». Efectos en el flujo: sección 4.
- **Esfuerzo:** 0,75 a 1 dp, incluidas las pruebas de la propia guarda y la mutación (cita inventada en la otra columna, ausencia de la referencia y modo estricto). A eso se suman 0,1 dp de B para corregir las 2 citas.

### B2. Inventario de pruebas de la otra rama, versionado en `master` (variante hermética de B)

- **Qué es:** un archivo generado `docs/adr/pruebas-feature-modelo-ng.txt` con los nombres de clase y método del árbol de `feature/modelo-ng`. Lo regenera un guion en el mismo paso en que se registra la unión, y la guarda valida contra él.
- **Ventajas:** es determinista, no depende de git y nunca da falsos rojos por una referencia vieja.
- **Inconvenientes:**
  - añade un paso y un artefacto generado al flujo de registro;
  - el inventario puede quedar viejo igual que hoy el manifiesto, porque depende de la misma persona: es justo el riesgo Medio que ADR-89 acepta.
  - Es un cambio de **procedimiento de la guía** (regla 5), no de la regla de ADR-89. Lo decide B y conviene informarlo al propietario.
- **Esfuerzo:** de 1 a 1,25 dp (guion más guarda).
- **Por qué la descarto frente a B:** duplica en un archivo lo que git ya da, y cuesta un paso más en cada registro.

### C. Llevar la guarda a `feature/modelo-ng` y leer el manifiesto de `origin/master`

- **Qué es:** la guarda, copiada en `feature/modelo-ng`, lee `estado.json` con `git show origin/master:docs/adr/estado.json` y valida su columna contra el árbol local.
- **Efecto:**
  - toda unión a `feature/modelo-ng` corre la guarda contra el manifiesto de `master`;
  - un PR de feature quedaría en rojo hasta que el PR de estado de `master` se una, y ese PR se hace **después** de unir (5.2). Eso invierte el orden;
  - además, duplica el código de la guarda en dos ramas.
- **Choque con ADR-89:** sí. Cambia el orden de la regla 5.2 (el estado tendría que registrarse antes o a la vez que la unión) y pone la guarda en una rama donde ADR-89 no la ubica. Requiere la firma del propietario.
- **Esfuerzo:** 1 dp, más el roce permanente en cada unión.

### D. Un manifiesto por rama

- **Qué es:** `estado.json` en cada rama, cada uno con su columna, y la guarda en ambas.
- **Choque con ADR-89:** sí, directo con GA-03 («vive solo en `master`»). También cambia la regla 5.2 y la guía: el estado se registraría en la rama de la unión, dentro del mismo PR.
- **Ventajas:** el estado viaja con el código y la validación es local y hermética.
- **Inconvenientes:**
  - dos fuentes, justo la causa de los desfases que ADR-89 quiso eliminar;
  - conflictos garantizados al unir en el corte de la entrega 1;
  - los ADR y su índice solo se registran en `master`, por decisión del 2026-10-06, así que en la rama habría entradas sin archivo.
- **Esfuerzo:** de 2 a 3 dp, más la consolidación en el corte. **No recomendada.**

### E. Tolerancia declarada «pendiente de unir»

- **Qué es:** un campo en la columna (por ejemplo, `"pruebasPendientesDeUnir": true`) que exime de comprobar la existencia.
- **Choque con ADR-89:** sí.
  - Permite declarar Implementado o Verificado con pruebas que no están en la rama, en contra de GA-01 («Verificado: con pruebas citadas que lo demuestran») y de la regla 5.2 (el registro se hace al unir, no antes).
  - Debilita GA-04 y RC-3. Requiere la firma del propietario.
- **Por qué la descarto:** tampoco resuelve el hueco, porque la columna `feature/modelo-ng` seguiría sin validarse.

## 4. Efecto en cada flujo de unión (alternativa B)

| Flujo | Hoy | Con B |
|---|---|---|
| PR a `master` que no toca el manifiesto | Valida la columna `master` | Igual, más la columna `feature/modelo-ng` contra `origin/feature/modelo-ng` (1,6 s). Si la referencia local está vieja y alguien citó una prueba nueva de feature, aparece un falso rojo; el mensaje pide `git fetch` |
| PR de estado a `master` que registra una unión a `feature/modelo-ng` («Estado: efecto de #NNN en feature/modelo-ng») | La columna feature no se valida | Se valida. Hay que hacer `fetch` después de la unión y correr con `GPOS_MANIFIESTO_ESTRICTO=1`. Una cita a una prueba de un PR **aún no unido** falla, y eso es lo que pide la regla 5.2 |
| PR a `feature/modelo-ng` | Sin guarda | Sin guarda (no cambia) |
| PR a `feature/modelo-ng` que renombra o borra una prueba citada | Nadie lo ve | En la siguiente ejecución, la guarda de `master` queda en rojo hasta que se registre en el manifiesto. Es una **obligación que hoy ya existe implícitamente** («actualiza el estado de cada cláusula que el PR toca», regla 5 de la guía), pero ahora se nota en otra rama. Conviene que la guía lo diga en una línea |
| Corte de la entrega 1 (`feature/modelo-ng` entra en `master`) | La heurística cambia a la columna feature y la columna `master` deja de validarse (hoy tendría 10 faltantes contra ese árbol) | Igual, pero la columna `master` se valida contra `origin/master`. En la ventana de GA-07 hay que revisar `Ramas` y la heurística: probablemente queda una sola columna |

## 5. ¿Choca con ADR-89?

- **B (recomendada): no cambia reglas de unión.**
  - GA-03: el manifiesto sigue solo en `master`.
  - GA-04: la guarda cumple completo «una prueba citada no existe».
  - Regla 5.2: no cambia ni quién ni cuándo.
  - Lo único nuevo es que la suite de `master` puede quedar en rojo por un cambio unido a `feature/modelo-ng`. Recomiendo **informarlo al propietario** con la decisión de B; no requiere su firma. Si B prefiere tratarlo como cambio de la guía (regla 5), la línea que añade la guía la aprueba B, porque no cambia el texto de ADR-89.
- **A y B2:** no cambian reglas. B2 sí cambia el procedimiento de la guía.
- **C, D y E: sí chocan** (regla 5.2 y GA-03; GA-01, GA-04 y RC-3) y **requieren la decisión del propietario**. No las recomiendo.

## 6. Riesgos de B

| Riesgo | Severidad | Mitigación |
|---|---|---|
| Falso rojo por una referencia local vieja | Media | El mensaje lleva el sha y pide `git fetch`; el modo estricto solo lo usa quien registra |
| Falso verde por falta de la referencia (clon sin `fetch`, CI futuro superficial) | Media | Aviso visible en la salida; modo estricto obligatorio en el paso de registro (línea en la guía) |
| La suite de `master` depende de git en el `PATH` | Baja | Ninguna prueba de `master` invoca git hoy (búsqueda `"git"` en `tests` @ `fcb7b47b`: 0 resultados). Sin git, se comporta como sin referencia |
| La guarda se vuelve más lenta | Baja | 1,6 s medidos; la lectura se cachea una vez por clase |
| Las 2 citas rotas ponen la guarda en rojo al entrar | Alta si se ignora | Corregirlas antes, o en el mismo PR (sección 2.2) |

## 7. Diff de alto nivel de la prueba (B)

En `tests/GPOS.Tests/Arquitectura/ManifiestoAdrTests.cs`:

```diff
+ public class ManifiestoAdrTests(ITestOutputHelper salida)   // hoy sin constructor
+ private const string VariableEstricta = "GPOS_MANIFIESTO_ESTRICTO";
+
+ /// Texto de tests/**/*.cs de origin/<rama> con `git archive` o `git cat-file --batch`; null si no hay git o referencia. Devuelve también el sha.
+ private static (string? Texto, string? Sha) TextoDePruebasDe(string rama) { ... Process "git" con WorkingDirectory = Raiz() ... }
+
+ private static readonly Lazy<Dictionary<string,(string? Texto,string? Sha)>> Arboles = ...  // la actual, del disco; las demás, de git

  [Fact] Las_clausulas_cargadas_tienen_identificador_estado_y_evidencia()
-     var pruebas = TextoDePruebas();
-     var rama = RamaActual();
+     var rama = RamaActual();
+     var arboles = Ramas.ToDictionary(r => r, r => r == rama ? (TextoDePruebas(), "árbol de trabajo") : TextoDePruebasDe(r));
+     foreach (var r in Ramas.Where(r => arboles[r].Texto is null))
+         if (Environment.GetEnvironmentVariable(VariableEstricta) == "1") errores.Add($"{r}: no se pudo leer origin/{r} (modo estricto)");
+         else salida.WriteLine($"Aviso: sin origin/{r}; su columna solo se comprobó en su formato");
      ...
-     if (r == rama && conPruebas)
-         foreach (var p in i.Pruebas!.Where(p => !ExistePrueba(pruebas, p)))
-             errores.Add($"{donde}, {r}: la prueba «{p}» no existe en este árbol");
+     if (conPruebas && arboles[r].Texto is { } t)
+         foreach (var p in i.Pruebas!.Where(p => !ExistePrueba(t, p)))
+             errores.Add($"{donde}, {r}: la prueba «{p}» no existe en {(r == rama ? "este árbol" : $"origin/{r} @ {arboles[r].Sha} (¿falta git fetch?)")}");
```

Se añaden también:

- **Comentario de la clase:** que la otra columna se valida contra `origin/<rama>` y la referencia a la variable estricta.
- **Pruebas de la guarda:** una cita inventada en la columna ajena falla; una referencia ausente sin modo estricto avisa y pasa; con modo estricto, falla. Se implementan extrayendo el cuerpo a un método que reciba el manifiesto y los textos, para probarlo sin git.
- **Guía de los PR (fuera de `tests/`, la escribe B):** una línea en la regla 5: «al registrar una unión a `feature/modelo-ng`, `git fetch` y correr la guarda con `GPOS_MANIFIESTO_ESTRICTO=1`; un PR que renombra una prueba citada actualiza el manifiesto».

## 8. Recomendación

1. **B corrige las 2 citas de ADR-113** en un PR de estado a `master` (0,1 dp).
2. **C implementa la alternativa B** en un PR de pruebas contra `master` (de 0,75 a 1 dp), con la plantilla y con evidencia: la ejecución verde en `master` y la mutación de una cita.
3. **B añade la línea de la guía** e informa al propietario del nuevo efecto entre ramas (sección 4, cuarta fila). No requiere firma.
4. **Antes de tocar `tests/`, espero la confirmación de B,** como pidió.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-diseno-guarda-manifiesto-adr.md`
- Supuestos: (1) el aviso de B partía de una observación en un árbol distinto de `origin/master` @ `fcb7b47b`, o anterior a él (inferido). (2) Quien registra el estado tiene git y la referencia `origin/feature/modelo-ng` actualizada.
- Decisiones candidatas a ADR: Ninguna con B, porque no cambia reglas de ADR-89. C, D o E serían una precisión de ADR-89 (GA-03 y regla 5.2) y no se recomiendan.
- Entregas a otros agentes: B → corregir `estado.json:16773-16774` (ADR-113, UF-05) a `FactorUnidadAjustesTests`; B → confirmar la alternativa B, añadir la línea de la guía e informar al propietario; B → indicar en qué árbol y con qué sha vio el fallo.
- Próximo paso recomendado: B confirma la alternativa B y corrige las 2 citas, y después C abre el PR de pruebas contra `master`.
