```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/rb-p4-pruebas-fiscales (d0fad94), PR #22 hacia feature/modelo-ng
Estado: Abierto
```

# C-11: pruebas de base de las reglas fiscales (RB-P4) — PR #22

**PR #22:** https://github.com/lfmendezb/GPOS-NG/pull/22. Se une sin conflictos con `ec459d5`. C no une.

## Qué se hizo
- **Clase nueva `ReglasFiscalesBaseTests`** (55 casos), contra SQL Server, que dispara el disparador real.
  - No cambia el código de producción ni duplica las reglas en el servicio.
  - En cada rechazo se comprueba el número exacto, el código de texto, `@@TRANCOUNT = 0`, que no se guardó nada (en una conexión nueva) y que no quedó ningún disparador apagado.
- **Cobertura:**

| Regla | Casos (fallan / pasan) |
|---|---|
| 51379 PLAZO_FISCAL | 3 / 6 |
| 51359 COMPRA_606_COSTO | 6 / 4 |
| 51362 DEVOLUCION_EXCEDE | 5 / 4 |
| 51374 RETENCION_RECIBIDA_INVALIDA | 7 / 5 |
| 51375 MONTO_BASE_INVALIDO, CxC y CxP | 6 / 4 |
| 51376 MOTIVO_EN_USO | 3 / 2 |

## Cómo se verificó (`.\SQLEXPRESS`)
- **La clase nueva:** 55/55 en tres corridas seguidas.
- **Con las clases cercanas:** 244/244 (disparadores de emisión, arquitectura, `MigracionOla4b`, conceptos de nota, conversión, notas de CxP, fecha anterior y período fiscal).
- **Limpieza:** no quedaron bases de prueba.

No llegó la lista de casos del arquitecto de datos de B. Si llega, C la compara con lo hecho.

## Observaciones (para el arquitecto de datos de B)
- **H-1:** 51376 **sí tenía** una prueba (`MigracionOla4bTests.cs:192-208`), así que hay que corregir RB-02 y §6.4 del inventario. 51359 solo tenía pruebas del camino válido.
- **H-2:** 51359 es asimétrica. El ITBIS exige igualdad, pero el ISC solo exige que el del 606 no sea menor, aunque el mensaje diga «no coinciden». La prueba lo deja fijado así. **¿Es intencional?**
- **H-3, informativa:** 51379 mide desde la factura hasta el «hoy» de la empresa, no hasta la fecha de la nota. Coincide con el comentario 2.5 del disparador.

## Riesgos que no cubre
- Las reglas se prueban aisladas, con los otros disparadores apagados durante la emisión; falta la emisión completa por el servicio.
- En 51362 las líneas son de servicio, así que no se prueba la comparación de artículo y unidad.

**Siguiente para C:**
- **C-12** (`NcfOrigenTests`), sola, ya en marcha.
- **La construcción de C-13** espera C13-P01 a 04 del propietario.
