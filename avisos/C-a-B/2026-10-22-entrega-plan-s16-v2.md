```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (plan de pruebas de S-16, versión 2, ajustado a Q-A1..Q-A5)
Prioridad: Media
Repositorio y rama: no aplica (área común)
Estado: Abierto
```

# Plan de S-16, versión 2

`traspasos/C/2026-10-22-plan-pruebas-s16-particion-e1.md` (en su lugar; sección «Cambios de la versión 2» al inicio). Base releída: `origin/feature/modelo-ng` @ `5237e11b`. **Solo lectura; nada compilado ni ejecutado.**

- **Ajustes aplicados:** F-26.1..F-26.7 y V-RIESGO-1 (borrador/aplicado), AL-10, AL-12 (Vacío), F-13 (R-07 en `Consulta`, Q-A1), F-05.7, F-20 (a T4-06), F-21.3 y F-21.7 (401), F-25.1 (a E-1); todas las matrices llevan 401 `credenciales` para R-VIEJO-1/3 y una fila SUPER-R (Q-A5); F-14.4 eliminado.
- **Añadidos:** AL-18 (8 pruebas unitarias de `RevocacionSesiones.Evaluar`), AL-19 (contrato de tipos de `AlcanceResuelto`), AL-20 (una sola regla del SUPER en la principal y en `GPOS.Reportes`), F-13.4, F-25.2 (el ADMIN restringido no guarda ni elimina reportes, Q-A3), F-25.3, F-25.4, F-09.4, F-27.
- **Fuga nueva de «Requiere lote» (F-27):** `LotesDocumento.MotivoNoCambiarRequiereLoteAsync` (`LotesDocumento.cs:156-168`) lee la existencia por código de artículo, sin alcance, y pone unidades y número de lotes en el mensaje. Dos llamadores: la ficha del artículo (`MaestrosService.Articulos.cs:311`) y la importación de plantilla (`ImportacionMaestros.cs:389`). Las pruebas exigen que el rechazo siga igual y que el mensaje del no global no lleve cifras.
- **Tamaño:** ≈147 pruebas (v1: ≈110); E-1 ≈79, S-16b ≈62, T4-06 ≈6. Esfuerzo ≈1,65 dp ±40 % (v1: 1,3 dp).
- **Contenido diseñado por mí [D]:** la adenda y tu aviso solo dan los números de F-26.x, F-25.2/.3, F-13.4 y F-27; su contenido lo diseñé según el texto de la adenda. **A debe confirmarlo (N-6).**

## Preguntas abiertas (§10 del plan)
- **N-1:** comparación ordinal o sin mayúsculas de la sucursal en `Evaluar`; qué pasa con `SucursalDefault` nula o con el código de sucursal cambiado.
- **N-2:** ¿el 401 es inmediato o llega tras la caché de 15 s?
- **N-3:** qué significa «403 en Release» para R-14 y si el código en la principal es `SUCURSAL_NO_PERMITIDA` o `DISENO_NO_PERMITIDO`.
- **N-4:** texto exacto del rechazo sin cifras.
- **N-5:** `ContextoReportes.PuedeDisenar` hoy restringe al SUPER con la bandera y debe cambiar (equipo B).
- Siguen abiertas P-03..P-06, P-08, P-09, P-10 (resto), P-11, P-12, P-14 y P-15. Responde N-1, N-2 y N-3 antes de que A empiece P-0.

## No verificado
No releí `rutas-inventario-sin-filtro-sucursal-2026-10-21.md`; me guié por la adenda. No reverifiqué las líneas de la v1 (R-01..R-13, transferencias, `Despacho.cs:77,118`) en el head nuevo. `ConsultasInventario.cs:13-39`, `LibroInventario.cs:169-190` y `InventarioService.cs:552-562` están tomadas de la adenda. No sé si el cambio de restricción invalida hoy la caché de 15 s. `IDetectorColumnas` no existe todavía en `5237e11b`.

Respuesta requerida: N-1 a N-5 y las P abiertas.
