# Serie E en `TiposComprobante.DeCliente` (verificación previa al 15-nov-2026)

**Equipo C, 2026-10-17.** Se revisó el código de `b/prep-27oct` @ `c01df683`, que contiene `feature/modelo-ng`. Solo se leyó código; no se cambió nada. Origen: el pendiente B-05 de `docs/propuestas/2026-10-11-valores-de-terceros-configurables.md` («`DeCliente` solo devuelve códigos de la serie B; no verifiqué cómo se elige la serie E»).

## 0. Resumen
**Hallazgo, severidad Alta (fecha dura: emisión exclusiva de e-CF desde el 15-nov-2026, aviso 06-26 de la DGII).**
- En una empresa con e-CF, **las facturas sin un tipo elegido a mano siguen tomando el tipo de la serie B** (01, 02, 14, 15 o 16).
- Si la empresa solo tiene secuencias E, la venta **se rechaza** por «sin secuencia».
- Si todavía tiene un bloque B vigente, **emite un B02 o un B01 fuera de contingencia**, lo que la DGII no admite desde el 15-nov.
- El diseño ya define la equivalencia (`docs/integraciones/2026-10-07-ecf-enchufable.md:291`, contingencia en ADR-51), pero en el código solo las notas de crédito y de débito cambian a E34 y E33 con el e-CF activo. Las facturas no.

## 1. Evidencia
| Lugar | Qué hace |
|---|---|
| `src/GPOS.Contracts/Fiscal/TiposComprobante.cs:57-64` | `DeCliente`: A → 02, B → 01, C → 15, D → 14, E → 16. No hay variante electrónica |
| `src/GPOS.Core/Servicios/PosService.cs:456` | Venta POS: si el cajero no elige un tipo, toma `DeCliente(...)` |
| `src/GPOS.Core/Servicios/PosService.cs:75` | El estado del NCF de la caja también usa `DeCliente` |
| `src/GPOS.Core/Servicios/DocumentosComercialesService.Ventas.cs:293` | **Factura CxC: siempre** `DeCliente(...)`, sin opción de elegir el tipo |
| `src/GPOS.Core/Infraestructura/EstadoNcf.cs:40-42` | Los avisos del POS revisan siempre `Consumo` (02) y `NotaCredito` (04). Con solo secuencias E, la caja muestra un aviso **grave** de «sin secuencia» para B02 y B04, aunque E32 y E34 estén vigentes |
| `src/GPOS.Core/Servicios/Modulos/Fiscal/EmisionNcfNg.cs:247-248` | `ModoTipoNota`: con `ConsultasFiscal.EcfActivo` (bloques E vigentes y sin contingencia), las notas pasan a 34 y 33. **Es el único lugar que consulta el modo e-CF** |
| `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesCfg.cs:36-58` | El catálogo `fiscal.TipoComprobante` ya trae 31 a 34, 41, 43 y 44 a 47 con `Electronico = 1` |
| `src/GPOS.Contracts/Admin/Admin.cs:171` | `PrefijoPara`: E o B más el código del tipo. Con el tipo 02, la serie electrónica daría «E02», que no existe: la equivalencia tiene que ser de **código** (02 → 32), no solo de prefijo |

## 2. Consecuencia por caso (con el código actual)
| Situación de la empresa después del 15-nov | Factura POS al cliente genérico | Factura CxC |
|---|---|---|
| Solo secuencias E (lo normal) | **Rechazada**: «sin secuencia» de 02. Solo pasa si el cajero elige E32 a mano | **Rechazada**: no hay forma de elegir el tipo |
| Secuencias E más un bloque B vigente (para la contingencia) | **Emite B02 fuera de contingencia** | **Emite B01 o B02 fuera de contingencia** |
| Contingencia habilitada (ADR-51) | B02, correcto | B, correcto |

Además, el aviso grave falso del punto 1 empuja a pedir secuencias B que la empresa ya no debe usar.

## 3. Corrección propuesta (para que B decida; C no la construyó)
1. **Una sola función de equivalencia en `Contracts`** (por ejemplo, `TiposComprobante.Electronico(string tipoB)`): 01 → 31, 02 → 32, 03 → 33, 04 → 34, 14 → 44, 15 → 45 y **16 → 46**. La lista del diseño no trae 16 → 46; la exportación electrónica existe en el catálogo.
2. **`DeCliente(clasificación, ecfActivo)`**: con el e-CF activo devuelve el tipo electrónico. El modo se lee **una vez por documento**, con la misma consulta `EcfActivo` que ya usan las notas (bloques E vigentes y sin contingencia). Así, la contingencia vuelve sola a la serie B, como manda ADR-51.
3. **Aplicarlo en los tres puntos:** `PosService.cs:456` y `:75`, y `DocumentosComercialesService.Ventas.cs:293`.
4. **`EstadoNcf.Calcular`:** revisar 32 y 34 en lugar de 02 y 04 cuando el e-CF está activo.
5. **Venta POS con un tipo elegido a mano:** con el e-CF activo y sin contingencia, rechazar un tipo B, con un mensaje que no sugiera «No generar comprobante» (regla del propietario del 2026-10-02).
6. **Pruebas:**
   - cliente A a E con solo secuencias E → 32, 31, 45, 44 y 46;
   - con un bloque B vigente y sin contingencia → sigue E;
   - con contingencia → B;
   - Factura CxC igual que el POS;
   - el aviso del POS no marca B02 como grave con solo E.

**Costo estimado:** de 0,5 a 1 día-persona más su revisión. **Orden único de bloqueos:** sin cambio; la lectura del modo es previa y no toma bloqueos.

## 4. Observación menor (Baja)
`TiposComprobante.RequiereRnc` (`TiposComprobante.cs:55`) exige el RNC para 01, 14, 15, 31, 44 y 45. La columna `RequiereRnc` del catálogo sembrado lo marca solo en 01 y 31 (14, 15, 44 y 45 nacen en 0). Hoy manda el código, pero hay dos fuentes que no coinciden. Conviene unificarlas, con el especialista contable para la lista exacta.

## 5. Decisión candidata a ADR
Ninguna nueva: la equivalencia ya está diseñada (ecf-enchufable, punto 291; contingencia de ADR-51). **Precisión que hay que confirmar:** la equivalencia 16 → 46 y el rechazo de un tipo B elegido a mano fuera de contingencia (punto 3.5).

### Cierre
- Estado: Completado (verificación). Corrección: propuesta, no construida.
- Supuesto: «e-CF activo» se define como hoy en `ConsultasFiscal.EcfActivo`, mientras no exista el módulo de ADR-108.
- Siguiente paso recomendado: que B decida si C construye la corrección del punto 3 en una rama `c/` con su PR, antes del 15-nov.
