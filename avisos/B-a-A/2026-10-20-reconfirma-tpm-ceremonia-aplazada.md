```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Aviso (decisión del propietario; A actualiza su hoja)
Prioridad: Media
Repositorio y rama: hoja de A `traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md` (v2.13); ADR-61 y ADR-62 en master
Estado: Abierto
```

# El propietario reconfirma la firma Básica con TPM y aplaza la ceremonia

## Lo que dijo el propietario el 2026-10-20 (chat de la sesión de B)
- «Quiero que aplacemos la ceremonia de los yubikeys e inicialmente firmaremos con TPM en mi equipo según la recomendación, de modo que en esta primera y segunda entrega podamos avanzar sin demora». No cambia F-2, F-3, DL-10 (a), DL-11, DL-12 ni DL-13: los confirma y los extiende explícitamente a la **primera y la segunda entrega**.
- Hasta tener las cuatro YubiKeys, la firma de licencias sigue en nivel Básico con el TPM.
- Compró **una** YubiKey 5C FIPS (FIPS 140-3; firmware 5.7+ por confirmar al recibirla, hacia el 2026-11-03). Los ADR piden cuatro (`lic-a1`, `lic-b1`, `upd-a1`, `upd-b1`); faltan tres. Con la primera se puede **ensayar** la ceremonia (modo de ensayo de ADR-61, precisión del 2026-10-14); antes de la ceremonia real se reinicia el applet PIV.
- **AP-02:** titular, el propietario; custodio suplente, su socio (el nombre completo va en el acta). Quedó anotado en la hoja de B (PR #104) y en ADR-33.
- **DL-12, fecha de compra de las YubiKeys restantes:** el propietario aprobó «tras la segunda entrega» (propuesta de B, «Si, por favor»). La revisión de la aceptación sigue siendo a más tardar el 2027-03-31.

## Corrección de B
ADR-62, punto 5 de la precisión del 2026-10-14, dice que DL-10 a DL-13 «siguen sin firmar». Ya no es así: DL-10 (a) y DL-13 (a) del 14-oct, DL-11 (a) y DL-12 (a) del 15-oct. Se corrige el texto del ADR en `master` por separado.

## Lo que sigue pendiente (no se firmó hoy)
- **AP-04:** las aceptaciones escritas FY-15-B, R-L11-B, CP-4 y CP-5 siguen sin marcar; las firma el propietario, antes de la primera licencia de pago.
- **AP-03:** procedimientos adaptados al nivel Básico (devops con el propietario), antes de la primera licencia de pago.
- **CI-7 / AI-07:** consulta legal de las tres excepciones de solo consulta, antes del 2026-11-16.
- **AP-06:** contrato de suscripción, antes del primer cliente.
- **Condiciones técnicas:** DL-13 (devops verifica E-1 a E-15 antes de generar `s1`) y DL-14 construida.
- **DL-10 (a):** la reserva `s1r` necesita un segundo equipo con TPM; el propietario no ha dicho cuál.

## Qué hace A
Subir su hoja a v2.14 con esta reconfirmación y la fecha de compra de DL-12. Sin trabajo nuevo de construcción por esto.
