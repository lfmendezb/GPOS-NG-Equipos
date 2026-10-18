```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Avance, dictamen de seguridad y preguntas para el propietario (por tu conducto)
Prioridad: Alta (H-2 es un incumplimiento fiscal)
Repositorio y rama: GPOS-NG a/rg04-rg05-no-generar-comprobante (desde dec845c)
Estado: Abierto
```

# A-3 (RG-04 y RG-05): construido; seguridad «Aprobado con observaciones»

**Construido.** Casi todo ya venía de `6566f15` (PR #2): el privilegio `sincomprobante` en Especiales, la bitácora en `audit.Bitacora` y `_LOG`, el mensaje de RG-05 y la opción oculta sin el privilegio. A completó:
- el rechazo **422 `NO_GENERAR_SIN_PRIVILEGIO`**;
- las pruebas de la bitácora;
- una guarda de textos;
- bUnit y paridad en MAUI.

**Seguridad.** Ningún camino de venta, factura a crédito o POS emite sin comprobante si el usuario no tiene el privilegio. Los huecos están en la excepción de «origen sin NCF».

**A corrige ahora, porque aplica RG-04 tal como está firmado:**
- **H-1 (Media):** la **nota de débito** contra una factura sin NCF se emitía sin comprobante, **sin el privilegio y sin tope**: un canal de ingresos sin comprobante. Pasará a exigir el privilegio. La excepción queda solo para la devolución y la nota de crédito, que están limitadas por cantidades o saldo.
- **H-5:** `DENY UPDATE, DELETE` sobre `dbo._LOG` a `gpos_app`.
- **H-8:** reforzar la guarda de textos.

**Para ti o el propietario:**
- **H-2 (Media; es un incumplimiento fiscal):** las **facturas históricas importadas pierden su NCF**. Solo se guarda en `ventas.Venta.Referencia`, con el motivo H, y `NcfDocumento` lee únicamente `fiscal.Comprobante`. Por eso sus devoluciones y notas salen **sin B04 y sin el privilegio**, cuando debían modificar ese NCF. Hay dos remedios, de alrededor de 1 semana-persona:
  - registrar ese NCF como comprobante histórico (rol propio, sin secuencia);
  - o hacer que `NcfDocumento` caiga en `Referencia` cuando el motivo es H.

  Necesita un diseño del arquitecto-datos. ¿Lo encargas a A?
- **H-3 (Baja):** la importación histórica no tiene tope de fecha. Un ADMIN puede cargar ventas de hoy como «históricas», sin NCF y sin el rastro de RG-05. Propuesta: exigir una fecha anterior a la de implantación y dejar una línea en la bitácora por lote.
- **H-4 (Baja):** la base valida solo el motivo N; los motivos O y H no se comprueban. Es defensa en profundidad, de unas 0,5 semanas-persona.
- **H-6 y H-7 (Baja):** no se pide un motivo del usuario y los rechazos 422 no dejan un evento de seguridad.

**Preguntas para el propietario, con la opinión del auditor:**
1. ¿Algún perfil recibe el privilegio por omisión? **Recomendado: ninguno.** Hoy lo tienen solo el ADMIN y el SUPER; si un usuario lo necesita, se le asigna a él. Si se quiere que un supervisor habilite casos puntuales, conviene hacerlo como **autorización de supervisor (ADR-68) del tipo SIN_NCF, con motivo**, en lugar de dar el privilegio al perfil. Costo: unos 2 a 3 días-persona.
2. ¿Se mantiene la excepción «origen sin NCF»? **Recomendado: sí** para la devolución y la nota de crédito, **no** para la nota de débito (H-1), y solo después de corregir H-2.
3. ¿422 o 403? **Recomendado: 422**, porque es una regla del documento y no el acceso a la pantalla.

**Para la sincronización de sucursales (futura):** al recibir documentos de un nodo, volver a validar en la central que el usuario de origen tenía `sincomprobante`.

El PR se abre cuando estén H-1, H-5 y H-8.
