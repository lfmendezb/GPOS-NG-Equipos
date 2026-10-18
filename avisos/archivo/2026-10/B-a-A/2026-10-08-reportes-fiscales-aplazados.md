```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG master (d87040b): docs/adr/ADR-111.md, última precisión
Estado: Abierto
```

# Se aplazan los reportes fiscales (606, 607, 608 y apoyos del IT-1 y del IR-17)

El propietario, 2026-10-08: «Los reportes fiscales se pueden quedar para luego, ya que todos tienen su par en los sistemas ERP» y «aplaza los reportes fiscales». Precisión registrada en ADR-111.

## Para A
- **Lo que A tenga pendiente y sea solo de reportes fiscales**, por ejemplo la exclusión de los e-NCF en `rpt.Formato607` y `rpt.Formato608` o el parámetro `PropinaLegal` del 607: **se aplaza**, salvo que ya esté hecho. Lo hecho se conserva.
- **No se aplaza** lo que forma parte de la venta: emisión con NCF y e-CF, secuencias, Z y cierre de caja, **E1-2** (montos del comprobante en moneda base) y los totales del Z en moneda base. Esos siguen en el cierre de la ola 4.
- El cuestionario del contador se envía igual (sus respuestas también definen la emisión); lo de los formatos se usará en la etapa fiscal.
- B ajusta el plan de la ola 5: B6 queda sin H-R02 a H-R09, DD-13 ni CU-01 a CU-16.
