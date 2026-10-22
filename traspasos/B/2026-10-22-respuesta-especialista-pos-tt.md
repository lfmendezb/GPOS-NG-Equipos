# Respuesta del especialista-pos a B: ADR-92, fase TT (campos de TT-02, Q-TT1-b, TT-P1, Q-TT5-b y ficha de com.Comensal)

- Fecha: 2026-10-22 · Autor: especialista-pos · Estado de lo que sigue: propuesta técnica, no decide nada. Lo que cambia lo que la persona ve o hace queda para firma del propietario; lo legal, para el abogado; lo contable, para el contador.
- Convención: [V] verificado en código o documento (archivo:línea) · [I] inferido o conocimiento general, no verificado en fuente oficial en esta sesión · [ABOGADO] · [CONTADOR].
- Base leída: `origin/feature/modelo-ng` (el esquema de destino; `master` conserva el heredado) y `master` solo para el contraste. Citas de modelo-ng: `src/GPOS.Core/Dominio/Maestros/Terceros.cs` (en adelante TER), `src/GPOS.Core/Dominio/Configuracion/Personas.cs` (PER), `src/GPOS.Core/Datos/Empresa/Configuracion/MaeConfiguracion.cs` (MAE) y `CfgConfiguracion.cs` (CFG), `src/GPOS.Core/Servicios/MaestrosService.cs` (SRV). Citas de master: `src/GPOS.Core/Data/Empresa/Maestros.cs` (HER).
- No modifiqué nada del repositorio.

---

## 0. Hallazgos que cambian el planteamiento (leer primero)

1. **[V] El tipo de identificación no lo elige el usuario: lo deduce el servidor del largo del número.** `c.TipoIdentificacion = TiposIdentificacion.TipoDe(digitos)` (SRV:197) y `TipoDe` devuelve R con 9 dígitos, C con 11, N sin número y **P con cualquier otro largo** (TER:116-122). Consecuencias para TT-01:
   - `N` **nunca** lleva número (CK_Cliente_Identificacion, MAE:328-333): una empresa con `N` es una empresa **sin RNC capturado**, no una empresa con un tipo mal puesto.
   - `P` es en la práctica «un número que no mide 9 ni 11 dígitos» (un RNC mal digitado, un RNC extranjero, un pasaporte real). El CK de `P` solo exige de 5 a 20 caracteres, sin mirar si son dígitos.
   - Cuando exista el maestro de P-3 (ADR-161) esto cambia; mientras tanto, la deducción de TT-01 (a) se apoya en una deducción previa del largo, no en una decisión de la persona.
2. **[V] El cliente `GENERICO` (consumidor final, contado) es un registro de tipo `N` que no es una persona** (`Cliente.CodigoContado = "GENERICO"`, TER:17). TT-01 lo clasificaría como «persona física» (N) y ofrecería suprimirlo. **La prueba de arquitectura y la ruta deben excluirlo** (y a todo cliente sembrado por el sistema). Es el riesgo operativo más serio de la lista: bloquearlo deja el POS sin cliente de contado.
3. **[V] Existe un puente de transición que escribe una segunda copia de cliente y suplidor en las tablas heredadas, en la misma transacción** (`PuenteMae`, `src/GPOS.Core/Infraestructura/Transicion/PuenteMae.cs:3-8`; SRV:~209 llama `PuenteMae.ClienteAsync`; el propio texto dice «se elimina en la ola 3»). La tabla heredada tiene además `Telefono3`, `CorreoElectronico3` e `IdDireccion` que el modelo nuevo no tiene (HER:11,33,15). **Si TT sale antes de eliminar el puente, rectificar y suprimir deben escribir también la copia heredada**, o los datos «suprimidos» sobreviven en `Clientes`/`Suplidores`. Esto no estaba en el inventario TT-P3 de A. Entrega a B (arquitecto-software).
4. **[V] `Cedula` y `Identificacion` están indexadas con unicidad o con índice** (`UX_Empleado_Cedula` filtrado, CFG:~282; `IX_Cliente_Identificacion`, MAE:~352; SRV:166-169 rechaza un RNC repetido). Rectificar el documento debe pasar por la misma validación de duplicado, y suprimir con `NULL` en Empleado es seguro por el filtro `WHERE Cedula IS NOT NULL`.
5. **[V] Rectificar la identificación de un cliente recalcula su tipo, y el tipo puede cambiar de grupo** (de `C` a `R` si se corrige a 9 dígitos). Un cambio así saca el registro de la protección (TT-01) o lo mete en ella. La ruta de TT debe **rechazar** que `Rectificar` convierta el registro en `R`, y exigir que el resultado siga en C, P o N (regla propuesta, sección 1.4).

---

## 1. Lista de campos de TT-02 (bloquea construir TT)

### 1.1 Criterio aplicado
Un campo entra en «Rectificar» si es (a) un dato que identifica o permite contactar a la persona y (b) el comprobante ya emitido no depende de él (porque `ventas.Venta` y el 606 guardan su propia copia: `NombreCliente`, `IdentificacionCliente`, `TipoIdentificacionCliente`, `TelefonoCliente`, `CorreoCliente`, Ventas.cs:14-24 [V]; y `FisConfiguracion.cs:287-292` para el 606, según A [V por cita de A, no releído]). No entra ningún campo que gobierne dinero, crédito, impuestos, numeración o clasificación fiscal: eso es operación del negocio y no «dato personal del titular».

