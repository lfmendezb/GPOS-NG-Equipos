```
Para: B                         De: C (QA)                    Fecha: 2026-10-20
Tipo: Revisión de pruebas, solo lectura (tarea 2 del encargo del 2026-10-20)
PR: #121 (T4-05), rama b/t4-05-vistas-p2, commit 59c16146 (SEG-T405-01 y SEG-T405-03), sobre 81c92c40
Estado: Abierto
```

# Revisión de pruebas del commit 59c16146 del PR #121

## Dictamen: lo que el commit corrige está cubierto, con observaciones (Aprobado con observaciones para este commit; el dictamen global del #121 no cambia)

**¿Las pruebas del commit cubren lo que corrige?** Sí en lo esencial, y las dos pruebas nuevas fallarían sin la corrección:
- **SEG-T405-01** (tasa 1 en moneda base del cheque devuelto y de la importación): `CobrosTests.Cheque_devuelto_en_moneda_base_guarda_tasa_1_y_en_dolares_conserva_su_tasa` (`CobrosTests.cs:128`) y `NcfHistoricoTests.La_importacion_en_moneda_base_guarda_tasa_1_y_en_dolares_conserva_su_tasa` (`NcfHistoricoTests.cs:148`) mandan tasa 58 en la moneda base y exigen tasa 1 en la cuenta, y la conservan en dólares. Sin `moneda.EsBase ? 1 :` (`CobrosService.cs:541`) o sin la normalización (`ImportacionesService.cs:434-440`) la tasa leída sería 58 y la aserción falla. La importación además afirma la advertencia en la columna `Tasa` (fila 2) y la ausencia de aviso en dólares.
- **SEG-T405-03** (mensaje del 51399): `VistasP2Tests.La_migracion_rellena_la_tasa_...` (`VistasP2Tests.cs:309-312`) afirma el conteo, la condición real y la ausencia de `ConciliacionCxc`, y conserva las comprobaciones de que no se cambió nada (la columna no existe, la vista tampoco). El guion idempotente (`database/empresa/gpos-empresa-20261021001638_Ola5VistasTramo4.sql:18098-18104`) y la constante de la migración (`SqlMigracionesOla5Tramo4.cs:19-25`) tienen el mismo bloque (comparados a ojo en el diff).

Lo que no cubre, y lo que sigue abierto de la primera revisión, está abajo. No ejecuté nada: las cifras esperadas (1000, 5800, 118, 6844) las tomé del código de las pruebas y no las verifiqué contra la base.

## Estado de los hallazgos Altos de la revisión anterior tras el commit

| Id | Antes | Ahora | Por qué |
|---|---|---|---|
| P121-01 (ningún origen de `cxc.Cuenta` verifica la tasa) | Alta | **Media** | Dos de los cuatro orígenes (cheque devuelto e importación) ya tienen prueba de flujo con la tasa en moneda base y en dólares, y son los que tenían el defecto. Quedan sin prueba la factura a crédito, la nota de débito y `Partidas` con tasa menor o igual a cero (P121S-02) |
| P121-02 («redondeo por fila» con datos que no redondean) | Alta | **Alta** | `CuadreCxc` repite la tautología y los datos nuevos tampoco redondean (P121S-03) |
| P121-03 (cuatro vistas sin aserciones con datos) | Alta | **Alta** | El commit no toca esas vistas |
| P121-04 (no se evidencia que `MigracionOla5VistasTests` corriera) | Alta | **Alta** | Sin cambio; B debe pegar el resultado en el PR |

Con P121-02, 03 y 04 abiertos, la recomendación del #121 sigue siendo Rechazado hasta que el PR apilado de B (tarea 1 del encargo) las cierre. Este informe no la cambia.

## Hallazgos nuevos

### P121S-01 · Media · No se afirma que `cxc.Cuenta.Tasa` sea la de la venta
- **Evidencia:** `VistasP2Tests.cs:421-444` (`CuadreCxc.TasaAsync` lee solo `cxc.Cuenta.Tasa`; ninguna prueba nueva lee `ventas.Venta.Tasa`). El mensaje del commit dice que «la cuenta por cobrar toma la tasa de la venta»: ese es el invariante que se corrige, y no se prueba directamente.
- **Prueba propuesta:** agregar a `CuadreCxc` `VentaTasaAsync(cadena, numero)` y afirmar en las dos pruebas nuevas `Assert.Equal(await VentaTasaAsync(...), await TasaAsync(...))`; más el invariante global de P121-01: `SELECT COUNT(*) FROM cxc.Cuenta c JOIN ventas.Venta v ON v.DocumentoId = c.DocumentoId WHERE c.Tasa <> v.Tasa` es 0 (`CuadreCxc.TasaDeLaCuentaEsLaDeLaVenta`).

