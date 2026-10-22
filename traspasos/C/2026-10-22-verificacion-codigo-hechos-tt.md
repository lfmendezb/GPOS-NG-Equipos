```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 1 del aviso 2026-10-22 `respuesta-dorados-y-tareas-nuevas-2`: verificar en el código los hechos que el especialista-pos no pudo)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (ref local `origin/feature/modelo-ng` @ `b4378650`, «Une PR #146»)
Estado: Abierto
```

# Verificación en el código de los hechos de TT

**Solo lectura; nada compilado ni ejecutado.** Lo verificó un agente de lectura con `git grep`/`git show`, sin `git fetch` (el ref local puede ir atrasado). **Yo comprobé personalmente cuatro puntos**: que `CobrosService.cs` no contiene ninguna coincidencia de «inhabilitad» (0) y que la línea 78 es solo `ReferenciasNg.ClienteAsync(...) ?? throw "Cliente incorrecto."`; que `CodigoContado = "GENERICO"` existe en `Terceros.cs:17` y no tiene otros usos en `src` ni en `tests` (el otro `CodigoContado` es el de `Catalogos.cs:63`, valor `"CONTADO"`, de otro catálogo); y que el suplidor sí se valida en `CuentasPorPagarService.Notas.cs:67-68`. El resto de las filas son del agente: V = leído en el texto, I = inferido.

## Resumen por hecho
1. **Cliente inhabilitado puede cobrar:** **V, sí**, el flujo no valida (`CobrosService.cs:78`).
2. **Puede recibir nota de crédito o de débito:** **V, sí**, no valida (`CobrosService.cs:343`).
3. **Puede recibir devolución:** **V, sí**, no valida (`DocumentosComercialesService.Ventas.cs:431` y `PosService.cs:856`).
4. **`GENERICO`:** **V**, no hay constante usada, bandera ni regla que lo proteja; solo lo frena que una caja lo use (`FK_Caja_Cliente`) o que tenga documentos. La constante `CodigoContado` no se referencia.
5. **`PuenteMae`:** **V**, escribe en el cliente y el suplidor (RNC en dígitos, nombres, teléfonos, dirección y catálogos), **sin `Inhabilitado`**, en la misma transacción.
6. **Suplidor inhabilitado y notas:** **V, no puede** (`Notas.cs:68`).
7. **Suplidor inhabilitado y pagos:** **V, no puede** (`EfectivoService.Bancos.cs:73`). Pero **solicitud de pago, aplicación de saldo a favor y devolución de compra no validan.**

**Hallazgo previo importante (hecho 0):** ninguna ruta del código pone `cat.Cliente.Inhabilitado = 1`. El estado «cliente inhabilitado» no es alcanzable por API ni por la interfaz; solo por SQL directo. Los hechos 1 a 3 describen lo que el código permitiría si el dato llegara a 1.

