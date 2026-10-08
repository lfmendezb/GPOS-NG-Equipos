```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG master (24112b6); b/conector-admcloud-diseno (63e8eee)
Estado: Abierto
```

# Conector AdmCloud firmado: ADR-116 y ADR-117 en `master`; piezas del núcleo A-1 a A-16

El 2026-10-08 el propietario firmó la hoja del conector: **ADM-01 a ADM-14 aprobados; AC-33 según la recomendación.** Quedaron registrados en `master` (`24112b6`):
- **ADR-116,** el conector GPOS NG ↔ AdmCloud (ERP y e-CF);
- **ADR-117,** el núcleo común de conectores ERP;
- precisiones de **ADR-44** (diario de todo conector), **ADR-51** (firmado de AdmCloud, comprobante «pendiente de validación» con plazo de 72 h por verificar, contingencia solo explícita desde la central), **ADR-53** (la central es la puerta de lo que manda el ERP) y **ADR-73** (plan de B-5). La de 73.8 ya estaba.

**Mandan** las 28 respuestas del propietario: `docs/decisiones/2026-10-08-respuestas-propietario-admcloud.md`, también copiadas en `master`.

## Piezas del núcleo de A (después del corte, con T-29)
Esfuerzo inferido: **unas 1,0 sp para A-1 a A-16**, más A-11, que estima A.

| # | Pieza |
|---|---|
| A-1 | DDL de `integ.Correspondencia`, con el GUID externo por maestro y documento y `NodoOrigenId`. El nombre ya está reservado |
| A-2 | La sincronización de ADR-53 lleva la correspondencia: sube lo nacido en el nodo y baja lo de la central y lo del ERP |
| A-3 | Subida a la central de la conciliación y del resumen de envíos del nodo |
| A-4 | Origen de los maestros: los clientes, con llave del rango del nodo; **los artículos, servicios y precios, solo en la central**. El nodo consume lo que la central procesó (NC-12) |
| A-5 | Aplicadores de entrada de artículos, servicios, **precios de venta**, unidades y monedas con origen `ERP`, según los tres modos (del ERP, hacia el ERP o bidireccional; en este último gana el ERP). El alta manual queda bloqueada cuando el ERP es el dueño |
| A-6 | Evento `EstadoComprobanteCambiado` en el despachador de e-CF de T-29; la ventana se entera por SSE |
| A-7 | `IClienteConectores` en el rol `Sucursal`, con el espacio `Comun` separado de `Ecf` y `Erp` |
| A-8 | El validador de la licencia del nodo lee `CONECTOR_ERP`. La precisión de ADR-58 sigue por preparar |
| A-9 | Las precisiones ya registradas (73.8 y ADR-53) |
| A-10 | Estado del maestro frente al ERP en las pantallas y en la API. **Un maestro sin GUID se usa en la venta y el documento espera; el orden es maestro, luego documento** (NC-16 a) |
| A-11 | **Interruptor por empresa sin cálculo de costos** (aviso `opcion-sin-costos-precision`). El inventario se sigue llevando. Para encender o reencender el cálculo: **sin existencias negativas y con fecha de corte para el recálculo**. El propietario pidió además la opinión del especialista-contable de B, que está en curso; B avisará |
| A-12 | Transporte de los sobres sellados (cuenta única de AdmCloud sellada en cada nodo) por la sincronización |
| A-13 | Impresión **«pendiente de validación»** como componente compartido de las ventanas de cada vertical, cuando el firmado tarda más de 15 s o cae internet |
| A-14 | **Contingencia de e-CF habilitada solo desde la central**, con autorización previa de la DGII, y que baja a la sucursal elegida. Revisarla contra ADR-51 y T-29 |
| A-15 | **Bandera de descuadre:** si el cálculo de AdmCloud difiere de lo cobrado en más de **±RD$0,99**, no se firma y nada se anula. Dentro de la tolerancia, mandan los montos del e-CF firmado y la diferencia va como redondeo (CPA-01) |
| A-16 | **Cliente sin sincronizar en la emisión:** con la sincronización de clientes apagada, el cliente nuevo de caja no entra al maestro y va solo en la factura (nombre y RNC). Variante: se registra y la factura usa el GUID del cliente general de AdmCloud, con una advertencia |

**Anulación:** AdmCloud solo anula lo que rechaza la DGII. En ese caso se anula también en GPOS NG y se emite un documento nuevo con otro e-NCF (DS-01), coherente con P-04-a.

**R-01:** el conector depende de T-29; si T-29 se atrasa, el conector también.

**Siguen por confirmar con el propietario:**
- si los documentos de inventario se envían a AdmCloud;
- la regla de la factura con bandera y la de una factura que AdmCloud rechaza antes de firmar;
- la fecha de corte al apagar el cálculo de costos.

B avisará las respuestas.
