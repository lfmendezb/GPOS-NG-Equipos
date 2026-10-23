Para: B        De: C        Fecha: 2026-10-24
Tipo: Revisión adversarial (encargo B-a-C/2026-10-23-prueba-exigente-revision-adversarial-170)
Prioridad: Alta
Repositorio y rama: GPOS-NG #170 `b/ola5-t4-03a`, rango `89fce5b5..30fc9516` (solo lectura)
Estado: Abierto

Convención: [V] comprobado con comando y resultado en mi equipo; [I] inferido. Árbol: `C:\Users\lfmen\source\repos\Solucion GPOS NG\GPOS-C-rev170`, HEAD 30fc9516. Nada se empujó. Rama local con pruebas nuevas: `c/rev170-hostiles` (commit de445c33, un archivo). Chrome 155.0.8059.85 instalado [V] (B cita 156).

# Veredicto

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario, C2). No hay defectos Críticos ni Altos.
- Corrida completa: 748/748 [V]. No coincide con el 356/356 de B (ver sección 1).
- Mutaciones: de las 6 familias del encargo, 5 se detectan bien. M2b (quitar `ComprobarTamano` de `ServicioRender.HtmlAsync`), M8b y M11 **no las detecta ninguna prueba** [V, suite completa]; M11 es equivalente (reconfirmado) y M2b también (nuevo: B no la declaró). M8b **no es equivalente** y es la que importa (regresión silenciosa de la carpeta privada).
- Entradas hostiles: 0 evasiones. Ninguna sugerencia de conexión salió sin sanear, ninguna excepción distinta de `FormatoInvalidoException` en 200.000 entradas, y el tiempo es lineal. Con Chrome como oráculo: 37.601 salidas saneadas cargadas, 0 elementos no admisibles.
- Hallazgos: 4 de pruebas (una de ellas, H170-04, de riesgo real), 1 de rendimiento (amplificación de 1,28 GB asignados por petición en el peor caso) y observaciones menores. Ningún vector nuevo en las desviaciones de P170-04 y P170-03.

# 1. Corrida propia (punto 1)

Comando: `dotnet test tests/GPOS.Reportes.Tests --blame-hang-timeout 10m` (sin filtro, compila antes), HEAD 30fc9516.

| Corrida | Total | Superadas | Fallidas | Omitidas | Tiempo |
|---|---|---|---|---|---|
| Limpia, sola (08:55:43 a 09:01:32 con la compilación) [V] | **748** | 748 | 0 | 0 | 5 m 42 s de pruebas |
| Doble, por error mío (ver abajo) [V] | 748 | 748 | 0 | 0 | 5 m 53 s y 5 m 59 s |

- **Difiere de 356/356 (encargo B): el total real es 748.** Es un hallazgo de cifras (H170-07), no de calidad. Causa **no identificada con certeza** [I]: «356» no aparece en los mensajes de commit de B ni en `avisos/B-a-A` ni en `traspasos/B`; 748 cuenta cada caso de teoría. Dejo ambas cifras a la vista; si B contó solo un subconjunto (por ejemplo, sin teorías), que lo diga.
- 0 omitidas: Chrome está instalado, así que corrieron las pruebas con navegador (no hay un 356 que se explique por omisiones).
- **Incidente propio, declarado:** la primera corrida salió duplicada. Lancé el comando una vez dentro de un subshell que creí muerto y otra vez como tarea de fondo: dos `dotnet test` simultáneos sobre el mismo árbol, durante unos 6 minutos (se vieron dos `testhost`). Ambas terminaron 748/748. Descarté ese log y repetí la corrida sola; la cifra válida es la «limpia». Rompí la regla de una sola corrida a la vez; no hubo daño visible, pero la medición de tiempo de esa corrida no vale.
- No hubo inestabilidad: 3 corridas completas (limpia, doble y la combinada con mutaciones, 5 m 28 s) dieron 748/748 sin una falla intermitente [V]. El caso `object` de `Un_documento_data_anidado_corta_el_render` no falló en ninguna.

# 2. Mutaciones (punto 2)

Todas aplicadas a mano sobre `src/`, restauradas con `git checkout -- <archivo>`, y `git status` limpio tras cada una [V]. Logs: `mut-*.log` en el scratchpad. Subconjuntos:
- `FCAPA0` = `--filter "FullyQualifiedName~ChromiumAisladoTests.La_capa_0|FullyQualifiedName~ChromiumAisladoTests.El_tope|FullyQualifiedName~ChromiumAisladoTests.La_banda"` (95 casos).
- `FLINEA` = `"FullyQualifiedName~La_linea_de_comandos_se_comprueba|FullyQualifiedName~Con_una_ruta_con_espacios"` (27 casos).
- `FP03` = `"FullyQualifiedName~Una_falla_transitoria|FullyQualifiedName~Tres_fallas|FullyQualifiedName~Enclavado_o_en_espera|FullyQualifiedName~El_estado_de_la_linea|FullyQualifiedName~Un_navegador_con_un_argumento_prohibido|FullyQualifiedName~Cerrar_el_navegador"` (6 pruebas).
- Comando común: `dotnet test tests/GPOS.Reportes.Tests --blame-hang-timeout 10m --filter "<subconjunto>"`. Rutas: P = `src/GPOS.Reportes.Api/Impresion/PoliticaRedNavegador.cs`, E = `.../EstadoLineaComandos.cs`, C = `.../ConvertidorPdf.cs`, R = `.../ServicioRender.cs`.

