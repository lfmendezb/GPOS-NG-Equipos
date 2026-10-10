```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/pruebas-ui-estables (2ae3816), PR #20 hacia feature/modelo-ng
Estado: Abierto
```

# C-9: pruebas de interfaz estables con carga (PR #20)

**PR #20:** https://github.com/lfmendezb/GPOS-NG/pull/20. Se une sin conflictos con `e7f1f96`. C no une.

## Qué se hizo
- **Causa común:** los eventos síncronos de bUnit despachan con el identificador de manejador del último render. Con carga, el componente se vuelve a pintar entre la búsqueda del elemento y el disparo (`UnknownEventHandlerIdException`), o el evento queda en cola y la aserción lee el DOM viejo. La provocan el render final de `OnInitializedAsync`, el cierre de `MudSelect` y la cola de popovers de MudBlazor.
- **Defecto adicional:** `WaitForAssertion(() => Boton(...).Click())` daba por buena la espera con el botón deshabilitado.
- **Cambio, solo en `tests/GPOS.Web.Tests` (26 archivos):**
  - clase nueva `DisparoSeguro` (`c.Hacer(() => …)`), que busca el elemento y dispara el evento dentro de `InvokeAsync`;
  - esperas explícitas en `RestauracionSitioTests`;
  - el mismo patrón en el resto de la suite, donde también fallaban `DialogoDispositivo`, `LienzoZoom`, `EdicionSeries`, `FacturacionAgil*`, `ListasPrecios` y `DevolucionPosUnidad`.
- **Sin cambios en el código de producción ni aserciones relajadas.** No se encontraron carreras reales en los componentes.

## Cómo se verificó (dos `dotnet test` de GPOS.Web.Tests en paralelo por vuelta)
| | Corridas con fallos |
|---|---|
| Antes (`e7f1f96`) | **9 de 20** (RestauracionSitioSuper con 5 fallos en 4 corridas, más las clases citadas) |
| Después, 10 vueltas | **0 de 20**, con 574/574 en cada una, de 11 a 15 s |

- **Carga fuerte** (dos corridas más 6 bucles de CPU), después del cambio: 8 de 10 en verde. Las 2 fallas fueron esperas de 5 s sin ninguna comprobación («Check count: 0»), atribuidas a falta de CPU, sin probarlo. **Si B lo ve con su carga, la salida es subir esas esperas a 10 s.**
- **`GPOS.UI.MAUI.Tests`:** 484/484, sin cambios porque su único par no dispara eventos.

## Pendiente
- **B:** correr su suite con su carga habitual sobre la rama antes de unir.
- **Convención propuesta:** `c.Hacer(() => …)` para las pruebas nuevas de bUnit.

**Siguiente para C:**
- **C-10** (`c/compra-variable-tabla`, PR «no unir antes del 14-oct»), en marcha.
- **PC-1 y la precisión C-1 en el blueprint de ADR-81**, en curso, solo diseño.
