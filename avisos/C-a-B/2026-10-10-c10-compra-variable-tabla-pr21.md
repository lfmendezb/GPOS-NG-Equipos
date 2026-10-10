```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/compra-variable-tabla (6c39a85), PR #21 hacia feature/modelo-ng — NO UNIR ANTES DEL 14-OCT
Estado: Abierto
```

# C-10: optimización de la compra (PR #21, no unir antes del 14-oct)

**PR #21:** https://github.com/lfmendezb/GPOS-NG/pull/21, con «NO UNIR ANTES DEL 14-OCT» en el título. Se une sin conflictos con `9e35b8b`. C no une.

## Qué se hizo
- **51344 sobre una variable de tabla, solo dentro de su guarda** (FCP o DVS emitida, fuera de la implantación): `@e` se carga una vez y sustituye las nueve repeticiones de la tabla derivada.
  - Las reglas 51341 a 51358 y 51407, los mensajes, el orden y las salidas tempranas no cambian.
  - Sin `KEEPFIXED PLAN` ni `NORECOMPUTE`, y sin bloqueos nuevos.
  - **Desviación del encargo:** `@e` en todas las reglas, como se propuso, empeoraba CHK, CC y DBA en 0,25 a 0,4 ms (planes con las tablas vacías al compilar), así que quedó acotada a 51344.
- **`UQ_CxpAplicacion` con INCLUDE** de `Monto, MontoAplica, Tasa, RetencionItbis, RetencionIsr, Anulada`.
  - **Desviación:** son más columnas que `Monto` y `Anulada`, porque las sumas de `SqlMigracionesOla4.cs:269, 285 y 445` y la 51347 leen las demás.
  - **Verificado en el plan:** pasa de recorrer la PK a buscar en `UQ_CxpAplicacion`.
- **Migración y guion:** `20261010155005_Ola4CompraVariableTabla`, después de `BitacoraLogSoloInsercion`, con su Down, y el guion acumulado regenerado con `--idempotent`.

## Cómo se verificó (`.\SQLEXPRESS`, máquina sola)
| Medición (`PerfilDisparadoresOla4Tests`, un hilo) | Antes (`e7f1f96`) | Después |
|---|---|---|
| FCP de 20 líneas, `UPDATE` de emisión | media 19,7 ms (17,4–24,2) | **media 12,7 ms (12,5–12,9), −35 %** |
| Compilación de 51344 | 91 ms | 36–37 ms |
| CHK, CC y DBA | sin cambio | sin cambio |
| POS | — | +3 µs por ejecución, dentro del ruido |

- **`CompraVariableTablaTests`** (nueva, 8 casos): 8/8 en tres corridas. Comprueba la migración idempotente y el Down; la equivalencia carácter por carácter con el disparador anterior; 51344 con una FCP real y cinco variantes que deben fallar; y los planes de CXP.
- **Conjunto relacionado:** 454/459 con 1 fallo y 4 omitidas.
  - **El fallo:** `AplicacionEmisionPlanTests`, con el error 952 bajo carga, que es la intermitencia que ya conocía B; pasa sola.
  - **Además:** `RendimientoOla4Tests.A1` falló una vez con carga; no ejecuta el disparador modificado.

## Pendiente o para B
- **Antes del 14-oct:** que B repita el perfil en su equipo.
- **Orden de unión:** si el segundo PR de H-11 de A se une antes, **hay que regenerar esta migración con una fecha posterior**, junto con el guion acumulado. C puede rebasarla si B lo pide.
- **Arquitecto de datos:**
  - registrar en el §8.2 de `docs/datos/2026-10-06-disparadores-emision-y-borrador.md` la excepción de la variable de tabla en `TR_Documento_Ola4`, solo para 51344;
  - **hallazgo fuera de alcance:** la suma de 51355 por `DocumentoAfectadoId` recorre `PK_CxpAplicacion`, porque `IX_CxpAplicacion_Afectado` no incluye `DocumentoAplicaId`. Probablemente pasa lo mismo en CXC (`IX_Aplicacion_Afectado`), sin verificar.
- **Para quien mantenga `AplicacionEmisionPlanTests`:** reintentar ante el error 952, como hace `CompraVariableTablaTests`.

## Estado de C
- **El encargo C-2, C-8, C-9 y C-10 queda completo.** Los PR #19 y #20 están unidos y el #21 queda a la espera del 14-oct.
- **ADR-81 fase A:** el diseño está cerrado (blueprint v3 y pantallas v2, con P-81A-14 firmada).
- **C queda sin agentes activos y disponible.** Cuando A una el segundo PR de H-11, C puede construir la fase A de ADR-81, empezando por T1 si B lo encarga antes.
