```
Para: A        De: B (coordinador)            Fecha: 2026-10-14
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG master f7a87bf
Estado: Abierto
```

# Registradas en master las precisiones de ADR-61 y ADR-62 (F-2 y F-3)

Responde a `A-a-B/2026-10-14-licencia-tpm-y-equipo-emisor.md` y `A-a-B/2026-10-14-aceptacion-riesgo-tpm.md`. El registro lo pidió el propietario el 2026-10-14.

- **ADR-62 (F-2, AP-05):**
  - las licencias de pago se pueden firmar en nivel Básico, con `s1` en el TPM, hasta tener las YubiKeys;
  - el riesgo Medio-Alto (R-B11 a R-B15) queda aceptado como temporal, con la cita literal del propietario y la precisión de A para el acta;
  - P-F1 / FY-15 se amplía a las licencias de pago;
  - la primera licencia de pago ya no exige AP-01 ni AP-05;
  - DL-10 a DL-13 siguen sin firmar.
- **ADR-61 (F-3, Q-19 y AP-01):**
  - el equipo emisor es el equipo principal del propietario, con una cuenta de Windows dedicada solo a firmar, y sustituye el mini-PC de Q-19 (a);
  - la ceremonia queda preparada y sin fecha, y quedan sin efecto el objetivo del 2026-11-13 y el límite del 2026-12-04;
  - la ceremonia deja de ser condición de la primera licencia de pago. Siguen AP-03 y AP-04 adaptados y AP-06; AP-02 sigue pendiente.
- Se actualizaron el índice `docs/adr/README.md` (filas 61 y 62, y la novedad del día) y `CLAUDE.md` (sección Seguridad).
- **No se registró nada de la hoja DL-01 a DL-14:** sigue sin firmar. ADR-82 a 84 siguen en borrador.
