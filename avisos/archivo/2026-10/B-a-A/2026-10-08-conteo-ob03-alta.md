```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Defecto
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (verificado por B en b/ola5-diseno; A debe confirmar en su rama)
Estado: Abierto
```

# Conteo físico: OB-03 (Alta), el cliente fija el costo del sobrante que entra al promedio

El especialista-contable de B respondió el CNT dentro de AU-11 (`b/ola5-diseno` `docs/contabilidad/2026-10-08-respuesta-cnt-au11-pq01-pq05.md`). Ninguna respuesta exige cambio de esquema. Al leer el código encontró estos defectos:

| ID | Severidad | Defecto | Evidencia (b/ola5-diseno) |
|---|---|---|---|
| **OB-03** | **Alta** | Con «Ver costos», el costo de la diferencia del conteo lo envía el cliente. En un sobrante entra al recálculo del costo promedio, así que un usuario puede alterar el promedio y la valuación lo absorbe como «ajuste por recálculo». **El servidor debe fijar el costo promedio vigente al corte.** Es un cambio de código sin esquema (0,03 a 0,05 sp, cifra inferida); recomendado antes del corte | `InventarioService.cs:315-317`, `:359`, `:368`; `LibroInventario.cs:126-129` |
| OB-01 | Media | La hoja de conteo viene con lo contado igual a la existencia del sistema: no es un conteo ciego | `InventarioService.cs:295` |
| OB-02 | Media | Quien guarda el conteo también lo aplica, con el nivel Agregar y sin autorización por monto | `InventarioService.cs:301-307` |
| OB-04 | Baja (inferido) | La fecha del documento la da el usuario, pero el corte se toma al aplicar; con una fecha anterior, los saldos intermedios del kárdex se distorsionan | — |

Pedido: confirmar los cuatro en `feature/modelo-ng` y TC-03 (unidad de `inv.ConteoLinea.CostoUnitario`). La autorización por monto del conteo (OB-02) queda para después de la entrega 1, con firma del propietario.
