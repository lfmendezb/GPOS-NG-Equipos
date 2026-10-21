# Revisión de pruebas del PR #121 (T4-05, ola 5, tramo 4)

**Autor:** QA del equipo C (OSHIN-LEGION) · **Fecha:** 2026-10-20 · **Encargo:** B, `avisos/B-a-C/2026-10-20-cola-de-tareas-para-c.md`, tarea 1
**PR:** `lfmendezb/GPOS-NG#121`, rama `b/t4-05-vistas-p2` (cabeza `81c92c40`) contra `feature/modelo-ng` (`b8f166db`)
**Alcance:** solo lectura del diff y de la rama (`git show origin/b/t4-05-vistas-p2:<ruta>`). No se compiló ni se ejecutó nada. Todo lo de abajo es lectura; lo que dice «no se evidencia» significa que no está en el diff ni en la descripción del PR.

## Dictamen: Insuficiente (corregible solo con pruebas)

La parte que más riesgo tiene en el diseño está bien probada: el enmascarado de RS-01, el monto de cierre en NULL de RS-02, el cuadre de la tarjeta de CxC con la vista, la migración con relleno de la tasa, la falla cerrada 51399, el reverso a la 1.2 y la guarda de rol H con ScriptDom. No encontré defectos de producción en el código escrito a mano.

Aun así faltan pruebas en cuatro puntos que mueven dinero o el contrato (hallazgos Altos P121-01 a P121-04):
- Ningún flujo real que crea `cxc.Cuenta` tiene una prueba que verifique que escribe la tasa de su venta.
- El «redondeo por fila» se afirma con datos que no redondean.
- Cuatro de las diez vistas (`rpt.Compra`, `rpt.DocBanco`, `rpt.CatTipoGasto`, `rpt.CatTermino`) no tienen ninguna aserción con datos, y `rpt.CxpDocumento` solo se compara con la tarjeta.
- No se evidencia que corrieran las pruebas de contrato frente al motor (VD7).

Ninguno exige cambiar código de producción.

## 1. Qué es generado y qué es escrito a mano

| Tipo | Archivos | Líneas aprox. |
|---|---|---|
| Generado (no revisado línea a línea) | `database/empresa/gpos-empresa-20261021001638_Ola5VistasTramo4.sql`, `...Ola5VistasTramo4.Designer.cs`, `EmpresaNgDbContextModelSnapshot.cs`, `VistasReportesOla5Tramo4.cs` (texto de las vistas generado desde el script; lo comprueba `VistasP2Tests.El_texto_de_cada_vista...`) | ~12 900 |
| Escrito a mano, SQL y migración | `SqlMigracionesOla5Tramo4.cs` (87), `20261021001638_Ola5VistasTramo4.cs` (34), `database/ola5/rpt-vistas-tramo4.sql` (559; diseño del arquitecto-datos), `contrato-vistas.v1.json` (+1 666) y `database/ola5/LEEME.md` | ~2 400 |
| Escrito a mano, producción C# | `Partidas.cs`, `CobrosService.cs`, `DocumentosComercialesService.Ventas.cs`, `ImportacionesService.cs`, `ConsultasCxc.cs`, `ConsultasTablero.cs`, `CuentasPorCobrar.cs`, `CxcConfiguracion.cs`, `CajConfiguracion.cs` | ~40 |
| Pruebas | `VistasP2Tests.cs` (473), `GuardaRolHTests.cs` (169), `MedicionVistasP2.cs` (197), `ContratoVistasTests.cs` (+58 −9), `CatalogoConsultasTests.cs` (±4), `ReglasFiscalesBaseTests.cs` (±4) | ~900 |

Pruebas existentes que el PR no toca pero que cubren sus vistas (porque `BaseDatosFixture` ya trae la migración nueva):
- `MigracionOla5VistasTests.VD7_cada_vista_tiene_en_el_motor_las_columnas_del_contrato` (`MigracionOla5VistasTests.cs:88`).
- `MigracionOla5VistasTests.VersionContrato_escribe_la_version_1_y_la_huella_del_JSON` (`MigracionOla5VistasTests.cs:108`).
- `MigracionOla5VistasTests.Los_roles_leen_solo_sus_esquemas_de_vistas_y_no_escriben` (`MigracionOla5VistasTests.cs:138`).
- `NcfHistoricoTests` (`NcfHistoricoTests.cs:207`, 51420).

## 2. Trazabilidad: lo que cambia el PR → prueba