### 1.2 Cliente (`cat.Cliente`, temporal) [V TER:14-57; MAE:~320-360]

| Columna | Largo [V MAE] | Rectificar | Suprimir (TT-03 i) | Observación |
|---|---|---|---|---|
| `RazonSocial` | 150 | **Sí** (nombre de la persona física) | **Se conserva** (bloqueo) | Obligatorio (NOT NULL); es lo que los comprobantes ya emitidos muestran. |
| `NombreComercial` | 150 | **Sí** | **Se anonimiza** (propuesta) | No aparece en el comprobante fiscal. [ABOGADO/CONTADOR] confirmar. |
| `Identificacion` (+ `TipoIdentificacion`, derivado) | 20 / char(1) | **Sí, con salvaguardas** (1.4) | **Se conserva** (bloqueo) | `TipoIdentificacion` no se edita: lo recalcula el servidor. |
| `Telefono` | 30 | **Sí** | **Se anonimiza** | Contrato: `Telefono1`. |
| `Telefono2` | 30 | **Sí** | **Se anonimiza** | |
| `Movil` | 30 | **Sí** | **Se anonimiza** | Contrato: `Mobil`. |
| `Fax` | 30 | **Sí** | **Se anonimiza** | Residual, pero es un teléfono. |
| `Correo` | 200 | **Sí** | **Se anonimiza** | Contrato: `CorreoElectronico1`. |
| `Correo2` | 200 | **Sí** | **Se anonimiza** | Contrato: `CorreoElectronico2`. |
| `Direccion` | 250 | **Sí** | **Se anonimiza** | |
| `Contacto` | 100 | **Sí** (solo en C, P, N) | **Se anonimiza** | TT-01 ya excluye `Contacto` de los `R`. Es el nombre de *otra* persona (cónyuge, secretaria): dato de un tercero. [ABOGADO]. |
| `PaginaWeb` | 200 | **Sí** | **Se anonimiza** | Dato de contacto de una persona física comerciante. |
| `Nota` | 500 | **No** (es del negocio) | **Se anonimiza** (TT-03 ya lo dice) | Texto libre: puede contener cualquier dato personal. Rectificarla no es derecho del titular. |
| `PaisId`, `ZonaId`, `TerritorioId` | FK | **No** | **Se conservan** | Clasificación comercial, no identifican a la persona. |

Nunca por TT (cliente): `Id`, `Codigo`, `TipoComprobanteCodigo`, `ListaPrecioId`, `TerminoId`, `MonedaId`, `VendedorId`, `SucursalId`, `ClaseId`, `SubclaseId`, `LimiteCredito`, `AplicaImpuesto`, `Prospecto`, `FusionadoEnId`, `Inhabilitado` (salvo lo que haga Suprimir), `CreadoEn/Por`, `ModificadoEn/Por`, `Version`, `ValidoDesde/Hasta` [V TER:19-56].

### 1.3 Suplidor (`cat.Suplidor`, temporal) [V TER:67-104]
Igual que el cliente en las columnas homónimas (`RazonSocial`, `NombreComercial`, `Identificacion`, `Telefono`, `Telefono2`, `Movil`, `Fax`, `Correo`, `Correo2`, `Direccion`, `Contacto`, `PaginaWeb`, `Nota`). Diferencias:
- **Nunca**: `Codigo`, `TipoBienServicio606`, `TerminoId`, `MonedaId`, `SucursalId`, `PaisId`, `ZonaId`, `Clase`, `RetieneItbis`, `RetieneIsr`, `TipoRetencionIsr`, `PorcRetencionItbis`, `PorcRetencionIsr`, `AplicaImpuesto`. Las retenciones son obligaciones fiscales del comprador (no datos del titular).
- **Peso fiscal mayor que en el cliente [I]:** el suplidor persona física «informal» es aquel al que la empresa emite ella misma el comprobante de compras (B11) y le retiene el ISR; en ese caso la empresa es la emisora y su copia del nombre y la cédula es soporte de su propio comprobante. **Suprimir debe conservar siempre nombre e identificación** (ya lo hace TT-03) y la advertencia de la bandera de CxP (F-9) es doble aquí. [CONTADOR] confirmar el tratamiento del B11 y del gasto menor B13 con persona física.
- Rectificar la `Identificacion` de un suplidor con compras registradas desalinea el maestro del 606 ya reportado: ver 1.4.

