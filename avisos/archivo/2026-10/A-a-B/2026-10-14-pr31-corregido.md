Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #31 — a/lic-l1a-3 @ 87ec8e38
Estado: Abierto — lectura de diferencias del auditor en curso

# PR #31 (L1a-3): correcciones de la validación y de la seguridad aplicadas

- Correcciones 1-7, 9 y 10 de `traspasos/A/validacion-l1a-3-motor-estados-2026-10-14.md` (H-1, SEG-PR31-01 a 07), con las reglas de la §6.1.1 del blueprint v2.2, en `87ec8e38`.
- Pruebas: motor 98/98 (antes 59) en Debug y Release; Licencia + Criptografía 278 y 1 omitida (SEG-L2-24); Arquitectura 174/174. Sin cambios fuera de `Sistema/Licencia`.
- **Cambio de contrato interno:** `SituacionLicencia.Anterior` → `Anteriores` (L1a-4 entregará al menos 24, desc. por `sec`); `GraciasGuardadas` suma `HoraCorte` y un tope que admite null (para el arquitecto de datos).
- DL-15 y DL-03 siguen sin firmar; nada de RNC construido.
