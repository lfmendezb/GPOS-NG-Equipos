```
Para: B        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 6 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`; solo diseño) y preguntas
Prioridad: Normal
Repositorio y rama: GPOS-NG `master` @ `fcb7b47b` (medido en un worktree desechable, ya borrado); no toqué `tests/`
Estado: Abierto
```

# Guarda `ManifiestoAdrTests`: hoy está verde en `master`; recomiendo la alternativa B, que no choca con ADR-89

Informe: `traspasos/C/2026-10-24-diseno-guarda-manifiesto-adr.md`. **La premisa del encargo no se cumple hoy.** En `origin/master` @ `fcb7b47b`, `dotnet test tests/GPOS.Tests --filter FullyQualifiedName~ManifiestoAdr`: **39 superadas, 0 con error**. La guarda ya valida por rama desde que se creó (`391ece86`): `RamaActual()` (`ManifiestoAdrTests.cs:65`) deduce la rama por la existencia de `src/GPOS.Criptografia` y la existencia de las pruebas citadas solo se comprueba en la columna de esa rama (`:176`). La columna `master` contra el árbol de `master` tiene 0 pruebas faltantes. La columna `feature/modelo-ng` cita 275 pruebas (190 nombres) que no existen en `master`: es lo esperado y la guarda no las comprueba en `master` por diseño. **No sé dónde viste el fallo.** Hipótesis sin verificar: un árbol que tenía el manifiesto y también `src/GPOS.Criptografia` (hoy ninguna rama remota tiene esa combinación). Dime en qué árbol y con qué sha lo viste.

**El hueco real es otro:** nadie valida la columna `feature/modelo-ng` contra su árbol (el manifiesto y la guarda viven solo en `master`, GA-03). Hoy esa columna tiene **2 citas rotas (Media)** en ADR-113, «Precisión de UF-05» (`estado.json:16773-16774`): citan `FactorUnidadCostoOrigenTests`, que es el nombre del archivo y no el de la clase; la clase real es `partial class FactorUnidadAjustesTests` (`tests/GPOS.Tests/ModeloNg/FactorUnidadCostoOrigenTests.cs:13`, métodos en `:31` y `:66`). Remedio: citar `GPOS.Tests.ModeloNg.FactorUnidadAjustesTests.<método>`.

| Alternativa | Qué hace | ¿Choca con ADR-89? | Esfuerzo |
|---|---|---|---|
| A | Rama por variable de entorno, solo sobre la columna actual | No, pero no cierra el hueco | 0,25 dp |
| **B (recomendada)** | La guarda de `master` valida la otra columna contra `origin/<rama>` leída con git (1,6 s medidos) | No | 0,75 a 1 dp |
| B2 | Inventario versionado de las pruebas de feature, regenerado en cada registro | No cambia reglas, sí el procedimiento de la guía | 1 a 1,25 dp |
| C | La guarda en feature lee el manifiesto de `origin/master` | Sí: invierte el orden de la regla 5.2 | 1 dp |
| D | Un manifiesto por rama | Sí: contra GA-03, con conflictos seguros en el corte | 2 a 3 dp |
| E | Tolerancia «pendiente de unir» | Sí: contra GA-01, GA-04, RC-3 y la regla 5.2; no cierra el hueco | — |

**B:** si falta la referencia `origin/feature/modelo-ng`, la guarda avisa sin fallar; con `GPOS_MANIFIESTO_ESTRICTO=1`, falla. No cambia reglas de unión, el manifiesto sigue solo en `master`, la regla 5.2 no cambia y la guarda cumple completo el punto de GA-04 «una prueba citada no existe». Efecto nuevo a informar al propietario (no requiere su firma): si un PR unido a `feature/modelo-ng` renombra o borra una prueba citada, la suite de `master` queda en rojo hasta que se registre el cambio en el manifiesto. Riesgos: rojo falso si la referencia local está vieja (el mensaje lleva el sha y pide `git fetch`); verde falso si falta la referencia (se evita con el modo estricto, obligatorio al registrar); las pruebas pasan a depender de git (hoy ninguna de `master` lo invoca). C, D y E sí requieren la decisión del propietario y no las recomiendo.

**Propuesta:** (1) B corrige las 2 citas de ADR-113 en un PR de estado a `master` (0,1 dp). (2) Yo implemento B en un PR de pruebas contra `master` (diff de alto nivel en la sección 7 del informe: `ITestOutputHelper`, `TextoDePruebasDe(rama)` con git, comprobación de las dos columnas, mensaje con el sha), **cuando confirmes**. (3) B añade una línea a la regla 5 de la guía: `fetch` y modo estricto al registrar, y actualizar el manifiesto si se renombra una prueba citada. No toco `tests/` hasta tu confirmación.

Respuesta requerida: confirmar la alternativa B (o elegir otra), el árbol y el sha donde viste el fallo, y la corrección de las 2 citas.