## 2.1 Las del encargo

| # | Mutación (diff mínimo) | Filtro | Pruebas que fallan |
|---|---|---|---|
| M1a | P:286 `if (LinkAdmitido(atributos) && !html.AsSpan(i + 1, fin - i - 1).Contains('<')) fin = -1;` → `if (LinkAdmitido(atributos)) fin = -1;` | FCAPA0 | 1: `La_capa_0_es_lineal_con_hojas_de_estilo_sin_cerrar_hasta_un_cierre_final` (solo por el plazo: «no terminó en 10 s (5.250.001 caracteres)»; la aserción funcional de la línea 1854 ni se alcanza) |
| M1b | P:301 quitar `&& !html.AsSpan(i + 1, fin - i - 1).Contains('<')` del `<meta` | FCAPA0 | 2: la misma prueba lineal (plazo, 4.000.001 car.) y `La_capa_0_quita_las_sugerencias_y_las_reglas_de_especulacion(elemento: "<meta name=\"viewport\" content=\"a<b\">")` |
| M2a | P:206 `MaximoEtiquetas = 262_144` → `int.MaxValue` | FCAPA0 | 2: `El_tope_se_comprueba_justo_despues_de_Razor`, `La_capa_0_tiene_tope_de_etiquetas` |
| **M2b** | R:53 quitar `PoliticaRedNavegador.ComprobarTamano(renderizado);` | FCAPA0 y suite completa (combinada) | **ninguna** (95/95; suite completa 748/748). Es **equivalente**: `SanearHtml` vuelve a llamar `ComprobarTamano` en su primera línea (P:241), así que el 400 sale igual. Ver H170-03 |
| M3a | P:300 `if (!atributos.Exists(a => … "http-equiv" …)` → `if (true` (el `meta` con http-equiv se deja) | FCAPA0 | 6: `La_capa_0_quita_la_prebusqueda_de_nombres_de_los_enlaces` y 5 casos de `La_capa_0_quita_las_sugerencias…` (meta con http-equiv: `x-dns-prefetch-control`, `Refresh`, `X-UA-Compatible`, `/http-equiv=refresh/`, orden invertido) |
| M3b | P:303 `else if (EmpiezaEtiqueta(html, i, "base"))` → `else if (false)` | FCAPA0 | 3: `…sugerencias…(<BASE target=_blank />)`, `…(<base href="http://h/">)`, `La_capa_0_rechaza_una_etiqueta_que_llega_al_final_sin_cerrarse(<BASE)` |
| M4 | P:96 `valores.TrueForAll(v => …)` → `valores.Exists(v => …)` («todas» → «alguna») | FLINEA | 10 casos de `La_linea_de_comandos_se_comprueba_al_lanzar` (dos perfiles, proxy repetido con barra / un guion / mayúsculas, reglas de resolución, excepciones del proxy, prebúsqueda con valor, tubería con valor, perfil repetido con barra y con un guion) |
| M5a | E:40 `if (FallasSeguidas >= FallasParaEnclavar)` → `if (true)` (enclavar siempre) | FP03 | 4: `El_estado_de_la_linea…`, `Enclavado_o_en_espera…`, `Tres_fallas…`, `Una_falla_transitoria…` |
| M5b | E:42 quitar `_enclavada = true;` de `FallaLectura` (no enclavar nunca por lecturas, en la clase) | FP03 | 1: solo `El_estado_de_la_linea…`. En el flujo real lo cubre `_linea.Rechazar()` de C:409 (la prueba con navegador pasa), así que es una mutación de estado, no de comportamiento |
| M5c | E:34 `Rechazar() => _enclavada = true;` → `Rechazar() { }` (no enclavar nunca un rechazo) | FP03 | 3: `El_estado_de_la_linea…`, `Enclavado_o_en_espera…`, `Un_navegador_con_un_argumento_prohibido…` |
| M5d | E:39 quitar `FallasSeguidas++;` | FP03 | 4 (las mismas de M5a) |
| M5e | C:407 `if (leida \|\| _linea.FallaLectura())` → `if (true)` (enclavar siempre, en el convertidor) | FP03 | 2: `Tres_fallas…`, `Una_falla_transitoria…` |
| M5f | C:407 → `if (leida)` (no enclavar nunca por lecturas) | FP03 | 2: las mismas |
| M5g | C:409 quitar `_linea.Rechazar();` | FP03 | 1: `Un_navegador_con_un_argumento_prohibido…` (solo con navegador; en un equipo sin Chrome no la vería nadie) |
| M6a | P:299 `if (fin == SinCierre) throw EtiquetaSinCierre("meta");` → `{ i++; continue; }` | FCAPA0 | 2: `…sin_cerrarse(<meta content=')`, `…(<meta http-equiv=refresh)` |
| M6b | P:307 quitar el `throw` de `<base` sin cerrar | FCAPA0 | 1: `…sin_cerrarse(<BASE)` |
| M6c | P:299 quitar el `throw` de `<meta` (queda un `ArgumentOutOfRange`) | FCAPA0 | 2: las de M6a |

