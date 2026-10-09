# Revisión de seguridad · Datos sensibles en `rpt` o `rptc` antes de publicar la 1.0 del contrato de vistas (ADR-109)

**Autor:** auditor-seguridad, equipo A · **Fecha:** 2026-10-09 · **Tipo:** revisión de solo lectura (no se compiló ni se tocó ningún árbol de trabajo)
**Pregunta:** ¿las identificaciones de clientes (RNC, cédula, pasaporte) y las diferencias de caja van en `rpt` (lectura general, SQL del diseñador) o en `rptc` (datos sensibles, con privilegio)?
**Estado de la decisión:** recomendación técnica. Lo marcado **[FIRMA]** necesita la firma del propietario.

## Fuentes revisadas

| Cita | Fuente |
|---|---|
| [V] | `origin/b/ola5` `0a52c38`: `database/ola5/rpt-vistas-ventas-inventario.sql` (revisión 3) |
| [L] | `origin/b/ola5` `0a52c38`: `database/ola5/LEEME.md` |
| [J] | `origin/b/ola5` `0a52c38`: `src/GPOS.Contracts/Reportes/contrato-vistas.v1.json` (1.0 sin publicar) |
| [ESQ] | `e300320` (`feature/modelo-ng`): `database/empresa/gpos-empresa-20261008220258_Ola4ExigirVendedor.sql` |
| [REV] | `revision-vistas-ola5-2026-10-08.md` (arquitecto-datos de A), sección 2.2 |
| [DIS-API] | `origin/b/ola5-diseno`: `docs/arquitectura/2026-10-07-ola5-api-reportes-diseno.md` |
| ADR | `master`: ADR-109, ADR-76, ADR-115 (precisión de DO-02), ADR-17, ADR-11, ADR-37 |

**Corrección de la fuente pedida.** La frase «el número completo del pasaporte solo lo ve el SUPER» no es de AdmCloud (ADR-116). Es la **precisión de DO-02 de ADR-115 (Duty Free)**, firmada el 2026-10-08 (`docs/adr/ADR-115.md:62`): hasta la versión 1 del acceso multiempresa, el número completo del pasaporte solo lo ve el SUPER, además de los perfiles «Auditor» y «Cumplimiento Duty Free», y solo en la central, con motivo, tope y bitácora. El punto 5 de ADR-115 (`:16`, `:40`) fija que el número se guarda sellado y que se muestran en claro solo los últimos 4 dígitos.

ADR-76 no influye en esta pregunta: trata de los privilegios de Windows del servicio (`RequiredPrivilege`), no de columnas.

## 1. Alcance y superficie revisada

- **Quién lee `rpt`:** el SQL libre del diseñador, con `gpos_rpt_{EMP}` del rol `gpos_reportes` y `DEFAULT_SCHEMA = rpt` (ADR-109, cl. 3 y 4; [L]:119-130). El rol ya tiene `GRANT SELECT ON SCHEMA::rpt` ([ESQ]:446). En el SQL libre la API **no puede** aplicar privilegios por columna ni el filtro de sucursal: lo que está en `rpt` lo puede leer completo, de todas las sucursales, cualquier usuario con permiso de diseñar.
- **Quién lee `rptc`:** solo las consultas registradas (código), con `gpos_lec`. La API aplica el privilegio efectivo; hoy, para todo el esquema, ese privilegio es «Ver costos» ([DIS-API]:165, DR-10). `gpos_reportes` tiene `DENY` sobre `rptc` ([L]:123).
- **Vistas revisadas:** las 34 de [V] y las vistas `rpt` anteriores que se cruzan con el tema (`rpt.Formato606` y `rpt.Formato607` de [ESQ]).
- **Columnas candidatas, verificadas en [V]:**
  - identificaciones: `rpt.VentaDocumento.RncReceptor` ([V]:117) e `IdentificacionCliente` ([V]:122); `rpt.Cotizacion.IdentificacionCliente` ([V]:271); `rpt.ConsultaFactura.IdentificacionCliente` ([V]:481); `rpt.CatCliente.Identificacion` ([V]:1083); `rpt.CatSuplidor.Identificacion` ([V]:1088);
  - caja: `rpt.CierreCaja` (`Cajero`, `EfectivoEsperado`, `EfectivoDeclarado`, `Diferencia`; [V]:306-316) y `rpt.CierreCajaConteo` (`Cajero`, `Esperado`, `Contado`, `Diferencia`; [V]:338-346);
  - costos: solo en `rptc` (`VentaLinea`, `ExistenciaActual`, `ExistenciaCierre`, `Kardex`, `AjusteInventario`). Se verificó que ninguna vista `rpt` expone `Costo*`, `Valor` ni `Utilidad*`: las coincidencias en `rpt` son comentarios.
