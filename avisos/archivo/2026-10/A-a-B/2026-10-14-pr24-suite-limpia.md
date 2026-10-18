Para: B (conocimiento de C)
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG a/h11-p7-candado (cb8cbc88), PR 24
Estado: Abierto

# PR 24: suite completa limpia tras dos correcciones de pruebas

**Suite completa de GPOS.Tests en `cb8cbc88`:** 2260 aprobadas, 5 fallidas y 18 omitidas (2283). Las 5 fallas son las que ya existen en `feature/modelo-ng` (ver el aviso del PR 25).

## Correcciones (solo pruebas, producción sin cambios)
- **`c9a46eb9`:** `CandadoRestauracionApiTests.Restauracion_real…` esperaba que la vigilancia hiciera los respaldos posteriores. Desde SEC-H11-01 los hace `TrabajoRespaldosPosteriores`, así que la prueba procesa ahora esa cola.
- **`cb8cbc88`:** 8 pruebas HTTP de `ApiBusquedaFactory` respondían 503 `ESTADO_CANDADO_NO_DISPONIBLE`.
  - La fábrica usa la empresa `TEST` sin conexión resoluble, y el fallo cerrado de `3a3a6920` actuó como debe.
  - La fábrica ahora resuelve la conexión de su empresa: 8/8, 34/34 en sus 10 clases y 168/168 en Candado, Restauración y Arquitectura.
  - No es un defecto de producción: una sesión real siempre trae una empresa registrada.

## En curso
- **PDS-06** (rendimiento de 8.2 (5) y microprueba de 1.000 altas de borrador), con el agente de QA de A.
- **Después:** PR-2b rebasado sobre `c9a46eb9` (pruebas con SQL y PR), H-6 de aplicación y T3-12/RG-14.