| Cambio / criterio | Prueba que lo cubre | Veredicto |
|---|---|---|
| Texto de las 10 vistas = script de diseño | `VistasP2Tests.El_texto_de_cada_vista_de_la_migracion_es_el_del_script_de_diseno` (`VistasP2Tests.cs:178`) | Cubierto |
| Grano y `BalanceBase` de `rpt.CxcDocumento` | `CxcDocumento_sin_duplicados_y_BalanceBase_redondeado_por_fila` (`:198`) | Parcial: no redondea (P121-02) |
| Tarjeta de CxC = suma de la vista | `La_suma_de_BalanceBase_cuadra_con_la_tarjeta_de_CxC` (`:224`) | Parcial: borde y CxP (P121-12) |
| RS-01 `rpt`/`rptc.CajaChica` | `CajaChica_enmascara_la_cedula_en_rpt_y_la_muestra_en_rptc` (`:248`) | Parcial: sin NULL, anulada ni NCF (P121-10) |
| RS-02 `rpt`/`rptc.MovimientoCaja` | `MovimientoCaja_deja_en_NULL_el_monto_del_cierre_y_de_su_reverso_en_rpt` (`:271`) | Parcial: sin fechas locales (P121-11) |
| T3-10 `Esperado` NULL | `CierreCajaConteoTests.Esperado_es_NULL_en_rpt_para_X_y_Z` (`:457`) | Cubierto |
| Migración: relleno, 51399, NOT NULL sin default, reverso, 2.º Up | `La_migracion_rellena_la_tasa_desde_la_venta_falla_cerrada_sin_venta_y_su_reverso_vuelve_a_la_1_2` (`:290`) | Parcial (P121-06, 07, 08) |
| Rol H: toda vista que lee `fiscal.Comprobante` filtra `Rol` | `GuardaRolHTests.Toda_vista_que_lee_fiscal_Comprobante_filtra_Rol` (`:25`) y la Theory (`:70`) | Cubierto con laxitud (P121-15) |
| Rol H y `NcfHistorico` en la consulta de facturas y la CxC | Solo la rama de `Referencia` (`VistasP2Tests.cs:211-213`) | Hueco (P121-05) |
| `rpt.CxpDocumento`, `rpt.Compra`, `rpt.DocBanco`, `rpt.CatTipoGasto`, `rpt.CatTermino` | Solo VD7 (columnas y tipos) y la tarjeta de CxP | Hueco (P121-03) |
| `cxc.Cuenta.Tasa` en los 4 orígenes | Ninguna | Hueco (P121-01) |
| Contrato 1.3: huella, versión, privilegios, superconjunto `rptc` | `ContratoVistasTests` (`:40`, `:62`, `:78`, `:94`, `:107`, `:131`) y `CatalogoConsultasTests.cs:66` | Cubierto; ver P121-09 y P121-17 |
| Medición p95 (T4-10OCT 7.1.11) | `MedicionVistasP2.P95_de_las_vistas_P2_...` (`:70`), detrás de `GPOST_B9` | No ejecutada; ver P121-16 |

## 3. Hallazgos

Convención: «rama» = `origin/b/t4-05-vistas-p2`. Las líneas son de esa rama.

### Altos

**P121-01 · Alta · Ningún origen de `cxc.Cuenta` tiene una prueba que verifique que escribe la tasa de su venta**
- Evidencia:
  - Los cuatro productores cambiaron de firma: `Partidas.cs:27,42` (`tasa <= 0 ? 1 : tasa`), `DocumentosComercialesService.Ventas.cs:334` (factura a crédito), `CobrosService.cs:426` (nota de débito), `CobrosService.cs:540,560` (cheque devuelto, con `c.Tasa <= 0 ? moneda.Tasa : c.Tasa`) e `ImportacionesService.cs:499`.
  - Las pruebas solo siembran `cxc.Cuenta` a mano (`VistasP2Tests.cs:100`, `MedicionVistasP2.cs:153`).
  - `ReglasFiscalesBaseTests.cs:503` cambió solo para seguir compilando.
  - `git grep RegistrarCuentaAsync` en `tests/` no encuentra ninguna llamada a la versión de CxC.
  - Las 29, 20 y 24 pruebas de flujo que cita el PR pasan, pero ninguna afirma `Tasa`.
- Riesgo: `CK_Cuenta_Tasa` solo exige `Tasa > 0`. Un productor que pase 1 o la tasa vigente en lugar de la del documento deja `BalanceBase` y la tarjeta de CxC mal sin que ninguna prueba falle. Es plata en moneda base.
- Pruebas propuestas (clase nueva con base propia, o agregarlas a `CobrosService` y `DocumentosComercialesService` si ya tienen fixture):
  - `Factura_a_credito_en_dolares_guarda_en_cxc_Cuenta_la_tasa_de_su_venta`
  - `Nota_de_debito_en_dolares_guarda_en_cxc_Cuenta_la_tasa_de_su_venta`
  - `Cheque_devuelto_sin_tasa_usa_la_tasa_de_la_moneda_en_la_venta_y_en_la_cuenta`
  - `Factura_importada_a_credito_guarda_en_cxc_Cuenta_la_tasa_de_la_cabecera`
  - `Partidas_RegistrarCuenta_con_tasa_cero_o_negativa_guarda_uno`
  - Invariante al final de cada una: `SELECT COUNT(*) FROM cxc.Cuenta c JOIN ventas.Venta v ON v.DocumentoId = c.DocumentoId WHERE c.Tasa <> v.Tasa` es 0.