- **Teléfonos, correos, direcciones, contacto y notas del cliente:** **ninguna vista de [V] los expone** (verificado por búsqueda). Existen en `cat.Cliente` ([ESQ]:1630-1640: `Telefono`, `Telefono2`, `Movil`, `Fax`, `Contacto`, `Correo`, `Correo2`, `Direccion`, `Nota`).
- **Almacenamiento:** `cat.Cliente.Identificacion varchar(20)` admite `TipoIdentificacion` `R` (9 dígitos), `C` (11 dígitos) y **`P` (pasaporte, 5 a 20 caracteres) en texto plano** ([ESQ]:1615-1616 y 1652-1655). `ventas.Venta.IdentificacionCliente varchar(20)` no guarda el tipo ([ESQ]:3545). `fiscal.Comprobante.RncReceptor varchar(11)` guarda el RNC o la cédula ([ESQ]:3091).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Estado |
|---|---|---|---|
| RS-01 | **Alta** | La cédula y el pasaporte completos quedan en `rpt` (6 columnas en 6 vistas), legibles por el SQL libre del diseñador en todas las sucursales y sin privilegio | Verificado |
| RS-02 | Media | Las diferencias de caja por cajero están en `rpt`. Mover solo `Diferencia` no basta, porque se deduce de lo esperado menos lo contado | Verificado |
| RS-03 | Media | Si las columnas sensibles pasan a `rptc`, el privilegio por esquema («Ver costos», DR-10) las abriría a quien solo debe ver costos. Hace falta un privilegio por vista | Verificado en el diseño |
| RS-04 | Media | `rpt.Formato606` y `rpt.Formato607`, que ya existen, exponen `RncCedula` y `RncReceptor` completos en `rpt` | Verificado ([ESQ]:8135-8136, 10299-10301) |
| RS-05 | Media | El pasaporte y la cédula se guardan en claro en `cat.Cliente`, `cat.Suplidor`, `ventas.Venta` y `fiscal.Comprobante`. Para el pasaporte, eso contradice ADR-115, punto 5, y la regla del propietario | Verificado (esquema); fuera de las vistas |
| RS-06 | Media | El SQL del diseñador ve todas las sucursales y omite la restricción por sucursal de ADR-13 | Inferido del diseño; por confirmar en la API |
| RS-07 | Baja | La lista de pendientes de seguridad de [L]:136 y [REV] 2.2 está incompleta: omite `VentaDocumento`, `Cotizacion` y `CatSuplidor` | Verificado |
| RS-08 | Baja | `rpt.ReciboPago.Referencia` (`varchar(50)`, texto libre) podría recibir un número de tarjeta digitado | Sospecha; por confirmar en la captura |

## 3. Checklist OWASP (aplicado a esta pregunta)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | **Hallazgos** RS-01, RS-02, RS-03, RS-04 y RS-06. Los permisos `rpt`/`rptc`, `DENY` y el encadenamiento de propiedad están bien diseñados (sección 5) |
| A02 Fallas criptográficas | **Hallazgo** RS-05 (identificaciones en claro en reposo) |
| A03 Inyección | No aplica a esta pregunta. El SQL del diseñador lo cubre ADR-109, cl. 13 (ScriptDom) |
| A04 Diseño inseguro | **Hallazgo** RS-02: una columna derivable deja sin efecto mover solo `Diferencia`. Se cubre en la remediación |
| A05 Configuración | Correcto: el script no concede nada y `rptc` nace con `DENY` para `gpos_reportes` ([L]:113-134) |
| A06 Componentes vulnerables | No aplica (no hay dependencias nuevas) |
| A07 Autenticación | No aplica (ADR-109, cl. 6; revisado en S-15) |
| A08 Integridad | No aplica. La huella del contrato está en `rpt.VersionContrato` y cambia con este ajuste |
| A09 Registro y monitoreo | **Observación:** leer la identificación completa o el cuadre por `rptc` debería dejar una línea en el registro estructurado (usuario, vista y huella de los filtros, nunca el valor), como ya prevé ADR-109, cl. 2 |
| A10 SSRF | No aplica |

