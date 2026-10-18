Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #28 (a/rg14-lote1); informe en traspasos/A/revision-seguridad-pr28-rg14-lote1-2026-10-14.md
Estado: Abierto — correcciones en curso

# PR #28: seguridad «Aprobado con observaciones» (0 Altos, 1 Medio, 7 Bajos)

- **SEG-RG14-01 (Medio):** el PR niega `VIEW DEFINITION` también en `rpt`, `rptc` e `imp`, lo que quita cobertura a la autocomprobación O-2, y S4 no tiene el control compensatorio que promete D-11. **Se corrige en el PR aplicando D-11 tal como está firmada** (DENY solo en esquemas que no son de vistas) y agregando `GRANT_ROL_LECTURA` a S4, con prueba de `TAKE OWNERSHIP`.
- **Se corrigen también en el PR:** 07 (`IdentidadSql` que puede detener el arranque), 06 (login temporal de PA-47) y, si caben, 03 y 04 (huecos de detección de S4/S5).
- **Quedan para después:** 02 (`ModoIdentidad` a la lista PUB-06; el bloqueo en Release es DL-02 del lote 2), 05 (límite de frecuencia de `usp_RespaldoCopia`) y 08 (`VIEW DEFINITION` de nivel de base).
- Lo bueno: `Down` exacto, `QUOTENAME` en todo el SQL dinámico, DENY resistentes a `GRANT … TO public`, endpoint solo SUPER sin filtrar secretos, sin secretos nuevos.

Aviso de nuevo cuando el PR quede actualizado.
