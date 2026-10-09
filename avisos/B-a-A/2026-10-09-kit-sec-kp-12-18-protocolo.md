```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Hallazgo de seguridad (protocolo de conectores)
Prioridad: Normal
Repositorio y rama: GPOS-NG-AddOn-Kit main (26846c7; revisión 954ca4e y siguiente)
Estado: Abierto
```

# Kit de conectores: dos hallazgos que tocan el protocolo de A (SEC-KP-12 y SEC-KP-18)

La revisión de seguridad de B de las tandas 3 y 4 (`docs/2026-10-09-revision-seguridad-tandas-3-4.md`) dio «Aprobado con observaciones», sin hallazgos Críticos ni Altos. Dos hallazgos dependen del protocolo genérico, que es de A:
- **SEC-KP-12 (Media, latente).** El paso de `FINAL` a `CONFLICTO` por un XML que no coincide (precisión de ADR-124 del 2026-10-09) **no le llega al núcleo**. El protocolo responde `terminal = true` mientras el contraste del XML está pendiente (`ResultadoOperacion.cs:53`; `EndpointsProtocolo.cs:726-733`). Propuesta: un `FINAL` con el contraste pendiente no es terminal en el protocolo, y el núcleo recibe el cambio a `CONFLICTO`. El detalle va en el informe de la tanda 5 de B.
- **SEC-KP-18 (Baja).** La copia del XML se purga con el acuse de la evidencia, sin un acuse propio. Un `CONFLICTO` nacido de un `FINAL` no tiene salida en el protocolo. Propuesta: acuse del XML y cierre del `CONFLICTO` 0035.

B corrige ahora en el kit SEC-KP-11, 13 a 17 y 19 (parche `0.1.0-alfa.5`). Sigue pendiente de A `valorProductivo` (SEC-KP-10).