**P121-02 · Alta · «Redondeo por fila» se afirma con datos que nunca redondean**
- Evidencia:
  - Todas las tasas de la siembra son 1, 60 o 58,5 y los montos son enteros o de un decimal (`VistasP2Tests.cs:91-92,110`). `ROUND(x × tasa, 2)` no cambia ningún valor.
  - La aserción `BalanceBase <> ROUND(Balance * Tasa, 2)` (`:205`, `:240`) repite la fórmula de la vista, así que es una tautología.
  - El cuadre con la tarjeta (`:233`) compara dos consultas que redondean igual.
- Riesgo: pasa igual con `SUM(x*t)` que con `SUM(ROUND(x*t,2))`. La regla P-4/P-5 (redondeo por fila, tasa `decimal(19,6)`) puede romperse sin que una prueba falle.
- Prueba propuesta: `BalanceBase_suma_los_redondeos_por_fila_y_no_redondea_la_suma_con_tasa_de_seis_decimales`. Sembrar tres cuentas en dólares con saldo 10,01 y tasa 58,437500 (u otra con 6 decimales) para que `Σ ROUND(fila)` y `ROUND(Σ fila)` difieran en un centavo. Verificar el valor exacto esperado, el cuadre con la tarjeta y lo mismo en `rpt.CxpDocumento` y `rpt.Compra.TotalBase`.

**P121-03 · Alta · Cuatro de las diez vistas nuevas no tienen ninguna aserción con datos; la quinta solo se compara con la tarjeta**
- Evidencia:
  - La siembra incluye `FCP1`, `FCP2` (dólares, tasa 58,5, B11), `NCP1` (nota de crédito con `NcfModificado`), `FCP3` anulada, `FCPI` importada, `CHK1`, `DEP1`, `TRB1` (dólares, tasa 60) y `CHK2` anulado (`VistasP2Tests.cs:70-79,108-126`).
  - Ninguna prueba las lee: `grep "rpt.Compra|rpt.DocBanco|rpt.CatTipoGasto|rpt.CatTermino"` en `VistasP2Tests.cs` no devuelve nada.
  - `rpt.CxpDocumento` solo aparece en `:235-240`, igualada a la tarjeta de CxP sin cifra absoluta.
- Qué queda sin verificar:
  - `Signo` de NCP y DVS, y `Ncf` como `COALESCE(606, comprobante O)`.
  - `NcfModificado` y `NumeroOrigen`.
  - `TotalBase`, `SubTotalBase`, `DescuentoBase` e `ImpuestoBase` en dólares.
  - `MontoBase` y `Signo` de `rpt.DocBanco`, y las anuladas.
  - `Dias` de `rpt.CatTermino` y `TipoBienServicio606` de `rpt.CatTipoGasto`.
- Pruebas propuestas:
  - `Compra_signo_ncf_y_documento_origen_de_cada_tipo` (FCP1 `B0100000123`, NCP1 `Signo=-1` y `NcfModificado=B0100000123` con `NumeroOrigen=FP00000001`, FCP2 `B1100000001`).
  - `Compra_en_dolares_TotalBase_es_el_redondeo_por_fila` (FCP2: 200 × 58,5 = 11 700).
  - `Compra_anulada_aparece_con_Estado_2_y_sigue_en_la_vista` (FCP3).
  - `DocBanco_MontoBase_Signo_y_cheque_anulado` (TRB1 = 9 000, CHK2 `Estado=2`).
  - `CxpDocumento_total_en_moneda_base_es_4705_y_vencido_1780_con_hoy_2026_10_10`
  - `CatTipoGasto_y_CatTermino_exponen_codigo_descripcion_inhabilitado_y_su_campo_propio`

**P121-04 · Alta · No se evidencia que corrieran las pruebas que comparan el contrato 1.3 con el motor**
- Evidencia:
  - `VD7_cada_vista_tiene_en_el_motor_las_columnas_del_contrato` (`MigracionOla5VistasTests.cs:88`) es la única prueba que compara, para las 10 vistas nuevas y las 4 redefinidas, nombre, orden, tipo, largo, precisión y nulabilidad del JSON con `sp_describe_first_result_set`.
  - `ContratoVistasTests.cs:74` solo busca `\bcolumna\b` en el cuerpo del script, y casi cualquier nombre aparece.
  - La descripción del PR enumera `VistasP2Tests`, `CierreCajaConteoTests`, `GuardaRolHTests`, «clases vecinas (migraciones, aprovisionamiento, reglas fiscales) 107», «contrato, SQL y parámetros 27» y `GPOS.Reportes.Tests` 44 y 26. No nombra `MigracionOla5VistasTests`; el PR no la modifica.
- Acción (sin código nuevo): B o el desarrollador confirman con el nombre `MigracionOla5VistasTests` que corrió completa (3 pruebas: VD7, huella, roles) y pega el resultado en el PR.

### Medias