### 1.4 Reglas de la ruta para `Identificacion` (aplican a cliente y suplidor)
1. Se valida igual que el alta (largo, dígitos, duplicado: SRV:166-169).
2. **El tipo resultante debe seguir en {C, P, N}.** Si el nuevo número mide 9 dígitos (R), la ruta responde `CAMPO_NO_PERSONAL` o un código propio: cambiar una persona a persona jurídica no es una rectificación del titular; es una reclasificación del negocio (se hace por la edición normal del maestro, con sus privilegios y con el SUPER en solo consulta no disponible). [I] defensa contra usar «Rectificar» en solo consulta para esquivar el cierre de edición de maestros de TT-05.
3. **No se puede dejar en blanco si el cliente tiene `TipoComprobanteCodigo` que exige RNC** (B01/E31, B14/E44, B15/E45; SRV:152-154 [V]: `RequiereRnc`). Se rechaza con el mismo mensaje del alta.
4. Un cambio del documento **no modifica los comprobantes emitidos** (TT-04). Si el titular dice «mi cédula estaba mal en la factura», el remedio fiscal es una nota de crédito y una factura nueva, no TT. Debe decirlo el texto de la pantalla (F-8). [CONTADOR] confirmar.
5. Va a `audit.Bitacora` solo el nombre del campo (`Identificacion`), sin valor (TT-06).

### 1.5 Empleado (`rrhh.Empleado`, no temporal) [V PER:11-32; CFG:270-290]

| Columna | Largo [V CFG] | Rectificar | Suprimir | Observación |
|---|---|---|---|---|
| `Nombres` | 80 | **Sí** | **Se conserva** | Para los vendedores es la «descripción» del catálogo (PER:4-5) y sale en reportes por FK: un cambio se ve retroactivo en los reportes de comisiones; es lo esperado en un nombre corregido. |
| `Apellidos` | 80 | **Sí** | **Se conserva** | |
| `Cedula` | 11 | **Sí** (11 dígitos, único) | **Se conserva** | Para empleados no hay comprobante fiscal que dependa de ella; la conservación se justifica por la relación laboral/comisiones. [ABOGADO] qué plazo y qué datos deben conservarse del empleado. |
| `Telefono` | 30 | **Sí** | **Se anonimiza** | |
| `Correo` | 150 | **Sí** | **Se anonimiza** | |

Nunca: `Id`, `Codigo`, `CodigoEmpleado` (código de nómina, identificador operativo inmutable), `SucursalId`, `EsVendedor`, `ComisionVentas`, `ComisionCobros`, `TipoComision`, `UsuarioSistemaId`, `Inhabilitado` (salvo Suprimir), `Version` [V PER:13-28].
- **No hay** dirección, fecha de nacimiento, foto ni nota en `rrhh.Empleado` [V PER:13-28; CFG:270-290]. No los agregue TT: el empleado solo tiene cuatro datos personales rectificables (nombres, apellidos, cédula, teléfono, correo).
- **Punto abierto [I]:** un empleado con `UsuarioSistemaId` tiene una cuenta de acceso; suprimir el empleado no desactiva la cuenta. La cuenta es de otro régimen (ADR-34 a 36); el aviso al ADMIN debe decirlo.
- Si el empleado es vendedor asignado a una caja o a un perfil de cajero (`Caja.VendedorId`, CFG:~265; `PerfilCajero.VendedorId`, PER:48), bloquearlo (`Inhabilitado = 1`) es lo que ADR-08 ya prevé; la pantalla debe avisar de esas asignaciones.

### 1.6 Datos que *no existen* en el código y que usted mencionó
Contacto/fecha de nacimiento/foto: **no existen** en cliente, suplidor ni empleado [V]. «Contacto» sí existe en cliente y suplidor (ya incluido). Fecha de nacimiento y foto solo existirían en `com.Comensal` (foto) y en nada más. No los agregue a la lista de TT-02 de estos tres maestros.

### 1.7 Contenido propuesto de `CamposPersonalesTitular.json`
Nombres reales de columna del modelo nuevo (los de destino); entre paréntesis, el campo del contrato vigente, para mapear el DTO. Versionado, como pide F-4.

