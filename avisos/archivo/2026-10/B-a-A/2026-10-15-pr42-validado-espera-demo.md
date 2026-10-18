```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: PR #42 a/lic-l1b-2 @ 520294b2 (unión de prueba sobre 7898beeb)
Estado: Abierto — espera la decisión del propietario sobre el DEMO
```

# PR #42 (L1b-2): validación de B **Apto**; la unión espera la decisión del propietario sobre el cupo del DEMO

## Unión de prueba sobre `7898beeb`
- Sin conflictos y sin migraciones. 41 archivos.
- Compilación de la solución correcta.
- `GPOS.Tests`: Mvp, licencia, arquitectura y usuarios, con el filtro oficial: **700/0/2**.
- Web: **655/655**. MAUI: **561/561**.
- No hace falta rebasar el #42 para unirlo: la unión es limpia. Si lo rebasas de todos modos, avisa.

## Los motivos del rechazo
| Motivo | Estado |
|---|---|
| Interruptor `GPOS:Licencia:Aplicar` | **Retirado.** `Program.cs` no llama a `UseLicencia` |
| Estricto sin `InstalacionId` no arranca | **Conforme**: C-08 y DL-02 (a) quedaron firmados el 2026-10-15 |
| `/api/super/licencia` retirada mientras la Web la usa | **Resuelto**: la Web usa L-04 (GET); el POST responde 410 (L-09) |
| Se apoya en DL-02 sin firma | **Resuelto**: DL-02 (a) firmada |

## Lo que falta antes de unir: decisión del propietario
Tu impacto de LV-17: sin un `.gposlic` cargado el cupo es 0, y no se pueden crear ni habilitar cuentas no SUPER.
- **El DEMO es Release**, así que una licencia firmada con `gsf-lic-dev` no le vale (CR-04 y A-N3).
- Necesitaría una licencia firmada con `s1`, y `s1` no existe hasta AI-09, que espera E-1 y DL-13.
- B se lo plantea al propietario. **No se une hasta que decida.**

## `a/lic-activar`
Con C-5 y DL-21 firmadas, ya puedes abrir el PR de la activación. Debe ir **después** del #42 y de la misma decisión sobre el DEMO.
