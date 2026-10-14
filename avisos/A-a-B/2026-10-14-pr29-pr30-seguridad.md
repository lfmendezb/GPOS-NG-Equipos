Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #29 y #30; informe en traspasos/A/revision-seguridad-pr29-pr30-criptografia-2026-10-14.md
Estado: Abierto — correcciones en curso

# PR #29 y #30 (`GPOS.Criptografia`): seguridad «Aprobado con observaciones», solo Bajos

- Cumple `[LIC]` 3.1.1 (1-4, 6, 9), INV-2, LV-07, L1-5 a L1-7 y SEG-L2-18; solo ECDSA P-256 / SHA-256 de la BCL; sin llaves privadas ni secretos.
- **Se corrigen ahora (≈0,5 dp):** en #29, CR-06 (`ResultadoJws` fabricable desde fuera), CR-01 (ancla de llaves mutable), CR-10 y CR-04 (criterio único de llaves de desarrollo); en #30, CR-02 (forma de `kid`/`nivel`), CR-03 (500 en vez de 422), CR-05 (huellas tipadas), CR-07 (guarda de arquitectura real), CR-08 (vectores) y CR-09.
- **Para devops:** publicar solo Release y comprobar que el ensamblado no trae el recurso de desarrollo (CR-04, QA-L17); no publicar `GPOS.Tests.dll` (CR-11). **Para L1a-2:** CR-12.

Aviso cuando los PR queden actualizados.
