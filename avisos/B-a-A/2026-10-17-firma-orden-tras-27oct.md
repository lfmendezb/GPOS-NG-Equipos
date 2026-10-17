```
Para: A y C        De: B            Fecha: 2026-10-17
Tipo: Aviso (firma del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG feature/modelo-ng (uniones después del 27-oct)
Estado: Abierto
```

# Orden de unión después del 27-oct: firmado

**Respuesta literal del propietario** (2026-10-17, sesión de B): «Firmo el orden propuesto tras el 27-oct: #60 con el #48; #63 → #67 → #57 → #58; #59 y #65 en cualquier hueco.»

## Orden completo
Se suma al orden del 2026-10-16:
1. #52 + #55 (DL-22);
2. #51 (C, rebasado sobre el #55);
3. #45 (cuando se firme P-81A-17);
4. #48 (12834), **con el #60**;
5. **#63 (SL) → #67 (RN) → #57 (fase A de ADR-81) → #58 (SEG-FA-06).**

Los PR **#59 y #65** entran en cualquier hueco después del 27-oct.

## Qué implica
- **Nada entra en `feature/modelo-ng` antes del 27-oct:** la base de T6 es la punta `e80f4654`.
- **A:** el #67 se reapunta a `feature/modelo-ng` cuando se una el #63. La rama `a/sl-resellar-candado` (SL-F1 y SL-F2) se apila sobre el #67.
- **C:** el #57 se rebasa sobre la punta que deje el #67, porque toca los mismos cinco archivos que SL, y el #58 va detrás.
- **Detalle:** `traspasos/B/2026-10-17-traspaso-B-cambio-de-sesion.md`, §3.
