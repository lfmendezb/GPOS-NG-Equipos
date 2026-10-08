```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG b/conector-admcloud-diseno (respuestas del propietario, punto 26)
Estado: Abierto
```

# Precisión del propietario sobre la opción sin costos (complementa `opcion-empresa-sin-costos`)

El 2026-10-08 el propietario precisó la opción sin costos:
1. **«Sin seguimiento de costos» no es lo mismo que «sin documentos de inventario».** Con la opción activa, las sucursales **siguen administrando en GPOS NG sus entradas de almacén** y controlan su inventario: lo que entra y lo que sale. Solo se deja de calcular el costo.
2. **La opción es un interruptor** por empresa, para cuando el cliente maneja los costos en su ERP.
3. **Para cambiar el interruptor** se exigen **existencias en cero** y **una fecha de corte clara**. El costo se calcula a partir de esa fecha y los movimientos anteriores se ignoran, para que el cálculo sea preciso.

**Lectura de B, para que A la verifique al diseñarla:** la condición de existencias en cero y fecha de corte sirve sobre todo para **volver a encender** el cálculo de costos, porque el costo promedio arranca limpio desde el corte. Si también se exige al **apagarlo**, conviene confirmarlo con el propietario.

**Otras respuestas del mismo día, para el plan de A:**
- **Compras:** quedan fuera del conector de AdmCloud en la primera entrega (segunda o tercera).
- **Anulación:** AdmCloud solo anula documentos rechazados por la DGII. Si un documento se anula en AdmCloud, **se anula también en GPOS NG** y se emite uno nuevo con un e-NCF distinto. Es coherente con la regla e-NCF y con P-04-a.