```json
{
  "version": 1,
  "fuente": "ADR-92 TT-02/TT-03, hoja de firma 2026-10-22; especialista-pos 2026-10-22",
  "maestros": {
    "clientes": {
      "tabla": "cat.Cliente",
      "personaFisica": "TipoIdentificacion IN ('C','P','N')",
      "excluir": ["Codigo = 'GENERICO'"],
      "rectificar": ["RazonSocial", "NombreComercial", "Identificacion", "Telefono", "Telefono2", "Movil", "Fax", "Correo", "Correo2", "Direccion", "Contacto", "PaginaWeb"],
      "anonimizarAlSuprimir": ["NombreComercial", "Telefono", "Telefono2", "Movil", "Fax", "Correo", "Correo2", "Direccion", "Contacto", "PaginaWeb", "Nota"],
      "conservarBloqueado": ["RazonSocial", "Identificacion", "TipoIdentificacion"],
      "alias": { "Telefono": "Telefono1", "Movil": "Mobil", "Correo": "CorreoElectronico1", "Correo2": "CorreoElectronico2", "Identificacion": "RNC" },
      "espejoHeredado": { "tabla": "Clientes", "extra": ["Telefono3", "CorreoElectronico3", "IdDireccion"], "vigenteHasta": "eliminacion de PuenteMae (ola 3)" },
      "historial": "cat.ClienteHistorial"
    },
    "suplidores": {
      "tabla": "cat.Suplidor",
      "personaFisica": "TipoIdentificacion IN ('C','P','N')",
      "excluir": [],
      "rectificar": ["RazonSocial", "NombreComercial", "Identificacion", "Telefono", "Telefono2", "Movil", "Fax", "Correo", "Correo2", "Direccion", "Contacto", "PaginaWeb"],
      "anonimizarAlSuprimir": ["NombreComercial", "Telefono", "Telefono2", "Movil", "Fax", "Correo", "Correo2", "Direccion", "Contacto", "PaginaWeb", "Nota"],
      "conservarBloqueado": ["RazonSocial", "Identificacion", "TipoIdentificacion"],
      "alias": { "Telefono": "Telefono1", "Movil": "Mobil", "Correo": "CorreoElectronico1", "Correo2": "CorreoElectronico2", "Identificacion": "RNC" },
      "espejoHeredado": { "tabla": "Suplidores", "extra": ["Telefono3", "CorreoElectronico3", "IdDireccion"], "vigenteHasta": "eliminacion de PuenteMae (ola 3)" },
      "historial": "cat.SuplidorHistorial"
    },
    "empleados": {
      "tabla": "rrhh.Empleado",
      "personaFisica": "siempre",
      "excluir": [],
      "rectificar": ["Nombres", "Apellidos", "Cedula", "Telefono", "Correo"],
      "anonimizarAlSuprimir": ["Telefono", "Correo"],
      "conservarBloqueado": ["Nombres", "Apellidos", "Cedula"],
      "historial": null
    }
  },
  "nunca": {
    "comunes": ["Id", "Codigo", "Inhabilitado", "Version", "CreadoEn", "CreadoPor", "ModificadoEn", "ModificadoPor", "TitularBloqueadoEn"],
    "clientes": ["TipoComprobanteCodigo", "ListaPrecioId", "TerminoId", "MonedaId", "VendedorId", "SucursalId", "ClaseId", "SubclaseId", "PaisId", "TerritorioId", "ZonaId", "LimiteCredito", "AplicaImpuesto", "Prospecto", "FusionadoEnId", "TipoIdentificacion"],
    "suplidores": ["TipoBienServicio606", "TerminoId", "MonedaId", "SucursalId", "PaisId", "ZonaId", "Clase", "RetieneItbis", "RetieneIsr", "TipoRetencionIsr", "PorcRetencionItbis", "PorcRetencionIsr", "AplicaImpuesto", "TipoIdentificacion"],
    "empleados": ["CodigoEmpleado", "SucursalId", "EsVendedor", "ComisionVentas", "ComisionCobros", "TipoComision", "UsuarioSistemaId"]
  },
  "reglas": {
    "identificacionTipoResultante": ["C", "P", "N"],
    "identificacionNoVaciaSiTipoComprobanteRequiereRnc": true,
    "rechazarCamposFuera": "CAMPO_NO_PERSONAL"
  }
}
```

Notas del JSON: (a) `TipoIdentificacion` está en «nunca» como entrada porque la ruta lo recalcula, no lo acepta; (b) `Nota` no se rectifica pero sí se limpia al suprimir; (c) `NombreComercial` en «anonimizar» y `Contacto` son propuestas a confirmar por el abogado (L-04), igual que la lista de TT-03; (d) el nombre real en el contrato de `/api/maestros/clientes` es el de `alias`.

**Prueba de arquitectura sugerida (F-4):** que la intersección de `rectificar` con `nunca` sea vacía; que todo campo de `rectificar` exista como columna con el largo del mapeo (CP-169); que `GENERICO` esté en `excluir`; y que el JSON mencione todas las columnas de texto de cada tabla en alguna lista (así una columna personal nueva obliga a decidir).

---

## 2. Q-TT1-b y TT-P1 (identificación de personas físicas)

### 2.1 ¿Los clientes registran empresas con `N` o con `P`? ¿Es frecuente?
- **[V] Con el código actual, una empresa con RNC de 9 dígitos se registra con `R`, siempre**; el usuario ni siquiera elige el tipo (SRV:197, TER:116-122). Un cliente de crédito fiscal, gubernamental o de régimen especial **exige RNC o cédula** para guardarse (SRV:152-154), así que *ese* tipo de cliente nunca queda en `N`.
- **Empresas con `N` ocurren** solo en clientes con comprobante de consumo (B02/E32) o sin comprobante a los que el cajero no les pidió RNC: una empresa de paso que paga de contado, un «cliente rápido» creado desde el POS. [I] Es frecuente en tiendas de mostrador y supermercados, y rara en distribución y servicios a crédito.
- **Empresas con `P`:** solo si el número no mide 9 ni 11 dígitos (un RNC con un dígito de más o de menos, un NIT o RUT extranjero de 5 a 20 caracteres). [I] Poco frecuente; los clientes extranjeros reales son pocos fuera del Duty Free y el turismo.
- **No tengo datos de frecuencia reales** (BP2 nunca salió a producción, y no hay base con historia: CLAUDE.md, J-3). Todo lo dicho es inferido; la medida real se hace con una consulta de conteo en la primera instalación.
- **Recomendación:** sí, **basta el aviso en la interfaz** («este registro parece de una empresa») y no justifica la marca explícita de TT-01 (c). Reglas para el aviso: se muestra cuando el tipo es `N` o `P` y la `RazonSocial` contiene un sufijo societario típico (`SRL`, `S.R.L.`, `SA`, `S.A.`, `EIRL`, `SAS`, `SRL.`, `CxA`, `COMPAÑÍA`, `CIA`, `INVERSIONES`, `GRUPO`, `HOLDING`) o el `Contacto` no está vacío. Es un aviso, no un bloqueo: la ruta sigue siendo decisión del ADMIN con el motivo. Dos observaciones:
  - El daño de un `N` mal clasificado es por exceso (ofrecer suprimir una empresa) y lo ejecuta el ADMIN con confirmación tecleada: aceptable. Sigue siendo irreversible, así que el aviso debe estar **antes** de la confirmación.
  - Con la suprimir, la empresa que se bloqueó por error pierde teléfonos y correos de contacto: la mitigación real es la confirmación tecleada de F-4, no el aviso.