**P121-05 · Media · El rol H nunca se siembra: `NcfHistorico` y el NCF de H se prueban solo por la rama de `Referencia`**
- Evidencia: `fiscal.Comprobante` se siembra solo con rol `'O'` (`VistasP2Tests.cs:104-106`). `HIST-0099` toma `B0100009999` de `ventas.Venta.Referencia` (`:95,211-212`). El `f.Rol = 'H'` de `rpt-vistas-tramo4.sql:72,470,526` nunca se evalúa. `rpt.ConsultaFactura` y `rptc.ConsultaFactura` no tienen ninguna aserción de valores (solo `COUNT(DISTINCT)` en `:202`).
- Pruebas propuestas:
  - `ConsultaFactura_y_CxcDocumento_toman_el_NCF_del_rol_H_y_marcan_NcfHistorico`. Sembrar una factura importada con comprobante `Rol='H'` (cumple `CK_Comprobante_Historico`: sin secuencia).
  - `ConsultaFactura_rpt_y_rptc_NcfHistorico_en_factura_normal_importada_con_referencia_e_importada_sin_nada`
  - `rptc_ConsultaFactura_IdentificacionCliente_completa_para_R_y_C_y_enmascarada_para_pasaporte`
  - `Una_factura_importada_con_O_y_H_en_el_mismo_documento_no_se_puede_crear` (verifica que 51420 realmente protege el grano de una fila).

**P121-06 · Media · El reverso solo verifica lo que borra, no lo que restaura**
- Evidencia: tras `Script(tramo4, anterior)` solo se afirma `COL_LENGTH Tasa` NULL, `OBJECT_ID(rpt.CxcDocumento)` NULL y la huella 1.2 (`VistasP2Tests.cs:327-330`). `ConsultaFactura`, `rptc.ConsultaFactura` y `CierreCajaConteo` redefinidas no se comprueban: si `Down` omitiera `Exec(texto)` de alguna, la prueba seguiría pasando.
- Pruebas propuestas:
  - `El_reverso_quita_NcfHistorico_de_ConsultaFactura_rpt_y_rptc`
  - `El_reverso_devuelve_Esperado_en_CierreCajaConteo_para_el_Z` (necesita un cierre Z sembrado en la base de la prueba de migración)
  - `El_reverso_borra_las_diez_vistas_nuevas_y_deja_las_que_existian_en_la_1_2`

**P121-07 · Media · Los dos índices con `DROP_EXISTING` no tienen prueba de forma**
- Evidencia: `SqlMigracionesOla5Tramo4.cs:34-35,40-41,47-51`. El `WHERE SaldoPendiente > 0` de `IX_Cuenta_ClienteVencimiento` y los INCLUDE se reescriben a mano; si se pierde el filtro la prueba no lo ve, y el comentario en `ConsultasCxc`/vista depende de ese índice filtrado (`rpt-vistas-tramo4.sql:44`).
- Prueba propuesta: `Los_indices_ampliados_conservan_filtro_y_llevan_Tasa_y_los_campos_de_MovimientoCaja_y_el_reverso_los_repone` (consulta `sys.indexes.filter_definition` e `sys.index_columns.is_included_column`, tras Up, Down y Up).

**P121-08 · Media · La prueba de migración tiene datos mínimos y la «falla cerrada sin cambios» es trivial**
- Evidencia:
  - `CuentasAntes` (`VistasP2Tests.cs:340-360`) crea una sola cuenta con venta (dólares, 58,5) y otra sin venta. No hay cuenta en moneda base, ni varias cuentas, ni una venta con tasa distinta.
  - El 51399 se lanza antes de cualquier `ALTER` (`SqlMigracionesOla5Tramo4.cs:19-21`), así que `COL_LENGTH Tasa` NULL (`:309`) se cumple aunque no hubiera rollback.
  - El orden de `Up` pone la comprobación de dueño V-R1 (`Ola5ComprobacionDueno`) después del bloque de la tasa (`:67-68`). Si V-R1 falla, la columna ya existe dentro de la migración. La prueba usa el script de EF, no `Migrate()`, que es la ruta real.
- Pruebas propuestas:
  - `La_migracion_rellena_la_tasa_de_varias_cuentas_en_moneda_base_y_extranjera`
  - `Ola5VistasTramo4_con_un_esquema_ajeno_a_dbo_falla_con_51399_y_no_deja_la_columna_Tasa` (aplicada con `Database.Migrate()` hasta la anterior y luego la migración)
  - `El_Up_del_tramo_4_ejecutado_dos_veces_seguidas_no_cambia_la_huella_del_esquema` (idempotencia a nivel SQL; hay `HuellaEsquemaAsync` en `BasesNgPrueba`).