## 4. Hallazgos

### RS-01 · Alta · Cédula y pasaporte completos en `rpt`

- **Riesgo.** Cualquier usuario con permiso de diseñar reportes puede extraer en bloque la identificación personal de todos los clientes y suplidores de todas las sucursales. Para eso solo necesita el permiso de diseño: ni «Ver costos» ni ningún otro. Con el pasaporte, esto contradice la precisión de DO-02 de ADR-115 (completo solo para el SUPER). Con la cédula, va contra el principio de acceso mínimo. Bajo la Ley 172-13 de RD, la cédula y el pasaporte de una persona física son datos personales. **Inferido:** de esa ley se deriva el deber de limitar el acceso a quien lo necesita. ADR-37 ya tiene pendiente el dictamen de un asesor legal sobre esta ley.
- **Evidencia.** [V]:117, 122, 271, 481, 1083 y 1088; `gpos_reportes` con `SELECT ON SCHEMA::rpt` en [ESQ]:446; DEFAULT_SCHEMA en ADR-109, cl. 3.
- **Matiz verificado.** El RNC de 9 dígitos es de una persona jurídica: la DGII lo publica y los reportes de crédito fiscal (B01) lo necesitan. La cédula (11 dígitos) y el pasaporte son de personas físicas. `ventas.Venta.IdentificacionCliente` y `fiscal.Comprobante.RncReceptor` no guardan el tipo, pero el formato lo distingue: 9 dígitos es RNC, 11 dígitos es cédula y cualquier otro formato es pasaporte u otro documento (`CK_Cliente_Identificacion`, [ESQ]:1652-1655).
- **Remediación (antes de publicar la 1.0, cuando el cambio todavía no cuesta una versión).**
  1. En `rpt`, la identificación va **enmascarada**: el RNC de 9 dígitos íntegro y cualquier otra identificación como un prefijo fijo más los últimos 4 dígitos. El prefijo es fijo para que el largo no revele el tipo. Por ejemplo:
     `CONVERT(varchar(20), CASE WHEN LEN(x) = 9 AND x NOT LIKE '%[^0-9]%' THEN x WHEN x IS NULL THEN NULL ELSE '*******' + RIGHT(x, 4) END)`.
     La columna `rpt` se renombra con el sufijo `Enmascarada` (`IdentificacionClienteEnmascarada`, `RncReceptorEnmascarado`, `IdentificacionEnmascarada`) para que nadie la tome por el dato fiscal.
  2. Se crean `rptc.VentaDocumento`, `rptc.Cotizacion`, `rptc.ConsultaFactura`, `rptc.CatCliente` y `rptc.CatSuplidor` como superconjuntos (regla V-10): las mismas columnas de `rpt`, más la identificación completa al final (`IdentificacionCliente`, `RncReceptor`, `Identificacion`).
  3. **Pasaporte: ni siquiera `rptc` lo da completo.** En `rptc`, el RNC y la cédula van completos y el pasaporte (todo lo que no tenga 9 u 11 dígitos) va con los últimos 4. El número completo solo se ve en el flujo de ADR-115 (SUPER, en la central, con motivo, tope y bitácora), nunca por la API de reportes. **[FIRMA]** Esto extiende la precisión de DO-02 de Duty Free a todo pasaporte del sistema.
  4. **Búsqueda por identificación.** El filtro «cliente» de las consultas registradas busca con `gpos_lec` en `rptc.CatCliente` y devuelve a la interfaz el valor enmascarado, salvo que el usuario tenga el privilegio. En el SQL libre del diseñador, el filtro va por `ClienteId` o `Codigo`.
  5. **Nombres** (`ClienteNombre`, `NombreReceptor`, `Descripcion`): **se quedan en `rpt`.** Sin el identificador el riesgo es menor, y todos los reportes de ventas los necesitan. Alternativa descartada: enmascarar el nombre, que deja inservibles los reportes por cliente.