## 2.2 M8b y M11 (las que B declara no detectables)

| # | Mutación | Filtro | Pruebas que fallan |
|---|---|---|---|
| **M8b** | C:113-114 `PrepararCarpeta`: `ComprobacionCarpetas.PrepararPrivada(raiz, Componente, carpeta, propia, servicio ?? …)` → `ComprobacionCarpetas.PrepararTemporales(raiz, Componente, carpeta, propia)` | clases de carpeta + `SeguridadTramo2Tests` (77 casos) y suite completa (combinada) | **ninguna** (77/77; suite completa 748/748). **Confirmado: no detectable con la suite actual.** No es equivalente: en producción la carpeta `render` dejaría de crearse con la DACL privada y protegida (S170-01, DM-11) y el servicio arrancaría con 200. Ver H170-04 |
| **M11** | P:402 quitar `!v.Contains('&') && ` de `LinkAdmitido` | suite completa (combinada) | **ninguna** (748/748). **Confirmado equivalente** [V + razonamiento]: un `rel` con `&` no puede tener todas sus fichas en `RelAdmitidos = {"stylesheet"}` |

La suite completa se corrió **con M2b, M8b, M11, X1, X5 y X9 aplicadas a la vez** (09:12:30 a 09:18:07, 5 m 28 s): 748/748 [V]. Argumento para no bisecar: son cambios en funciones independientes; que ninguna de las seis haga fallar nada en conjunto implica que ninguna lo hace sola, salvo interacción improbable [I].

## 2.3 Mutaciones propias (probé las pruebas nuevas de B más allá del encargo)

| # | Mutación | Filtro | Resultado |
|---|---|---|---|
| X1 | P:199 `MaximoPasadas = 32` → `1000` | FCAPA0 | **no detectada** (95/95): la prueba de pasadas anida `MaximoPasadas + 5` niveles con la propia constante, así que se auto-ajusta (H170-02) |
| X2 | E:22 esperas `[5 s, 30 s]` → `[5 s, 5 s]` / `[0, 0]` | FP03 | detectada: 1 / 2 pruebas |
| X3 | `ServiciosLectura.SaludAsync` sin la comprobación de `LineaComandosEnclavada` | FP03 | detectada: 3 |
| X4 | C:368 sin `EsperaPendiente()` | FP03 | detectada: 2 |
| **X5** | C:504 `return (…"no se pudo comprobar…", true)` → `false` (una excepción al **comprobar** la línea deja de ser un rechazo inmediato) | FP03 y suite completa | **no detectada** (6/6; completa 748/748) (H170-06) |
| X6 | P:402 quitar `rels.Count > 0 &&` (un `link` sin `rel` se deja) | FCAPA0 | detectada: 1 (`<link data-rel="preconnect" …>`) |
| X6b | `RelAdmitidos = {"stylesheet", "preconnect"}` | FCAPA0 | detectada: 12 |
| X11 | P:269 `EmpiezaEtiqueta` sin el delimitador `/` | FCAPA0 | detectada: 3 |
| **X9** | P:325 `EsEspacio`: quitar `'\f'` / quitar `'\r'` / quitar `'\t'` / dejar solo `' '` y `'\n'` | FCAPA0 y suite completa | **no detectada ninguna** (95/95 en cada una; completa 748/748 con solo `' '` y `'\n'`) (H170-01) |

Las pruebas nuevas de la rama `c/rev170-hostiles` (`tests/GPOS.Reportes.Tests/CapaCeroRevisionCTests.cs`, 9 casos) matan X9 (FF, CR y TAB, una por una) y X1: cada mutación hace fallar exactamente 1 caso, y con el código sin mutar pasan 9/9 [V].

# 3. Entradas hostiles (punto 3)

