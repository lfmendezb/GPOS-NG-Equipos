```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Entrega (tarea 5: PR de documentos por P126-01 a P126-09) y dos firmas del propietario tomadas en la sesión de C
Prioridad: Media
Repositorio y rama: GPOS-NG c/p126-documentos, PR #147 sobre master (cb9c5fe4)
Estado: Abierto
```

# Entrega: PR #147, seguimiento de documentos de la revisión del #126

[#147](https://github.com/lfmendezb/GPOS-NG/pull/147), respuesta a la tarea 5 de `B-a-C/2026-10-21-nuevas-tareas-para-c.md`. Antes del 3-nov. Solo documentos, sobre `master`.

## Cómo se aplicó su regla
- **Sin reescribir:** según ADR-91, DF-04, ninguna frase se borra ni se reescribe. Las correcciones son anotaciones fechadas con su fuente.
- **Registro de novedades:** no se anota, porque es una instantánea (DF-03). Se le agrega una entrada nueva del 2026-10-21.
- **Sin fuente:** dos observaciones no tenían ninguna fuente firmada, porque las recomendaciones que se mostraron en el chat del 20-oct no están ni en `docs/` ni en el área común. Se las pregunté al propietario en la sesión de C, y las firmó:
  - **P126-01:** ante «¿Qué rige mientras DP-2 está sin decidir?», respondió **«Lo firmado»**. Rigen LV-12, con la excepción 2 completa, y la regla de (e); la opción (C) es solo la pregunta 2.8 al abogado.
  - **P126-07:** ante «¿Quién designa al custodio?» (DP-4), respondió **«Yo designo»**. El abogado fija el plazo; el custodio lo designa el propietario.

## Qué cambia
| Observación | Dónde | Fuente |
|---|---|---|
| P126-01, P126-07 | consulta CI-7, (h), precisiones del 2026-10-21 | firmas de arriba |
| P126-02 (condiciones de DP-3) | (h) | ADR-92 (firmado el 20-oct): CS-04, UR-02, CS-01, UR-01 y CS-05 recogen las cinco de 3.5 |
| P126-03 (marcas) | encabezado, (g) y (h) | ADR-91, DF-01 y DF-02: línea «Pendiente de firma: DP-2» y marca calificada «DP-2 de la consulta CI-7» (DP-2 se repite en la hoja del 2026-09-29 y en ADR-113) |
| P126-06 (a quién afecta) | (h) | ADR-92, «Consecuencias» |
| P126-08 (DP-5) | (h) | ADR-92, fase CS-1 (P-1 (a)) |
| P126-04, P126-05 | ADR-90, precisión nueva tras la de F-5 y F-6 | copia de F-5 y de la tabla 4.1 de B; plan de D1, 6.3 (T1-3 y T1-5 en la API; T1-4 y T2-0 en `GPOS.Migracion`) |
| P126-09 | `docs/decisiones/2026-10-20-respuestas-b-f5-f6.md` (nuevo) | copia literal de F-5, F-6 y la fila de 4.1 de su documento (`f854ef2`) |

Hice el barrido de DF-03: `DP-2` aparece 21 veces en `docs/`. Solo 6 son de la consulta; las demás son de otras hojas y no las toqué.

**Pruebas:** `ManifiestoAdr` 39/39, incluida la guarda de firmas DF-05; no toca código.

B revisa y une, con orden expresa del propietario. Sigo con la tarea 7 (plan de pruebas E-1 de ADR-93, 5-nov), con el boceto v2.2 que mandaron.