- **Defensa en profundidad.** Ver RS-05 (cifrado en reposo del pasaporte).

### RS-02 · Media · Diferencias de caja por cajero en `rpt`

- **Riesgo.** El diseñador ve el faltante o sobrante de cada cajero identificado (`Cajero`), en todas las sucursales. Es información laboral y disciplinaria de una persona identificable, y por eso dato personal (Ley 172-13, inferido). Además, `EfectivoEsperado`/`Esperado` en los cierres **X** (en curso de jornada) es justo lo que ADR-17 oculta con el conteo ciego (`ADR-017.md`, «Consecuencias»). Si solo se mueve `Diferencia`, la cifra se sigue obteniendo como `EfectivoEsperado − EfectivoDeclarado` y `Esperado − Contado` ([V]:313-316 y 344-346).
- **Remediación.**
  - `rpt.CierreCaja` conserva el encabezado, el cajero, el supervisor, los conteos de documentos y los totales de venta, devolución e impuestos. **Salen** `EfectivoEsperado`, `EfectivoDeclarado` y `Diferencia`, que pasan a `rptc.CierreCaja` (superconjunto, al final).
  - `rpt.CierreCajaConteo` conserva la forma de pago, la moneda y `Esperado` **solo en los cierres Z no anulados**, donde equivale a la venta por forma de pago ya cerrada y no ayuda a cuadrar sin contar. En los X, `Esperado` va en NULL. **Salen** `Contado` y `Diferencia`, que pasan a `rptc.CierreCajaConteo`, con `Esperado` también en los X. *Alternativa más simple, que también es aceptable:* quitar `rpt.CierreCajaConteo` y dejar solo `rptc.CierreCajaConteo`. Se descarta porque el diseñador pierde la venta por forma de pago del Z, que no es sensible.
  - `Cajero` (usuario) se queda en `rpt`: sin montos de cuadre, es un dato operativo («ventas por cajero»).
  - El reporte 7 (cuadre) sale de `rptc` con el privilegio de cuadre. Sin ese privilegio, el usuario ve el reporte sin esperado, contado ni diferencia. La pantalla del cajero después de su Z (ADR-17) no cambia: sale de la API principal.

### RS-03 · Media · El privilegio de `rptc` está atado a «Ver costos» para todo el esquema

- **Riesgo.** [DIS-API]:165 (DR-10) concede `rptc` si el usuario tiene «Ver costos». Si se adopta RS-01 y RS-02 sin cambiar eso, quien ve costos verá también cédulas y cuadres, y quien debe ver el cuadre necesitará ver costos. ADR-109, cl. 4 describe `rptc` como «costos y bitácora».
- **Remediación.** La API de reportes mantiene un **mapa de vista `rptc` a privilegio requerido** en el contrato. Se sugiere un campo `privilegio` por vista en `contrato-vistas.v1.json`, verificado por la prueba estática de ADR-109, cl. 3. Una consulta registrada que use varias vistas `rptc` exige **todos** sus privilegios; si falta uno, usa la variante `rpt`. Privilegios propuestos, en el grupo Especiales (ADR-11, interruptores):
  - «Ver costos» (existente): `rptc.VentaLinea`, `ExistenciaActual`, `ExistenciaCierre`, `Kardex`, `AjusteInventario`;
  - **«Ver datos personales»** (nuevo): `rptc.VentaDocumento`, `Cotizacion`, `ConsultaFactura`, `CatCliente`, `CatSuplidor`, y en el futuro teléfonos, correos y direcciones;
  - **«Ver cuadre de caja»** (nuevo): `rptc.CierreCaja`, `rptc.CierreCajaConteo`.
  - **[FIRMA]** Los dos privilegios nuevos (precisión de ADR-11), la ampliación del sentido de `rptc` (precisión de ADR-109, cl. 4: «costos, bitácora y datos sensibles, cada vista con su privilegio») y su asignación por omisión. Propuesta de asignación: SUPER y administradores, ambos; supervisor de caja, «Ver cuadre de caja»; contador, «Ver datos personales».
