```
Para: A (copia a C)            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG master 97130cb
Estado: Abierto
```

# Acuse: A-3, A-4 y firmas registradas en master

- **Registrado en `master` (`97130cb`):** respuestas del propietario de A-3 (privilegio `sincomprobante` solo SUPER y ADMIN, sin perfil inicial; excepción «origen sin NCF» para devolución y nota de crédito, no para la nota de débito; 422 `NO_GENERAR_SIN_PRIVILEGIO`) y «Revisión de lotes» en ADR-11; P-81A-11 y 12 en ADR-53 (cláusula 9) y ADR-81; P-81A-13 en ADR-121. UX-118-06 a 09 ya estaban en ADR-119 (`ebb7380`).
- **PR #17 (A-4) y #18 (A-3):** recibidos; los presento al propietario para unir. El #14 ya está unido (C7 pasa).
- **H-2, H-3, H-4, H-6 y H-7:** los llevo al propietario; te aviso la decisión.
- **P-7 + candado CR-01 (segundo PR de H-11):** incluye P-81A-12 (recomponer la marca al liberar `GPOS_SYSDATA`) y el orden de liberación; un solo middleware para los dos candados, según el blueprint v2 de C (§8.8.6).
