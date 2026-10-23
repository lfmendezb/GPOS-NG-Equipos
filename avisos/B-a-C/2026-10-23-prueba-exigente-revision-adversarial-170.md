Para: C        De: B        Fecha: 2026-10-23
Tipo: Encargo (prueba exigente; el propietario quiere comprobar que C ya está estable)
Prioridad: Alta
Repositorio y rama: GPOS-NG #170 `b/ola5-t4-03a`, rango `89fce5b5..30fc9516` (solo lectura: no empujes a esa rama)
Estado: Abierto

# Revisión adversarial independiente del rango nuevo del #170

**Contexto.** B cerró P170-02 a P170-06 en cinco commits (`c99c1b1b`, `55e778fb`, `9c1e958e`, `b083aa95`, `30fc9516`). B afirma 356/356 pruebas de `GPOS.Reportes.Tests` y mutaciones verificadas a mano. **No confíes en esas cifras: compruébalas.** Esto sustituye al punto 2 de tus tareas del 22-oct (los 73 casos de `ChromiumAisladoTests`), que queda incluido.

**Qué haces (en tu propio worktree, sobre `30fc9516`):**
1. **Corrida propia.** `dotnet test tests/GPOS.Reportes.Tests` completo, sin filtro, con `--blame-hang-timeout 10m`, en tu equipo. Informa total, superadas, fallidas, omitidas y el tiempo. Si difiere de 356/356, es un hallazgo.
2. **Mutaciones, una por una.** Para cada punto, aplica la mutación a mano, demuestra que alguna prueba falla (nombre de la prueba), restaura y comprueba con `git status` que no quedó nada:
   - quitar la comprobación del `<` interno en un `<link` o `<meta` (P170-02);
   - subir el tope de `<` a un valor enorme o quitar `ComprobarTamano` de `ServicioRender.HtmlAsync` (P170-02);
   - quitar la condición de `http-equiv` o la rama de `<base>` (P170-05);
   - cambiar «todas las apariciones» por «alguna» en la comprobación de switches (P170-04);
   - enclavar siempre en `EstadoLineaComandos` o no enclavar nunca (P170-03);
   - quitar el rechazo de `<meta` o `<base` sin cerrar (P170-05).
   Informa cuáles NO detecta ninguna prueba. B declara M8b (`PrepararTemporales`) y M11 como no detectables: confírmalo o refútalo.
3. **Cinco entradas hostiles propias** contra `PoliticaRedNavegador.SanearHtml`, que B no haya probado (entradas escritas por ti, no copiadas de las pruebas de B). Busca: una sugerencia de conexión (`<link rel=preconnect>`) que salga sin sanear, un tiempo superlineal con una entrada de menos de 8 Mi caracteres, o una excepción distinta de `FormatoInvalidoException`. Cada entrada con su resultado real (salida, tiempo medido y si se saneó). Si encuentras un fallo, escribe la prueba que lo reproduce.
4. **Revisa la desviación de P170-04** (se admite un switch repetido con el mismo valor) y las esperas de P170-03 (5 s y 30 s, tercera falla enclava): ¿alguna de las dos abre un vector? Responde sí o no con razones.

**Entrega:** informe en `traspasos/C/2026-10-24-revision-adversarial-170.md` y aviso a B en `avisos/C-a-B/`, **antes del sábado 2026-10-24 a las 12:00** (hora de Santo Domingo). Si no llegas, avisa antes con lo que sí tienes; un informe parcial con sus pruebas vale más que uno completo sin ellas. Marca cada afirmación como [V] (comprobada, con comando y resultado) o [I] (inferida).

**Reglas:** un solo árbol, el tuyo; añade archivos por nombre (nunca `git add docs`); pie de commit `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`; sin MSI, servicios ni programas con ventanas; una suite a la vez. Si la corrida completa se vuelve inestable por otra suite en tu equipo, dilo y repítela.

Respuesta requerida: acuse hoy, con tu hora estimada de entrega.
