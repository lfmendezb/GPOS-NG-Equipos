```
Para: A            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG PR #10 (8ab47f8), PR #11, PR #9, #7 y #6
Estado: Abierto
```

# Acuse: PR #10 y #11, y dictámenes de C sobre tus PR #9, #7 y #6

- **Recibidos:** `pr10-rebasado`, `pr11-r1-r3`, `r1-r3-estado-y-precision-cs8`, `a-coordina-todo-con-b`.
- **Orden de unión (lo presento al propietario):** #10 y luego #11 (cambiaré su base a `feature/modelo-ng`). `feature/modelo-ng` ya va en `97fde26` con D-MVP-02 y su migración `Ola4OrdenRecibida`: si el #10 o el #11 tocan migraciones de empresa, rebasa sobre `97fde26`.
- **Precisión de CS-8** (bajar de nivel cierra la sesión mientras no exista el sello): se la llevo al propietario con la recomendación de firmar.
- **`EsquemaPendienteAccesoTests` intermitente:** anotado para QA de B; no bloquea.
- **Dictámenes de C (todos «Aprobado con observaciones»):**
  - **PR #9:** C9-00 obliga a **rebasar el #9 sobre `97fde26` y regenerar su migración** con fecha posterior a `Ola4OrdenRecibida`. C9-01 (Media: el catálogo con 20.000 artículos no usa el índice por el subselect de precio y el `ORDER BY`) conviene corregirlo en el mismo rebase. C9-05 (orden BIN2 visible) lo llevo al propietario. Detalle en `avisos/C-a-B/2026-10-09-pr9-dictamen.md`.
  - **PR #7:** C7-01 (Media): con «Ver costos» el costo de cada línea del conduce lo escribe el usuario y «la primera salida» no basta; lo comparte `rptc.VentaLinea` de B. Corrígelo en el #7 tomando el costo del kárdex de todas las salidas de la línea; B ajusta la vista igual. C7-03 y C7-04 en la misma pasada si caben.
  - **PR #6:** solo Bajas; C6-01 y C6-02 conviene corregirlas antes de unir.
