Para: C        De: B        Fecha: 2026-10-23
Tipo: Respuesta (a tus dudas de `traspasos/C/2026-10-23-plan-pruebas-t4-02b.md` y `2026-10-23-plan-tabla-adversaria-p170-07.md`)
Prioridad: Media
Estado: Abierto

# Respuestas técnicas de B a tus dudas (el arquitecto las verificó contra el código)

Estas son decisiones técnicas; **las dos que cambian algo visible van al propietario** (al final). Fuentes: blueprint de T4-02, `ConvertidorPdf.cs`, `ClienteRender.cs` (rama `b/t4-02a`), `ReglasReimpresion.cs`, `MedicionRender.cs` y la espiga `b/p170-07-espiga`.

1. **Línea base de C-3:** `docs/calidad/AAAA-MM-DD-linea-base-medicion-render.md` en `master` (hay precedente en esa carpeta: la línea base de la ola 0). Se mide con `GPOST_B9=medir` (con `=1` la prueba falla por la meta de +50 ms), los 4 escenarios de `MedicionRender.cs:105-106`, 5 de calentamiento y 50 pasadas, 3 corridas. La medición la hago yo (esta PC), cuando actualices el #156.
2. **Código del 503 del navegador:** **`NAVEGADOR_NO_DISPONIBLE`** (blueprint 5.3, `ConvertidorPdf.cs`, `ClienteRender.cs`). `REPORTES_NO_DISPONIBLE` queda solo para la API de reportes apagada o sin respuesta. Dos correcciones a tu plan: no es «carpeta ausente» (si falta, se crea) sino una carpeta que **no cumple ADR-77**; y **no existe** la opción `GPOS:Reportes:Render:Perfil`.
3. **¿10 o 13 archivos de pruebas?:** ninguno de los dos, por búsqueda de nombres (sin compilar): 9 archivos usan los motores directamente (`SeguridadPc3Tests` no cambia), y aparte hay una lista de archivos que pasan por las rutas de impresión (`NumeracionPc3EjemploTests` no genera PDF). El PR de T4-02b trae las dos listas con su conteo de pruebas.
4. **Reintento libre (R429-06):** `ReglasReimpresion.cs:34-55`: 2 reintentos en 600 s, del mismo usuario, dejan una fila de clase `F` sin «COPIA»; un 429 no gasta reintento.
5. **Prueba transitiva:** va en `GPOS.Tests` (`GPOS.Reportes.Tests` no referencia `GPOS.Api`). Lee `GPOS.Api.deps.json` filtrando `type: package` (sin el filtro, los ensamblados de Razor del marco dan falsos positivos). Lista negra: seis paquetes reales del archivo más los sospechosos que ya vigila `AuditoriaAdr109Tests` (no aparecen SkiaSharp ni HarfBuzz). No sirve el método por ensamblados cargados (`GPOS.Tests` también carga `GPOS.Reportes.Api`). Si pasa a `GPOS.Tests`, `estado.json` cambia en dos nombres de prueba, no uno.
6. **Código cuando C-1 rechaza:** **400 `FORMATO_INVALIDO` con un texto propio**; un código nuevo caería en el caso por omisión de `ClienteRender` y saldría como 503 «el servicio no está», que es falso. El rechazo no registra ninguna copia.
7. **Doble banda con QuestPDF:** no puede ocurrir; cada documento pasa por un solo motor (`ServicioRender.cs:29,33`).
8. **Margen de la guarda:** fijo de 10 mm en una sola constante; las pruebas escriben 25 mm y 20 mm a mano para que un cambio del margen se note.
9. **Espiga, TA-27, TA-43 y TA-54** (el arquitecto revisó los PDF y PNG que dejó la corrida en `%TEMP%\GPOS_TEST_ESPIGA_P17007`; no hay registro de qué pruebas pasaron): TA-27, las cajas de margen se pintan alrededor de la banda y la marca y el pie quedan encima y completos; TA-43, la marca y el pie salen en su sitio y la plantilla solo baja su contenido; TA-54, ningún PDF trae `/Rotate` (Chromium da la hoja apaisada intercambiando la `/MediaBox`): **la guarda debe rechazar si aparece `/Rotate` o si el número de `/MediaBox` no coincide con el de páginas.** Ninguno rompe (b): no se pasa a (c).

**Correcciones a lo que esperas:** R429-03 y R429-05: la primera reimpresión es «COPIA 2», no «COPIA 1» (`ReglasReimpresion.cs:41`, `ReglasReimpresionTests.cs:28-34`); R429-07 (doble clic): la petición que pierde sale como reintento de clase `F`, no como copia (`ImpresionEndpoints.cs:202`); S503-02: la tabla es `doc.Documento`.
**Otras:** P170-07 va en su propio PR, después de T4-02b; el contrato sigue en la versión 1; la lectura del PDF adopta la técnica de la espiga (solo la biblioteca base de .NET: no necesita consulta); la espiga se porta pero las pruebas van contra el código de producción; en la vista previa con copia manda la vista previa (`ModeloImpresion.cs:68`); M-d se registra «No aplica»; el **pie de hoy sigue sin `!important`** (`ServicioRender.cs:128-129`): es el cambio de una línea de la hoja de P170-07, lo hago yo.

## Las dos que van al propietario (te aviso cuando decida)
- **P-1:** ¿la guarda C-1 también en la vista previa con un comprobante real? (Sin ella, la vista previa puede salir sin «SIN VALOR FISCAL».) Mi recomendación: sí; afecta solo al SUPER que mantiene plantillas Razor; 0 dp.
- **P-T402-03:** formato estándar de emergencia cuando falta el navegador. Recomendación (a): no en T4-02; lo decide C-02-2 con T4-10. Tú la necesitas para fijar C4-02: **trabaja con (a)** hasta que el propietario firme.

**#156:** el propietario lo asignó a C; si no está unido el 13-nov, lo adopto yo.

Respuesta requerida: ninguna.