## Tabla
| Hecho | Veredicto | archivo:línea (`b4378650`) | Cita breve | Observaciones |
|---|---|---|---|---|
| 0. Previo: ¿alguna ruta pone `cat.Cliente.Inhabilitado = 1`? | **V: NO encontrada** | `ClienteDto` (`Contracts/Tablas/Maestros.cs:22-60`) sin campo `Inhabilitado`; `GuardarClienteNgAsync` (`MaestrosService.cs:137-210`) no lo escribe; `ClienteDtoAsync` (`MaestrosService.cs:85-116`) no lo devuelve; `Dominio/Maestros/Terceros.cs:51` lo declara | El suplidor sí lo expone: `Contracts/Tablas/Maestros.cs:115`, `MaestrosService.cs:358` | Única columna relacionada: `CK_Cliente_Fusion` (`MaeConfiguracion.cs:334`) exige `FusionadoEnId` con `Inhabilitado = 1`, pero ningún código escribe `FusionadoEnId`. Las asignaciones a `Inhabilitado` que existen son de otras entidades (p. ej. caja, `CatalogosConfiguracion.cs:302`) |
| 1. Cliente inhabilitado puede cobrar | **V: el flujo NO valida** | `CobrosEndpoints.cs:25` → `CobrosService.cs:62-64` (`GuardarReciboAsync`) → `:73-171` (`GuardarReciboSinClaveAsync`); `ReferenciasNg.cs:52-60` | `:78 var cliente = await ReferenciasNg.ClienteAsync(u, r.ClienteId, ct) ?? throw new ReglaNegocioException("Cliente incorrecto.");` | 0 coincidencias de `Inhabilitad` en `CobrosService.cs` (verificado por mí) ni en `CobrosEndpoints.cs`. `ReferenciasNg.cs:57` proyecta `Inhabilitado` en `ClienteRef` (`:22`) pero ningún consumidor lo lee. `Ventas/Recibos.razor`: 0 |
| 2. Cliente inhabilitado puede recibir NC o ND | **V: NO valida** | `CobrosEndpoints.cs:37` → `CobrosService.cs:319` (`GuardarNotaAsync`) → `:323` (`GuardarNotaSinClaveAsync`) | `:343 var cliente = await ReferenciasNg.ClienteAsync(u, n.ClienteId, ct) ?? throw ... "Cliente incorrecto."` | Mismo patrón. `NotasCxc.razor`: 0 |
| 3. Cliente inhabilitado puede recibir devolución | **V: NO valida en las dos rutas** | (a) Devolución CxC: `DocumentosComercialesService.Ventas.cs:116` → `:424-431` (`ValidarVentaAsync`). (b) Devolución POS: `PosEndpoints.cs:41` → `PosService.cs:844` (`DevolverAsync`) → `:856` (`DevolverSinClaveAsync`) | `Ventas.cs:431 ... ClienteAsync(u, doc.TerceroId, ct)) is null) errores.Add("Cliente incorrecto.")` | (a) 0 coincidencias en `Ventas.cs`. (b) `DevolverSinClaveAsync` no lee el cliente; toma el de la factura POS. Sin comprobación en esa ruta |
| 4. `GENERICO` no suprimible/eliminable/inhabilitable | **V: no hay constante usada, bandera ni regla; solo protección indirecta** | Constante `Terceros.cs:17`; eliminación `MaestrosService.cs:212-224`; FK `CfgConfiguracion.cs:256` (`FK_Caja_Cliente`); error 547 traducido en `ValoresCatalogo.cs:84-98`; prueba `tests/GPOS.Tests/TablasTests.cs:136`; semilla `database/02_actualizacion_gpos.sql:256` y `SqlMigracionesMae.cs:56-58` | `Terceros.cs:17 public const string CodigoContado = "GENERICO";` · `MaestrosService.cs:220 u.Ng.Clientes.Remove(c);` (sin comparar el código) | (a) `CodigoContado` no se referencia en `src` ni `tests` (verificado por mí). (b) `EliminarClienteAsync` no tiene excepción para `GENERICO`; lo frena solo que una caja lo use como `ClienteContado` (547 → `EnUsoException`, `inhabilitable:false`) o que tenga documentos heredados (`UsosCliente`, `:33-37`). **Si ninguna caja lo usa, se elimina.** La prueba `TablasTests.cs:136` pasa solo porque la caja de la semilla lo usa. (c) Inhabilitar: no hay ruta (hecho 0). (d) Si la caja tiene `ClienteContado` inhabilitado, la caja no vende (`PosService.cs:176-179`) |
| 5a. `PuenteMae` en el CLIENTE | **V** | `Infraestructura/Transicion/PuenteMae.cs:143-152` (`ClienteAsync`); alta/modificación `MaestrosService.cs:206` (misma transacción); baja `PuenteMae.cs:247-252` → `MaestrosService.cs:221`; cambio de lista `PuenteMae.cs:132-135` → `ListasPreciosService.cs:293`; entidad heredada `Data/Empresa/Maestros.cs:3-38` | `PuenteMae.cs:147 h.RNC = d.RNC; ... h.Telefono1 = d.Telefono1; ...` · `:151 ... h.Direccion = d.Direccion;` | Copia: razón social, nombre comercial, RNC (solo dígitos, `MaestrosService.cs:166` y `:204`), teléfonos, móvil, fax, contacto, dirección, correos, web y catálogos (clase, subclase, país, territorio, zona, sucursal, vendedor, términos, moneda, nivel de precio), NCF, impuesto, prospecto, nota. **No copia `Inhabilitado` ni `LimiteCredito`**: el heredado nunca ve un cliente inhabilitado |
| 5b. `PuenteMae` en el SUPLIDOR | **V** | `PuenteMae.cs:154-162` (`SuplidorAsync`); llamada `MaestrosService.cs:361`; RNC en dígitos `:360`; baja `:375` | `:158 h.RNC = d.RNC; ... :161 ... h.Impuesto = d.Impuesto; h.Nota = d.Nota;` | Copia razón social, nombre comercial, RNC (dígitos), teléfonos, móvil, fax, contacto, dirección, correos, web, clase, país, zona, sucursal, términos, moneda, impuesto y nota. **No copia `Inhabilitado`** (`MaestrosService.cs:358` lo guarda solo en NG) |
| 6. Suplidor inhabilitado y notas (NC/ND) | **V: NO puede** | `CuentasPorPagarService.Notas.cs:67-68` | `:68 if (suplidor.Inhabilitado) throw new ReglaNegocioException($"El suplidor {suplidor.Codigo.Trim()} está inhabilitado.");` | Verificado por mí. Va antes de la rama de crédito (`:73`), así que cubre NC y ND |
| 7. Suplidor inhabilitado y pagos | **V: NO puede** | `EfectivoService.Bancos.cs:47` (`GuardarPagoSinClaveAsync`), `:70-73` | `:73 if (suplidor.Inhabilitado) throw new ReglaNegocioException(...)` | Solo aplica cuando el pago trae `SuplidorId` |
| 7b. Suplidor inhabilitado: solicitud de pago | **NO: sin comprobación** | `EfectivoService.Bancos.cs:355-370` | `:370 suplidor = await PartidasCxp.SuplidorAsync(u, s.SuplidorId, ct) ?? throw ... "Suplidor incorrecto."` | Puede crearse la solicitud. Si el pago de la solicitud pasa por `:73`, esa barrera aplica al pagar: **no lo verifiqué (I)** |
| 7c. Suplidor inhabilitado: aplicación de saldo a favor | **NO: sin comprobación** | `CuentasPorPagarService.Aplicaciones.cs:40`, `:52` | `:52 var suplidor = await PartidasCxp.SuplidorAsync(u, a.SuplidorId, ct) ?? throw ... "Suplidor incorrecto."` | 0 coincidencias de `Inhabilitad` en el archivo |
| 7d. Suplidor inhabilitado: devolución a suplidor (compra) | **NO: sin comprobación** | `DocumentosComercialesService.Devoluciones.cs:31`, `:71` | `:71 var suplidor = (await PartidasCxp.SuplidorAsync(u, factura.SuplidorId, ct))!;` | Solo se valida el almacén (`:70`) |
| 7e. Suplidor inhabilitado: compra | **V: NO puede** | `DocumentosComercialesService.Compras.cs:443-444` | `:444 else if (suplidor.Inhabilitado) errores.Add(...)` | Dato adicional |

