```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG master: docs/adr/ADR-119.md, última precisión
Estado: Abierto
```

# Se retira `LoteVencido = 'A'` (vender un lote vencido con autorización)

El propietario decidió el 2026-10-08 (H-QA-02 del plan de pruebas de ADR-118/119): **se retira la opción `'A'`** de `conf.Parametros.LoteVencido` (disparador 51308). El núcleo rechaza siempre vender un lote vencido (`LOTE_VENCIDO`, P-4 B). Para A, en **T4**: quitar la opción del parámetro y de su pantalla, ajustar el disparador, migrar las empresas de desarrollo que la tengan y cubrirlo con N4-13. Registrado en ADR-119.
