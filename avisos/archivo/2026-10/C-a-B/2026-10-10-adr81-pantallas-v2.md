```
Para: B (copia a A)            De: C            Fecha: 2026-10-10
Tipo: Entrega | Pregunta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/adr81-fase-a-diseno (1e0d62c)
Estado: Abierto
```

# Pantallas de la fase A de ADR-81, versión 2: alineadas con el blueprint v3

Completa `C-a-B/2026-10-10-adr81-blueprint-v3-pc1-c1.md`. Es solo diseño.

**Dónde:** `docs/ux/2026-10-10-adr81-fase-a-pantallas.md`, en `1e0d62c`.

## Qué cambió
- **Precisión C-1 (UX-V-01):** el motivo es **`factor`** y el cliente decide solo por el encabezado `X-GPOS-Sesion`.
  - Ese 401 abre **P6 «Confirmar su Identidad» sin cerrar la sesión**, igual que `REAUTENTICAR`, con un texto de entrada propio para cada caso.
  - Tras el código, la acción se repite **una sola vez**. Si vuelve a dar 401 `factor`, se cierra la sesión y se va al inicio con el motivo `factor`. Si se cancela, la sesión sigue.
  - **P10** tiene ahora una tabla con las respuestas que cierran la sesión y las que no.
  - **El visor de reportes** reutiliza `DialogoConfirmarIdentidad` y P16, sin diálogos propios.
- **P-81A-14 (pendiente de firma; el diseño sigue la opción a):** flujo 3.3b y **P16 «Verificación en Dos Pasos Requerida»** (`DialogoFactorRequerido`).
  - **Se abre** con el 401 `factor` a un SUPER sin factor activo (según `GET /api/auth/factor`) o con el 409 `ALTA_REQUERIDA`.
  - **Es un modal** que no se cierra con Esc y tiene un solo botón, [Ir al inicio de sesión]: llama a `/salir` y abre el inicio con el motivo `alta` («tenga a mano su teléfono»). Después sigue el alta de P-81A-10.
  - Si se firma la opción (b), P16 se sustituye por un asistente de alta dentro de la sesión.
- **Restauración del Sistema (PC-1 a):** P15 marca lo que agrega C:
  - el aviso P-D81-01 con [Generar códigos nuevos];
  - la fila `SuperConFactor`, con advertencia si hay menos de dos SUPER con factor;
  - P6 al pulsar [Liberar el Sistema], conservando el motivo.
- **Textos definitivos para A (que construye esas pantallas):** **P13**, la franja «Sistema restaurado», y **P14**, el usuario que no es SUPER e intenta entrar con el candado activo.
- **Otros cambios:**
  - P6 pide también la contraseña con un código revivido (`CLAVE_REQUERIDA`) y P7 avisa de esos códigos;
  - avisos nuevos al entrar: P5e (reloj desfasado) y P5f (sistema restaurado);
  - UX-81A-01 a 08 quedan como firmadas y D-01 a D-07 como incluidos en el contrato.

## Para A (vía B): una confirmación
**P14:** ¿qué pasa con un usuario que no es SUPER y **ya estaba conectado** cuando se activa el candado? C siguió el diseño de A: conserva la sesión, ve la franja y sus peticiones reciben 503. Hay que confirmarlo con A antes de que una su pantalla.

## Pendiente
- **P-81A-14:** firma del propietario antes de T7.

**Estado de C:** C-10 (compra) sigue en curso.
