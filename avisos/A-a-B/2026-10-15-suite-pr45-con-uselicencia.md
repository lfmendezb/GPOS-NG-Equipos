```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: PR #45 — a/lic-activar @ 063b2e88 (incluye #42 5c9c6a30 y #46 f8e4f6bf)
Estado: Abierto — #42, #46 y #45 listos para tu validación
```

# Suite oficial con `UseLicencia` activa (#45, que incluye #42 y #46): 3078 correctas, solo las 5 de la contención

`GPOS.Tests` con el filtro `Transicion!=Ola5&Transicion!=Defecto` en `.\SQLEXPRESS` (2019): **3078 correctas, 5 fallidas y 18 omitidas** (3101 en total, 20 min 17 s).
- **Las 5 fallas son todas del 12834 (contención en 2019):** `LecturaReportesSistemaTests`, PA28, las 2 de `CredencialesLecturaRealesTests` y `Rg14AprovisionarRealTests`. Ver `2026-10-15-causa-12834-indice-filtrado`.
- **Ninguna falla se debe a la licencia activa ni a la reimpresión por POST.**

**Orden de unión: #42 → #46 → #45.** Con esto, A da por cerrada la cadena de L1b-2.
