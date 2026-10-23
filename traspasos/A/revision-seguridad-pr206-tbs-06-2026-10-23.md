# Informe de seguridad: PR #206 (TBS-06, avisos del tablero por sucursal)

- Fecha: 2026-10-23 · Revisor: A (auditor de seguridad, solo lectura)
- PR: lfmendezb/GPOS-NG #206, rama `b/tbs-06-avisos` (HEAD 314324ee), base `feature/modelo-ng`
- Contexto: ADR-93, TA-P08, S168-02, S168-05, Q-A5, TBS-01..06 (hoja D-03)

## 1. Alcance y superficie revisada

- Ruta autenticada `GET /api/reportes/dashboard/avisos` (`src/GPOS.Api/Endpoints/ReportesEndpoints.cs:23` grupo con `RequireAuthorization()`; `:89` mapeo).
- Diff (4 archivos): `ConsultasCierreSucursal.cs` (consulta `CerradasConExistencias`), `AvisosTableroService.cs`, pruebas `AvisosTableroRestringidoTests.cs` e `InyeccionAlcanceTests.cs`.
- Dependencias leídas (no cambian en el PR): `AlcanceAlmacenes.cs`, `UsuarioAlcance.cs`, `EstadoCuentaSesion.cs`, `RevocacionSesiones.cs:140`, `Program.cs:173-174,247`, `GPOS.Core.csproj:49-51`.
- No ejecuté compilación ni pruebas (C6): las conclusiones sobre las pruebas salen del análisis estático de mutaciones.

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| R206-01 | Baja | La guarda `resuelto.Vacio` y el predicado SQL se respaldan entre sí y las pruebas no aíslan cada capa |
| R206-02 | Baja | Ninguna prueba de la ruta HTTP con la cadena real `EstadoCuentaRevocacion` y la inyección de dependencias |
| R206-03 | Baja (aceptada) | Un cambio de la bandera o de la sucursal tarda hasta 15 s en aplicarse (vigencia CS-3 de `RevocacionSesiones`) |

No hay hallazgos Críticos, Altos ni Medios.

## 3. Checklist OWASP

| Punto | Resultado |
|---|---|
| A01 Control de acceso | Correcto. El alcance se aplica en el servidor y la falla es cerrada (sección 5) |
| A02 Criptografía | No aplica |
| A03 Inyección | Correcto. `@global` y `@sucursalAlcance` van tipados con `DbType` (`AlcanceAlmacenes.cs:50-51`); el código de sucursal se pasa como `Sql.Varchar(..., 20)` (`:115`); no se concatena texto en el SQL |
| A04 Diseño inseguro | Correcto. `AlcanceResuelto` por omisión es vacío (`AlcanceAlmacenes.cs:24-42`) |
| A05 Configuración | No aplica (no cambia la configuración) |
| A06 Componentes vulnerables | No aplica (no hay paquetes nuevos) |
| A07 Autenticación | No cambia; la ruta sigue exigiendo autenticación (`ReportesEndpoints.cs:23`) |
| A08 Integridad | No aplica |
| A09 Registro y monitoreo | No aplica. La lista vacía del restringido no se registra, igual que en existencias y kárdex |
| A10 SSRF | No aplica |

## 4. Hallazgos

### R206-01 (Baja): las dos capas de la falla cerrada no se prueban por separado
- **Riesgo:** si alguien elimina `if (resuelto.Vacio) return [];` (`AvisosTableroService.cs:30`), ninguna prueba falla. El SQL devuelve cero filas porque `s.Id = NULL` nunca se cumple (`ConsultasCierreSucursal.cs`, predicado `AND (@global = 1 OR s.Id = @sucursalAlcance)`). Al revés, si se cambia el predicado por algo como `@sucursalAlcance IS NULL OR ...`, la guarda en C# lo tapa. Hoy no hay fuga, pero una regresión en una de las capas pasaría desapercibida hasta que fallara también la otra.
- **Evidencia:** `tests/GPOS.Tests/Alcance/AvisosTableroRestringidoTests.cs:182-190` solo comprueba el resultado final.
- **Remediación mínima:** agregar una prueba de la consulta registrada con `@global = 0` y `@sucursalAlcance = NULL` que exija cero filas. Lo ideal es dejarla en la guarda general de consultas con el patrón de falla cerrada, si ya existe para existencias y kárdex. Esfuerzo: menos de 0,5 h.

### R206-02 (Baja): no se prueba la cadena real de la API
- **Riesgo:** las pruebas inyectan `CuentaFija` (`AvisosTableroRestringidoTests.cs:52-55,62-66`), no `EstadoCuentaRevocacion`. Lo que protege la composición es otra cosa: el único constructor público exige `IAlcanceAlmacenes` (`InyeccionAlcanceTests.cs:20`) y `IAlcanceAlmacenes` está registrado por petición (`Program.cs:173-174`). Una prueba de integración HTTP con un usuario restringido cerraría el hueco por completo.
- **Remediación mínima:** opcional. Agregar un caso a la prueba de integración de la API que ya cubra a un restringido, si existe una que lo haga. Esfuerzo: menos de 1 h.