**P121-09 · Media · Los permisos de los roles se prueban para 3 de 4 vistas `rptc` nuevas y ninguna es genérica**
- Evidencia:
  - `VistasP2Tests.cs:259-262,281-282,465-468` cubre `rptc.CajaChica`, `rptc.MovimientoCaja` y `rptc.CierreCajaConteo`. `rptc.ConsultaFactura` (redefinida) no se prueba.
  - `Los_roles_leen_solo_sus_esquemas...` (`MigracionOla5VistasTests.cs:138`) comprueba INSERT, EXECUTE y ALTER por esquema, no UPDATE ni DELETE.
  - `rpt.CatTipoGasto` y `rpt.CatTermino` son vistas de una sola tabla, por lo tanto actualizables.
  - La lista de claves de privilegio está escrita a mano (`ContratoVistasTests.cs:96`) en lugar de leer `Permisos`.
- Pruebas propuestas:
  - `Gpos_reportes_no_lee_ninguna_vista_rptc_y_gpos_lectura_lee_todas_las_rpt_y_rptc` (recorre `sys.views` de `rpt` y `rptc`)
  - `Los_roles_de_lectura_no_pueden_UPDATE_ni_DELETE_sobre_las_vistas_de_una_sola_tabla`
  - `Cada_privilegio_del_contrato_existe_en_el_catalogo_Permisos` (`GPOS.Reportes.Tests`; usa `Permisos.VerCostos`, `VerDatosPersonales`, `VerCuadreCaja`)
  - `Las_vistas_rptc_nuevas_del_contrato_incrustado_exigen_su_privilegio_en_el_ejecutor_del_disenador` (hoy se prueba con un contrato de juguete en `LectorRegistradasSqlTests`).

**P121-10 · Media · Caja chica: faltan NULL, anulada, NCF y `ItbisBase`**
- Evidencia: la siembra tiene dos filas, ambas con identificación y `Estado=1` (`VistasP2Tests.cs:135-137`). `CK_CajaChica_Rnc` admite `RncCedula IS NULL` (`CmpConfiguracion.cs:152`) y la vista tiene esa rama (`rpt-vistas-tramo4.sql:242`). No se afirma `Ncf` (606 `B0200000055`, B13 `B1300000001`), `ItbisBase` (30 y 0) ni una anulada.
- Pruebas propuestas:
  - `CajaChica_sin_RNC_ni_cedula_devuelve_identificacion_NULL_en_rpt_y_en_rptc`
  - `CajaChica_anulada_aparece_con_Estado_2`
  - `CajaChica_Ncf_viene_del_606_o_del_comprobante_O`
  - `CajaChica_en_dolares_MontoBase_e_ItbisBase_se_redondean_por_fila`
  - `CajaChica_Concepto_y_Beneficiario_no_exponen_la_cedula_completa_de_rpt` (barrido genérico: ninguna columna de texto de `rpt.CajaChica` contiene los 11 dígitos de una cédula sembrada).

**P121-11 · Media · Movimientos de caja: las fechas locales y el reverso de un movimiento que no es cierre**
- Evidencia: `Fecha`, `FechaRegistroLocal` y `Hora` (`DATEADD(HOUR, -4, RegistradoEn)`, `rpt-vistas-tramo4.sql:317-319`) no se afirman. La siembra sí tiene un caso útil, el CIERRE a las `2026-10-10T01:30` UTC (`VistasP2Tests.cs:143`), que en hora local es el día anterior. El único `REVERSO` sembrado es de un CIERRE (`:146-147`); no hay uno de un GASTO, que debe conservar el monto en `rpt`.
- Pruebas propuestas:
  - `MovimientoCaja_FechaRegistroLocal_y_Hora_restan_cuatro_horas_y_cruzan_la_medianoche` (esperado: `2026-10-09` y `21:30:00` para el cierre)
  - `MovimientoCaja_Fecha_es_la_de_la_jornada_aunque_RegistradoEn_caiga_en_otro_dia`
  - `MovimientoCaja_reverso_de_un_gasto_conserva_Monto_y_EsCierre_es_cero`

**P121-12 · Media · La tarjeta se compara con la vista, no con un valor, y no hay caso de borde de vencimiento**
- Evidencia:
  - `La_suma_de_BalanceBase...` afirma 7 150 (`VistasP2Tests.cs:232`) pero el vencido solo como igualdad `vista == tarjeta` (`:233`), sin cifra absoluta. Los valores calculados a mano: CxC vencido 1 150 (600 + 300 + 250) y CxP total 4 705.
  - No hay una cuenta que venza exactamente en «hoy» (`FechaVencimiento < @hoy` frente a `<=`); si ambas lecturas cambian a la vez, la prueba no lo detecta.
  - CxP no tiene cifra absoluta (`:239`).
- Pruebas propuestas:
  - `Tarjeta_de_CxC_vencido_es_1150_y_no_incluye_la_cuenta_que_vence_hoy` (agregar una cuenta con vencimiento 2026-10-10)
  - `Tarjeta_de_CxP_total_es_4705_y_vencido_es_1780`