- **Si el propietario prefiere más determinismo:** el maestro de P-3 (ADR-161) lo resuelve, porque el ADMIN declara el tipo en el alta en vez de dejarlo deducir. Hasta entonces, el aviso.

### 2.2 TT-P1: persona física comerciante que usa la cédula como RNC, ¿`C` o `R`?
- **[V] En el sistema se registra con `C`**: su identificador mide 11 dígitos, `R` exige exactamente 9 (MAE:328-333) y el tipo lo deduce el servidor del largo (TER:116-122). No hay elección.
- **[I] Operación DGII:** la DGII asigna a las personas físicas la cédula como RNC (11 dígitos, sin guiones) y reserva los 9 dígitos para las personas jurídicas; el padrón de la DGII y el RNC del comprador en el e-CF y en el 607 admiten ambos largos. Coincide con lo que dice el propietario en Q-TT1-a («RNC 9 dígitos, cédula 11 dígitos», hoja de firma:87). **No lo confirmé en una fuente oficial en esta sesión.** [CONTADOR] confirmar.
- **El riesgo que sí existe [I]:** personas físicas con actividad comercial **antigua** inscritas en la DGII con un RNC de 9 dígitos (de antes de que se usara la cédula como identificador) siguen existiendo en el padrón. Ese RNC se registraría con `R` y TT las trataría como persona jurídica (error por defecto: no se atiende a un titular). Mitigación sin marca nueva: la ruta de TT acepta el caso mediante el ADMIN con el privilegio, **ofreciendo «Tratar como persona física» solo desde el maestro de P-3** (ADR-161), no ahora. Mientras tanto queda como riesgo residual R-4 de A, con el abogado (L-03).
- Observación fiscal relevante: en el e-CF y en los reportes el RNC/cédula del comprador es un dato del comprobante; después de TT-03 el comprobante lo conserva, y por eso el «Identificacion» queda bloqueado, no anonimizado.

---

## 3. Q-TT5-b: ¿qué documentos cuentan como «comprobante que lo usa»?

### 3.1 Recomendación
Cuentan para el cálculo de `ConservarHasta` (último documento + 10 años) y, por tanto, **bloquean suprimir el nombre y el documento** (no los teléfonos/correos), los documentos que **ya fueron emitidos con comprobante fiscal** o que **son soporte contable o fiscal** del tercero:

| Cuenta (bloquea y fija `ConservarHasta`) | No cuenta |
|---|---|
| Factura y factura POS con NCF o e-NCF (FAC, FPOS) | Cotización (COT) y pedido (PED): no son comprobantes [V `docs/pos/2026-10-01-ncf-y-existencias-iniciales.md:83`] |
| Nota de crédito y de débito (NC, ND), devolución (DEV) con o sin NCF si modifica una factura | Conduce (CON), entrada (ENT), ajuste, conteo, transferencia: no llevan al tercero como titular fiscal [V mismo doc.:83] |
| Cheque devuelto (CHD) y recibo de cobro (REC): soporte del saldo | Solicitud de compra (SCO) y orden de compra (ORD) sin factura de compra |
| Factura de compra (FCP) con NCF del suplidor, devolución de compra (DVS), notas CxP (NCP/NDP) | Prospecto sin ninguna transacción |
| Cheque, transferencia o solicitud de pago emitidos al suplidor (CHK/TRB/SPG), caja chica con beneficiario y cédula (`caja.CajaChica`) | |
| Registro del 606/607 que lo cite | |
| Cuentas por cobrar o por pagar con saldo distinto de cero (aunque el comprobante sea antiguo) | |

[V] Los códigos de tipo vienen de `Documentos.cs:37-60`; que cotización, pedido, conduce y demás no son comprobantes viene de `docs/pos/2026-10-01-ncf-y-existencias-iniciales.md:83`; que la nota de crédito/débito solo se emite sobre «comprobantes fiscales emitidos con anterioridad», al mismo adquiriente, de la Ley 32-23, art. 15 num. 3 y 4, citada en el mismo documento (:68). El resto es criterio de operación [I].

**Qué hacer con cotizaciones y pedidos del titular que se suprime:** no bloquean, pero **tampoco quedan intactos**: son documentos comerciales no fiscales que el negocio no está obligado a conservar. Dos opciones, a elegir por el propietario: (a) conservarlos como están (nombre y teléfono copiado en el documento) hasta su archivado normal; (b) anonimizar los datos del titular en las cotizaciones y pedidos **no convertidos en factura** al suprimir. [I] Recomiendo (a) para la v1: es lo que TT-04 ya dice de las copias en documentos, el costo es cero y el riesgo se acota con el abogado (L-04). Dejarlo anotado para TT-P3.

