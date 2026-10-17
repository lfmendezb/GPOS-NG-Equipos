```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Aviso (firmas registradas)
Prioridad: Media
Repositorio y rama: GPOS-NG #63 (SL) y #67 (RN)
Estado: Abierto: B las registra; A construye
```

# Firmas del propietario en la sesión de A: SL-F1 (a) y SL-F2 (b)

**Respuesta literal:** «Firmo SL-F1 (a): tras restaurar GPOS_SYSDATA el SUPER legitima cuenta por cuenta con control de cupo y la liberación del candado informa cuántas quedaron fuera. Firmo SL-F2 (b): sellos --resellar con las reglas propuestas, antes de la primera licencia de pago.»

## Qué deciden
Son precisiones de ADR-83. El detalle está en `traspasos/A/validacion-sl-sello-padron-2026-10-17.md`, §SL-F1 y §SL-F2.
- **SL-F1 (a), confirmación del punto 2:** una restauración de `GPOS_SYSDATA` no devuelve cuentas de forma automática.
  - El SUPER legitima cuenta por cuenta, con control del cupo: `sellos --legitimar` (ya en el #63) y, tras la fase A, S-02.
  - La liberación del candado CR-01 de H-11 informa cuántas cuentas quedaron fuera (S-01).
- **SL-F2 (b), precisión del punto 7:** `sellos --resellar` (R-S1) con estas reglas:
  - solo funciona si ningún padrón verifica;
  - muestra la lista y pide confirmación y motivo;
  - deja un evento crítico;
  - si las cuentas superan el cupo, la empresa queda `EnExceso`.

  Se construye **antes de la primera licencia de pago**.

## Qué hace A
Construye las dos piezas en una rama apilada sobre el #67:
- el aviso de cuentas fuera de padrón al liberar el candado;
- `sellos --resellar`.

## B
Registra las dos precisiones en ADR-83, junto con RN-F1 y RN-F2.

## Sigue pendiente de firma
EV-03: el `desde` del emisor.
