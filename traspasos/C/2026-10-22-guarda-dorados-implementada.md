```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (grupo 0 del plan de dorados: guarda G-1..G-6 de P152-16) y P152b-03
Prioridad: Media
Repositorio y rama: GPOS-NG `c/dorados-guarda-t4-01` (desde `origin/b/ola5-t4-01-render` @ cf6ccf98), empujada; sin PR (apilar sobre #152)
Estado: Completado (guarda); la captura de los grupos 1-6 la corre B en LFMB
```

# Guarda de los dorados de T4-01 implementada

Commits: `3bd8f9bc` (guarda + línea base) y `847527ae` (P152b-03). Sin cambios en `src/` ni en los 78 dorados (`git diff f8897418 HEAD -- .../Dorados/html .../pdf` vacío).

## Qué se hizo
- `tests/GPOS.Tests/Impresion/GuardaDorados.cs` (nuevo): la comparación de `RenderTrasladoTests` se trasladó sin cambios (solo CRLF y fechas `/CreationDate`/`/ModDate`; los mensajes de diferencia son los de antes). Entorno, reloj y versiones se inyectan, así que las pruebas usan una carpeta temporal.
- `RenderTrasladoTests.cs`: cada caso llama a `GuardaDorados.Real.Html(...)` o `.Pdf(...)` con la salida de la principal y la de reportes. `NormalizarHtml` y `NormalizarPdf` se mantienen y delegan en la guarda.
- `Dorados/LEEME.md`, `Dorados/manifiesto.json` y `Dorados/CAMBIOS.md` (nuevos). La línea base se creó con la herramienta explícita `GPOS_TEST_DORADOS=linea-base` + motivo «línea base de B, f8897418, manifiesto inicial» (prueba `Crear_la_linea_base_de_los_dorados`, omitida sin la variable). Registra los 78 archivos con «— → hash» y no escribió ningún dorado.
- `GuardaDoradosTests.cs` (nuevo, `Esquema=Neutral`): 24 pruebas más la herramienta. **No usan SQL** (verificado: corren sin `GPOST_TEST_SERVER`).

| G | Comportamiento | Prueba | Mutación hecha (compilada y corrida) → pruebas que cayeron |
|---|---|---|---|
| G-1 | `regenerar` escribe si cambió y el caso **falla siempre**, con la lista acumulada de los recapturados y la orden de revisar el diff. Si la copia difiere de la principal, también lo dice | `Regenerar_siempre_falla`, `Regenerar_sin_cambios_tambien_falla_y_no_toca_nada`, `Regenerar_avisa_si_la_copia_difiere…` | quitar el `Assert.Fail` final → 7 fallan |
| G-2 | Sin `GPOS_TEST_DORADOS_MOTIVO` (nulo, vacío o espacios) falla antes de escribir. Un modo desconocido también falla | `Regenerar_sin_motivo_no_escribe_nada` (×3; compara una foto de bytes de la carpeta), `Un_modo_desconocido_falla_sin_escribir` | quitar la comprobación → 3 fallan |
| G-3 | Una entrada por corrida en `CAMBIOS.md`: fecha UTC, motivo (en una línea), versiones y «`archivo`: anterior → nuevo». La verificación exige la historia **encadenada** de cada dorado y que termine en el hash del manifiesto | `Regenerar_agrega_su_entrada…`, `Un_dorado_cambiado_sin_su_entrada_en_CAMBIOS_se_detecta`, `Una_entrada_borrada_de_CAMBIOS_se_detecta`; real: `Todo_dorado_cambiado_tiene_entrada_en_CAMBIOS` | no escribir la línea → 2; quitar la cadena → 1; quitar «última = manifiesto» → 1 |
| G-4 | `manifiesto.json`: SHA-256 del contenido **normalizado** (HTML UTF-8 con LF, PDF sin fechas) y versiones (QuestPDF 2026.9.0, Mvc.Razor.RuntimeCompilation 10.0.12, .NET 10.0) | `Un_byte_cambiado_a_mano_se_detecta`, `Un_dorado_fuera_del_manifiesto…`, `Los_fines_de_linea_y_las_fechas…`, `Una_version_distinta_del_motor…`; reales: `Los_dorados_coinciden_con_el_manifiesto`, `Las_versiones_del_manifiesto_son_las_del_proceso` | quitar la comparación del hash → 1; no actualizar el manifiesto al recapturar → 2; **editar `</html>` en `html/Pago.Carta.html` real** → falla la prueba real (restaurado) |
| G-5 | LEEME con el modo, el motivo, CAMBIOS.md, el manifiesto, la línea base, CI y la revisión humana (no hay `CODEOWNERS`) | `El_LEEME_de_los_dorados_explica_la_guarda` | cambiar «CAMBIOS.md» en el LEEME real → falla (restaurado) |
| G-6 | Con `CI`, `TF_BUILD` o `GITHUB_ACTIONS` (distinta de `false`/`0`) y el modo o el motivo puestos, falla antes de escribir. Sin esas variables, en CI se compara como siempre | `Regenerar_no_se_acepta_en_integracion_continua` (×3), `CI_en_falso_no_cuenta…` | quitar la comprobación → 3 fallan |

