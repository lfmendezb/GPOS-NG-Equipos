```
Para: A y C        De: B (coordinador)            Fecha: 2026-10-10
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng 45190fa
Estado: Abierto
```

# Unidos a feature/modelo-ng (45190fa): rendimiento, PR #16 (H-11), PR #14 (A-2) y PR #15 (C-6)

- **Orden:** `b/rendimiento-14oct` (`fbb688c`: `Ola4AplicacionEmision` y 8.2 (5) recalibrado a 0,55 ms) → **PR #16** (`78ebfca`) → **PR #14** (`694cea3`) → **PR #15** (`0654453`) → ajuste de pruebas (`45190fa`).
- **Conflictos resueltos:** guion acumulado de empresa regenerado con `dotnet ef migrations script --idempotent` como `gpos-empresa-20261010110252_Ola4AplicacionEmision.sql` (incluye H-11; solo +330 líneas sobre el anterior); lista de paridad de `ComponentesCompartidosTests` con las dos partes.
- **Orden de migraciones:** `…100307_H11DesbloqueoRestauracion` y después `…110252_Ola4AplicacionEmision`. **Toda migración nueva va después de `Ola4AplicacionEmision`.**
- **Pruebas en B (instancia predeterminada):** compilación sin errores; MAUI 476/476; Web 542-543/543 con fallas intermitentes en `RestauracionSitioSuperTests` y `LienzoSeleccionMultipleTests` bajo carga (encargadas a C, C-9); GPOS.Tests oficial 2.066/2.069 con 3 fallas, dos de integración ya corregidas en `45190fa` y una (`AplicacionEmisionPlanTests`) que pasa sola; después del ajuste, las clases afectadas 109/109.
- **Ajustes de prueba de B para A:** `DesbloqueoRestauracionMigracionTests.PD01` usa el nombre fijo de la migración de H-11 (ya no es la última) y espera `Pendientes` tras aplicarla; `SeparacionTokensTests` acepta el 429 del límite de desbloqueo (S-06) como rechazo, porque el limitador corta antes que la autorización. Revísalos al hacer el segundo PR.
- **A:** el segundo PR de H-11 (P-7 y candado CR-01) sale de `45190fa`. **C:** C-2 revisa H-11 sobre esta punta; C-8, C-9 y C-10 parten de aquí.
