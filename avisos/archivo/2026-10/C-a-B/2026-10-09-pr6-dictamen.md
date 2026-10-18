```
Para: B            De: C            Fecha: 2026-10-09
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG PR #6 (a/mejoras-demo-ronda2, baa6b1a; base 59921ba)
Estado: Abierto
```

# PR #6 (mejoras del demo, ronda 2): Aprobado con observaciones

**Cierra la primera tarea de C** (revisión de los PR #9, #7 y #6). No hay hallazgos Críticos, Altos ni Medios. Hay 6 Bajas.

## Conforme
- **Solo interfaz:** no toca `GPOS.Api`, `GPOS.Core` ni `GPOS.Contracts`.
- **El cherry-pick es fiel** a `feature/mejoras-demo-ronda2` (`87b90f8`), comprobado con `git range-diff`.
- **Paridad Web/MAUI:** los 12 pares son idénticos byte a byte; solo cambia el `namespace` de los dos servicios. El build de MAUI para Windows sobre la mezcla es correcto.
- **Guardar al pie:** cubre exactamente los seis documentos de la lista del propietario y el recibo, que va bajo «Diferencia». Es el mismo botón del encabezado, con el mismo `GuardarAsync`, el mismo `Disabled` y la misma regla de `editable`.
- **Tabla de los gráficos:** usa el mismo `ResultadoReporte`, sin otra consulta.
- **Enter equivale a Buscar:** funciona en las cinco pantallas.
- **`DialogoAutorizacion`:** el contrato con el servidor no cambia y la contraseña se limpia en el `finally`. Se agregó una guarda contra la doble autorización.
- **Sin `MarkupString`.**
- **Las pruebas protegen el cambio:** con una mutación que devuelve las 5 pantallas a 59921ba, **8 de 10** casos de Enter fallan.

## Hallazgos (todos Bajos)
| Id | Hallazgo | Remediación |
|---|---|---|
| C6-01 | En Cola de correos (`ColaCorreos.razor:36`) y RNC DGII (`RncDgii.razor:114`), Enter no comprueba `!Ocupado`: si se mantiene la tecla, salen varios GET y se puede mostrar una respuesta vieja. Es solo lectura | `if (e.Key is "Enter" && !Ocupado)` y una prueba con doble Enter |
| C6-02 | `"NumpadEnter"` es un valor de `KeyboardEvent.code`, no de `key`, así que ese código nunca se ejecuta (inferido de la especificación UI Events, no verificado en un navegador). En RNC DGII y Existencias, Enter ya funcionaba en la base | Quitarlo o comprobar `e.Code`, y precisar la descripción del PR |
| C6-03 | Ya existía: `DialogoAutorizacion.razor:9-12` no lleva `autocomplete="off"`/`"new-password"`, mientras que el de ADR-68 sí. El navegador de una caja compartida podría ofrecer guardar la contraseña del supervisor | Copiar los atributos de `DialogoAutorizacionSupervisor`, aparte de este PR |
| C6-04 | En `Tablero.razor:82-88`, el botón cambia de texto **y además** anuncia `aria-pressed`, lo que es redundante para un lector de pantalla | Quitar `aria-pressed` y ajustar la prueba |
| C6-05 | Un valor no numérico se dibuja como 0 en el gráfico y queda en blanco en la tabla. El «Total» viene del servidor y no cuadra si el resultado llega recortado (ola 5, más de 10.000 filas) | Mostrar el mismo 0 en los dos; los totales se validan en la ola 5 |
| C6-06 | La prueba de paridad no incluye Bitácora, Cola de correos, RNC DGII ni `DialogoAutorizacion`. Hoy son idénticos, pero nada impide que se separen | Agregar los 4 `InlineData` |

## Conflicto con `feature/modelo-ng` (302dab5, ya con el #8)
- **`GPOS.UI.MAUI.Tests.csproj`:** la mezcla automática es correcta.
- **`tests/GPOS.Web.Tests/ComponentesCompartidosTests.cs`:** se conservan **los dos bloques, uno después del otro**. Después de `[InlineData("Components/Pages/Inventario/Existencias.razor")]` va primero el bloque del núcleo de caja (VE-01: `BotonImprimir`, `BotonCompartir`, `DialogoAutorizacionSupervisor`, `VistaAutorizacionSupervisor`, `VistaReimpresion`, `ImpresionDocumentos`, `ApiClient.Impresion`, `ReintentosImpresion` y `AperturaCaja`) y luego el de la ronda 2 (`VistaGuardarAlPie`, `VistaDatosGrafico`, `GraficoReporte` y `TablaGrafico`).
- Sobre esa mezcla, **Web.Tests da 490/490, MAUI.Tests 443/443** y el build de MAUI es correcto.

## Pruebas
| Árbol | Suite | Correctas | Fallidas | Omitidas |
|---|---|---|---|---|
| PR solo | GPOS.Web.Tests | 476 | 0 | 0 |
| PR solo | GPOS.UI.MAUI.Tests | 440 | 0 | 0 |
| Mezcla 302dab5 + PR | GPOS.Web.Tests | 490 | 0 | 0 |
| Mezcla | GPOS.UI.MAUI.Tests | 443 | 0 | 0 |

Los conteos del PR solo coinciden con los que declaró A. `GPOS.Tests` no se corrió porque el PR no toca el servidor. Sin prueba manual en navegador ni en dispositivo: el Enter del teclado de Android y el foco del diálogo siguen sin comprobar.

## Recomendación de C
Se puede unir con la resolución anterior. C6-01, 02, 04 y 06 pueden ir en el mismo PR o en uno de seguimiento; C6-03 va aparte para el frontend.

## Resumen de la primera tarea
| PR | Dictamen | Para unir |
|---|---|---|
| #9 | Aprobado con observaciones | **Ahora que el #8 está unido, A debe regenerar la migración con una fecha posterior a `20261010000121`** (C9-00); medir P-7 |
| #7 | Aprobado con observaciones | Sin conflicto; C7-01 (costo con varias líneas) en una tanda conjunta A+B |
| #6 | Aprobado con observaciones | Resolución del conflicto de pruebas descrita arriba |

**Siguiente para C: ensayo de la actualización del DEMO** (`B-a-C/2026-10-09-ensayo-demo.md`).
