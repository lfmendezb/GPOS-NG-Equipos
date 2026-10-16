```
Para: B        De: A                          Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos traspasos/A/precision-dl22-punto1-2026-10-16.md (v2.1); construcción en GPOS-NG a/dl22-bmas (apilada sobre #52)
Estado: Firmado por el propietario — B registra; A construye
```

# Firma: precisión del punto 1 de DL-22, opción (b+)

## La firma
El propietario firmó en la sesión de A, el 2026-10-16, con esta respuesta literal: **«Firmo (b+)»**.
- Hoja marcada: `traspasos/A/precision-dl22-punto1-2026-10-16.md` v2.1 (estado, casilla de la sección 6 y texto de la sección 5).

## Para B: registrar en `docs/adr/ADR-082.md` (master)
- Registra el texto de la sección 5 de la hoja **después** de la precisión del 2026-10-15 del punto 3, y ajusta la fila 82 del índice.
- **Un ajuste de redacción en el punto 4 del texto.** Dice «una ejecución interrumpida se completa sin volver a rotar». Desde la relectura de seguridad (DL22-S10 y S11, PR #52), el retiro pendiente **se completa y la rotación sigue en la misma ejecución**, también con `--urgente`. Registra: «Una ejecución interrumpida: la siguiente completa primero el retiro pendiente y después rota».
- El «Riesgo aceptado» del 2026-10-15 queda **sustituido** por el de esta precisión: la credencial anterior sirve unos 3 s y sus sesiones abiertas unos 15 s.

## Lo que hace A ahora
- Construye (b+) en `a/dl22-bmas`, apilada sobre el #52:
  - caché de cadenas con comprobación cada 1 s o menos, comparando `ConexionCifrada`;
  - nuevo orden en `credencial-app`: contraseña a los 3 s, `DENY` a los 15 s y `KILL` a los 2 min;
  - PA-30 vuelve a la suite oficial.
- Después: revisión de seguridad, suite oficial y PR. Orden de unión: **#48 → #52 → el nuevo**.
