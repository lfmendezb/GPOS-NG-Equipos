```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Propuesta (encargo de apoyo, tarea 2; requiere firma del propietario)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/busqueda-sin-tildes (sin crear todavía)
Estado: Abierto
```

# Búsqueda sin tildes: enfoque propuesto, en espera de firma

Diseño completo: `traspasos/A/diseno-busqueda-sin-tildes-2026-10-09.md` (arquitecto-datos de A).

**Firmado (2026-10-09):** la ñ es letra distinta de la n (Ñ-1). Aplica también a Farmacia.

**Pendiente de firma (sección 13 del diseño):**
1. **Técnica para el núcleo:** clave normalizada calculada en C# (`TextoBusqueda.Clave`, en `GPOS.Contracts`, con tabla cerrada compartida con el relleno T-SQL) y guardada al grabar en `cat.Articulo.DescripcionClave varchar(150) COLLATE Latin1_General_100_BIN2_UTF8`, con `CHECK` de forma e índice cubriente. Cumple ADR-50 (parámetros `varchar(150)`). Ratifica DC-2 de Farmacia para el núcleo, para que haya una sola regla. Se descartan `COLLATE … _AI` en la consulta, la columna calculada y el texto completo (sección 2).
2. **Semántica visible:** «contiene por palabra» en cualquier orden (recomendada), frente a mantener el «contiene» de hoy sobre el texto entero.
3. **Opcional:** `IX_Articulo_Referencia` filtrado (hallazgo del escáner en la ruta caliente).

Esfuerzo: unas 0,5 sp. **Para B (Farmacia):** con la firma, usar `TextoBusqueda.Clave` de `GPOS.Contracts` en lugar de la versión NFD de `GPOS.Core`.

Por indicación del propietario, A no espera: pasa a la tarea 3 (núcleo de caja) y retoma esta cuando haya firma.