### P121S-02 · Media · Orígenes y ramas de la tasa que siguen sin prueba
- **Evidencia:** `Partidas.cs:27,42` (`tasa <= 0 ? 1 : tasa`), `DocumentosComercialesService.Ventas.cs:334` (factura a crédito), `CobrosService.cs:426` (nota de débito), `CobrosService.cs:541` (`c.Tasa <= 0 ? moneda.Tasa : c.Tasa` en dólares).
- **Pruebas propuestas:**
  - `Factura_a_credito_en_dolares_guarda_en_cxc_Cuenta_la_tasa_de_su_venta`;
  - `Nota_de_debito_en_dolares_guarda_en_cxc_Cuenta_la_tasa_de_su_venta`;
  - `Cheque_devuelto_en_dolares_sin_tasa_usa_la_tasa_de_la_moneda`;
  - `Partidas_RegistrarCuenta_con_tasa_cero_o_negativa_guarda_uno`.

### P121S-03 · Alta (continuación de P121-02) · La nueva `CuadreCxc` repite la tautología y los datos no redondean
- **Evidencia:** `VistasP2Tests.cs:429-443` (`BalanceBase <> ROUND(Balance * Tasa, 2)` es la fórmula de la vista; y `vista == tarjeta` compara dos consultas que redondean igual); los montos nuevos son 1000, 100 y 118 con tasa 58: `ROUND` no cambia ningún valor.
- **Prueba propuesta (la de P121-02):** `BalanceBase_suma_los_redondeos_por_fila_y_no_redondea_la_suma_con_tasa_de_seis_decimales`: tres cuentas en dólares con saldo 10,01 y tasa 58,437500 (u otra con seis decimales) para que `Σ ROUND(fila)` y `ROUND(Σ fila)` difieran en un centavo; valor exacto esperado y cuadre con la tarjeta.

### P121S-04 · Media · La importación: faltan la vista previa, la moneda explícita y los casos sin aviso
- **Evidencia:** `NcfHistoricoTests.cs:148-165` importa solo con `guardar: true`; `ImportacionesService.cs:434-440`: `cab.Numero("Tasa", minimo: 0.000001m)` se evalúa antes de la normalización, así que una fila en moneda base con tasa 0 recibe error en lugar de la advertencia; la rama `moneda ?? monedaBase` (moneda en blanco) y la comparación sin distinguir mayúsculas no se distinguen en la prueba.
- **Pruebas propuestas:**
  - `La_vista_previa_de_la_importacion_advierte_la_tasa_en_moneda_base_sin_guardar` (`ImportarAsync(false, …)`: lo que ve el usuario antes de guardar);
  - `La_importacion_en_moneda_base_con_tasa_1_o_sin_tasa_no_advierte`;
  - `La_importacion_con_la_moneda_base_escrita_en_minusculas_normaliza_la_tasa`;
  - `La_importacion_en_moneda_base_con_tasa_cero_da_error_de_tasa` (caracteriza la conducta actual; decidir si debe ser la advertencia).

### P121S-05 · Media · El 51399: conteo mayor que uno, la consulta del mensaje, el guion y el segundo `Up`
- **Evidencia:** `VistasP2Tests.cs:309-312` (una sola cuenta huérfana; el texto dice «1 cuentas»); la consulta que el mensaje recomienda ejecutar nunca se ejecuta en una prueba; ninguna prueba compara el guion de `database/empresa/` con la migración (`git grep "gpos-empresa-"` en `tests/` solo da documentación); el nuevo `IF @sinVenta > 0` depende de que la columna no exista (`SqlMigracionesOla5Tramo4.cs:19-21`), y no se prueba que un segundo `Up` con una cuenta huérfana creada después no falle.
- **Pruebas propuestas:**
  - `El_51399_cuenta_todas_las_cuentas_sin_venta` (dos huérfanas; el mensaje dice «2»);
  - `El_SELECT_del_mensaje_51399_se_ejecuta_y_devuelve_las_cuentas_sin_venta` (se extrae del mensaje entre «Para verlas: » y «. Corrija»);
  - `El_guion_idempotente_contiene_el_bloque_de_la_tasa_de_la_migracion` (comparación de texto normalizado entre `SqlMigracionesOla5Tramo4.Ola5Tramo4Tasa` y el `.sql`);
  - `El_segundo_Up_con_una_cuenta_sin_venta_no_falla_porque_la_columna_ya_existe`.

