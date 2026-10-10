```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega | Pregunta
Prioridad: Alta
Repositorio y rama: GPOS-NG c/adr118-119-ux (e0a05a0)
Estado: Abierto
```

# C-5, revisión 2: pantallas del lote ajustadas a las firmas (UX-118-01 a 05, F-1 y F-1b)

Responde a `B-a-C/2026-10-10-firmas-ux-118.md` y `B-a-C/2026-10-10-firmas-c5-c7.md`. Solo es diseño.

**Dónde:** `docs/ux/2026-10-10-adr118-119-pantallas.md` y el prototipo, en `c/adr118-119-ux` (`e0a05a0`).

**Verificación:** las afirmaciones sobre el código se revisaron contra `109aae0`. Los tiempos de captura son inferidos, sin medición.

## Qué cambió
- **UX-118-01 (vencimiento obligatorio):**
  - Un solo control, «Lote y vencimiento», en la entrada, la factura de compra y el ajuste de entrada. Se validan juntos con un solo mensaje y se muestran juntos («L-2501 · vence 31/05/2027»).
  - Al leer el lote con el lector, el foco pasa al vencimiento; la fecha se puede teclear con 8 dígitos seguidos.
  - Se quitó todo rastro de «opcional».
  - **Ayuda para los lotes que no vencen:** «Si el producto no vence, indique una fecha lo bastante lejana para que no le afecte, según la cantidad que recibe y lo que tarda en venderla.» No hay opción «sin vencimiento» ni fecha precargada.
- **UX-118-02 (bandera de revisión):**
  - **Quien recibe nunca ve ni recibe precargada la fecha registrada de un lote existente**; si la viera, la copiaría y la comparación no detectaría nada.
  - El servidor compara al guardar, rechaza con `LOTE_VENCIMIENTO_DISTINTO` y registra la bandera aparte, para que quede aunque el documento no se guarde.
  - Quien recibe ve el diálogo «Lote en Revisión», solo con «Aceptar»; el renglón queda bloqueado y solo se puede quitar.
  - Pantalla nueva **Inventario › Revisión de Lotes**: contador de abiertas en el menú, detalle de cada revisión y «Resolver Revisión» con motivo.
- **UX-118-03 a 05:** marcadas como firmadas.
- **F-1 y F-1b:**
  - La casilla «Requiere lote» **ya existe** en la ficha Web y MAUI (`Articulos.razor:114`) y en la plantilla (`Importaciones.cs:218`). Pasa a un grupo «Control de inventario» con ayuda visible; en los servicios queda deshabilitada.
  - La plantilla de existencias gana la columna **«Vencimiento»**.
  - Una fila sin lote de un artículo que lo exige pasa a ser **error**; hoy solo avisa (`ImportacionExistencias.cs:149`).
  - Una fila con lote de un artículo que no lo exige también es error.

## Esfuerzo (±40 %)
- **Interfaz:** 0,9 a 1,25 semanas-persona en T4 y T2; antes eran 0,45 a 0,6.
- **Servidor (orientativo):** bandera 0,3 a 0,5; vencimiento obligatorio 0,1 a 0,15; reglas de «Requiere lote» 0,05 a 0,1.
- **Riesgo para el 22-oct:** T4 crece unas 0,9 a 1,4 semanas-persona. El rechazo de la línea con su bandera no se puede aplazar; la pantalla de revisión puede salir primero como lista mínima.

## Para el arquitecto de B
- **Imprescindibles:**
  - F-3: vencimiento obligatorio al crear el lote.
  - F-10: bandera (rechazo, registro aparte, consultas y resolución).
  - F-6: marca de fuera de orden.
- **F-4:** responde solo si el lote existe, **sin su vencimiento**.
- **Resto:** F-2, F-5, F-7 a F-9 y F-11 a F-13 están en el documento.

## Preguntas nuevas al propietario (cada una dice qué construir mientras no se firme)
| # | Pregunta | Recomendación |
|---|---|---|
| **UX-118-06** | Cómo se resuelve una revisión | El encargado cierra con una de tres resoluciones y motivo: «el registrado es correcto», «corregir el vencimiento del lote» (avisando cuántas unidades afecta) o «es otra mercancía, con otro código de lote». Cerrar no crea movimientos |
| **UX-118-07** | Qué pasa con el resto del documento | En la entrada y el ajuste se quitan los renglones en revisión y se guarda el resto. La factura de compra no se guarda sin el renglón, para que su total coincida con la del suplidor |
| **UX-118-08** | Quién es el «encargado de inventario» | Privilegio nuevo «Revisión de lotes» (precisa ADR-11), por omisión para el ADMIN y quien tenga «Ajustes de inventario», más un evento de notificación por correo |
| **UX-118-09** | Cambiar «Requiere lote» en un artículo con movimientos | Marcarla se rechaza si hay existencia sin lote; desmarcarla se rechaza si algún lote tiene existencia; la devolución de una venta anterior sin lote pide lote y vencimiento |

**Pendiente:**
- la firma de UX-118-06 a 09, conviene antes del 15-oct;
- la confirmación del especialista POS de que quien recibe no vea la fecha registrada (Farmacia y Duty Free).
