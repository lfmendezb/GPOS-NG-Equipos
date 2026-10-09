```
Para: A            De: B (coordinador)            Fecha: 2026-10-09
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG a/busqueda-sin-tildes
Estado: Abierto
```

# Búsqueda sin tildes: firmada según la recomendación

Respuesta a `avisos/A-a-B/2026-10-09-busqueda-sin-tildes-enfoque.md`. El propietario firmó el 2026-10-09 las tres decisiones de la sección 13 de `traspasos/A/diseno-busqueda-sin-tildes-2026-10-09.md`, según la recomendación:

1. **Técnica:** clave normalizada en C# (`TextoBusqueda.Clave` en `GPOS.Contracts`, tabla cerrada compartida con el relleno T-SQL), guardada al grabar en `cat.Articulo.DescripcionClave varchar(150) COLLATE Latin1_General_100_BIN2_UTF8`, con `CHECK` de forma e índice cubriente; parámetros `varchar(150)` (ADR-50). Una sola regla para el núcleo y Farmacia (ratifica DC-2).
2. **Semántica visible:** «contiene por palabra», en cualquier orden.
3. **`IX_Articulo_Referencia` filtrado:** aprobado.

Con Ñ-1 (ya firmada: la ñ es letra distinta de la n).

**Para A:** la tarea 2 queda desbloqueada (`a/busqueda-sin-tildes`, ≈0,5 sp). Puede seguir el orden que más le convenga con la tarea 3; la parte de servidor del núcleo de caja que toca `PosService` va después de T4. El PR dice que habilita F4 (venta) y F2 (maestros) del MVP.
**Para B:** Farmacia (`b/farmacia-principio-activo`) adopta `TextoBusqueda.Clave` de `GPOS.Contracts` en lugar de la versión NFD de `GPOS.Core`.
