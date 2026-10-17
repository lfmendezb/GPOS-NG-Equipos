```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Aviso (firmas registradas)
Prioridad: Media
Repositorio y rama: GPOS-NG a/sl-resellar-candado (SL-F1/SL-F2, en corrección)
Estado: Abierto: B las registra
```

# Firmas del propietario en la sesión de A: SLF-01 y el acta firmada por GSF

**Respuesta del propietario.** La eligió con el botón de su sesión; el mensaje llegó cortado a 300 caracteres, y este es el texto completo de ese botón:

«Firmo la precisión de ADR-83 punto 7 (SLF-01): --resellar se niega si Licencia.SelloInicial verifica, o si falta y hay alguna licencia aceptada, y reescribe SelloInicial con origen RESELLAR. Firmo también que, antes de la primera licencia de pago, el acta del resellado sea una autorización firmada por GSF ligada a la instalación y que el resellado se reporte a GSF en L-06/L-07.»

## Qué deciden (precisiones de ADR-83, punto 7)

### 1. SLF-01
La revisión de seguridad de SL-F1/SL-F2 lo calificó Media.
- **Riesgo:** sin esta regla, quien tenga el anillo podría destruir los dos padrones y resellar. Así legitimaría cuentas creadas por SQL o recuperaría el cupo después de una reducción.
- **Regla:** `--resellar` se niega si `Licencia.SelloInicial` verifica, o si falta y hay alguna licencia aceptada.
- **Además**, reescribe `SelloInicial` con el origen `RESELLAR`.
- **Dónde:** se construye en el PR de SL-F1/SL-F2.

### 2. Acta firmada por GSF
**Antes de la primera licencia de pago:**
- el acta del resellado pasa a ser una autorización firmada por GSF y ligada a la instalación;
- el resellado se reporta a GSF en L-06/L-07.

El auditor lo estima en unos 0,85 dp. Hay que planificarlo.

## Informes
- `traspasos/A/validacion-sl-f1-f2-2026-10-17.md`: Conforme con correcciones.
- `traspasos/A/revision-seguridad-sl-f1-f2-2026-10-17.md`: Aprobado con observaciones.

## Para B
- Registrar las dos precisiones en ADR-83.
- Ubicar el acta firmada por GSF en el plan, antes de la primera licencia de pago. Toca a L, al emisor y a I.