Arnés: dos archivos xUnit temporales (no están en el repositorio; copia en `scratchpad/CHostilesCapa0Tests.cs` y `CHostilesCapa0Escala.cs`). Salidas crudas: `hostiles-salida.txt`, `hostiles-tiempos.txt`, `hostiles-tiempos2.txt`, `hostiles-fuzz2.txt`. El oráculo lanza Chrome con los argumentos de la capa 2 (proxy muerto, nombres sin resolver) y el JavaScript apagado, carga el HTML con `SetContent` y lee el DOM con `querySelectorAll('link,meta,base,script,iframe,frame,frameset,object,embed')`. «Admisible» = `link` solo con `rel=stylesheet`, `meta` sin `http-equiv`, nada de lo demás. Las entradas están escritas por mí; las de B no se copiaron (B no probó VT/NBSP/Kelvin, el `=` como primer carácter del nombre, el NUL en `http-equiv`, ni el doble escape de `<script>` con una sugerencia detrás).

## 3.1 (a) Sugerencias de conexión y variantes: 5 entradas

Marco común: `<!DOCTYPE html><html><head><meta charset="utf-8">` + ENTRADA + `</head><body><p>Hola</p></body></html>`. Tiempos de una sola llamada, incluida la primera (JIT) [V].

| # | Entrada (ENTRADA) | Salida real | Tiempo | ¿Saneada? | Chrome (DOM de la salida) |
|---|---|---|---|---|---|
| E1 costuras del analizador | `<link\u000Brel=preconnect href=http://h.invalid><link =rel=preconnect href=http://h.invalid><link rel=stylesheet/preconnect href=http://h.invalid>` | quitados=2; queda `<link\u000Brel=preconnect href=http://h.invalid>` (VT no es espacio HTML: no es un `link`) | 3,07 ms | sí (lo que es `link` se quitó; lo que queda es inerte) | `[meta]`: el VT no forma un `link` (control crudo: `[meta, link\|\|, link\|stylesheet/preconnect\|]`, o sea que el `=rel` y el `stylesheet/preconnect` sí eran enlaces) |
| E2 `http-equiv` disfrazado | `<meta http-equiv\0=refresh content="0;url=http://h.invalid"><meta HTTP-EQUIV\f=refresh content=0><meta http-equiv ="x-dns-prefetch-control" content=on><meta name=a name=b HTTP-equiv=refresh content=0>` | quitados=3; queda solo la de NUL (`http-equiv\u0000`) | 2,29 ms | sí | `[meta, meta]` sin `http-equiv` (el NUL pasa a U+FFFD en el nombre del atributo: no es `http-equiv`) |
| E3 guion, comentario, noscript, svg, template | `<script><!--<script></script><link rel=preconnect href=http://h.invalid>--></script><noscript><link rel=dns-prefetch href=http://h.invalid></noscript><!--><link rel=prefetch href=http://h.invalid>--><svg><link rel=preconnect href=http://h.invalid></svg><template><link rel=preconnect href=http://h.invalid></template>` | quitados=6; salida `…--></script><noscript></noscript><!-->--><svg></svg><template></template>…` | 0,32 ms | sí | `[meta]` (control crudo: `[meta, script, link\|dns-prefetch\|, link\|prefetch\|, link\|preconnect\|]`) |
| E4 `rel` con NBSP, `ſ`, Kelvin | `<link rel="stylesheet\u00A0preconnect" …><link rel="\u017Ftylesheet" …><link rel="stylesheet\u212A" …><LINK REL="STYLESHEET" HREF="data:text/css,p%7B%7D"><li\u212Ak rel=preconnect href=http://h.invalid>` | quitados=3; quedan la hoja `data:` legítima y el `<li\u212Ak …>` | 0,12 ms | sí (los tres `rel` raros se quitan; `OrdinalIgnoreCase` no pliega `ſ` ni K de Kelvin a ASCII) | `[meta, link\|STYLESHEET\|]`: el elemento con K de Kelvin no es un `link` |
| E5 comillas mezcladas, `<`/`>` en valores, `<base>` | `<link rel='preconnect' title="a>b" href=…><link title='"' rel=preconnect href=…><link rel="stylesheet" title="<link rel=preconnect href=…>"><base href=…><BASE/href=…>` | quitados=5; queda solo el `<meta charset>` | 0,09 ms | sí | `[meta]` (control crudo: `[meta, link\|preconnect\|, link\|preconnect\|, link\|stylesheet\|, base\|\|, base\|\|]`) |

Resultado: **ninguna sugerencia de conexión salió sin sanear**; 0 violaciones en el DOM de Chrome de las cinco salidas [V]. Lo que la capa 0 deja y Chrome no lee como `link`/`meta` (VT, NUL, Kelvin) es inerte [V con el oráculo].