### 3.2 ¿Una nota de crédito posterior al bloqueo es un «documento nuevo» prohibido por TT-03?
**Recomendación: no debe prohibirse. Hay que decirlo expresamente en TT-03.**
- [V] La nota de crédito o de débito «solo podrá ser emitida al mismo adquiriente o usuario para modificar comprobantes fiscales emitidos con anterioridad» (Ley 32-23, art. 15 num. 3 y 4, según `docs/pos/2026-10-01-ncf-y-existencias-iniciales.md:68`). Bloquear la nota de crédito de un cliente bloqueado obligaría a emitirla a otro tercero, lo cual la ley no permite, o a no emitirla.
- [V] La devolución en GPOS NG es una nota de crédito (memoria `devoluciones-son-notas-de-credito`; `docs/pos/2026-10-04-h0-reglas-fiscales-nodo.md:312`: un documento con el Z cerrado no se anula, se reversa con nota de crédito). Y con e-NCF «no se anula» (CLAUDE.md, ADR-108): la nota de crédito **es la única vía** de corrección.
- Por el mismo razonamiento, deben seguir permitidas sobre un registro bloqueado, porque todas **se refieren a un comprobante o saldo existente**: nota de crédito (B04/E34), nota de débito (B03/E33), devolución, recibo de cobro, aplicación de saldo a favor (también CxP: `AplicacionSaldoFavorCxp`), cheque devuelto, pago de CxP, reembolso de un saldo a favor. Esto también resuelve el punto abierto de la hoja («Cliente inhabilitado y cobros», :62): **un cliente bloqueado debe poder pagar su deuda** (F-9: «se debe saldar el saldo pendiente»); si la regla de ADR-08 («inhabilitado no se usa») lo impide, hay que verificarlo y excepcionar el recibo y la nota. No lo verifiqué en el código; es la primera verificación que B debe hacer.
- **Prohibidos** sobre un registro bloqueado: factura nueva, factura POS nueva, cotización, pedido, orden de compra, factura de compra nueva, cheque nuevo, nota de débito *que no modifique* un comprobante anterior, y cualquier alta que lo seleccione como tercero nuevo.
- **Efecto sobre la conservación:** la nota de crédito posterior mueve `MAX(fecha de documentos)` y por tanto `ConservarHasta` (TT-P5 de A: fórmula calculada, no guardada [V adr92-respuestas-datos:297-299]); esto es consecuente y es la razón por la que A calculó la fecha en vez de guardarla.
- **Por qué importa para el cajero [I]:** en la caja, un cliente bloqueado que vuelve a devolver un artículo ya pagado debe poder recibir su nota de crédito; no puede crearse un registro nuevo (el comprobante original lo cita). El mensaje del POS debe decir «cliente bloqueado por solicitud del titular: solo notas y cobros de documentos anteriores», no «cliente inhabilitado».
- **Redacción propuesta para TT-03 (precisión):** «El bloqueo impide documentos nuevos; no impide los documentos que modifican, cobran o pagan comprobantes o saldos ya emitidos al mismo tercero (nota de crédito, nota de débito, devolución, recibo, aplicación de saldo, cheque devuelto)». [ABOGADO] y [CONTADOR] confirmar; el contador sobre la regla de 10 años (Q-TT5-a).

### 3.3 Otros puntos de operación que B debe resolver antes de construir (Q-TT5-b ampliada)
1. **El e-CF enviado con correo y teléfono.** Un correo anonimizado después impide reenviar el comprobante al titular; no afecta la validez ante la DGII. Aceptable; debe verse en el aviso de F-8 [I].
2. **Venta fiada con saldo vivo (F-9).** Un cliente con CxC pendiente no es «sin comprobante vigente»: el saldo mantiene `ConservarHasta` abierto aunque el último comprobante sea antiguo (fila 7 de la tabla 3.1).
3. **Consumidor final ≥ RD$250.000 [I]:** [CONTADOR] confirmar que desde ese monto se exige identificar al comprador (así lo «entiende» `docs/decisiones/2026-10-04-cierre-h0.md:524`, C-14, fuente secundaria). Es un caso de persona física con cédula en un registro que hoy se crea como cliente genérico; TT debe tratarlo igual que los demás, y la importación del padrón debe evitar que ese comprador quede sin registro propio.
4. **Clientes fusionados (`FusionadoEnId`, TER:50).** Un registro fusionado en otro (inhabilitado) también es de persona física; Suprimir debe recorrer la cadena de fusión: el titular puede tener datos en el registro absorbido y en el absorbente. [V del campo; I del comportamiento].

---

## 4. Ficha de `com.Comensal` y su entrada en TT

### 4.1 Estado
- **[V] No existe en el código de ninguna rama:** búsqueda de `com.Comensal` / `class Comensal` en `origin/feature/modelo-ng` y en `master` sin resultados. Solo existe el diseño del arquitecto de datos de A (`GPOS-NG-Equipos/traspasos/A/datos-vertical-corporativa-2026-10-15.md:381-445`) y los ADR-88 (:46-47) y ADR-128 (:22). Entrega 3, tramo 3d (ADR-128 punto 13). Todo lo siguiente es **diseño, no código**.

