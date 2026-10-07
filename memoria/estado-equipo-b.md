---
name: estado-equipo-b
description: Estado y aprendizajes del equipo B al cierre del 2026-10-07 (ola 3b firmada y unida; Backup Tool con N-01 construido; pendientes del propietario)
metadata:
  type: project
---

Cierre del equipo B (2026-10-07, nota `traspaso-B-2026-10-07-cierre.md`):
- **Ola 3b:** diseño firmado por el propietario (hoja `docs/decisiones/2026-10-07-hoja-firma-ola3b.md`) y unido a `feature/modelo-ng` por A (`7c7f5ad`). Clase 8 «Diferencia de transferencia» para pérdidas, sobrantes y sustituciones (H-3b-01); índice de nodo vigente para la entrega 2 (H-3b-02). Se construye en el orden de su sección 6 **después de unir la ola 4**; 12,3 sp; si la ola 4 compromete el corte, la 3b sale entera de la entrega 1 (OB-02).
- **Backup Tool:** ramas `fp01-clave-7zip` (`282de43`, verificación de FP-01, diseños, hoja firmada en parte) y `n01-bloqueo-subida-sin-llave` (`75455fc`, N-01 construido en dos entregas, ADR-0002, 168/168 pruebas). Firmados S-1, S-2 (la unión espera la indicación del propietario), BT-10 A, BT-10b, BT-11 a BT-15, ADR-0002. **Sin firmar:** fuente de carpeta (BT-01 a BT-09, ADR-0003, ADR-0004). La rama `r0-respaldos-gpos` que citan FP-01 y la hoja de seguridad no existe en `origin`. N-05: `.7z` creados por la entrada estándar sin `-scc` con contraseñas no ASCII solo abren sin `-sccUTF-8` (7-Zip 26.03).
- Aprendido: `ADR-073` estaba solo en `master` (A debe traer `master` a `feature/modelo-ng` tras cada registro de ADR). ADR-34 hace inmutable el código de usuario: la segregación por código (ADR-106) es segura.
- **Pendiente del propietario:** comparar el literal de `1bd735f` con la clave heredada real; L-1 a L-7 y K-1 a K-5 en cada instalación (ninguna base real a Drive antes de L-2); enviar al CPA la sección 7 de la hoja de la 3b (C-17, plazo de 10 años); indicar cuándo se unen las dos ramas de Backup Tool (2026-10-07: antes de unir, el equipo B hace una revisión con QA; esperar su resultado).

Relacionado: [[dos-equipos-a-coordina]], [[adjuntos-en-documentos]].