**Fuzz con oráculo:** 60.000 entradas aleatorias (semilla 24102026, 1 a 69 fichas de un vocabulario de 57: `<`, `>`, `link`, `LINK`, `script`, `meta`, `base`, `iframe`, comillas, `=`, `/`, NUL, FF, NBSP, VT, Kelvin, `ſ`, `&#112;`, `<!--`, `]]>`, `</script`, `rel=preconnect`, etc.); 37.601 no fueron rechazadas con 400 y se cargaron en Chrome: **0** con un elemento no admisible en el DOM [V] (`hostiles-fuzz2.txt`).

## 3.2 (b) Tiempo con entrada de menos de 8 Mi caracteres

Medido con `Stopwatch` tras calentamiento, en esta PC (varía; lo que importa es la razón). Razón = tiempo / tiempo del tamaño anterior (8× más caracteres); lineal ≈ 8.

| Forma | 64 Ki | 512 Ki | 4 Mi | Razón | Al tope (≈8,39 Mi car.) |
|---|---|---|---|---|---|
| S1 `<link rel=preconnect>` repetido, todo quitado | 1,6 ms | 14,1 ms | 107,1 ms | 8,6 / 7,6 | 274 ms, 137 MB asignados |
| S2 un solo `<link>` con millones de atributos `a a a …` | 2,5 ms | 21,0 ms | 267,7 ms | 8,5 / **12,8** | 515 ms, 224 MB |
| S3 hojas de estilo que se dejan | 1,5 ms | 12,9 ms | 103,1 ms | 8,4 / 8,0 | 219 ms, 110 MB |
| S4 `<script>` + señuelos `</scriptx ` sin cierre | 1,7 ms | 10,9 ms | 400 (más de 262.144 `<`) | 6,4 | 400 en 1,8 ms |
| S5 `<meta>` que se dejan | 2,3 ms | 14,8 ms | 118,6 ms | 6,4 / 8,0 | 400 en 1,0 ms (tope de `<`) |
| S6 un `<link>` con un `rel` de millones de fichas | 0,5 ms | 5,5 ms | 42,2 ms | 10,3 / 7,7 | 87 ms, 71 MB |
| S7 `<b>` hasta el tope de etiquetas (786 Ki car.) | 4,7 ms | 39,2 ms | 57,7 ms (786 Ki) | 8,4 | — |
| S8 anidado de 31 niveles sobre relleno `<i>x</i>` | 117,1 ms (400) | 927,6 ms (400, 192 MB) | 400 por tope de `<` | 7,9 | 400 en 1,7 ms |
| S9 un `<link>` con millones de atributos `a="x"` | 1,4 ms | 11,0 ms | 118,5 ms | 7,9 / 10,8 | 301 ms, 128 MB |
| S10 `<base>` + `<meta http-equiv>` quitados | 1,6 ms | 12,2 ms | 101,1 ms | 7,8 / 8,3 | 400 (tope de `<`) |
| **S11 peor caso**: un `<b>` cada 32 car. (262.000 `<`), anidado de 31 niveles | 17,0 ms | 129,2 ms | 1.017 ms (640 MB) | 7,6 / 7,9 | **2.081 ms y 1.279 MB asignados**, resultado 400 («anidadas que no se pueden sanear») tras las 32 pasadas |

Conclusión (b): **lineal, no superlineal** en todas las formas (razones 6 a 10; el 12,8 de S2 es el crecimiento de la lista de atributos y la presión sobre el LOH, no un término cuadrático [I]). Pero la constante en el peor caso es alta: **~2,1 s de CPU y 1,3 GB asignados por petición** con un texto de 8,4 Mi caracteres que se rechaza con 400 (H170-05). Con una entrada que sí se sanea en 31 pasadas el costo es parecido.

## 3.3 (c) Excepciones distintas de `FormatoInvalidoException`

Fuzz de 200.000 entradas (semilla 20261024, 1 a 59 fichas del mismo vocabulario), cada una pasada dos veces por `SanearHtml` [V]:

| Métrica | Resultado |
|---|---|
| Saneadas / rechazadas con 400 | 121.784 / 78.216 |
| **Excepciones distintas de `FormatoInvalidoException`** | **0** |
| Salidas no idempotentes (`SanearHtml(salida) != salida` o `quitados != 0`) | 0 |
| Salidas con `<script`, `<base` o `<iframe`/`frame`/`frameset`/`object`/`embed`/`portal`/`fencedframe` seguidos de espacio HTML, `/` o `>` | 0 |
| Peor caso de una entrada | 4,04 ms |
| Tiempo total | 1,5 s |

(La primera versión de mi invariante dio 120 «residuales»: eran falsos positivos de mi regex, porque `\s` de .NET incluye NBSP y VT, que no son espacios de HTML. Corregida con `[ \t\n\r\f/>]` dio 0. Lo digo para que no se confunda con una evasión.)
Las 5 entradas del 3.1 y las 11 formas del 3.2 también terminaron sin excepción ajena (las 11 al tope incluidas).