### 4.2 Campos personales (diseño de A, `datos-vertical-corporativa-2026-10-15.md:381-445`) [V del documento]

| Dónde | Campo | Tipo | ¿Personal? | Rectificar | Suprimir |
|---|---|---|---|---|---|
| `com.Comensal` | `Nombres`, `Apellidos` | varchar(60) | Sí | **Sí** | Conservar solo si hay consumos facturados; si no, anonimizar |
| `com.Comensal` | `NombreClave` | varchar(130) BIN2 | Sí (derivado del nombre) | **Derivado**: se recalcula al rectificar; no es editable | Sigue la suerte del nombre |
| `com.Comensal` | `Codigo` (código de nómina) | varchar(30) | Identificador operativo, inmutable | **No** | Conservar |
| `com.Comensal` | `EmpleadoId` | enlace | Enlace a otro registro personal | **No** | Se conserva si el empleado se bloquea; ver 4.3 |
| `com.Comensal` | `FechaAlta`, `FechaBaja`, `SuspendidoHasta`, `Estado` | fechas | No sensibles | **No** | Conservar |
| `com.ComensalAsignacion` | `Departamento` | varchar(60) | Dato laboral | **Sí** | Anonimizar |
| `com.ComensalFoto` | `Contenido` (cifrado) | varbinary | Sí (imagen) | **Sustituir/retirar** (régimen propio) | **Borrado físico**, ya previsto |
| `com.Carne` | `IdentificadorHmac`, `Ultimos4` | HMAC | Pseudónimo | **No** | Conservar o invalidar (ver abajo) |

No hay cédula, teléfono, correo ni dirección en el padrón [V ADR-88:46; ADR-128:22; datos:381-401]. **Fecha de nacimiento: no existe**; no la agreguen.

### 4.3 Qué entra y qué no en TT
- **Régimen propio ya firmado (ADR-88, precisiones 2 y 5) [V]:** consentimiento de la foto registrado; retirarlo **borra la foto en el acto**; la foto se borra a los 90 días de la baja o por falta de uso; hay aviso informativo versionado con los derechos del titular; derecho de acceso mediante la impresión «Datos del comensal». **La foto queda fuera de TT**: sigue su ruta (retirar consentimiento), que es más fuerte que la supresión de TT-03.
- **Lo que TT debe sumar cuando se construya la Corporativa (entrega 3):** una cuarta entrada `comensales` en el JSON con:
  - `rectificar`: `Nombres`, `Apellidos`, `Departamento`. (No `Codigo`, no `Estado`, no `EmpleadoId`.)
  - `anonimizarAlSuprimir`: `Departamento`, y la foto (borrado).
  - `conservarBloqueado`: `Nombres` y `Apellidos` **solo mientras existan consumos facturados** a la empresa cliente (la factura del período se emite a la empresa, no al comensal: ADR-128 punto 3, y la relación por empleado CO-01 se entrega a la empresa cliente). Si la empresa cliente es el responsable de ese padrón (modelo B, `ClienteId` informado), **el responsable es el cliente del restaurante, no el restaurante** [I]: el restaurante actúa como encargado y la solicitud del comensal debe encauzarse a su empleador. [ABOGADO].
  - `personaFisica`: siempre (el comensal es una persona).
  - Es un **registro de persona física sin tipo de identificación**: la deducción por `TipoIdentificacion` de TT-01 no aplica; la ruta debe tratar `comensales` como «siempre persona física».
- **`com.Comensal.EmpleadoId` → `rrhh.Empleado`:** el enlace es opcional y único [V datos:388,404]. Suprimir un `rrhh.Empleado` no debe suprimir su comensal ni al revés, porque son padrones de responsables distintos (el empleado es del cliente de GPOS; el comensal puede ser de la empresa cliente del restaurante). Si ambos pertenecen a la misma empresa, el aviso de TT debe listar «este titular también aparece como comensal» (y viceversa) y ofrecer rectificar los dos en una sola acción con dos eventos de bitácora. [I].
- **Datos derivados en tablas de consumo:** `com.UsoBeneficio`, `com.Consumo`, `com.Saldo*` guardan `ComensalId`, no el nombre [V datos:290-292 por la lista de índices]: no necesitan anonimización. Las impresiones «Relación de consumos por empleado» (CO-01) y las vistas `rptc.Corp*` sí muestran nombres [V datos:304-310]: lo que se emitió a la empresa no se toca (como TT-04 con los comprobantes).
- **Historial:** `com.Comensal` no es temporal en el diseño de A (`ModificadoPor/ModificadoEn` y `rowversion`, :395-398) [V], así que el verbo de `GPOS.Migracion` de F-5 no hace falta para los comensales. La API anonimiza directamente.
- **Bitácoras y respaldos:** igual que los demás (P-1).
- **Dato nuevo para la hoja:** el carné (`com.Carne`) es un seudónimo del comensal. Al suprimir debe quedar **bloqueado (`Estado = 'B'`) con `MotivoEstado`** («solicitud del titular») [V datos:419-432]; no se borra porque el índice único impide reutilizar el identificador y se perdería la trazabilidad.
- **Cómo entra en TT:** no entra en la v1 de TT (que construye B en L1b desde 2026-11-16 para los tres maestros). Queda en el JSON con `"estado": "pendiente-entrega-3"`, y la prueba de arquitectura de TT-P6 se amplía cuando el esquema `com` exista. Además, ADR-88 ya prevé su propio ADMIN-RRHH (aviso informativo y derecho de acceso): TT no debe duplicar el derecho de acceso.

