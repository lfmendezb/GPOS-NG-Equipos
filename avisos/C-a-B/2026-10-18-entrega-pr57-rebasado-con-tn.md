```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG c/adr81-fase-a @ 36bfc36e (PR #57, base feature/modelo-ng @ af27e5d4)
Estado: Abierto
```

# Entrega: el #57 (fase A de ADR-81) rebasado sobre la punta del #68 e incluye T-n

Responde al orden firmado (`B-a-C/2026-10-17-union-prep27-hecha`, punto 5: «el #57 se rebasa sobre la punta que deje el #68») y a `B-a-C/2026-10-18-unidos-51-45-y-48-en-curso`. Vi en `feature/modelo-ng` que #63, #67 y #68 ya están unidos (`af27e5d4`), aunque el aviso de B aún no estaba publicado. **No unir: lo une B tras su validación y la suite oficial.**

## Qué se hizo
1. **Rebase del #57 sobre `af27e5d4`.** Como la rama tenía 40 commits sobre `ce33b2a8` y 31 archivos compartidos con lo que la punta cambió desde entonces (SL, RN, #68, ola 5, 3b, DL-22), reproducirlos uno a uno daba conflictos en casi cada commit (a la sexta ya había cuatro archivos). Se hizo así:
   - **Un commit con la fase A completa (`67d65982`)**, tomada de la rama T-n, que ya la tenía integrada con SL, RN y el #68 (`c/adr81-tn-sobre-rn` @ `9e0cf8a5`): se aplicó la diferencia `130306c0..9e0cf8a5` con `git apply -3`. Solo entraron los cambios de C; las versiones viejas de SL/RN/#68 que T-n llevaba quedaron fuera porque ya están unidas rebasadas. **Tres conflictos, todos de líneas vecinas, resueltos conservando ambos lados:** `LimitesPeticiones` (política `Escaneos` de la 3b y `FactorOtroSuper`), `RutasLicenciaAprobadas.json` (liberar/desbloquear del #45 y las rutas del segundo factor) y `ComponentesCompartidosTests` (paridad de lotes y del segundo factor).
   - **Los 6 commits de T-n** (puntos 1 a 4, correcciones TN-02 a TN-09, TN-01 y 7(b)/7(d), estas tres firmadas por el propietario el 2026-10-17) aplicados en cherry-pick **sin conflictos**. **El #57 ya incluye T-n**: el título del PR pierde el «(sin T-n)».
   - Comprobación: ningún archivo del resultado difiere de la T-n final (`d6a1edba`) salvo los que la punta cambió desde `130306c0`; el 51618 de RN sigue y no vuelve ningún 51616.
   - **La historia original de 40 commits** queda en la rama `c/adr81-fase-a-historia-4e5bc446` (subida), por si B quiere revisar un commit concreto. `c/adr81-tn-sobre-rn` queda como estaba, ya superada.
2. **Rutinario:** #69 (pantallas SL/RN, estaba sobre el #68), #56 (SC08, sobre el #49) y #62 (propuesta LP, sobre `b/prep-27oct`) reapuntados a `feature/modelo-ng`, porque sus bases ya están unidas. El #58 de A sigue apilado sobre `c/adr81-fase-a` y ahora muestra solo su diferencia.

## Cómo se verificó (OSHIN-LEGION, `.\SQLEXPRESS`, filtro oficial; sin suite completa ni MAUI aquí)
- `dotnet build GPOS-NG.slnx -c Debug`: **0 errores** (toda la solución, MAUI incluida).
- **GPOS.Tests dirigidas** (segundo factor, sellos, cambio de RNC, ciclo de sesión, autenticación reciente, bitácora, licencia y rutas, cierre forzado, separación de tokens, introspección): **726 superadas, 2 fallidas, 3 omitidas** (3 min 13 s). Las 2 son `RecuperacionFactorServicioTests` PF_J2_07 y SEG_TJ2_02, las de concurrencia que C ya informó como intermitentes por el pool (`2026-10-17-tn-revision-y-correcciones`); **la clase sola 23/23**.
- **Web, paridad y mayúsculas** (`ComponentesCompartidosTests`, `MayusculasDeTitulo`): **152/152**.
- La suite oficial, Web completa y MAUI quedan para B (LFMB).

## Para B al unir (sigue vigente lo del PR)
- TN-06, nota de unión: un SUPER sellado con `SinFactorSuper` que ya tenga el factor solo existe en bases de desarrollo.
- La marca del esquema de `GPOS_SYSDATA` de la fase A y la introspección (`SolicitudIntrospeccion.Automatica`) siguen como dice la descripción del PR; hace falta tu visto bueno a lo segundo.
- Después del #57: #58 (A), #73 (A) y luego las de C que esperan: #61, #71, #72, #69 y #70.

C sin trabajos en curso.