Veredicto del punto 3: **no encontré ninguna evasión, ninguna excepción ajena ni tiempo superlineal.** Por eso la rama `c/rev170-hostiles` no lleva pruebas que reproduzcan un fallo del código, sino las que matan los mutantes de la sección 2 (H170-01 y H170-02).

# 4. P170-04 y P170-03 (punto 4)

## 4.1 P170-04: switch repetido con el mismo valor — **No abre un vector**

1. Con el mismo valor, el valor efectivo es el mismo: Chromium se queda con el último valor de un switch repetido [I, `CommandLine::AppendSwitchNative`: el mapa se sobrescribe]. `PoliticaRedNavegador.cs:96` admite la repetición solo si **todas** las apariciones son iguales al esperado (`TrueForAll`); M4 confirma que la regla se aplica (10 casos fallan con «alguna»). Una aparición posterior con otro valor (`/proxy-server=…`, `-user-data-dir=…`, `--PROXY-SERVER=…`) se rechaza (`:97`).
2. La normalización cubre los prefijos que Chromium acepta en Windows (`--`, `-`, `/`; `NombreSwitch`, `:109-116`) y no distingue mayúsculas (Chromium las baja a minúsculas en Windows [I]).
3. La razón de la desviación es real: PuppeteerSharp repite varios de la capa 2 por su cuenta (`--disable-background-networking`, `--disable-sync`…) y «exactamente una vez» rechazaría todo arranque; B lo comprobó con Chrome (`Con_una_ruta_con_espacios_el_perfil_no_se_parte` registra los repetidos reales) y la prueba pasa en mi equipo [V].
4. **Límites que conviene saber (no son vectores hoy, H170-08):** (i) la comprobación solo mira los switch listados; no están en `Prohibidos` ni en lo exigido `--no-proxy-server` (que en Chromium **anula** `--proxy-server` [I]), `--proxy-pac-url`, `--proxy-auto-detect`, `--host-rules`; (ii) no trata el terminador `--` (lo que va detrás ya no son switch para Chromium pero la comprobación los leería como tales) [I]. Ambos exigen poder agregar argumentos, y los argumentos son constantes: `ArgumentosPrueba` es `internal` (`OpcionesRender.cs:97`), no enlazable desde la configuración, y el entorno del navegador va filtrado (`PoliticaRedNavegador.cs:129-135`). Defensa en profundidad, no un hueco.

## 4.2 P170-03: esperas de 5 s y 30 s, la tercera falla enclava — **No abre un vector de seguridad; sí hay un costo de disponibilidad conocido**

1. **Confidencialidad / evasión de la comprobación: no.** Un navegador cuya línea no se pudo leer **no se usa nunca**: `ConvertidorPdf.cs:403-426` lo cierra (`DesecharRechazadoAsync`, `:423`), borra su perfil (`:424`) y lanza 503; `_navegador` se asigna solo si `problema is null` (`:427-430`). La lectura ocurre antes de que cargue ningún documento (`:399-403`), así que el contenido de un formato no la puede provocar. Un fallo al **comprobar** (no al leer) sigue enclavando de inmediato (`:502-505`, `leida: true`).
2. **Esperas crecientes** (`EstadoLineaComandos.cs:22`, `:45`): durante la espera todos los personalizados responden 503 «se reintentará en N s» sin lanzar otro Chrome (`ConvertidorPdf.cs:368-369`); X4 y M5 lo verifican. Un atacante necesita un navegador **cerrado** y una **falla de lectura**; ninguna de las dos la causa un formato [I]. El acceso a la ruta lo exige autenticación.
3. **Enclavado tras 3 fallas** (`EstadoLineaComandos.cs:16`, `:40-44`): es un modo de falla cerrada con costo de disponibilidad (503 hasta reiniciar). Es estrictamente mejor que O170-03 (enclavar a la primera). El estado es visible: `/api/salud` responde 503 `NAVEGADOR_NO_DISPONIBLE` (`ServiciosLectura.cs:60`), sin decir el motivo; la prueba lo cubre (X3 la detecta). El camino alterno falla/éxito/falla… no acumula: `Cumple()` pone el contador a 0 (`EstadoLineaComandos.cs:50-54`).
4. **Observaciones (H170-09, H170-10), todas [I]:** (i) `LeerLineaComandosAsync` (`ConvertidorPdf.cs:508-522`) no tiene plazo propio y corre con el semáforo `_bloqueo` tomado (`:360`): depende del plazo de protocolo de PuppeteerSharp (por omisión 180 s [I]), o sea hasta ~3 min de bloqueo por intento; (ii) `DesecharRechazadoAsync` (`:528-538`) se traga cualquier excepción del cierre: si falla antes de matar el proceso quedaría un Chrome huérfano sin control (con CDP por tubería no hay a quién escucharlo, y un máximo de 3), conviene que registre y mate el proceso por PID; (iii) las esperas usan el reloj de pared (`TimeProvider.System`, `:67`): un salto del reloj las alarga o acorta (exige ser administrador).