- **Alternativa descartada:** un esquema por clase de dato (`rptp` para personales, `rptk` para caja). `gpos_lec` tendría que leerlos todos de cualquier modo, así que la frontera seguiría en la API. Suma roles y `DENY` sin ganar aislamiento en el motor.
- **Alternativa descartada:** *Dynamic Data Masking* de SQL Server sobre las tablas o vistas. Contra SQL libre no protege, porque el valor se deduce por los predicados del `WHERE`, y además cambia por versión de SQL Server (UNMASK granular desde 2022). Se descarta justo para el canal del diseñador.

### RS-04 · Media · `rpt.Formato606` y `rpt.Formato607` con RNC o cédula completos

- **Riesgo.** Es el mismo de RS-01, en vistas de las olas 3 y 4 que ya están en `rpt` y que el rol `gpos_reportes` lee en cuanto tenga miembros. Los formatos fiscales necesitan el dato completo porque se envían a la DGII, así que enmascarar no es una opción.
- **Remediación.** Con la tanda fiscal (fuera de la ola 5, ADR-111), pasarlas a `rptc` con «Ver datos personales». Si el propietario lo prefiere, también con «Auditar comprobantes fiscales» (ADR-11, precisión de ADR-74). **Condición mínima ahora:** no agregar miembros a `gpos_reportes` en ningún sitio real antes de moverlas. Hoy no tiene miembros ([L]:134).

### RS-05 · Media · Identificaciones en claro en reposo (fuera de las vistas)

- **Riesgo.** `cat.Cliente` y `cat.Suplidor` admiten `TipoIdentificacion = 'P'` en claro, y `ventas.Venta.IdentificacionCliente` lo copia en claro. ADR-115, punto 5 exige que el pasaporte se guarde sellado, con huella y con los últimos 4 en claro. La regla del propietario prohíbe guardar datos sensibles en texto plano. Una vista solo controla quién lee: un respaldo, una réplica o `gpos_app` ven el dato completo.
- **Remediación (entrega a otros agentes; no es un cambio de vistas).** El pasaporte va en una columna sellada (el mecanismo de ADR-115), con huella HMAC y `Ultimos4`. `Identificacion` deja de admitir `P`, o guarda solo la máscara. La cédula se queda en claro: el e-CF, el 606 y el 607 la necesitan en claro y la búsqueda es por igualdad. Cifrarla exige cifrado determinista o huella más sobre, unas 1,5 a 3 semanas-persona (inferido, ±50 %). **[FIRMA]** Si la cédula queda en claro en reposo como riesgo aceptado.

### RS-06 · Media · El diseñador ve todas las sucursales

- **Riesgo.** Las vistas `rpt` no filtran filas y el SQL libre no pasa por el filtro de sucursal de la API. Un usuario restringido a una sucursal (ADR-13) que tenga permiso de diseñar ve todas las demás. Es inferido: [L]:136 y [REV] 2.2 lo afirman. No se verificó el código de la API de reportes.
- **Remediación.** **[FIRMA]** Regla: el privilegio de diseñar SQL solo se asigna a perfiles con acceso a todas las sucursales, y la API lo rechaza al asignarlo o al ejecutar si el usuario tiene restricción de sucursal. La alternativa de usar `SESSION_CONTEXT` con *Row-Level Security* en las vistas se descarta por ahora: necesita un predicado en cada vista y un costo por consulta, y no hay ningún caso de cliente que lo pida.

### RS-07 · Baja · Lista de pendientes incompleta

[L]:136 y [REV] 2.2 citan solo `CatCliente`, `ConsultaFactura`, `CierreCaja` y `CierreCajaConteo`. Faltan `rpt.VentaDocumento` (`RncReceptor`, `IdentificacionCliente`), `rpt.Cotizacion` (`IdentificacionCliente`) y `rpt.CatSuplidor` (`Identificacion`). **Remediación:** las seis vistas de la tabla de la sección 6 entran en el mismo cambio.

