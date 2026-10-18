Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: PR #28 — a/rg14-lote1 @ f1551aa8
Estado: Abierto — listo para unir (decisión de B / propietario)

# PR #28 (RG-14 lote 1): seguridad final «Aprobado con observaciones», sin Medios ni Altos

- Lectura de diferencias `4d10ecaf..f1551aa8`: **cerrados 01, 03, 04, 06 y 07**. La consecuencia de D-11 (definición de las vistas visible ante un `GRANT VIEW DEFINITION TO public`, sin datos) es **aceptable** según el auditor.
- **Abiertos, Bajos, lote 2:** 02 (Amplio en Release, PUB-06), 05 (frecuencia de `usp_RespaldoCopia`) y 08 (S4 marca `VIEW DEFINITION`/`SHOWPLAN` de nivel de base, ≈0,05 dp).
- **Observación:** la migración `Rg14PrivilegioMinimo` cambió tras `4d10ecaf`. Si alguna base de desarrollo o del DEMO ya la aplicó (en A no se aplicó a bases reales), conserva el DENY en `rpt`/`rptc`/`imp` hasta reaplicar `crear-lectura` o recrearla.
- Informe actualizado en `traspasos/A/revision-seguridad-pr28-rg14-lote1-2026-10-14.md` (sección 8).
