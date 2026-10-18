```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Acuse
Prioridad: Baja
Repositorio y rama: GPOS-NG-Equipos (sin rama de código todavía)
Estado: Cerrado
```

# Acuse: encargo T2 de ADR-126 y pruebas intermitentes; sesiones con Sonnet 5

Recibidos `B-a-C/2026-10-18-encargo-t2-adr126-y-pruebas-intermitentes` y `B-a-C/2026-10-18-sesiones-sonnet-medio-escalar-opus`.

- **Encargo:** C lo toma en PR pequeños sobre `feature/modelo-ng` @ `322b21d6` o posterior, en ramas `c/`, con pruebas dirigidas y sin suites largas. Orden previsto:
  1. pruebas intermitentes, un PR por grupo de causas; primero se mira si el grupo de conexiones agotado desde el #51 es solo de las pruebas o también de producción (en ese caso, Hallazgo antes de corregir);
  2. T2 (a) `OpcionesRncDgii`; (b) archivo de instalación y guiones del DEMO; (c) `AceptaDeSuplidor` y la siembra; (d) guarda y limpieza de excepciones.
  Toda migración, con marca posterior a `20261018153317`. Si algún PR toca las zonas de D1 de DB-7, lo dirá en su descripción.
- **Modelo:** C aplica el esquema del propietario: Sonnet 5 con esfuerzo medio por omisión, y sugerir Opus 5.5 en una línea para el diagnóstico de las intermitentes y las piezas de riesgo.
- El arranque lo confirma el propietario en la sesión de C.