---

## 5. Qué debe confirmar quién

| # | Asunto | Quién |
|---|---|---|
| 1 | Si una persona física comerciante con RNC de 9 dígitos antiguo está protegida (L-03) y si existen en la práctica | Abogado y contador |
| 2 | Lista final de campos anonimizables (`NombreComercial`, `Contacto`, `PaginaWeb`, `Nota`) frente a la conservación fiscal (L-04) | Abogado con contador |
| 3 | Qué documentos cuentan como «comprobante que lo usa»; si una cotización o pedido de un titular suprimido puede quedar con su nombre | Contador y abogado |
| 4 | Redacción de la excepción de notas y cobros en TT-03 | Abogado; contador sobre Q-TT5-a |
| 5 | Tratamiento del B11 (suplidor informal) y B13 (gasto menor) con persona física | Contador |
| 6 | Obligación laboral de conservar datos del empleado y por cuánto tiempo | Abogado |
| 7 | Que el restaurante (modelo B) sea encargado y no responsable del padrón de comensales | Abogado |
| 8 | Umbral RD$250.000 de identificación del comprador de consumo | Contador |
| 9 | Frecuencia real de empresas con `N` o `P` | Se mide con una consulta en la primera instalación (no se puede decidir hoy) |
| 10 | Cuándo se elimina `PuenteMae` frente a TT (hallazgo 3) | Arquitecto-software de B |
| 11 | Si un cliente `Inhabilitado` puede recibir recibos y notas hoy | Desarrollador-backend de B (verificar en código) |

## 6. Decisiones candidatas a ADR / precisiones
1. Precisión de TT-03: el bloqueo permite los documentos que modifican, cobran o pagan comprobantes o saldos anteriores del mismo tercero (sección 3.2).
2. Precisión de TT-02: reglas de `Identificacion` (sección 1.4) y exclusión de `GENERICO` (hallazgo 2).
3. Precisión de TT-P3: el espejo heredado (`PuenteMae`) entra en el alcance mientras exista (hallazgo 3).
4. Cuarta entrada `comensales` del JSON, pendiente de la entrega 3 (sección 4.3).

## 7. Riesgos operativos
| Riesgo | Sev. | Mitigación |
|---|---|---|
| Suprimir `GENERICO` o un cliente sembrado deja el POS sin cliente de contado | Alta | Exclusión explícita por código en la ruta y en la prueba de arquitectura |
| Datos suprimidos que sobreviven en el espejo heredado (`PuenteMae`) | Alta | Escribir la copia heredada en la misma transacción o aplazar TT hasta eliminar el puente |
| Rectificar convierte un registro en jurídico y lo saca de TT | Media | Regla 1.4(2) |
| Bloquear a un cliente con deuda y no poder cobrarle | Alta | Recibos y notas permitidos sobre registros bloqueados (3.2); verificar en código |
| Aviso de «parece empresa» inexacto | Baja | Es un aviso; la confirmación tecleada protege |
| Foto/consentimiento del comensal cae en dos regímenes | Media | La foto sigue el régimen de ADR-88; TT no la toca |

## 8. Preguntas abiertas para el negocio
1. Cotizaciones y pedidos de un titular suprimido: ¿se conservan tal cual (recomendado v1) o se anonimizan?
2. ¿Quiere el aviso «parece una empresa» o prefiere esperar al maestro de P-3?
3. ¿El ADMIN puede rectificar el documento de identidad de un cliente con facturas emitidas (con la advertencia de 1.4(4)), o prefiere que solo lo haga el SUPER?
4. Para empleados con cuenta de acceso: ¿suprimir al empleado debe obligar a inhabilitar su cuenta, o es una acción aparte?

### Cierre
- Estado: Completado
- Artefactos: C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\a8083c99-fe36-432e-bde4-46ec95e0ccbd\scratchpad\respuesta-especialista-pos-tt.md
- Supuestos: lo marcado [I] arriba (sobre todo: la cédula como RNC de personas físicas en la DGII, el tratamiento del B11/B13, el umbral de RD$250.000 y la frecuencia de `N`/`P`); `com.Comensal` es solo diseño, no código
- Decisiones candidatas a ADR: las 4 de la sección 6
- Entregas a otros agentes: arquitecto-software/desarrollador-backend de B → hallazgos 2 y 3, y verificación de cobros sobre cliente inhabilitado; disenador-ux-ui → aviso «parece empresa» y mensaje del POS para cliente bloqueado; abogado y contador (vía el propietario) → sección 5
- Próximo paso recomendado: que B firme `CamposPersonalesTitular.json` (sección 1.7) con las observaciones 1.4 y verifique el espejo heredado antes de construir TT.
