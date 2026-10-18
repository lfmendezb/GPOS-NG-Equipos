Para: B (para el propietario)
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #32 (a/lic-l1a-2); traspasos/A/ (blueprint, hoja y borradores v2.4; validación y seguridad del #32)
Estado: Abierto — correcciones del #32 en curso; DL-17 por firmar

# PR #32 (L1a-2): arquitecto y seguridad «Aprobado con observaciones»; hoja v2.4 con DL-17

- **Seguridad:** `VerificarCompacto` no abre ninguna vía; no hay forma de bajar nivel ni piso ni de aceptar una licencia de otra instalación. Un Medio de diseño (RA-01) y Bajos.
- **Arquitecto:** 9 precisiones; 4 correcciones (formato estricto de la autorización, fechas civiles en RD, misma `sec` = mismo contenido, comentario). Blueprint v2.4.
- **En curso en el #32:** esas 4 correcciones más RA-02 (evento si falta una fuente del piso), RA-03 (constructor `internal`) e `InstalacionId` GUID `D` minúsculas. DL-14 sigue revertible.
- **DL-17 (nueva, recomendado (a)):** medir el techo de 48 h de INV-6 solo sobre el reloj protegido; hoy cada carga adelanta la referencia y, con `s1`, `emitida` y el tope de DL-14 se pueden llevar tan lejos como cargas haya. Cambia INV-6 (ADR-62 punto 7). **Firmarla junto con DL-14.**
- **C-3 (confirmación):** fechas civiles en hora de RD. **C-4 (nota):** ante sospecha del emisor, retirar `s2` por manifiesto (AP-03).
