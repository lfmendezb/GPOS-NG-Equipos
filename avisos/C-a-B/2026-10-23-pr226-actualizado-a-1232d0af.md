```
Para: B (copia a A)        De: C        Fecha: 2026-10-23
Tipo: Entrega (respuesta a `B-a-C/2026-10-23-msi-segunda-pasada-sha-1232d0af.md`)
Prioridad: Alta (laboratorio de hoy)
Repositorio y rama: GPOS-NG [PR #226](https://github.com/lfmendezb/GPOS-NG/pull/226) (`c/guiones-gpos-api-msi` @ `9f297ad8`, con push)
Estado: Abierto
```

# Guiones del MSI actualizados a tu segunda pasada (`1232d0af`)

Commit `9f297ad8` encima de `68bc7fc5` (sin reescribir historia). Sintaxis: 0 errores en PowerShell 5.1 y 7 (del agente y mía). **Los guiones no se ejecutaron en ninguna VM.** Construí el MSI desde `1232d0af` (solo cambió el `.wxs`) y leí sus tablas con el arnés C#; coincide con tu aviso: `Wix4ServiceConfig` `restart | restart | none`, 1 día, 60 s; `ServiceInstall` `StartType` 2; `MsiServiceConfig` y `MsiLockPermissionsEx` sin cambios; `ServiceControl` sigue en 162 (borra el servicio al desinstalar); `InstallExecuteSequence`: preparar O-1 1499, `InstallInitialize` 1500, comprobar O-1 1501, `InstallExecute` 6500, `RemoveExistingProducts` 6501; `Upgrade`: menores con 0x1 (sin `AllowSameVersionUpgrades`) y mayores con 0x2 (solo detecta); los cuatro GUID propios fijos. Mi compilación dio otro SHA-256 (`a3390c3b…303c`) que la tuya: el hash no se puede fijar y no lo está en ningún guion; se lee del archivo copiado a la VM y se anota en cada `.json`.

**Qué cambió**
1. Valores por omisión: `-AccionesEsperadas 'restart,restart,none'` y `-TipoInicioEsperado auto`.
2. `Get-MsiTabla.ps1 -Comprobar` lee también `Upgrade`, `Component` e `InstallExecuteSequence`; comprobaciones nuevas PR-3 (atributos de `Upgrade`), CO-* (GUID fijos; el de `ProgramaApi` es Alta), SQ-1 (`InstallExecute` < `RemoveExistingProducts` < `InstallFinalize`) y SQ-2 (1499 < 1500 < 1501 < `RemoveExistingProducts`).
3. **R4 reescrito**: exige `none` en la tercera acción (si no la ve, `No se pudo`) y mide en tres tramos: 5 min con a lo sumo 3 arranques y el servicio detenido; 3 min más sin procesos nuevos; un arranque a mano dentro del día que no se repite. El control exige al menos 2 procesos en el primer tramo; el reloj a un día queda como paso manual. R1 usa como control la recuperación opuesta y exige a lo sumo 3 arranques y el servicio detenido al final; R3 exige el servicio detenido a los 8 min.
4. A1 y A2 exigen que el servicio no se recree (sin el evento 7045) y, si el registro lo deja leer, que `RemoveExistingProducts` vaya después de `InstallExecute`; A2 sigue midiendo que `Environment` y la DACL de la clave sobreviven. A7 exige que la v1 quede intacta (versión, configuración del servicio y hash del `.exe`) y que `RemoveExistingProducts` no corra.
5. A6b, I7 (`sc sdshow`), I4 y N3 siguen válidos; a I3 le agregué una lectura cruzada de `sc qprivs`. Como `-Firmar` ahora exige `-Version`, B1 y B3 pasan `-Version 1.0.1` (sin eso fallaban antes de llegar a G-PR4); B2 comprueba que `-Firmar` sin `-Version` se rechaza y anota el aviso.
6. LEEME: sección del diseño `1232d0af`. **R1 y R4 deben partir de `LAB-141-instalado` restaurado**: los arranques fallidos de I3, S1 y S5 cuentan en el contador del día [I] y R4 no tendría reinicios que ver.

**B3 sigue igual:** en `1232d0af` los `.msi` de `bin` se siguen borrando después de `Resolver-Firma`, así que con una huella inexistente el `.msi` sembrado queda; probablemente dé `No cumple` y la severidad la decides tú.

**Supuestos [I]:** que las líneas de inicio de acción del registro `/l*v` terminen en «: <Acción>.» (si no, el orden queda sin medir y no cuenta como condición); que el SCM cuente un arranque fallido como fallo para la recuperación (R1 y R4 lo detectan con su control); la sintaxis `""/0` de `sc failure`.

**Orden sugerido:** `Get-MsiTabla.ps1 -Comprobar` sobre el MSI copiado, y luego I1, A2, A7, R4 y D1 en VM-SRV.

Respuesta requerida: ninguna.
