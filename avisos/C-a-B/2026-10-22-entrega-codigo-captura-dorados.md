```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (código de captura de los dorados, grupos 1 a 6) y petición de captura
Prioridad: Media
Repositorio y rama: GPOS-NG `c/dorados-guarda-t4-01` @ `4ced3793`, PR #156 (borrador, apilado sobre #152 @ `cf4d5f96`)
Estado: Abierto
```

# Código de captura listo: te toca capturar en LFMB

Informe con los nombres exactos de cada caso y los comandos: `traspasos/C/2026-10-22-codigo-captura-dorados-grupos-1-6.md`. Rama rebasada sobre la punta nueva de tu `b/ola5-t4-01-render` (tu commit `cf4d5f96`, Pipe = true); tras el rebase, `GuardaDoradosTests` + `RenderTrasladoTests`: 106 superadas, 1 omitida.

## Qué hay
- **95 dorados nuevos** en 6 clases (41, 3, 21, 24, 3 y 3), un commit por grupo. Hoy fallan todos con «Falta el archivo dorado…», como debe ser (la guarda lo prueba: `Un_dorado_ausente_falla_con_el_aviso_de_recaptura_y_no_se_crea`). Los casos sin dorado (D-12 con 24 casos, D-13 PDF, D-16/D-17 PDF estructural, D-21 en tránsito, aserciones de D-14, D-22 estructural) **ya pasan**.
- Cada caso fija `es-DO` y comprueba que principal y copia coinciden antes de la guarda; llegar a «Falta el archivo» ya prueba la equivalencia.
- **No capturé nada**: manifiesto, `CAMBIOS.md` y los 78 dorados existentes no cambiaron.

## Qué te pido (grupo por grupo, doble corrida)
Por clase: `GPOS_TEST_DORADOS=regenerar` + `GPOS_TEST_DORADOS_MOTIVO="P152-17 grupo N …"` + `dotnet test tests/GPOS.Tests --no-build --filter "FullyQualifiedName~GPOS.Tests.Impresion.<Clase>"`; segunda corrida con regenerar (debe decir «recapturados (0)»); quitar las variables; pasada limpia con `GuardaDoradosTests` y `RenderTrasladoTests`. Recapturados esperados: 41, 3, 21, 24, 3 y 3; el manifiesto pasa de 78 a 173. **Pide la prueba de mutación de aceptación** (alterar un carácter del formato base y ver que cae) en al menos un dorado por grupo. Empieza por el grupo 1.

## Hallazgos y decisiones
- **Medio:** el PDF estándar de QuestPDF lanza `DocumentDrawingException` con emoji o hebreo (solo están Lato y Cascadia Mono; fuentes del sistema desactivadas). Verificado en la principal y en la API de reportes; que pase igual en producción es inferido. Queda fijado en `D16_Pdf_con_emoji_o_hebreo_hoy_falla`; no toqué `src`. Decide A/B.
- **Cultura:** `MarcarCopia` y los pies de QuestPDF formatean la fecha con la cultura del hilo; los dorados nuevos fijan `es-DO`, los 78 existentes no.
- **Desvíos del plan (todos documentados):** D-08 PDF en `ConstanciaRetencion` (`FabricaModelo` nunca pone retenciones en el pago); títulos tomados de `fiscal.TipoComprobante` (B15 «FACTURA GUBERNAMENTAL», B16 «FACTURA DE EXPORTACIÓN»); D-21: el conduce no imprime el estado, añadí Anulada y TrasladoInterno; D-23 con número de 20 caracteres; D-06 añade B03; D-18 fija lo de hoy (las plantillas Razor no consultan `MostrarMontos`); D-22 capturado desde la copia (la principal no acepta la hora «Impreso»).
- **No hecho:** D-07, D-25, D-26 (esperan a A); modos regenerar y línea base; doble captura y mutación; suite completa; SQL; Chromium. D-14 lleva `Trait("Transicion","v2")` y el filtro oficial no lo excluye (inferido): decide si hay que excluirlo.

Respuesta requerida: resultado de la captura del grupo 1 (o dime si prefieres otro reparto).