## Búsquedas realizadas (para auditar las ausencias)
Todas con `git grep`/`git show` sobre `origin/feature/modelo-ng` (`b4378650`):
- `PuenteMae` en todo el repositorio (`git grep -n -i "PuenteMae"`).
- `GENERICO` y `CodigoContado` en `src`, `tests`, Web y MAUI.
- `Inhabilitad` en `src/**.cs`, con filtro manual para excluir Migraciones, Ncf, Motivo, Perfil, Usuario, Empresa, Formato, Sucursal, Ofertas, Articulo y Numeracion.
- Patrones de cliente: `(cliente|Cliente|cl|c|x|n|r|d|h|f|v)\.Inhabilitado\b` en Core, Api y Web; `ClienteRef`, `ClienteHabilitado`, `ClienteContadoInhabilitado`, `ClienteContado`.
- Patrones de suplidor: `SuplidorAsync\(`, `suplidor\.Inhabilitado`, `is \{ Inhabilitado`.
- `FusionadoEnId`, `UsosCliente`, `ClienteContadoId`, `EliminarClienteAsync`, `EliminarSinReferenciasAsync`.
- Conteo de `Inhabilitad` por archivo: `CobrosService.cs` 0, `CobrosEndpoints.cs` 0, `DocumentosComercialesService.Ventas.cs` 0, `PosEndpoints.cs` 0, `CuentasPorPagarService.Aplicaciones.cs` 0, Web `Recibos`/`NotasCxc`/`DevolucionPosPage`/`DevolucionNotaVentas`/`Tablas Clientes.razor` 0; `ReferenciasNg.cs` 8, `PosService.cs` 14 (vendedor, almacén y caja; sin lectura del cliente), `Devoluciones.cs` 1, `MaestrosService.cs` 2, `PuenteMae.cs` 3.

## Qué no verifiqué
- No se ejecutó nada: no se compiló, no se corrieron pruebas, no se usó la base de datos. Solo lectura de git.
- No se hizo `git fetch`; la referencia es la local `b4378650`.
- No se leyó en detalle `GuardarNotaSinClaveAsync` (`CobrosService.cs:400-520`) línea por línea; su ausencia se apoya en el conteo 0 de `Inhabilitad` en todo el archivo (verificado por mí).
- No se revisó `ConsultasCxc.cs` ni el endpoint de listado de clientes para cobros en profundidad; la interfaz se revisó solo por conteo de palabras.
- No se verificó si la solicitud de pago a suplidor pasa luego por `Bancos.cs:73` (marcado I).
- No se revisaron scripts de carga fuera del repositorio ni datos reales de instalaciones VB6: la conclusión de que nadie escribe `Cliente.Inhabilitado` vale para el código de este repositorio.
- No se revisaron los nombres exactos de métodos en `EfectivoService.Bancos.cs:355-370` ni en `Devoluciones.cs` fuera de las líneas citadas.
