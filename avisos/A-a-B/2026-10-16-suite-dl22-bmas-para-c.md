```
Para: C (copia a B)        De: A                          Fecha: 2026-10-16
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG a/dl22-bmas @ d3a65288 (sobre a/dl22-rotacion @ cd480ddd, PR #52)
Estado: Encargo a C (delegación del propietario, aviso 2026-10-16-delegacion-a-c)
```

# Suite oficial de DL-22 (b+) con el #48

**Qué es:** la construcción de la opción (b+) del punto 1 de DL-22, firmada hoy por el propietario. Son un solo commit, `d3a65288`, y siete archivos (caché de `EmpresasService`, `credencial-app` y S4).

**Encargo (sustituye al del #52 solo; esta rama lo incluye):**
1. En una rama local temporal: `a/dl22-bmas` + `origin/a/rg14-contencion-indice` (#48, `808cbe0a`). La fusión de `Rg14VerificarTests.cs` se resuelve sola.
2. Corre la suite oficial con `--filter "Transicion!=Ola5&Transicion!=Defecto"`. **PA-30 «ningún 500» ya no está en `Defecto`:** entra en la suite.
3. Si la carga lo permite, corre 5 veces aparte `Rg14RotacionApiTests` (PA-30). En la PC A, con SQL 2019, dio 5 de 5, 0 fallidas de unas 8100 a 8800 peticiones, credencial anterior inútil a los ~3,05 s y sesión a los ~15,07 s. **En SQL 2025 no se ha medido:** compara el 916 y el 18456.
4. Informa en `C-a-B` con copia a A: correctas, fallidas y omitidas, causa de cada falla, y las ventanas de PA-30.

**Datos de la PC A:**
- 23 de 23 en `Rg14Lote2`, `Rg14Verificar` y `Rg14Aprovisionar`.
- 209 de 209 en 23 clases de caché, candado y reapertura.
- `EsquemaPendienteAccesoTests` dio 8 de 9: la falla de `Una_empresa_cuya_base_no_existe…` es previa e intermitente, y ocurre también sin DL-22.

La revisión de seguridad de `d3a65288` está en curso en A. El PR sale después de la revisión y de tu suite. Orden de unión: #48 → #52 → (b+).
