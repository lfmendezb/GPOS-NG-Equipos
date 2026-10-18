```
Para: B (copia a C)        De: A            Fecha: 2026-10-18
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG #48 (a/rg14-contencion-indice @ 5c7e5acd) y #60 (a/d04-pa28-contencion @ 847f6e13), sobre feature/modelo-ng @ 17ecc9b9
Estado: Abierto
```

# #48 con la marca regenerada y #60 apilado encima (paso 4 de la cadena)

## #48 (`5c7e5acd`, antes `808cbe0a`)
- **Migración regenerada:** `20261015030000_Rg14ContencionMotivoAnulacion` → **`20261018042207_Rg14ContencionMotivoAnulacion`**. Es posterior a `20261015142020_Uf05ForceSeek`.
  - El Designer y el snapshot los generó `dotnet-ef` 10.0.12 sobre `17ecc9b9`. El Designer coincide línea a línea con el snapshot. El único cambio de modelo es el de siempre: `IX_Documento_MotivoAnulacion` sin `HasFilter`.
  - El cuerpo es el propio, sin cambios: Up idempotente y Down con 51616 en `PARTIAL`.
  - `Rg14ContencionTests` usa la marca nueva.
- **Guion acumulado:** `database/empresa/gpos-empresa-20261018042207_Rg14ContencionMotivoAnulacion.sql` reemplaza al de `Uf05ForceSeek`. Respecto a ese, solo se agrega el bloque de esta migración (26 líneas).
- **Toda migración que venga después** lleva una marca posterior a **`20261018042207`**.

## #60 (`847f6e13`, antes `b4a87f09`)
- El #48 ya traía el mismo cambio de PA28 (`InstanciaContenidos.ContenerAsync`). El #60 se rebasó **sobre el #48**, y su base en GitHub pasa a **`a/rg14-contencion-indice`**.
- Ahora el #60 **solo cambia el comentario** de PA28: junta la causa del 5061 (D-04 del QA de T-r) y la nota del 12834.
- **B decide:** unirlo después del #48 (GitHub lo reapunta solo) o cerrarlo como incluido en el #48. Las dos salidas dejan el mismo código.

## Pruebas dirigidas (SQL 2019 de la PC A, `.\SQLEXPRESS`)
`Rg14*`, `Migracion*` y las de usuarios contenidos, sobre `847f6e13` (#48 + #60): **244/0/2**.
- **PA28 pasa en SQL 2019.** Con el #48 se cierra el 12834 de la PC A.
- Las de contención de `Rg14ContencionTests` también pasan: ida y vuelta PARTIAL/NONE, y Down rechazado.

## Para B/C
La suite oficial en SQL 2025 y unir #48 → #60. Antes van #52 + #55 → #51 → #45.

## Siguiente de A
Paso 5: **#63** (`a/sl-sello-padron`), rebasar.
