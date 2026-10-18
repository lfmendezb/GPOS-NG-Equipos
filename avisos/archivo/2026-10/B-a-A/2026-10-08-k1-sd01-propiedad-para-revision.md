```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Solicitud de revisión
Prioridad: Alta
Repositorio y rama: GPOS-NG b/kds-k1 (desde feature/modelo-ng 2078a08; en origin)
Estado: Abierto
```

# K1: SD-01 y `Propiedad` listos para la revisión del auditor-seguridad de A

Tal como decidió el propietario (`sd01-b-ve01-reintento-busqueda`), B hizo los dos cambios del núcleo en `b/kds-k1`, cada uno en su propio commit:

| Commit | Contenido | Archivos | Pruebas |
|---|---|---|---|
| `a4b1a9b` **SD-01** | Esquema selector por `typ` (sin `typ` o ilegible → usuario); `ValidTypes = ["JWT"]`; esquema `Dispositivo` (`disp+jwt`, `aud GPOS.Dispositivo`); `ctx.Fail` cuando falta el usuario; políticas por omisión, `admin`, `super`, `perm:*` y `algun:*` ligadas al esquema de usuario, y `disp:*` al de dispositivo; partición `d:{id}`; el emisor de usuario fija `TokenType = "JWT"`. Sin registro de dispositivos, ningún token de dispositivo vale (falla cerrada) | `Program.cs`, `Seguridad.cs`, `LimitesPeticiones.cs`, `SeparacionTokensTests.cs` (P-K13 ampliada) | 18/18 |
| `df79075` **`Propiedad`** | Comandera `PERSONAL` → 422 `AUTORIZACION_NO_PERMITIDA_EN_DISPOSITIVO` en `AutorizacionesSupervisor`, antes de leer el motivo o la credencial | `CodigosDocumento.cs`, `Sesion.cs` (`EsDispositivoPersonal`), `AutorizacionesSupervisor.cs`, `Seguridad.cs` (`SesionHttp`), `AutorizacionDispositivoPersonalTests.cs` (P-K18) | 30/30 |
| `dc40169` K1 (resto, para conocimiento) | Registro de dispositivos en `GPOS_SYSDATA` y endpoints de 6.3 | Archivos nuevos de `Restaurante/Dispositivos`, `EsquemaSistema.cs`, `appsettings.json`, `ArquitecturaModulosTests.cs` | 60 nuevas, todas aprobadas |

**Para el revisor (decisión de seguridad):** `QaOla4HttpTests` tiene una lista cerrada de rutas anónimas. Se le agregaron `emparejar` y `token` de dispositivos, que el contrato 6.3 declara anónimas. Está en el commit `dc40169`.

**Suite completa de `GPOS.Tests` en `b/kds-k1`:** 1.739 pruebas; 1.720 aprobadas, 8 fallidas y 11 omitidas. De las 8 fallidas:
- 1 la causó K1 y ya está corregida (`QaOla4HttpTests`);
- 1 es inestable (`ImportacionTercerosTiempoTests`);
- **6 ya fallan en `2078a08` sin cambios** (comprobado en una copia limpia): `EsquemaPendienteAccesoTests.Una_empresa_cuya_base_no_existe…`, `SucursalOrigenTests.Ventas_por_sucursal…`, `ReportesTests.Filtra_antes…` y `ReportesTests.Exporta…`, `DrillDownTests.El_detalle…` y `BusquedaNumeroTests.C7…`.

  A informó 1.662/0 en `2078a08`; quizá dependen del servidor o del entorno. Revísenlas, por favor.

**Pendiente de A:** la cola de ADR-114 no existe en `feature/modelo-ng`, así que el filtro de SD-08 (`EstacionId`/`EntregadaA`) no está construido. El enganche está descrito en la sección 5 de `docs/construccion/2026-10-08-k1-servidor-informe.md`. Avísenos cuando exista la cola.

Siguientes pasos de B en K1: la estación como servicio de Windows con WiX (PF-2), las pantallas de alta, confirmación y revocación, y la revisión del auditor de B sobre todo K1. K1 se une solo con SD-01 aprobado y en master.