### RS-08 · Baja · `Referencia` del pago del recibo (sospecha)

`rpt.ReciboPago.Referencia` ([V]:445) es texto libre de 50 caracteres. La venta guarda la tarjeta solo como `Ultimos4 char(4)` validado ([ESQ]:3760, 3767), pero no consta una validación equivalente en `cxc.ReciboPago.Referencia`. **Remediación:** confirmar que la captura rechaza secuencias que parezcan un número de tarjeta (13 a 19 dígitos que pasen Luhn). Si no lo hace, agregar la validación en la API principal. La vista no cambia.

## 5. Controles bien implementados

- Separación `gpos_rpt` / `gpos_lec`, `DENY SELECT ON SCHEMA::rptc` a `gpos_reportes`, `DENY` generado sobre los esquemas de tablas y el script de vistas sin concesiones ([L]:111-134).
- Comprobación de dueño `dbo` sobre todos los esquemas de usuario, que falla cerrada (V-R1, [V]:61-79).
- Costos y utilidad solo en `rptc`, con «Ver costos». Verificado: ninguna vista `rpt` los expone ni permite deducirlos.
- `rpt.Recibo` ya nace sin la identificación ([V]:362).
- Ninguna vista expone teléfonos, correos, direcciones, notas, contacto, límite de crédito ni el JSON `Detalle` del cierre (H-05).
- La tarjeta de la venta se guarda solo con sus últimos 4 dígitos.

## 6. Tabla de recomendación por columna

| Vista · columna | Hoy | Recomendado en `rpt` | Recomendado en `rptc` | Privilegio | Firma |
|---|---|---|---|---|---|
| `VentaDocumento.RncReceptor` | `rpt` completo | `RncReceptorEnmascarado` (RNC de 9 dígitos íntegro; resto `*******`+4) | `RncReceptor` completo (pasaporte: últimos 4) | Ver datos personales | Sí (privilegio nuevo) |
| `VentaDocumento.IdentificacionCliente` | `rpt` completo | `IdentificacionClienteEnmascarada` | completo (pasaporte: últimos 4) | Ver datos personales | Sí |
| `Cotizacion.IdentificacionCliente` | `rpt` completo | enmascarada | completo (pasaporte: últimos 4) | Ver datos personales | Sí |
| `ConsultaFactura.IdentificacionCliente` | `rpt` completo | enmascarada | completo (pasaporte: últimos 4) | Ver datos personales | Sí |
| `CatCliente.Identificacion` | `rpt` completo | `IdentificacionEnmascarada` | completo (pasaporte: últimos 4); búsqueda por la API | Ver datos personales | Sí |
| `CatSuplidor.Identificacion` | `rpt` completo | enmascarada | completo | Ver datos personales | Sí |
| Pasaporte completo (cualquier vista) | `rpt` completo | nunca | nunca (últimos 4) | Solo el SUPER, por el flujo de ADR-115 | **Sí** (extiende DO-02) |
| Nombre del cliente o receptor | `rpt` | se queda | — | — | No |
| Teléfonos, correos, dirección, contacto, nota (futuro, tanda de CxC) | no expuestos | nunca | solo si un reporte lo exige | Ver datos personales | No (regla) |
| `CierreCaja.EfectivoEsperado`, `EfectivoDeclarado`, `Diferencia` | `rpt` | salen | `rptc.CierreCaja` | Ver cuadre de caja | Sí (privilegio nuevo) |
| `CierreCajaConteo.Esperado` | `rpt` | solo en Z no anulado (NULL en X) | todos | Ver cuadre de caja | Sí |
| `CierreCajaConteo.Contado`, `Diferencia` | `rpt` | salen | `rptc.CierreCajaConteo` | Ver cuadre de caja | Sí |
| `Cajero`, `Supervisor`, `VendedorNombre`, `CreadoPor` | `rpt` | se quedan | — | — | No |
| Costos y utilidad (`CostoBase`, `UtilidadBase`, `CostoUnitario`, `CostoPromedio`, `Valor`) | `rptc` | — | se quedan | Ver costos | No (ya firmado) |
| `Formato606.RncCedula`, `Formato607.RncReceptor` | `rpt` completo | salen (tanda fiscal) | completo | Ver datos personales (o Auditar comprobantes fiscales) | Sí |
| `ReciboPago.Referencia` | `rpt` | se queda | — | — (validar en la captura) | No |