**P121-13 · Media · Grano y clave única solo se verifican en CxC y en la consulta de facturas; nada con borradores ni con base vacía**
- Evidencia:
  - Solo `rpt.CxcDocumento` y `rpt.ConsultaFactura` tienen `COUNT(*) − COUNT(DISTINCT DocumentoId)` (`VistasP2Tests.cs:201-202`).
  - Las otras vistas nuevas unen `fiscal.Registro606` y `fiscal.Comprobante` por `DocumentoId` (PK `(DocumentoId, Rol)`; el rol O, H o R está filtrado). Una clave única por vista es lo que hace estable el `OFFSET/FETCH`.
  - Todas las vistas filtran `d.Estado IN (1, 2)`, pero la siembra no tiene ningún borrador (Estado 0).
- Pruebas propuestas:
  - `Toda_vista_nueva_tiene_una_fila_por_su_clave` (Theory sobre las diez; clave `DocumentoId` o `MovimientoId`)
  - `Un_documento_en_borrador_no_aparece_en_ninguna_vista_nueva` (cxc, cxp, compra, banco, caja chica)
  - `Las_vistas_nuevas_responden_sin_filas_en_una_base_recien_aprovisionada` (conteo 0 sin error; `rpt.VersionContrato` con una fila).

**P121-14 · Media · Sucursal: toda la siembra es de una sucursal**
- Evidencia: `SucursalId = 1` en todos los documentos y jornadas (`VistasP2Tests.cs:82,128,138`); las vistas hacen `JOIN org.Sucursal` interno y toman `SucursalId` de `d` en unas vistas y de `m` en `rpt.MovimientoCaja` (`rpt-vistas-tramo4.sql:76,321`). Si el dato divergiera, nada lo detecta.
- Prueba propuesta: `Las_vistas_exponen_SucursalId_y_SucursalCodigo_del_documento_con_dos_sucursales` (segunda sucursal, un documento por vista y un movimiento de caja de la jornada de esa sucursal).
- Nota: el aislamiento entre empresas no aplica a nivel de vista (base por empresa; las vistas no llevan `EmpresaId`). Lo cubre la API de reportes (`AuditoriaAdr109Tests`, no leído en esta revisión).

**P121-15 · Media · La guarda del rol H acepta cualquier mención de `Rol`**
- Evidencia: `filtra = columnas.Any(c => ... Rol ...)` (`GuardaRolHTests.cs:111-113`) cuenta como filtro cualquier columna `alias.Rol` en el `ON` o el `WHERE`, incluso `c.Rol IS NOT NULL` o `c.Rol = x.Rol`. La Theory (`:70-78`) no tiene casos negativos de ese tipo. El umbral `conComprobante >= 8` (`:66`) deja que una vista salga del análisis sin que nadie lo note. La excepción de `rpt.NcfHistoricoIncidencia` (`:22`) es explícita y está contada.
- Casos propuestos para la Theory `El_analizador_reconoce_el_filtro_de_rol`:
  - `... ON c.DocumentoId = d.Id AND c.Rol IS NOT NULL` → 1
  - `... ON c.DocumentoId = d.Id AND c.Rol <> 'H'` → 0
  - `... CROSS APPLY (SELECT TOP (1) c.Ncf FROM fiscal.Comprobante c WHERE c.DocumentoId = d.Id) x` → 1
  - `WITH k AS (SELECT c.Ncf FROM fiscal.Comprobante c) SELECT * FROM k` → 1
  - `... UNION ALL ...` con un solo lado filtrado → 1
- Cambio: sustituir `>= 8` por la lista exacta de vistas que leen `fiscal.Comprobante`, en la prueba `Toda_vista_que_lee_fiscal_Comprobante_filtra_Rol`.

**P121-16 · Media · La medición no verifica que las consultas devuelvan lo esperado**
- Evidencia: `MedicionVistasP2.cs:99-107` lee el resultado completo sin contar filas y solo compara el tiempo. Una consulta que devolviera cero filas por error de siembra o de vista pasaría. El `ORDER BY` de M1 (`:37`, `NombreCliente, Documento`) no desempata por `DocumentoId`, y un `Numero` repetido hace inestable la paginación. La prueba no se ejecutó (PR: «no se verificó»).
- Pruebas propuestas (sin cambiar de tecnología): agregar a cada `Caso` un `FilasEsperadas` y afirmarlo en `P95_de_las_vistas_P2_con_el_volumen_del_cliente_grande`. M1 500, M2 5 000, M4 5 000, M6 500; M7 y M9 contra el conteo calculado de la siembra. Agregar `DocumentoId` al `ORDER BY` de M1.

