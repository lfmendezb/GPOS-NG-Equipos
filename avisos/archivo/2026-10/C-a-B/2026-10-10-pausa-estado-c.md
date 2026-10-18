```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG ramas c/
Estado: Abierto
```

# Pausa acatada: estado del equipo C para retomar

Respuesta a `B-a-C/2026-10-10-pausa.md`.

**Situación a las 14:15:**
- Sin agentes activos.
- Sin compilaciones, pruebas ni procesos de dotnet o testhost.
- Ninguna migración, unión ni archivo a medias.
- Todas las ramas `c/` limpias y subidas; no hizo falta un commit de «pausa».
- El vigilante de novedades sigue armado; C solo atiende avisos nuevos de B.

## Hecho
| Tarea | Rama y commit | Estado |
|---|---|---|
| C-1 paquete del DEMO | `c/paquete-demo` `f22035b` | PR #12 unido |
| C-4 AUTO_CLOSE OFF | `c/dm04-autoclose` `fe2124e` | PR #13 unido |
| C-6 plantillas con lotes | `c/demo-plantillas-lote` `033c4d7` | PR #15 unido; la nota de vencimiento obligatorio se subió después de unir |
| C-8 ADR-50 en cuatro servicios | `c/adr50-servicios` `22aa0b8` | PR #19 unido |
| C-9 pruebas de interfaz estables | `c/pruebas-ui-estables` `2ae3816` | PR #20 unido |
| C-10 optimización de la compra | `c/compra-variable-tabla` `dfde08e` (rebasada sobre la ola 5) | **PR #21 abierto, no unir antes del 14-oct** |
| C-11 pruebas RB-P4 (75 casos, P1 a P28) | `c/rb-p4-pruebas-fiscales` `9dee5e6` | **PR #22 abierto** |
| C-12 NcfOrigenTests estable | `c/ncf-origen-estable` `3a26101` | **PR #23 abierto** |
| C-2 revisión de H-11 | — | Dictamen entregado (C2-01 Alta, ya en el segundo PR de A) |
| C-3, C-7, PC-1 y C-1: fase A de ADR-81 | `c/adr81-fase-a-diseno` `42881e2` (rebasada sobre la ola 5) | Diseño cerrado (blueprint v3 y pantallas v2), con todas sus firmas |
| C-5 pantallas de ADR-118/119 | `c/adr118-119-ux` `b7be058` | Diseño cerrado, base de T4 |
| Ensayo y publicación del DEMO | OneDrive `GPOS ARGON\Actualización` | Paquete 2026-10-10 publicado |

## Falta (para retomar)
1. **C-13, aviso por correo de la revisión de lote:**
   - Diseño hecho (`c/revision-lote-correo` `ce3bb80`, desde `b/adr118-119-t1`).
   - **La construcción espera la firma del propietario de C13-P01 a 04** (`C-a-B/2026-10-10-c13-diseno-aviso-correo.md`). Se estimó en unos 3 días-persona.
2. **C-10, PR #21:**
   - si el segundo PR de H-11 de A se une antes, regenerar la migración con una fecha posterior (y aplicar RB-P5 si hace falta);
   - decidir el reintento del error 952.
3. **Fase A de ADR-81:**
   - construir después de la unión del segundo PR de H-11 de A;
   - T1 se puede adelantar si B lo encarga.
4. **P29 a P31 (RB-P3):** cuando una migración toque `TR_Documento_Anulacion`.
5. **Posible:** la interfaz Web de transferencias (ola 3b), si B la encarga.

**Preguntas abiertas para B y el arquitecto de datos:**
- H-2 de C-11 (asimetría del ISC en 51359) y la observación de 51374 y 51375 (`Origen <> 'I'`);
- el hallazgo de 51355 y `IX_CxpAplicacion_Afectado`;
- la prueba de concurrencia `NumeracionQaDefectosPreexistentesTests.Anulacion_…`.
