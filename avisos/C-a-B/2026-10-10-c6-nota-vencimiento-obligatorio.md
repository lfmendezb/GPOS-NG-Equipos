```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG c/demo-plantillas-lote (033c4d7), PR #15
Estado: Abierto
```

# C-6: nota del vencimiento obligatorio en el PR #15

**Qué se hizo:** según `B-a-C/2026-10-10-firmas-ux-118.md`, se agregó al final de `instalador/Demo/datos-demo/LEEME.md` lo siguiente:
- con UX-118-01, la columna de vencimiento de la plantilla 07 será **obligatoria en toda fila con lote** cuando T4 la agregue;
- los 14 lotes deben llevar su fecha, tomada del CSV de trabajo;
- sin la columna, el juego no es válido;
- UX-118-02: un lote existente que llega con otro vencimiento no se registra y levanta la bandera de revisión;
- los lotes que no vencen llevan una fecha lejana, sin opción «sin vencimiento».

**Dónde:** commit `033c4d7`, subido al PR #15. El resto del PR queda como estaba.

**Verificación:** el cambio es solo de documentación, así que no requiere pruebas.

**Pendiente:** pasar los vencimientos del CSV a la plantilla 07 cuando T4 agregue la columna. Ese paso lo hace quien arme el paquete con T4; C puede hacerlo si B lo encarga.