**P121-17 · Media · Filtros exactos y ADR-50 solo se prueban en la medición**
- Evidencia: el filtro exacto por código con parámetro `varchar` (`x.ClienteCodigo = @cliente`, `m.CajaCodigo = @caja`) solo existe en `MedicionVistasP2.cs:44,54,96-97`, detrás de `GPOST_B9`. VD7 asegura que las columnas son `varchar`, no que una consulta con parámetro tipado las use bien.
- Pruebas propuestas:
  - `CxcDocumento_filtra_exacto_por_ClienteCodigo_con_parametro_varchar_20`
  - `MovimientoCaja_filtra_exacto_por_CajaCodigo_con_parametro_varchar_30`
  - `Filtro_por_codigo_con_parametro_nvarchar_no_cambia_el_resultado_pero_se_documenta_el_CONVERT_IMPLICIT` (opcional; verificaría el plan con `SET SHOWPLAN_XML`, T-SQL de la propia base; B decide si lo quiere).
  - Caso de borde de colación: con `SQL_Latin1_General_CP1_CI_AS`, `'c01'` y `'C01 '` igualan a `'C01'`. Si «exacto» significa distinguir mayúsculas, hay que decidirlo antes de T4-10 (los filtros del diseñador).

**P121-18 · Media · Compatibilidad del contrato 1.2 → 1.3**
- Evidencia: el JSON borra tres líneas (`version`, `alcance`, `grano`); no se quita ninguna columna. Pero `rptc.ConsultaFactura` inserta `NcfHistorico` antes de `IdentificacionCliente` (`rpt-vistas-tramo4.sql:526-529`), así que esta última cambia de posición ordinal dentro de una versión menor. No hay prueba que afirme que las columnas de la 1.2 siguen con el mismo nombre, tipo y nulabilidad.
- Prueba propuesta: `La_migracion_no_quita_ni_cambia_el_tipo_de_columnas_de_las_vistas_existentes`. En la prueba de migración, capturar `sp_describe_first_result_set` de las vistas `rpt` y `rptc` de la base «anterior» y comparar tras `Up`. Solo se admiten columnas nuevas. Si se acepta el movimiento ordinal, dejarlo escrito en la prueba como excepción de V-10.

### Bajas

- **P121-19 · Baja.** `ComoAsync` (`VistasP2Tests.cs:424-437`) devuelve 0 también cuando la vista no tiene filas, de modo que «el rol puede leer» no prueba que vea datos. Complementar con una lectura del recuento por el rol, `Gpos_lectura_ve_las_filas_de_rptc_CajaChica_y_gpos_reportes_las_de_rpt_CajaChica`.
- **P121-20 · Baja.** La migración «anterior» está fija en `"20261019171025_Rs03RncObligatorio"` (`:292`) y la huella 1.2/1.3 en cuatro sitios (`ContratoVistasTests.cs:28`, `CatalogoConsultasTests.cs:68`, `VistasP2Tests.cs:319,330`, el script). Derivar la anterior de `VersionEsquemaNg.Migraciones` por posición; si otra migración se une antes, el PR avisa que regenera la marca, pero esta cadena se rompe en silencio.
- **P121-21 · Baja.** `ContratoVistasTests.El_script_crea_exactamente...` (`:74`) busca `\bcolumna\b` en todo el cuerpo; nombres como `Id`, `Codigo` o `Numero` siempre coinciden. Es redundante con VD7 (P121-04); dejarla, pero no contarla como cobertura.
- **P121-22 · Baja.** `CierreCajaConteoTests` no siembra un cierre anulado (`z.Anulado = 1`) ni la parte `Contado/Diferencia` de `rptc`.
- **P121-23 · Baja.** Comentario obsoleto en producción: `ConsultasVentasReportes.cs:92-93` dice que `rpt.CierreCajaConteo` «conserva el esperado»; desde T3-10 y este PR es NULL. No requiere prueba; sí corregir el texto en T4-10.
- **P121-24 · Baja.** R-D6 (`MaestrosService` suma el saldo del cliente sin tasa mientras la tarjeta ya suma en moneda base): sin prueba de caracterización. Propuesta: `Saldo_del_cliente_sigue_sumando_sin_tasa_hasta_R_D6` (con una factura en dólares), para que el cambio posterior sea una decisión y no un accidente.

## 4. Lo que está bien probado (no hace falta tocar)

- Texto de cada vista de la migración = script de diseño, con las nuevas y las redefinidas separadas (`VistasP2Tests.cs:178`).
- RS-01: el RNC de 9 dígitos íntegro, la cédula enmascarada en `rpt` y `rptc` (columna enmascarada), la completa solo en `rptc.Identificacion`, y la denegación 229 de `gpos_reportes` sobre `rptc` y de `gpos_lectura` sobre la tabla (`:248`).
- RS-02: `EsCierre` para CIERRE y su REVERSO, NULL en `rpt` y valor en `rptc.MontoCompleto` (`:271`).
- T3-10: `Esperado` NULL en X y Z de `rpt`, con valor solo en `rptc` (`:457`).
- Migración: tasa desde la venta, `NOT NULL` sin valor por omisión (error 515), el 51399 sin venta, huella 1.3 → 1.2 → 1.3 y segundo `Up` (`:290`).
- Guarda de H-2 con ScriptDom, sobre el texto que guarda el catálogo (cubre todas las migraciones) y con casos que prueban al propio analizador (`GuardaRolHTests.cs:69-86`).
- Contrato: huella SHA-256 sin BOM y LF, versión 1.3, superconjunto `rptc`, privilegios, ninguna vista nueva lee otra vista de reportes ni usa tres partes (`ContratoVistasTests.cs:40,78,107`).

