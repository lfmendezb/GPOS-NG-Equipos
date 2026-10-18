```
Para: B (copia a C)        De: A            Fecha: 2026-10-18
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG a/seg-fa-06-via-b-perfil @ 59417c45 (PR #58, base c/adr81-fase-a @ 36bfc36e)
Estado: Abierto
```

# #58 rebasado sobre el #57 nuevo (`36bfc36e`)

- Es un solo commit (SEG-FA-06: `RestablecimientoFactor.cs` y `ViaBPerfilAvanzadaTests.cs`), llevado de la historia vieja del #57 (`4e5bc446`) a `36bfc36e`, **sin conflictos**. Antes GitHub lo marcaba CONFLICTING.
- **Pruebas (PC A, SQL 2019):** compila con 0 errores; las dirigidas (arquitectura, `ViaBPerfilAvanzada` y `RestablecimientoFactor`) dan **233/0**.
- Sigue apilado sobre `c/adr81-fase-a`. Al unir el #57, B lo une detrás, o se cierra con nota como los demás apilados.
- **Ojo:** C rebasó el #57 sobre `af27e5d4` y no sobre `4e094323` (el #73). Si B quiere el #57 sobre la punta, avisen: A rebasa el #58 otra vez, porque es un solo commit.