# Hallazgos

| ID | Severidad | Tipo | Hallazgo y evidencia |
|---|---|---|---|
| H170-01 | Baja | Pruebas (control de seguridad) | `EsEspacio` (`PoliticaRedNavegador.cs:325`) no tiene prueba por carácter: quitar `'\f'`, `'\r'` o `'\t'`, o dejar solo `' '` y `'\n'`, **no hace fallar ninguna de 748 pruebas** [V, X9]. Con esa regresión, `<link\frel=preconnect href=…>` dejaría de ser un `link` para la capa 0 y saldría sin sanear (en HTML, FF es espacio). Los casos de B con `\n\t` se quitan igual por no tener `rel`. **Prueba nueva en `c/rev170-hostiles` (de445c33):** `Cada_espacio_de_HTML_separa_el_nombre_de_la_etiqueta_de_los_atributos` (5 casos) y `Lo_que_no_es_espacio_de_HTML_no_forma_una_etiqueta_link` (3). Cada mutación X9 hace fallar su caso. |
| H170-02 | Baja | Pruebas | `MaximoPasadas` y `MaximoHtml` no están fijados: las pruebas de tope se construyen con la propia constante (`ChromiumAisladoTests.cs:1822-1826`), así que subir `MaximoPasadas` a 1000 no hace fallar nada [V, X1]; costaría ~30 veces la CPU de hoy. Solo `MaximoEtiquetas` está fijado (`:1877`). Prueba nueva `Los_topes_de_la_capa_0_son_los_vigentes` (fija 32, 8 Mi y 262.144). |
| H170-03 | Baja | Pruebas / diseño | `ServicioRender.HtmlAsync` llama `ComprobarTamano` (`:53`) y `SanearHtml` vuelve a llamarlo (`PoliticaRedNavegador.cs:241`): quitar la de `HtmlAsync` **no cambia ningún resultado** [V, M2b]. `El_tope_se_comprueba_justo_despues_de_Razor` (`:1889`) pasa con o sin ella: no prueba lo que dice su nombre. Con `FinAperturaBody` lineal, la comprobación anticipada ya no protege nada observable. Opciones: quitarla o dejarla como defensa en profundidad y renombrar la prueba. B no declaró esta mutación como equivalente. |
| H170-04 | **Media** | Pruebas (regresión de seguridad no detectable) | `PrepararCarpeta` (`ConvertidorPdf.cs:110-115`) usa `PrepararPrivada`; cambiarla por `PrepararTemporales` **no hace fallar nada** [V, M8b, suite completa]. En producción la carpeta `render` dejaría de crearse con la DACL privada y protegida (S170-01, DM-11) y el servicio arrancaría normal. B lo declaró; confirmado, y es la mutación con más consecuencias de las no detectadas. **Remediación (unas 2 horas)**: inyectar la comprobación de los padres en `PrepararCarpeta` (un parámetro interno `Func<…>` con `PrepararTemporales` por omisión) y que las pruebas la sustituyan por «sin rechazo»: entonces `PrepararCarpeta` real llega a `PrepararPrivada` y se puede afirmar que `render` nace con SDDL privada y rechaza al lector ajeno. Alternativa menos intrusiva: una prueba que lea la DACL tras un `PrepararCarpeta` sobre una raíz de pruebas con `ComprobarCarpeta` apagado. |
| H170-05 | Baja | Rendimiento | La capa 0 es lineal pero con constante alta: **2.081 ms y 1.279 MB asignados** con 8,38 Mi car., 262.000 `<` y anidado de 31 niveles (resultado 400 tras 32 pasadas), 1.017 ms y 640 MB con 4 Mi [V, S11]. Cada pasada copia el texto con un `StringBuilder` nuevo. Quien puede provocarlo es quien escribe la plantilla Razor (SUPER) [I], pero N peticiones simultáneas son N×1,3 GB de asignaciones (LOH). Un formato legítimo necesita 1 pasada de limpieza y 1 de verificación: bajar `MaximoPasadas` a 4 a 8 divide el peor caso por 4 a 8; o releer solo desde el primer cambio. Decisión de B/A. |
| H170-06 | Baja | Pruebas | La rama «una excepción al **comprobar** la línea de comandos es un rechazo inmediato, no una falla de lectura» (`ConvertidorPdf.cs:502-505`) no tiene prueba [V, X5: cambiar `true` por `false` no rompe nada]. Con el cambio, un perfil con ruta inválida reintentaría 3 veces antes de enclavar (sigue fallando cerrado, pero con 35 s de espera inútil). |
| H170-07 | Informativa | Cifras | La corrida completa da **748/748**, no 356/356 [V]. No pude reconstruir de dónde sale 356 [I]. Y mi propio incidente: una corrida doble involuntaria el 2026-10-24 (sección 1). |
| H170-08 | Baja / informativa | Seguridad (defensa en profundidad) | `Prohibidos` y los switch exigidos no cubren `--no-proxy-server`, `--proxy-pac-url`, `--proxy-auto-detect`, `--host-rules` ni el terminador `--` (`PoliticaRedNavegador.cs:62-67`, `83-106`). Sin vector hoy: los argumentos son constantes. Si algún día se admite configurar argumentos, hay que ampliar la lista antes. [I sobre Chromium] |
| H170-09 | Informativa | Operación | Lectura de la línea de comandos sin plazo propio bajo el semáforo (`ConvertidorPdf.cs:360`, `:508-522`); cierre del navegador rechazado que se traga la excepción (`:528-538`). [I] |
| H170-10 | Informativa | Operación | Esperas con el reloj de pared (`ConvertidorPdf.cs:67`, `EstadoLineaComandos.cs:45`). [I] |

