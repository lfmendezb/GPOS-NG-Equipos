```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Solicitud
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos memoria/
Estado: Abierto
```

# Memoria común: dos archivos nuevos que pide registrar el propietario

El propietario pidió el 2026-10-08 registrar en la memoria común sus dos decisiones del día. Como `memoria/` es solo de A (y la publicación de A la sobrescribe), B entrega los archivos listos: **cópienlos tal cual** a la memoria local de A y a `memoria/`, agreguen las dos líneas a `MEMORY.md` y publiquen. Sustituyen el texto propuesto en `2026-10-08-prioridad-ventas-inventario.md` y `2026-10-08-prioridad-precision.md`.

Conviene además ajustar la frase final de `ecf-no-se-anula.md` («de momento solo se usa el 606 para ellos») con «el 606 también está aplazado como archivo (ver reportes-fiscales-aplazados)».

## Líneas para `MEMORY.md`
```
- [prioridad-ventas-inventario](prioridad-ventas-inventario.md) — 2026-10-08: núcleo = POS operativo con sus verticales, ventas e inventario; lo demás se agrega por etapas
- [reportes-fiscales-aplazados](reportes-fiscales-aplazados.md) — 2026-10-08: 606, 607, 608 y apoyos IT-1/IR-17 aplazados (los tiene el ERP); la emisión NCF/e-CF y el Z no se aplazan
```

## Archivo `prioridad-ventas-inventario.md`
````markdown
---
name: prioridad-ventas-inventario
description: Directriz del propietario (2026-10-08): lo principal es el POS operativo con sus verticales, ventas y control de inventario; lo demás se agrega por etapas
metadata:
  type: feedback
---

El 2026-10-08 el propietario pidió concentrarse en lo más importante de GPOS NG: **ventas y control de inventario**. Precisó enseguida: **el POS y sus verticales deben estar operativos**; lo demás (reportes adicionales, integraciones, análisis, etc.) **se agrega paulatinamente según se completa cada etapa**.

**Why:** el núcleo que vende el producto es vender (en cada vertical) y controlar existencias; lo accesorio dispersaba el esfuerzo.

**How to apply:**
- Primero lo que hace funcionar o hace confiable la venta y el inventario: POS y ventanas de facturación de cada vertical, facturación, NCF y e-CF, existencias, costos, traslados, conteos. Las verticales NO son secundarias.
- Reportes y funciones complementarias: se agregan por etapas, al cerrar cada una, no se meten de golpe en la ola en curso.
- Defectos que afecten la venta o la existencia (p. ej., existencia por lote con negativos) van antes que funciones nuevas.
- Al presentar pendientes, separar núcleo (POS, verticales, inventario) de lo complementario.

Relacionado: [[siguiente-paso-pc-b]], [[dos-equipos-a-coordina]], [[ventana-facturacion-por-vertical]].
````

## Archivo `reportes-fiscales-aplazados.md`
````markdown
---
name: reportes-fiscales-aplazados
description: Decisión del propietario 2026-10-08: se aplazan los reportes fiscales (606, 607, 608, apoyos IT-1/IR-17); los tienen los ERP; el 606, que es el único que hoy se usa, también queda aplazado
metadata:
  type: project
---

El 2026-10-08 el propietario aplazó los **reportes fiscales** a una etapa posterior al corte de la entrega 1: archivos 606, 607 y 608, apoyos del IT-1 y del IR-17, pruebas de cuadre fiscal y, en Duty Free, el RZC-01 y el detalle a la DGII. Precisión registrada en ADR-111 (`d87040b` en `master`).

**Why:** «todos tienen su par en los sistemas ERP»; con el e-CF, el 607 y el 608 no llevan e-NCF y hoy solo se trabaja con el 606, que el ERP también genera. El propietario cree posible que en 2027 el 606 y el 607 sean inútiles. Aplica [[prioridad-ventas-inventario]].

**How to apply:**
- No invertir en formatos fiscales hasta la etapa fiscal; lo que ya existe en el código (p. ej. `rpt.Formato607` con H-R01) se conserva sin más trabajo.
- **No se aplaza** lo que es parte de la venta: emisión con NCF y e-CF, secuencias, Z y cierre de caja, montos del comprobante en moneda base (E1-2), reportes de ventas e inventario, evidencia de exportaciones y `rptexportar`. Las compras, CxP y retenciones se siguen registrando; solo el archivo 606 se aplaza (confirmado por el propietario).
- La etapa fiscal empieza por verificar con la DGII qué formatos siguen vigentes.
- Riesgo: un cliente sin ERP necesitaría los formatos de otra fuente; antes de implantarlo, reabrir la etapa fiscal.

Relacionado: [[ecf-no-se-anula]], [[contabilidad-ligera-erp-externo]].
````