## 5. Riesgos no cubiertos por pruebas (para el PR)

- Medición `MedicionVistasP2` sin ejecutar (`GPOST_B9`); el plan de las consultas con la cardinalidad del cliente grande es una hipótesis hasta entonces.
- `rpt.NcfHistoricoIncidencia` lee `fiscal.Comprobante` sin filtrar rol por diseño; la guarda lo tolera con una excepción numerada y A decide. Mientras tanto, los 607/608 y las incidencias podrían mezclar H.
- Web y MAUI no se compilaron (según el PR); `ConsultasTablero.CuentasPorCobrar` cambió de semántica (ahora en moneda base).
- Las pruebas de CxC con `GPOST_B9` (una omitida) y `MaestrosService` (R-D6) siguen sumando sin tasa.
- Seguridad: queda pendiente la revisión del auditor-seguridad que menciona el PR; yo solo leí las pruebas.

## 6. Texto de comentario para el PR (listo para pegar)

```
Revisión de pruebas (QA de C, solo lectura; no se compiló ni se corrió nada). Informe: GPOS-NG-Equipos/traspasos/C/2026-10-20-revision-pruebas-pr121.md

Dictamen: Insuficiente, pero corregible solo con pruebas: no encontré defectos en el código de producción. Bien cubiertos: RS-01 (enmascarado), RS-02 (monto de cierre en NULL), T3-10, la migración con relleno de la tasa, 51399 y el reverso a la 1.2, la tarjeta de CxC vs la vista y la guarda de rol H (ScriptDom).

Altos:
- P121-01: ninguno de los 4 orígenes de cxc.Cuenta (factura a crédito, ND, cheque devuelto, importación) tiene una prueba que afirme que guarda la tasa de su venta; las pruebas de flujo pasan sin mirar Tasa.
- P121-02: el «redondeo por fila» se prueba con tasas 1, 60 y 58,5 y montos enteros: nunca redondea. Falta un caso con tasa de 6 decimales donde Σ ROUND(fila) ≠ ROUND(Σ fila).
- P121-03: rpt.Compra, rpt.DocBanco, rpt.CatTipoGasto y rpt.CatTermino no tienen ninguna aserción con datos (la siembra ya trae FCP, NCP, TRB y anuladas); rpt.CxpDocumento solo se iguala a la tarjeta.
- P121-04: confirmen que corrió MigracionOla5VistasTests completa (VD7, huella y roles): es la única que compara las columnas del contrato 1.3 con el motor, y la lista del PR no la nombra.

Medias (P121-05 a 18): rol H nunca sembrado (solo se prueba la rama de Referencia); el reverso no verifica lo que restaura ni los índices (filtro e INCLUDE); la migración se prueba con una sola cuenta y la comprobación V-R1 va después del bloque de la tasa; permisos de rptc probados para 3 de 4 vistas y sin UPDATE/DELETE en las de una tabla; caja chica sin NULL, anulada ni NCF; fechas locales UTC-4 sin aserción; borde «vence hoy»; grano/clave única/borradores/base vacía; una sola sucursal; guarda de rol H acepta cualquier mención de Rol; la medición no cuenta filas; filtros exactos solo bajo GPOST_B9; compatibilidad 1.2 → 1.3 (IdentificacionCliente cambia de ordinal en rptc.ConsultaFactura).

Cada hallazgo trae el nombre exacto de la prueba propuesta en el informe. Ningún cambio de tecnología.
```

## Cierre
- Estado: Rechazado (recomendación técnica sobre las pruebas; la decisión es del propietario y de B)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-pruebas-pr121.md`
- Supuestos: `MigracionOla5VistasTests` usa `BaseDatosFixture` con todas las migraciones aplicadas (inferido; no leí el fixture completo). El aislamiento entre empresas por base se cubre en `AuditoriaAdr109Tests` (no leído). Los valores 1 150, 4 705 y 1 780 los calculé a mano desde la siembra; hay que confirmarlos al escribir las pruebas.
- Decisiones candidatas a ADR: Ninguna. Se plantea una pregunta de producto/datos: si «exacto» en los filtros debe distinguir mayúsculas y espacios finales (colación CI_AS) y si se acepta el cambio de ordinal de `IdentificacionCliente` en `rptc.ConsultaFactura` dentro de una versión menor.
- Entregas a otros agentes: desarrollador del PR → escribir las pruebas P121-01 a P121-18 (solo pruebas y datos de siembra); B → ejecutar `MigracionOla5VistasTests` y `MedicionVistasP2` (`GPOST_B9`) y publicar el comentario en GitHub; auditor-seguridad → revisión pendiente de RS-01/RS-02 con la ayuda de P121-09 y P121-10.
- Próximo paso recomendado: B publica el comentario del apartado 6 en el PR #121 y pide el resultado de `MigracionOla5VistasTests` antes de aprobar.
