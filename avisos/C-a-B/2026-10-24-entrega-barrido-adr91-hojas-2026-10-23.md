```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 5 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`) y hallazgos
Prioridad: Media (conviene corregir C1 y S1 a S5 antes de la primera ventana del laboratorio del MSI)
Repositorio y rama: GPOS-NG: hojas de `docs/decisiones/2026-10-23-*` y PR #219, #221, #222, #227; sin cambios
Estado: Abierto
```

# Barrido de ADR-91 (DF-07) de lo firmado el 2026-10-23

Informe: `traspasos/C/2026-10-24-barrido-adr91-hojas-2026-10-23.md`. No edité hojas ni el repositorio. Leí todo con `git show` y `git grep` desde `origin/master`, `origin/feature/modelo-ng` y las ramas de #219, #221, #222 y #227 (y #218 por contraste). Resultado: 0 Críticos, 2 Altos, ~10 Medios, el resto Bajos. **Ninguno cambia lo firmado**: son marcas, estados y cifras. Límites: no revisé #228 ni #225 salvo existencia y base; otras ramas de PR quedaron fuera.

**«Pendiente de firma» de algo ya firmado: 9 casos (S1 a S9).**
- F2 y F3 de `tls`: #227 las firma completas, pero siguen pendientes en #221 (líneas 6 y 38), #222 (línea 6) y #219 (línea 583; ese bloque incluso lleva la marca, ya falsa). #227 (línea 24) dice que esas líneas «se anotan» en #221 y #219 y las cabezas actuales no lo hacen.
- #219 dice «propuesta de diseño; nada construido» (línea 3) y su próximo paso (línea 619) pide que el propietario responda P-1 y P-9, ya respondidas.
- La hoja de D-03 (en `feature/modelo-ng`): la línea 4 dice «borrador; no presentado» y la 34 «barrido por hacer», con la firma de TBS-01 a TBS-06 más abajo; sus «pendientes» de la línea 39 ya están construidos según `estado.json`. Las precisiones de ADR-109 y ADR-93 no están anotadas en `master`.

**Referencias vivas sin la marca: 9 casos (M1 a M9).** En `master`, las marcas de P-T402-01/02/04 y P-G5-01/02/03 (6 líneas en el blueprint de T4-02 y la lista de cierre) traen `(..decisiones2026-…)` sin las barras (#222 sí usa el enlace correcto); quedan acciones como «llevar P-T402-01 a 04 a la firma» y condicionales como «Depende de P-G5-01»; ADR-109:142 no cubre P-T402-03, T4-06 P-1 a P-4 ni C-1 en la vista previa; ADR-90:136 y :150 siguen con `PFX_CLIENTE` y «en minutos» pese a que P-5 y P-7 los precisan; el barrido de #221 solo busca P-1 a P-9 (`SA-01…` colisiona con la serie del módulo de análisis; `M-2` y `P-1` se repiten en ADR-38 y ADR-109); la lista de cierre de G-O5-T4 dice «Equipo C fuera de servicio» y «T4-06 P-2: sin rama ni PR», cuando hoy existe #225.

**Hojas que se contradicen: 8 casos (C1 a C8).**
- **C1 (Alta):** Q-3, Q-4 y Q-7 tienen dos significados. En #222 y en `construir.ps1:73` son proveedor de firma, nombre legal y qué se firma, y siguen sin respuesta; en #227 son reinicios, actualización y `Start`, y están firmados. La misma cita queda a la vez «firmada» y «sin respuesta».
- `Start` del MSI: **no hay contradicción** (#227, `Package.wxs:63` y la hoja de operaciones dicen `auto`; los `demand` son del spike DE-01).
- El documento de operaciones de A (líneas 156 y 205, en `feature/modelo-ng` y #218) dice «60 s en el tercer fallo» y «x3»; lo firmado y construido es restart, restart, none.
- F1 en 2,75 o 3,35 dp: las adendas lo explican, pero quedan residuos de 2,75 en #221 (línea 21) y #219 (líneas 16, 543, 553, 556 y 595); las filas SA suman 0,55 dp, no los +0,6 firmados. #227 mantiene USD 2.400 a 3.200 con 8,6 dp (esa cifra corresponde a 8 dp; con 8,6 dp saldría de ~USD 2.580 a 3.440). Fecha de F1: #219 dice «antes del 5-nov» (líneas 16 y 543) y «antes del 2-nov» (595); lo firmado es 5-nov. Publicación del DEMO: la hoja de PR-D2 dice «hasta la tarea 3» y la hoja del DEMO del 2026-10-22 «hasta PR-D2», sin igualarlas.

**`estado.json` frente a las hojas:** casi coincide (no cita PR-D2, `tls`, el anillo, SA ni P-T402). **E1 (Alta):** la cláusula «Impresión» de ADR-109 dice que el emisor real del token de servicio «no existe»; era cierto sobre `67b4353a`, anterior al merge de #217 (`1b310591`, cabeza `11a1e822`; confirmado con `gh`) y no hay PR de estado abierto para el #217. E2 (Baja): ADR-90 sigue con `prEsperado` «por abrir» aunque existen #219 y #228. E3 (Baja): TB-07 dice «Pendiente: #212», ya unido; lo cierra el #216, abierto.

**Remedio, en orden:** (1) B marca F2 y F3 como firmadas y alinea 2,75/3,35/8,6 dp y las fechas en #221, #219 y #222; (2) B resuelve C1 antes de que el laboratorio use esos identificadores; (3) A corrige la hoja de operaciones de `GPOS.Api` (recuperación restart, restart, none); (4) el Documentador registra las precisiones en ADR-90, ADR-109 y ADR-93 al unirse los PR, corrige los 7 enlaces rotos y abre el PR de estado del #217; (5) el Arquitecto Maestro redacta la precisión de ADR-90 (P-5, P-7, P-6).

Respuesta requerida: ninguna con fecha propia; C1 y S1 a S5 antes de la primera ventana del laboratorio del MSI.