### R206-03 (Baja, riesgo aceptado): hasta 15 s de desfase
- **Riesgo:** `EstadoCuentaRevocacion.LeerAsync` reutiliza la lectura guardada por `RevocacionSesiones` (`EstadoCuentaSesion.cs:13-14`, `RevocacionSesiones.cs:140`). Si se activa la restricción o se cambia la sucursal, los avisos pueden seguir con el alcance anterior hasta 15 s. Es la vigencia firmada CS-3, la misma que usan existencias y kárdex. No requiere acción; se anota para dejar rastro.

## 5. Controles bien implementados (verificado)

1. **De dónde sale el alcance.** Sale de la cuenta guardada en `GPOS_SYSDATA` (`IEstadoCuentaSesion`), no de los claims del token. `Restringida` se calcula con `UsuarioAlcance.Restringe(Nivel, RestringirSucursal)` (`UsuariosService.cs:1095`, `UsuarioAlcance.cs:15`). Del token solo se usa `sesion.EmpresaCodigo`, y únicamente para exigir que coincida con la empresa asignada (S168-05, `AlcanceAlmacenes.cs:110`).
2. **Falla cerrada.** El alcance queda vacío en todos estos casos: sin cuenta o cuenta inhabilitada (`AlcanceAlmacenes.cs:106`); empresa distinta o sin asignar (`:110`; `UsuarioAlcance.MismaSucursal` exige los cuatro valores, `UsuarioAlcance.cs:22-26`); sucursal en blanco o inexistente (`:113-118`); sin usuario (`:98`). Con alcance vacío, el servicio devuelve `[]` antes de consultar (`AvisosTableroService.cs:30`).
3. **SQL.** El predicado está en la única rama de la consulta. Los joins `Almacen.SucursalId = s.Id` e `Existencia.AlmacenId = a.Id` no pueden traer filas de otra sucursal: cada almacén pertenece a una sola sucursal y el filtro va sobre `s.Id`. La existencia en tránsito solo cuenta si está en un almacén de la sucursal filtrada. El aviso muestra código, nombre y cantidad de artículos de esa misma sucursal; el enlace `inventario/Ajuste` es fijo. No hay conteos agregados de otras sucursales.
4. **Caché.** El servicio de avisos no guarda resultados. `AlcanceAlmacenes` memoriza la cuenta y la sucursal por petición, porque está registrado por petición (`Program.cs:174`), igual que el servicio (`:247`). La caché de `RevocacionSesiones` va por usuario y guarda el estado de la cuenta, que es global en `GPOS_SYSDATA`. La empresa se vuelve a comparar en cada petición, así que no se mezclan alcances entre usuarios ni entre empresas.
5. **SUPER y ADMIN sin restricción.** `Restringe` excluye al SUPER aunque tenga la bandera (Q-A5). Sin la bandera, el alcance es global (`AlcanceAlmacenes.cs:107`), y el ADMIN con la bandera sí queda restringido (D-3). Las pruebas cubren las tres situaciones (`AvisosTableroRestringidoTests.cs:154-155,166-175`).
6. **El constructor `internal` no se puede usar desde la API.** `GPOS.Core` solo expone sus internos a `GPOS.Tests` y `GPOS.Migracion` (`GPOS.Core.csproj:49,51`). El contenedor de dependencias de ASP.NET Core solo considera constructores públicos, y la prueba `InyeccionAlcanceTests` comprueba que el único público exige `IAlcanceAlmacenes`. Hoy el constructor sin alcance solo lo usa `CierreSucursalExistenciasTests.cs:28,36`. `GPOS.Migracion` no lo usa.
7. **Análisis de mutaciones de las pruebas nuevas.** Si se quita el predicado SQL, falla `Assert.Single` (`:149`) y la prueba de la sucursal abierta (`:162`). Si se elimina la exención del SUPER o del ADMIN sin bandera, falla `:169-174`. Si se quita la comparación de empresa (S168-05), falla `:187`. Si se quita la regla de cuenta inhabilitada o inexistente, fallan `:188-189`. Solo sobreviven las mutaciones de R206-01.

## 6. Remediaciones priorizadas

1. R206-01: prueba de la consulta con `@global = 0` y `@sucursalAlcance` nulo (menos de 0,5 h). No bloquea.
2. R206-02: caso de integración HTTP con un restringido (opcional, menos de 1 h).
3. R206-03: sin acción (CS-3 firmada).

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario, C2). Ninguno de los hallazgos bloquea la unión.
