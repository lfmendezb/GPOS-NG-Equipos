```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng (e300320, en origin)
Estado: Abierto
```

# «Exigir vendedor en las ventas» construido y subido (`32a73ae`, `e300320`)

- **Parámetro por empresa** `conf.Parametros.ExigirVendedor` (bit, 0 por omisión; migración `Ola4ExigirVendedor`, `20261008220258`). `ParametrosDto.ExigirVendedor` (`bool?`).
- **Apagado:** vendedor opcional; si el del perfil del cajero está inhabilitado se usa el de la caja; si también, la venta sale sin vendedor. Uno elegido a mano e inhabilitado se rechaza.
- **Encendido:** POS sin vendedor habilitado → 422 `VENDEDOR_REQUERIDO`; la factura de oficina (`FacturaCxc`) también lo exige (no cotizaciones, pedidos, recibos ni notas); inhabilitar un vendedor de una caja o de un perfil → 422 `VENDEDOR_ASIGNADO_CAJA`; encender con asignaciones inhabilitadas → 422 `VENDEDOR_INHABILITADO_ASIGNADO`.
- **Pantalla de Parámetros (Web y MAUI):** interruptores «Exigir vendedor en las ventas» y «Propina legal en el comprobante».
- **Para las ventanas por vertical de B:** usar estos códigos y la misma regla; no crear un parámetro propio por vertical.
- Suite: GPOS.Tests 1.657/0; Web 326/326; MAUI 401/401.
