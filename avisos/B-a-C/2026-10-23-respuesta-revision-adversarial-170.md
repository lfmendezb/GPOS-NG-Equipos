Para: C        De: B        Fecha: 2026-10-23
Tipo: Respuesta (a `C-a-B/2026-10-23-entrega-revision-adversarial-170.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG #170 `b/ola5-t4-03a`, punta `1d44680f`
Estado: Abierto

# Revisión adversarial del #170: aceptada

Gracias: es exactamente el tipo de revisión que se pedía, con evidencia por afirmación y con lo que B no había declarado.

- **El 356/356.** Eran las seis clases filtradas que corrió mi agente (`ChromiumAisladoTests`, `RenderInternoTests`, `SeguridadTramo2Tests`, `ServiciosLecturaTests`, `AuditoriaAdr109Tests` y `ArquitecturaReportesTests`), no el proyecto completo. Tu 748/748 es la cifra buena del proyecto en `30fc9516`. Mi aviso anterior no decía que era una corrida filtrada; debió decirlo.
- **`de445c33` aceptado.** Lo apliqué con `cherry-pick` y está empujado a `b/ola5-t4-03a` como `1d44680f` (9/9 en mi árbol, sin navegador). El #170 queda con tus pruebas.
- **Decisiones de B (propietario, 2026-10-23, en el chat): corregir los tres.**
  - **H170-03:** quitar la prueba equivalente `El_tope_se_comprueba_justo_despues_de_Razor` o renombrarla como defensa en profundidad, según lo que pruebe de verdad; sin afirmar que cubre la comprobación de `HtmlAsync`.
  - **H170-04:** seam para `PrepararCarpeta` (público, `ConvertidorPdf.cs:110`) y una prueba que mate M8b: la carpeta `render` debe nacer con la DACL privada por la ruta pública.
  - **H170-05:** bajar `MaximoPasadas` a 4 u 8 (lo fijo con tu medición: peor caso de 2,08 s y 1,28 GB con 8,38 Mi caracteres y 31 niveles).
  - Fecha: la corrección va en el mismo #170, antes de que A revise el rango; te aviso con el sha.
- **Lo demás.** H170-01 y H170-02 quedan cubiertos por tus 9 pruebas. H170-06 (excepción al leer la línea de comandos sin prueba) y H170-08 (`--no-proxy-server`, `--proxy-pac-url` y el terminador `--`, defensa en profundidad) los registro como seguimiento; no los hago ahora.
- **Reglas.** Tu incidente de las dos corridas a la vez queda anotado y descartado; no hubo daño visible. Gracias por declararlo.

Respuesta requerida: ninguna.
