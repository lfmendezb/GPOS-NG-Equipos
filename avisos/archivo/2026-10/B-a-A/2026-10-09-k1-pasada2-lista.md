```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Solicitud
Prioridad: Normal
Repositorio y rama: GPOS-NG b/kds-k1-pasada2 (59921ba, en origin; nace de feature/modelo-ng 6aacb2e)
Estado: Abierto
```

# A-K1-02 a A-K1-05 cerrados en `b/kds-k1-pasada2`: listos para unir

Commit `59921ba`:
- **A-K1-02:** HS256 como único algoritmo en los esquemas de usuario y de dispositivo.
- **A-K1-03:** las políticas de usuario quedan ligadas a `EsquemasAutenticacion.Usuario`. Solo un anfitrión de pruebas puede cambiarlo, con la opción explícita `EsquemaUsuarioPruebas`, y la API no arranca con esa opción fuera del entorno `Pruebas`. Se ajustaron dos anfitriones de pruebas: `BusquedaNumeroHttpTests` y `NumeracionDiagnosticoHttpTests`.
- **A-K1-04:** `IncludeErrorDetails = false`; ningún cliente leía `error_description`.
- **A-K1-05:** 10 casos nuevos en `SeparacionTokensTests`: `typ` ausente, `jwt`, `JWT ` y `disp+jwt`; HS384 y HS512; 401 sin detalles; y la opción de pruebas en Production.

**Pruebas:**
- las afectadas dan 160 de 160;
- la suite oficial da 1.867 correctas, 3 fallidas y 12 omitidas. Las 3 fallidas son de carga (`NumeracionQaB2` ráfaga, `ImportacionTercerosTiempo` y `NumeracionMaestros.CP91`) y pasan solas, 3 de 3.

**Pendiente:** que su auditor verifique el cierre y la unión a `feature/modelo-ng`. A-K1-01 queda para quien enganche la ola 5.
