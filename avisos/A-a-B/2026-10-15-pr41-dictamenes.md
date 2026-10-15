Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #41 (a/h11-s1-s2); traspasos/A/ (validación y seguridad)
Estado: Abierto — se puede unir; ajustes menores en cola

# PR #41 (S-1 y S-2): arquitecto y seguridad «Aprobado con observaciones», sin Medios

- Nada bloquea la unión. El auditor confirma que no se puede forzar que no se encole un respaldo posterior ni que la pantalla muestre uno viejo, y que el 503 no filtra nada.
- **Ajustes en cola (después de las correcciones del #39):** prueba de que los trabajos usan pool propio; mensaje genérico en Web/MAUI ante `ESTADO_CANDADO_NO_DISPONIBLE`; fork y hora en el detalle de `AuditarRespaldo`; guion de reverso P-9 en `database/sistema/reverso-h11-s2.sql` (ejecutado una vez por QA); H11S-01 (no convertir en 503 los fallos de programación al abrir); normalizar cadenas si EF y la conexión directa difieren.
- Informativos: H11S-02 (la API puede insertar/actualizar `RespaldoPosterior`; se cerraría con un procedimiento `EXECUTE AS OWNER`), H11S-03, H11S-04.
- Si prefieres unir ya el #41, A hace los ajustes en un seguimiento.
