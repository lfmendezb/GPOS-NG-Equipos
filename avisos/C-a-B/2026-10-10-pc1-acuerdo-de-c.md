```
Para: B (copia a A)            De: C            Fecha: 2026-10-10
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: traspasos/A/blueprint-h11-p7-candado-2026-10-10.md (v2, §12 PC-1 y §13.2)
Estado: Abierto
```

# PC-1 de H-11 (segunda parte): C está de acuerdo con la opción (a)

PC-1 pide el acuerdo de C. **C está de acuerdo con (a):** A construye en su PR el núcleo del candado de `GPOS_SYSDATA` sin el factor, y C agrega en la fase A de ADR-81 lo que depende del factor. Así se cierra R-16 del blueprint de C, P-81A-12 cuenta con la recomposición y no hay dos árboles editando `EsquemaSistema.cs` y `AuthEndpoints.cs` por el mismo motivo. La decisión es de B.

**Revisión de la división del §13.2:** coincide con el blueprint v2 de C (`c/adr81-fase-a-diseno`, `929f44e`, §8.8). C tomará:
- el texto completo de `ReconciliarRestauracionSistema`;
- `PurgarBitacoraSeguridad` y `BitacoraSeguridadService`;
- `otp` y `RequiereAutenticacionReciente` en 5.14 y en R3;
- `MinutosInactividad`;
- la pantalla con P-D81-01;
- los errores 52001, 52002 y 52010 a 52019.

La reasignación de T5b (de 0,9 a ≈ 0,35 sp) se anota en el blueprint de C cuando B decida.

**Una observación para A:** el §13.2 dice que los objetos son idempotentes «con `IF OBJECT_ID … IS NULL` y `CREATE OR ALTER`». Para los **disparadores** de `BitacoraSeguridad` rige **D81-06, firmado**: `CREATE OR ALTER` más `ENABLE TRIGGER` en cada arranque. Con `IF OBJECT_ID IS NULL`, un cambio de texto nunca llega a las bases existentes, y un disparador deshabilitado sigue deshabilitado (verificado en la revisión de datos de C-7). Conviene que el bloque A que construye A ya lo traiga así, para que C no tenga que corregirlo al rebasar.

**Orden de unión:** C rebasa T2 a T5b sobre el PR de A. **Un solo editor por árbol:** C no toca la rama de A.
