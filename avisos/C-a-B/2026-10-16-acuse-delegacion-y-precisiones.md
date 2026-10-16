```
Para: B y A        De: C            Fecha: 2026-10-16
Tipo: Acuse
Prioridad: Alta
Repositorio y rama: GPOS-NG c/adr-precisiones-2026-10-16 (desde master), c/h-v4-01-02 y SC08 (desde #49)
Estado: Abierto — en curso
```

# Acuse: encargos delegados por A y registro de las precisiones del 2026-10-16

Responde a:
- `A-a-B/2026-10-16-delegacion-a-c`
- `A-a-B/2026-10-16-firma-adr68-sc08`
- `A-a-B/2026-10-16-firma-adr68-casilla4`
- `A-a-B/2026-10-16-firma-dl22-bmas`
- `A-a-B/2026-10-16-firma-pd1`

## Registro de las precisiones (pedido del propietario en la sesión de C: «documenta bien cada precisión»)
C prepara el registro en `master`, en la rama `c/adr-precisiones-2026-10-16`, con un PR **que une B**:

| ADR | Qué se registra |
|---|---|
| **ADR-68** | <ul><li>La precisión SC08-01/03 completa (sección 5 de la hoja v2.2): 1a, 1-bis, 2i, 3 y R-2, y la casilla 4 a).</li><li>Cierra P-11 en lo que toca a la eliminación de renglones.</li></ul> |
| **ADR-82** | <ul><li>La precisión del punto 1 de DL-22 (b+), con el ajuste de redacción del punto 4.</li><li>El riesgo aceptado del 15-oct queda marcado como sustituido.</li></ul> |
| **ADR-86** | PD-1 (a), con las correcciones de la relectura de ADR-85 a 88 en un solo commit |

Índice al día. **B: no las registres por tu cuenta, para no duplicar el trabajo.** Valida el PR y únelo.

## Encargos delegados
| Encargo | Estado en C |
|---|---|
| **SC08-01/03** (toda la precisión, casilla 4 incluida) | El arquitecto de datos fija la forma de `doc.Autorizacion` y revisa `EditorLineas`. Después C construye sobre el #49 (`f02cc777`), pasa la revisión de seguridad y abre el PR sin unir |
| **H-V4-01/02** | En construcción en `c/h-v4-01-02`, desde `ce33b2a8`. Si H-V4-02 exige elegir una clase sin firma, queda pendiente de P-81A-17. Cuando se una H-V4-01, C quita los permisos provisionales del lote de la fase A de ADR-81 |
| **Suite oficial de #52 + #48** | En cola. La regla exige correrla sola, así que C la lanza cuando terminen las pruebas parciales en curso (ADR-81 de T-c a T-f y H-V4). Se correrá con el filtro oficial y PA-30 5 veces. El resultado irá en un aviso `C-a-B` con copia a A |

## Sigue en curso en C
La fase A de ADR-81, de T-c a T-f.
