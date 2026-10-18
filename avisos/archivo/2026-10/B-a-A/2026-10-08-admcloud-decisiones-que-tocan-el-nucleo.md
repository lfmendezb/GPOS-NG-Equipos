```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG master (bb6207b, a12e9eb); b/conector-admcloud-diseno (4a45237)
Estado: Abierto
```

# Conector AdmCloud: decisiones del propietario que tocan el núcleo de A, y dos registros en `master`

Las decisiones están en `docs/decisiones/2026-10-08-respuestas-propietario-admcloud.md`, rama `b/conector-admcloud-diseno`: 25 puntos que mandan sobre los diseños. El arquitecto-maestro de B está preparando la hoja de firma del conector. **Se construye después del corte.**

## 1. Registrado en `master` (para que A lo traiga a `feature/modelo-ng`)
- **`bb6207b`: precisión de la cláusula 73.8 de ADR-73, firmada.** En una empresa con sucursales en modo nodo, **cada nodo publica directo al ERP** con su conector. La central publica lo suyo y lo de las sucursales en línea, y nunca reenvía lo publicado por un nodo (se distingue por el nodo de origen del documento).
- **`a12e9eb`: precisión de DO-02 en ADR-115.** Mientras el ADMIN sea global, el número completo del pasaporte **solo lo ve el SUPER**.

## 2. Decisiones que afectan al núcleo
1. **Maestros con ERP: solo la central sincroniza artículos y servicios**, tanto contra el ERP como hacia los nodos. Los nodos consumen lo que la central procesó, y el alta local de artículos y servicios se bloquea cuando el ERP es el dueño.
2. **La llave del vínculo es el GUID del ERP, no el código.** Si el ERP cambia un código o SKU, el vínculo sigue y el código propio de GPOS NG no cambia (sigue siendo inmutable).
3. **Dirección de la sincronización de artículos y servicios, parametrizable:**
   - del ERP a GPOS NG;
   - de GPOS NG al ERP;
   - bidireccional, pasiva o a demanda; si un mismo registro cambia en los dos lados, **gana el ERP**.

   Además, **los precios de venta** de artículos y servicios **entran desde el ERP**, lo que toca las listas de precios por sucursal.
4. **Interruptor por tipo de maestro y de documento:** si está apagado, ese tipo no se sincroniza. **Si las facturas se sincronizan y los clientes no**, el cliente nuevo de caja **no se registra en el maestro** de GPOS NG: va solo en la factura con su nombre y su RNC, como ya hace la Facturación Ágil.
   - **Variante admitida:** registrarlo igual en GPOS NG; si no tiene GUID, la factura usa el GUID del cliente general de AdmCloud y muestra una advertencia.
5. **Un maestro creado en GPOS NG sin GUID se puede usar en la venta.** El documento espera para publicarse, y el orden es siempre: **primero el maestro, después el documento**.
6. **e-CF:**
   - si el firmado tarda **más de 15 s** o cae internet, la ventana ofrece imprimir un comprobante **«pendiente de validación»**;
   - **la contingencia nunca es automática:** se hace solo de forma explícita, con autorización previa de la DGII por la Oficina Virtual, **se habilita únicamente desde la central y baja a la sucursal elegida**;
   - este punto puede tocar el diseño general de la contingencia (ADR-51 y T-29). **Pedimos a A revisarlo.**
7. **Inventario:** el de GPOS NG es independiente del ERP. Ya se avisó en `opcion-empresa-sin-costos`, con la **opción por empresa para omitir el cálculo de costos**.
8. **Credenciales:** hay **un único usuario global** de AdmCloud, sellado en cada nodo para que conserve su independencia operativa. AdmCloud obliga a cambiar la contraseña **cada 90 días**; el cambio se hace en la central y llega sellado a los nodos, sin intervención en las sucursales.

## 3. Para el plan de A
- Las piezas A-1 a A-10 (aviso `admcloud-piezas-para-el-nucleo`) siguen vigentes. A esas se suman:
  - la **entrada de precios** desde el ERP;
  - el **interruptor por tipo**;
  - la regla de los **clientes sin sincronizar**;
  - la **contingencia habilitada desde la central**.
- B le confirma la lista definitiva cuando el propietario firme la hoja.
- **Alcance de la primera entrega del conector:**
  - **maestros:** artículos, servicios, precios de venta, unidades de medida, monedas y clientes;
  - **documentos:** cotizaciones, pedidos, facturas, notas de crédito y débito, devoluciones y recibos;
  - **e-CF por AdmCloud.**

  **Quedan fuera:** suplidores, compras, pagos y el costo de ventas cuando el ERP lleva el costo.
