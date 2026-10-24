```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 3 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`) y hallazgo para el propietario
Prioridad: Alta (C-T01 conviene decidirlo antes de habilitar cuentas restringidas con permisos de ventas)
Repositorio y rama: GPOS-NG `feature/modelo-ng` (#202, #205, #206, #212 unidos; #220 abierto); sin cambios
Estado: Abierto
```

# Revisión adversarial de punta a punta de la cadena del tablero: Aprobado con observaciones

Informe: `traspasos/C/2026-10-24-revision-adversarial-cadena-tablero.md` y las pruebas en `...cadena-tablero.cs.txt`. Recomendación técnica; la decisión es del propietario. **Dentro de la cadena no encontré fugas entre sucursales**: aplica D-03 y TBS-01 a TBS-06 tal como se firmaron. La observación de fondo está un clic más allá: los enlaces del tablero llevan a una pantalla que no aplica la restricción. Sin Críticos ni Altos. Desde la seguridad, el #220 se puede unir después del #212 (no lo compilé ni corrí aquí; cito las cifras de A).

| ID | Sev. | Qué pasa | Prueba |
|---|---|---|---|
| **C-T01** | **Media** | Las tarjetas «Cuentas por cobrar» y «Ventas» (`Tablero.razor:218-220`) enlazan con la consulta de facturas, que no aplica la restricción de sucursal. | CT01, verde |
| C-T02 | Baja | El gráfico `DASH-CXC-ANTIGUEDAD` del propio tablero está en la lista P-2: aun con el reenvío lo ejecuta la principal, sin alcance (`ReportesEndpoints.cs:40-47`, `ReportesService.cs:276-285` y `:318`). Hoy no hay fuga, pero el gráfico sale vacío para todos: en una base del modelo nuevo `dbo.vw_GPost_DocumentosCxC` existe pero viene vacía (R-14 ya conocido; lo cierra T4-06, #225). | CT02, caracterización |
| C-T03 | Baja | La prueba de ruta de TBS-04 cubre 3 de las 7 rutas de datos de la API de reportes; las 7 sí pasan por `ProveedorContexto`. | CT04, guarda de fuente |
| C-T04 | Informativa | La hoja D-03 dice que el 403 alcanza «todas las rutas»; las 4 rutas `/interno/render/*` no pasan por el contexto. No es fuga: solo existen por el canal interno y reciben los datos ya armados por la principal. | Lectura y CT04 |

**C-T01, detalle.** El restringido a S2 ve 236 en la tarjeta, pero la consulta le devuelve también la factura de otra sucursal («FC00000002 saldo 236, FC00000001 saldo 118; suma 354»); también le entrega el detalle de la factura ajena por su número (IDOR), la búsqueda por número y la exportación. Causa: `ConsultaFacturasService` no recibe el alcance (`ConsultaFacturasService.cs:16`; el único recorte, en `:91`, es para el cajero de solo POS). No lo encontré en R-01 a R-14 ni en las revisiones previas. **Sube a Alta si el propietario confirma que la frontera de la sucursal cubre toda lectura de ventas.**

**Hipótesis descartadas con evidencia:** envenenamiento de la caché (CT03 lanzó contra la base 60 peticiones en paralelo e intercaladas —ADMIN global, restringido a S2 y restringido a la otra sucursal— con una sola `CacheTablero` y un solo `ResolutorCatalogos`: cada una recibió exactamente la cifra de su alcance); IDOR por parámetros en el tablero (la ruta no admite sucursal); sucursal tomada del token (manda la de `rptsis`); SUPER y ADMIN (solo el SUPER queda exento; el ADMIN con la bandera queda restringido); TBS-04 (compara sin distinguir mayúsculas ni espacios y falla cerrada si falta un valor); avisos (filtran por sucursal, sin otros nombres ni conteos); interfaz (no hay caché de indicadores en el cliente y `Tablero.razor` es idéntico en Web y MAUI).

**Ejecutado** (SQL Server local, una compilación a la vez): `GPOS.Tests` (mis 4 pruebas más las existentes del tablero, avisos y alcance) 19/19; `GPOS.Reportes.Tests` (tablero, contexto y rutas) 53/53; `GPOS.Web.Tests` (filtro «Tablero») 28/28. Pasaron por dos rojos de preparación antes del verde (en CT02 no existe `GPOS_SYSDATA` en la base de prueba; en CT03 chocaba el turno por usuario), ya corregidos en el anexo.

**Remediación, priorizada:** (1) el propietario decide C-T01 antes de habilitar cuentas restringidas con permisos de ventas: (a) aplicar la restricción ya en la principal o (b) aceptar el riesgo hasta T4-08 (enero); **recomiendo (a)**. (2) Con (a): pasar el alcance a `ConsultaFacturasService` (lista, detalle, búsqueda por número y exportación) con falla cerrada, ~0,5 dp, USD 150 a 200 [estimación]; descarté quitar solo el enlace porque la consulta seguiría abierta desde el menú. (3) Comprobar C-T02 en la revisión del #225. (4) Completar la prueba de TBS-04 o adoptar la guarda CT04 (~0,25 dp). (5) Precisar en la hoja D-03 «todas las rutas de datos» en el barrido de ADR-91. Candidata a ADR: precisión de ADR-93 o ADR-109 sobre si la restricción de sucursal rige en la consulta de facturas del restringido.

**Supuestos:** la columna de sucursal que debe filtrar la consulta de facturas es la que alimenta `rpt.VentaDocumento.SucursalId` (el nombre exacto en `ng.Documentos` está sin confirmar); las cifras de esfuerzo usan el valor del plan del tramo 4.

**Reparto:** B → llevar C-T01 al propietario y asignar C-T01 y C-T03; A → la frase de C-T04 y que T4-08 herede el escenario de CT01 como prueba de partición; C → comprobar C-T02 en la revisión del #225.

Respuesta requerida: decisión del propietario sobre C-T01 (a o b).
