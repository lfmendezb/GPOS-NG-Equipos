```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Informe (segunda relectura de seguridad de PR-2 de ADR-90, sobre 0102cbca y 23176529)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/relectura2-seguridad-pr2-adr90-2026-10-22.md`
Estado: Abierto
```

# Segunda relectura de seguridad de PR-2: aprobado con observaciones

**Recomendación técnica (la unión la ordena el propietario, vía B):** unir #140 junto con #139, o antes. Sin hallazgos Críticos, Altos ni Medios. Solo lectura; no se compiló ni ejecutó nada.

- **R-01, R-03, R-04, R-05:** cerrados, sin regresiones. **R-02:** cerrado en lo pedido; la desviación de la API (solo se prohíben las vías globales) basta, porque `ReenvioReportes.cs:253` conecta por canalización con nombre a HTTP de loopback y comprueba el dueño.
- **S2-04 opción (b):** aceptable con el modo (la API solo escucha HTTPS y el DNS rebinding no llega). Sin modo (DEMO) el residuo es el de antes. Sigue pendiente la confirmación del propietario vía B.
- **Observaciones Bajas, para el PR siguiente:** R2-01 (la regla S6 de la API no controla qué se escribe en `Console.Error`: exigir solo `.Message`), R2-02 (ampliar el patrón a `\bSslStream\b` y `ServerCertificate\w*ValidationCallback`, y recorrer todo `src/`), R2-03 (informativa) y R2-04 (registrar la precisión de H-15 y el residuo sin modo en `ADR-090.md`).

**Suite oficial:** sobre `23176529`, 4937 correctas, 4 con error, 29 omitidas (aviso del 2026-10-22 aparte). Una de las 4 (`NumeracionMotorTests.CP103…1222`) la explica el diagnóstico de C (`ClearAllPools()` en paralelo, #153). **Sin explicar por ese diagnóstico:** `NumeracionBloqueosTests.Venta_factura_y_cierre_Z_simultaneos…`, `RendimientoOla4Tests.A1…` (venta de 9152 ms) y `NumeracionEmisionTests.El_cierre_Z_espera_el_bloqueo_explicito_de_su_cajero`; las tres pasaron al repetir sus clases solas (48 de 48). Conviene que C las mire con el mismo método.

Respuesta requerida: ninguna.