Sobre la calidad de lo que B sí hizo bien (para que conste lo verificado): las pruebas de P170-01, P170-02 (plazo propio de 10 s), P170-03 y P170-05 detectan sus mutaciones principales en 1 a 12 casos cada una; el oráculo de Chrome no encontró una sola diferencia entre el analizador de la capa 0 y el de Chromium en 37.601 salidas; la prueba de rendimiento con plazo (`SanearConPlazoAsync`) falla a los 10 s en vez de colgar la suite (verificado con M1a y M1b). Un detalle de las pruebas de rendimiento: la afirmación `< 3000 ms || >= 10000 ms` (`ChromiumAisladoTests.cs:1810`) falla si una máquina cargada tarda entre 3 y 10 s; en mi equipo el caso tarda ~0,15 s [V, por la serie S3], así que el margen es ~20×, pero OSHIN-LEGION es inestable [I].

# Qué no verifiqué

- Edge y Chrome 156 (solo Chrome 155.0.8059.85). El oráculo y las pruebas con navegador usaron Chrome.
- Concurrencia: los 1,3 GB son por petición; no medí N peticiones simultáneas ni el efecto en el servidor real (GC, LOH).
- El servicio de Windows, el MSI, el cortafuegos (evento 5118) y la raíz de SYSTEM de `PrepararCarpeta`: no se puede sin elevación (y las reglas del equipo lo prohíben); por eso M8b queda como hallazgo.
- El comportamiento «último valor gana» de Chromium con switch repetidos, `--no-proxy-server`, `--` y la minúscula de los nombres en Windows: [I] por conocimiento de la fuente de Chromium, no lo probé con una línea de comandos real.
- El plazo de protocolo de PuppeteerSharp (180 s) y si el cierre de un navegador falla deja un Chrome vivo: [I].
- El oráculo ve el DOM, no el tráfico: el proxy muerto y el JavaScript apagado impiden las conexiones, así que «0 violaciones» significa que ninguna salida contiene un elemento que Chromium podría usar para conectar, no que se observara el tráfico. Los marcos con `srcdoc` y el contenido de `<template>` no se inspeccionan en el DOM (la capa 0 rechaza todos los marcos antes).
- El fuzz usa semilla fija y un vocabulario de 57 fichas; no es una prueba formal de equivalencia con el analizador de HTML. No probé un fuzz estructurado por gramática ni entradas con millones de fichas distintas en el oráculo.
- Las pruebas de P170-01, la ruta `GPOS.Api` (el render anterior de la principal) y las demás suites (`GPOS.Tests`, `GPOS.Web.Tests`, MAUI): fuera del alcance.
- Si 356 es el recuento de otra configuración (otro filtro, otra rama), no lo verifiqué.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: informe en este archivo; pruebas nuevas en la rama local `c/rev170-hostiles` (commit de445c33, `tests/GPOS.Reportes.Tests/CapaCeroRevisionCTests.cs`, sin empujar); arnés temporal y salidas crudas en el scratchpad (`CHostilesCapa0Tests.cs`, `CHostilesCapa0Escala.cs`, `hostiles-*.txt`, `mut-*.log`, `corrida*.log`)
- Supuestos: Chrome 155 como oráculo; las afirmaciones de comportamiento de Chromium marcadas [I]
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: B → decidir H170-03 (quitar o renombrar), H170-04 (seam para probar `PrepararCarpeta`) y H170-05 (bajar `MaximoPasadas`); B/A → aceptar o no la rama `c/rev170-hostiles` (un cherry-pick de de445c33)
- Próximo paso recomendado: B cierra H170-04 y H170-01/02 (cherry-pick) antes de unir el #170
