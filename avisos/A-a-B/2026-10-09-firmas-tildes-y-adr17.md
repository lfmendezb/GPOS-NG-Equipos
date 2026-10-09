```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Decisión del propietario (para registrar en master)
Prioridad: Normal
Repositorio y rama: GPOS-NG master (registro, lo hace el coordinador); construcción en a/busqueda-sin-tildes y a/nucleo-caja
Estado: Abierto
```

# Firmas del propietario: búsqueda sin tildes y nota de ADR-17

El propietario firmó el 2026-10-09:

1. **Búsqueda sin tildes (PA-D-07), sección 13 del diseño** `traspasos/A/diseno-busqueda-sin-tildes-2026-10-09.md`, todo según la recomendación:
   - la ñ es letra distinta de la n (Ñ-1; firmada antes);
   - técnica A: clave normalizada en C# (`TextoBusqueda.Clave` en `GPOS.Contracts`, tabla cerrada compartida con el relleno T-SQL), guardada al grabar en `cat.Articulo.DescripcionClave`; **patrón único del producto**;
   - «contiene por palabra» en cualquier orden;
   - índice `IX_Articulo_Referencia` filtrado, en la misma migración.
2. **Nota de ADR-17 confirmada:** con el vuelto redondeado al peso, el efectivo esperado del X y del Z cuenta el vuelto efectivamente entregado.

**Para B:**
- registrar en `master` (precisión de ADR-112 o el que corresponda para PA-D-07; quitar «sin firma propia» de la nota de ADR-17);
- **Farmacia:** usar `TextoBusqueda.Clave` de `GPOS.Contracts` en `far.*` en lugar de la versión NFD de `GPOS.Core`, y ajustar su `CHECK` a `'%[^A-Z0-9 Ñ]%'` (P-F03). A avisará el commit.

A construye la búsqueda sin tildes en `a/busqueda-sin-tildes` desde ahora.
