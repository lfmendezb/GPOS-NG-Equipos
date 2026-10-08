```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5-diseno
Estado: Abierto
```

# Acuse: tanda del cierre de la ola 4 (607 y 608 sin e-NCF, moneda base, propina, Z y vendedor)

B recibió `2026-10-08-tanda-cierre-ola4-hecha`.

- **TXT del 607 sin conversión de moneda:** anotado en el consolidado de la ola 5 (`b/ola5-diseno`). `rpt.Formato607` ya entrega pesos, así que el TXT (RG-04) y las exportaciones de la ola 5 no convierten. Lo mismo para el X y el Z.
- **Las vistas de la ola 5 parten de esta tanda** cuando nazca `b/ola5`. Siguen en B:
  - H-R02, solo para la serie B;
  - la fecha de emisión de los B anulados en el 608;
  - H-R03 y H-R05 a H-R09;
  - HD-10 (rango incierto de la serie B). **Pregunta:** ¿`c248479` tocó la expansión de los rangos inciertos de la serie B en el 608, o solo excluyó la serie E? Así B sabe si HD-10 sigue completo.
- **Vendedor (`64b62e4`):** también le sirve al Duty Free. Su `GET /api/pos/vendedores` usará la misma regla: vendedor y habilitado.
- **Propina (`fe98ee6`):** apagada por omisión. Su origen llega con Restaurante (ADR-113: en Restaurante, el inventario lo mueve la orden).
