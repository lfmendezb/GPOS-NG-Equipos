```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Acuse (tareas nuevas y uniones del 2026-10-22)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/adr90-rt05-tls-escucha` (local, con los 9 commits de `b/deuda-pr2-p137-p140`)
Estado: Abierto
```

# Acuse de A

Enterados de las uniones (#122, #130, #136, #124 y las de C) y de la firma de S2-04 (b) en el #155. Con #124 y #136 unidos, **la tarea 1 del instalador (`--servicio`, firma de la `.CA.dll`, P-O1-7 con FIPS) queda desbloqueada: la empezamos tras PR-4 y la entregamos el 13-nov**, como aceptamos.

| Tarea de B | Respuesta de A |
|---|---|
| 1. Relectura de `338d899f` y `89f03411` | **Hecha**: `traspasos/A/relectura3-seguridad-pr2-adr90-2026-10-22.md` (R2-01, R2-02 cerradas; P139-01 correcto; sin Críticos/Altos/Medios) |
| 1b. Rama `b/deuda-pr2-p137-p140` | Los 9 commits **cherry-picked sin conflicto** sobre `89f03411` en el árbol local de A; el único cambio de producción es `SelectorCertificadoServidor.cs` (P140-03). **Relectura en curso**, informe antes del **2026-10-27** (3 días hábiles; tu plazo era 5). **No subimos al #140 hasta tener la relectura y la orden del propietario** |
| 2. Adenda a S-16 (V-RIESGO-1 y F-25) | Aceptada: **antes del 2026-11-06** (pedido el 9-nov) |
| 3. S152-02, D-25/D-26 | Aceptadas; las decidimos con la revisión del #152 (**antes del 2026-10-29**); S152-02 es condición de T4-02 |
| 4. Revisión de la DDL rev. 3 de D1 (CS-P2, D1-01 a D1-06) | Aceptada: 3 días hábiles desde que la publiquen |

Sin cambios en lo ya aceptado: T4-06 desde el 3-nov, token de T4-04 antes del 10-nov, DEMO antes de D4. Recordatorios: la frontera del token y P-1 esperan tu respuesta (F-1 a F-5 antes del 28-oct), y el DEMO es condición antes de publicar nada (riesgo R-2 del blueprint de T4-06); el plan del DEMO está en preparación.

Nada se une sin orden expresa del propietario.

Respuesta requerida: ninguna.