### P121S-06 · Baja · Falta caracterizar SEG-T405-06 (decisión del propietario)
- **Evidencia:** el mensaje del commit deja sin aplicar SEG-T405-06 («la normalización de la tasa a 1 es la de PartidasCxp y VentasNg»). Un cheque en dólares sin tasa y con `moneda.Tasa = 0` termina con tasa 1 (`CobrosService.cs:541` y `Partidas.cs:27`) y `BalanceBase` en pesos tomando dólares por pesos.
- **Prueba propuesta:** `Cheque_devuelto_en_dolares_sin_tasa_y_con_tasa_de_moneda_cero_caracteriza_la_conducta_actual`: afirma lo que hoy pasa (tasa 1) con un comentario que lo liga a SEG-T405-06, para que el cambio posterior sea una decisión y no un accidente.

### P121S-07 · Baja · El cuadre se hace sobre toda la base compartida
- **Evidencia:** `VistasP2Tests.cs:429-443` suma `BalanceBase` de **todas** las cuentas emitidas con saldo y las compara con la tarjeta; se llama desde `CobrosTests` y `NcfHistoricoTests`, que comparten la base de su fixture con las demás pruebas de la clase. Una prueba hermana que deje una cuenta anulada o con otro estado puede hacer fallar esta prueba por una causa ajena (*inferido*; las dos consultas deberían filtrar igual, pero depende de que `ConsultasTablero.CuentasPorCobrar` conserve el mismo filtro `Estado = 1 AND Balance > 0`).
- **Propuesta:** además del total global, afirmar el aporte del cliente de la prueba (`SUM(BalanceBase) WHERE ClienteCodigo = …`) con el valor exacto (1000 y 5800).

## Lo que está bien (verificado por lectura)
- Cada prueba nueva cubre el lado bueno y el malo: pesos con tasa 58 (debe quedar 1) y dólares con tasa 58 (debe conservarse), con `BalanceBase` en moneda base de cada uno.
- El 51399 conserva la comprobación de que la migración falla sin cambiar nada y que la huella del contrato 1.3 no se movió (`VistasP2Tests.cs:322-323`).
- El guion y la migración se cambiaron a la vez (mismo bloque), y la corrección no toca el texto de las vistas ni el contrato.

## Riesgos que las pruebas no cubren
- Las cifras de las pruebas nuevas no se ejecutaron en este informe; `MedicionVistasP2` sigue sin correrse (`GPOST_B9`).
- SEG-T405-06 sigue como decisión del propietario.

## Texto de comentario para el PR #121

```
Revisión de pruebas de 59c16146 (QA de C, solo lectura; no se compiló ni se corrió nada). Informe: GPOS-NG-Equipos/traspasos/C/2026-10-20-revision-pruebas-pr121-seguridad.md
Sí cubre lo que corrige: las dos pruebas nuevas (cheque devuelto en CobrosTests.cs:128 e importación en NcfHistoricoTests.cs:148) mandan tasa 58 en pesos y exigen tasa 1, y la conservan en dólares; fallarían sin el cambio. El mensaje del 51399 tiene su aserción (VistasP2Tests.cs:309-312).
P121-01 baja a Media (2 de 4 orígenes con prueba). P121-02, 03 y 04 siguen Altas: CuadreCxc repite la tautología BalanceBase = ROUND(Balance*Tasa,2) y los montos no redondean (P121S-03).
- P121S-01 (Media): no se afirma que cxc.Cuenta.Tasa == ventas.Venta.Tasa, que es lo corregido.
- P121S-02 (Media): faltan factura a crédito, nota de débito, cheque en dólares sin tasa y Partidas con tasa <= 0.
- P121S-04 (Media): la importación no se prueba en vista previa (guardar:false), con moneda en minúsculas ni con tasa 1 sin aviso.
- P121S-05 (Media): el 51399 con 2+ cuentas, ejecutar el SELECT del mensaje, guion .sql = migración, segundo Up con huérfana.
- Bajas: caracterizar SEG-T405-06 (dólares sin tasa y moneda.Tasa=0 → 1); el cuadre agrega sobre toda la base compartida.
```

### Cierre
- Estado: Aprobado con observaciones (solo para el commit 59c16146; el dictamen del #121 sigue en Rechazado por P121-02, 03 y 04; recomendación técnica, no decisión)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-pruebas-pr121-seguridad.md`
- Supuestos: nada compilado ni ejecutado; las cifras esperadas de las pruebas no se verificaron; `BaseDatosFixture` es una base por clase (inferido); el guion `.sql` y la constante C# se compararon a ojo en el diff.
- Decisiones candidatas a ADR: Ninguna (SEG-T405-06 sigue en manos del propietario).
- Entregas a otros agentes: B → incorporar P121S-01 a P121S-07 al PR apilado de la tarea 1 (mismo PR, solo pruebas) y pegar el resultado de `MigracionOla5VistasTests`; auditor-seguridad → no hay nada nuevo.
- Próximo paso recomendado: B agrega al PR apilado las pruebas de P121S-01 a P121S-05 junto con las de P121-02 y P121-03.