Extra (P152-16): en `regenerar`, un PDF que solo cambió de fechas **no se reescribe**, así que el diff no tiene ruido. El PDF se sigue escribiendo tal como sale, como antes.

## Corridas (todas en OSHIN-LEGION, Debug, una a la vez)
- `dotnet build tests/GPOS.Tests`: correcta. La única advertencia nueva (ASPDEPR003 en mi archivo) se corrigió cargando el ensamblado de Razor por nombre. Las demás advertencias ya existían.
- `GuardaDoradosTests`: 24 superadas y 1 omitida (la herramienta).
- `RenderTrasladoTests` (la clase), **3 corridas**: 81/81 cada una, en 27, 25 y 25 s.
- Cableado real (teoría de PDF, 16 casos): con `regenerar` + motivo, 16 fallan con el mensaje G-1, no se escribió nada y el md5 de `CAMBIOS.md` y del manifiesto no cambió. Sin motivo, 16 fallan con G-2. Con `CI=true`, 16 fallan con G-6.
- 8 mutaciones de `GuardaDorados.cs` con un script (compila, corre la clase, restaura) y 2 sobre archivos reales. Todo restaurado y verificado.
- `PruebasNeutralesTests`: 28/28.
- P152b-03: `GPOS.Reportes.Tests` en Debug: la prueba del `Program` real pasa (1/1; `--filter Compilacion=Debug` la encuentra). En Release se compiló y la prueba sale **omitida** con su motivo.

## Qué NO se corrió
- La suite completa y el filtro oficial completo (regla de la PC).
- `RenderTrasladoTests` en Release; la guarda no depende de DEBUG.
- Una recaptura real con un cambio verdadero de plantilla: está cubierta por las pruebas en carpeta temporal, no sobre los dorados reales.
- La captura de los grupos 1-6 (la hace B en LFMB).

## Decisiones para B
1. **Versiones estrictas:** `Las_versiones_del_manifiesto_son_las_del_proceso` falla si sube QuestPDF o Razor aunque los dorados sigan iguales. Para registrarlo basta una corrida con `regenerar` + motivo, que deja la entrada con «Antes: …». De .NET solo se fija mayor.menor, porque el parche cambia entre máquinas. ¿Se acepta así, o prefieren que sea solo informativo?
2. **Formato del manifiesto:** JSON con hash del contenido normalizado; la revisión proponía `manifiesto.sha256`. Lo cambio si lo quieren.
3. **Modo `linea-base`:** es un modo nuevo, de un solo uso y que se niega si ya hay manifiesto. ¿Se conserva o se borra tras unir?
4. **Coordinación:** este PR modifica `RenderTrasladoTests.cs` (el comparador) y `tests/GPOS.Reportes.Tests/RenderInternoTests.cs` (P152b-03: atributo `FactSoloEnDebug` y `Trait("Compilacion","Debug")`). Avísenme si su agente toca esos archivos.
5. En LFMB, para capturar los grupos: `GPOS_TEST_DORADOS=regenerar` + `GPOS_TEST_DORADOS_MOTIVO="D-xx …"`, la clase, revisar el diff y luego una corrida limpia sin variables. Cada dorado nuevo entra con «— → hash».
