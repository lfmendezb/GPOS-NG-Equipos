Para: B (conocimiento de C)
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-p7-candado (cd456f4c, PR 24); a/h2-ncf-historico (37694341)
Estado: Abierto

# A retoma: corredor de pruebas desbloqueado y SEC-H11-01 subida al PR 24

## 1. Causa y arreglo del bloqueo de pruebas del 11-oct

El bloqueo no estaba en SQL Server ni en el login `gsf`.
- El login `gsf` está habilitado y existe desde el 11-oct 13:10. Las pruebas no lo usan: entran con autenticación de Windows.
- La causa es `testhost.exe`, el apphost de VSTest, firmado por Microsoft. En este equipo recibe «acceso denegado» (Win32 5) al abrir su proceso padre y muere antes de ejecutar nada.
- `dotnet testhost.dll`, el mismo host lanzado por `dotnet`, funciona.
- Al acceso denegado de SqlClient (memoria compartida) lo causaba el aislamiento de Codex. Desde la sesión de Claude, .NET conecta bien a `.\SQLEXPRESS`.

**Arreglo local, sin tocar código ni el servidor:** después de cada `dotnet build`, borrar `tests\GPOS.Tests\bin\Debug\net10.0\testhost.exe` y correr `dotnet test --no-build`. VSTest pasa entonces al host `dotnet`.

Comprobado: NcfHistoricoTests 17/17 aprobadas contra SQL Express. Si B o C ven el mismo error, sirve igual.

## 2. PR 24: commit cd456f4c (subido)

- **SEC-H11-01** (informe `docs/seguridad/2026-10-11-h11-vigilancia-respaldos.md`): la cola de respaldos posteriores pasa a `TrabajoRespaldosPosteriores`, y la vigilancia del candado ya no espera un BACKUP demorado. Era trabajo de Codex del 11-oct que había quedado sin confirmar; se revisó y se confirmó.
- **Dos guardas que fallaban en el PR 24:**
  - `ArquitecturaModulosTests`: el módulo `Sistema` no tenía nivel. Viene del commit 26ae8fce; queda en nivel 1, junto a `Sitio`.
  - `PruebasNeutralesTests`: faltaba el rasgo `Esquema` en `CandadoNoDisponibleTests` y en la guarda nueva.
- **Verificación:** compilación con 0 errores; `GPOS.Tests.Arquitectura` más `CandadoNoDisponible`, 121/121.

Siguen pendientes la suite completa del PR 24 y PDS-06. No se une.

## 3. En curso

- **H-2:** la suite completa de GPOS.Tests corre en `a/h2-ncf-historico`; al terminar, PR y aviso.
- **Segundo PR de H-11 (PR-2b):** núcleo del candado de `GPOS_SYSDATA` sin el factor y recomposición P-81A-12, según PC-1 (a). Se construye en `a/h11-sysdata-candado`, que sale de cd456f4c.
- **Después:** H-6 de aplicación y T3-12/RG-14.
