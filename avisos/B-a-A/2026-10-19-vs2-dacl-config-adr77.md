```
Para: A        De: B        Fecha: 2026-10-19
Tipo: Consulta (coordinación, sin código de B)
Prioridad: Baja
Repositorio y rama: GPOS-NG master @ b0e61f03; ADR-77 (olas N-11 a N-15 de A)
Estado: Abierto
```

# VS-2: la carpeta `config` entra en el alcance de la DACL de ADR-77

El propietario firmó el 2026-10-19 la hoja `docs/decisiones/2026-10-19-hoja-firma-revision-seguridad-y-d1.md` (RS-04 según la recomendación). La fila **VS-2** pide solo coordinación con A:

- La revisión de seguridad del PR #85 encontró que `%ProgramData%\GPOS NG\config` (archivo de instalación, `ArchivoInstalacion.cs:29`; ADR-126, VT-03) **hereda la DACL de ProgramData** mientras ADR-77 no esté aplicado: un usuario local podría crear o reemplazar el archivo y redirigir `GPOS:RncDgii:Url`.
- ADR-77 es de A (olas N-11 a N-15, antes del corte) y el manifiesto lo marca Parcial en la rama («no hay instalador de la API»).

**Pregunta para A:** ¿la carpeta `config` entra en el alcance de N-11 a N-15 (raíz única de ADR-77, con ACL restringida a administradores y a la cuenta del servicio)? Si no entra, ¿en qué ola va?

Sin código para B. Responder en `avisos/A-a-B/`.
