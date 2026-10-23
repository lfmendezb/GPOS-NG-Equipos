# Revisión de seguridad del #170, rango `89fce5b5..03bbceea` (A, 2026-10-23)

Rama `b/ola5-t4-03a`. Árbol de lectura `GPOS-NG-r170` (solo lectura, `HEAD` en `03bbceea`). Alcance: P170-01 a P170-06, H170-03, H170-04 y H170-05.

## Veredicto
**Aprobar con condiciones.** Sin Críticos, Altos ni Medios. Dos observaciones Bajas y una prueba intermitente que conviene arreglar antes de la unión.

## Qué se revisó
- `SanearHtml`, `ComprobarTamano` y `MaximoPasadas = 4` (`PoliticaRedNavegador.cs`).
- `ProblemaLineaComandos` normalizada por nombre de switch.
- `EstadoLineaComandos` y su uso en `ConvertidorPdf` (P170-03), más el 503 `NAVEGADOR_NO_DISPONIBLE` de `/api/salud`.
- `FinAperturaBody` en lugar de la expresión regular, `Marcador` y los ganchos internos de prueba.

## Resultado por punto
- **P170-01, 02, 05 (capa 0):** correctos. Falla cerrada: la apertura sin cerrar se rechaza, `link` y `meta` con otro `<` en su tramo se quitan, `meta http-equiv` y `base` se quitan siempre. `EmpiezaEtiqueta` exige delimitador, así que `<metadata>` y `<basefont>` no se confunden. `FinAperturaBody` es equivalente a la expresión regular anterior y lineal.
- **H170-05 (4 pasadas):** aceptable. Agotar las pasadas lanza `FormatoInvalidoException` (falla cerrada); una cadena legítima usa 1 o 2. `Marco` se comprueba al inicio de cada pasada, incluida la última que devuelve.
- **P170-04:** correcto. Cada switch exigido debe aparecer y todas sus apariciones tener el valor esperado. Admitir repetidos con el mismo valor es seguro (Chromium toma el último y es el mismo).
- **P170-03:** correcto. «Se leyó y no cumple» enclava de inmediato; «no se pudo leer» enclava a la tercera (esperas de 5 s y 30 s). La lectura de `Enclavada` es `volatile`; el resto del estado va bajo el semáforo.

## Observaciones
- **R170-01 (Baja, prueba intermitente):** `Un_documento_data_anidado_corta_el_render` falló 1 vez de 4 corridas en esta PC con el caso «iframe sandbox (proceso aparte con IsolateSandboxedIframes): salió a la red» (`ChromiumAisladoTests.cs:955`), con `SinArgumentosRed = true`. Las otras 3 corridas y las 275 pruebas restantes pasaron. P170-06 excusa la intermitencia solo para `<object>` (`limitacionCapa1`), pero el iframe sandbox con proceso aparte muestra la misma carrera de la capa 1 sola. No es un hueco de producción (la capa 2 está activa fuera de la prueba), pero la prueba puede fallar en CI. Pedir: tratar ese caso como `<object>` (limitación conocida de la capa 1 sola) o quitar `SinArgumentosRed` del caso y comprobar la capa 2.
- **R170-02 (Baja, diseño):** `InternalsVisibleTo Include="GPOS.Reportes.Api"` expone todos los internos de `GPOS.Reportes` a la API para un solo gancho de pruebas (`PrepararPrivadaEnComponente`, que salta la comprobación de padres de ADR-77). Pedir: una prueba de arquitectura que fije que solo `ConvertidorPdf` lo llama en código de producción, o mover el gancho detrás de un método público con la comprobación de padres.
- **Información:** un adversario que provoque 3 fallas de lectura seguidas enclava el navegador hasta reiniciar el servicio (denegación de servicio acotada, visible en `/api/salud` y en el 5156). Es el compromiso firmado; no pido cambio.

## Pruebas
`GPOS.Reportes.Tests` con filtro `ChromiumAislado|CapaCero|PoliticaRed`: 275/276 en la primera corrida (la intermitente), 5/5 en tres corridas posteriores del mismo caso. No corrí la suite completa de 758.

## Abiertos sin tocar (según B)
P170-07 (marca del HTML), H170-06 y H170-08 (seguimiento de C): fuera de este rango.
