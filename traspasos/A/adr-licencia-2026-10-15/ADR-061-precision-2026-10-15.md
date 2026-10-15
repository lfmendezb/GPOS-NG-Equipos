# ADR-61 · Precisión del 2026-10-15 para registrar (NV-08 en la cadena; P-1 del blueprint v2.3)

**Para quien registra (B), no se copia al ADR.**
- **No estaba en el encargo:** sale de la misma firma («las P de v2.2 a v2.4») y es la única de esas precisiones que toca ADR-61. Es técnica, dentro de lo firmado.
- **Dónde va:** al final de `docs/adr/ADR-061.md`, después de las precisiones del 2026-10-14 (DL-13 y DL-10).
- Con ADR-84 registrado, agregar además en ADR-61 la remisión a [ADR-84](ADR-084.md) (F-3, DL-10, DL-11 y DL-13), como la de ADR-62.
- **Fuente:** blueprint de la licencia del lote 2 (`traspasos/A/blueprint-licencia-lote2-2026-10-14.md`), registro de cambios v2.3 (P-1) y sección 6.1.1, reglas 7 y 12; validación del modelo de datos de L1a-4 (`traspasos/A/validacion-datos-l1a4-2026-10-14.md`).

---

> **Precisión del 2026-10-15 del punto 5 (NV-08 dentro de la cadena de licencias anteriores; P-1 del registro de cambios v2.3 del blueprint de la licencia del lote 2; aprobada por Leonardo Méndez, propietario, el 2026-10-15 en la sesión de B con la tercera firma de la hoja de firma DL-01 a DL-22 v2.13, en el área común `traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md`\*: «Aprobado según la recomendación: Las firmas de licencia DL-01, 02, 03, 05 y las demás de la lista.», lista que incluye «las P de v2.2 a v2.4»).** Sin cambiar el texto firmado de arriba:
> 1. Una licencia anterior cuyas llaves están todas retiradas **sigue en la cadena de licencias anteriores** con la que se calcula el derecho previo (NV-02 en cadena, precisión de [ADR-59](ADR-059.md) del 2026-10-15), pero **el derecho previo que da queda acotado por su retiro efectivo** (`RetiroEfectivoUtc`).
> 2. El fin de la gracia `LlaveRetirada` es el menor de su `Hasta`, el tope por empresa (NV-01) y el corte del día siguiente a `vence` de la entrada: nunca más allá del último día pagado (Q-04).
>
> Costo: unos 0,15 dp (L1a-3 y L1a-4). **Decidido, no implementado.**
>
> \* *La hoja vive en el área común; no está copiada en `master`.*