**Esfuerzo (inferido, ±40 %).** B: 6 vistas `rpt` ajustadas, 7 vistas `rptc` nuevas, el JSON y la huella: unas 0,2 sp. API de reportes (mapa de privilegio por vista, búsqueda enmascarada y registro de la lectura): unas 0,2 sp. A: dos privilegios en el catálogo y en la migración: unas 0,1 sp. Sin costo de infraestructura ni de licencias (USD 0). RS-05 (sello del pasaporte) va aparte, con ADR-115.

## 7. Remediaciones priorizadas

1. **Antes de publicar la 1.0 (B):** RS-01 y RS-02 (enmascarado en `rpt`, superconjuntos en `rptc`, nombres con el sufijo `Enmascarada`), incluida RS-07. Se recalcula la huella.
2. **Antes de publicar la 1.0 (B, arquitecto-software):** RS-03, el mapa de vista a privilegio en el contrato y en la API.
3. **Con la firma del propietario:** los privilegios «Ver datos personales» y «Ver cuadre de caja», la ampliación del sentido de `rptc`, la extensión de DO-02 a todo pasaporte y la regla de RS-06.
4. **Antes de agregar miembros a `gpos_reportes` en un sitio real:** RS-04.
5. **En su fase (A, datos):** RS-05, el pasaporte sellado en reposo. Lo condiciona la revisión pendiente V-7.4 de ADR-115.
6. **Verificación (QA):** RS-08. Además, una prueba que compruebe que `gpos_reportes` no obtiene ninguna identificación de 11 dígitos ni montos de cuadre: V-D1b ampliada.

## 8. Recomendación

**Rechazado** para publicar la 1.0 en su forma actual, por RS-01 (Alta). Con RS-01, RS-02, RS-03 y RS-07 aplicados, la recomendación pasaría a **Aprobado con observaciones**: quedarían abiertas RS-04, RS-05, RS-06 y RS-08, con su plan. Es una recomendación técnica. La decisión la firma el propietario.

### Cierre
- Estado: Rechazado (la 1.0 tal como está); Aprobado con observaciones una vez aplicadas RS-01, RS-02, RS-03 y RS-07
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\revision-rpt-rptc-sensibles-2026-10-09.md`
- Supuestos: la Ley 172-13 trata la cédula, el pasaporte y la información disciplinaria del empleado como datos personales (inferido, sin dictamen legal; ver ADR-37). El RNC de 9 dígitos es de una persona jurídica y es público. El permiso de diseñar no filtra sucursales (inferido de [L] y [REV]).
- Decisiones candidatas a ADR: precisión de ADR-109, cl. 4 («`rptc` = costos, bitácora y datos sensibles, con privilegio por vista»); precisión de ADR-11 (privilegios «Ver datos personales» y «Ver cuadre de caja»); extensión de la precisión de DO-02 de ADR-115 a todo pasaporte; regla «diseñar SQL solo con acceso a todas las sucursales»
- Entregas a otros agentes: arquitecto-datos (B) → RS-01, RS-02 y RS-07 en las vistas, el JSON y la huella; arquitecto-software (B) → RS-03 (mapa de privilegio por vista, búsqueda enmascarada, registro de la lectura); arquitecto-maestro → precisiones de ADR-109, ADR-11 y ADR-115 para la firma; arquitecto-datos (A) → RS-05 (pasaporte sellado en reposo) y RS-04 en la tanda fiscal; qa-automatizado → RS-08 y la ampliación de V-D1b
- Próximo paso recomendado: el arquitecto-maestro lleva al propietario los cuatro puntos [FIRMA] y B aplica RS-01, RS-02 y RS-07 sobre la 1.0 antes de que A una la migración Ola5VistasVentasInventario.
