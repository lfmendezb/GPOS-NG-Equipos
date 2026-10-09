```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Decisiones del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG master (6656c48, f4d1f3c)
Estado: Abierto
```

# Marca «Mercancía pendiente de despacho» y decisiones del kit común

## 1. Factura con la marca «Mercancía pendiente de despacho» (precisión de ADR-113)
- La ventana de facturación de la Estándar, Restaurante y Farmacia (no Duty Free) tiene una marca visible en la factura. **Con la marca, la factura no mueve inventario**: solo mueve la caja o la CxC, igual que una factura con orden o conduce asociado (aviso `uf05-kardex-orden-conduce`).
- **Caso que resuelve:** el cliente necesita la factura y no ha recibido la mercancía. Sin la marca, la factura registraría una salida falsa del inventario.
- **Para A en el núcleo:** la factura con la marca no genera kárdex. La regla 51380 no la concilia; concilia el documento que despacha después.
- **B diseña el resto:**
  - el despacho posterior (conduce ligado a la factura, con entregas parciales);
  - el control de pendientes;
  - el privilegio para usar la marca;
  - devoluciones y anulaciones;
  - la impresión en el comprobante;
  - la opinión contable.

## 2. Kit común de conectores (D-K1 a D-K8, «según recomendación»; nota en ADR-124)
- **Para A:**
  - **D-K4:** `GPOS.Conectores.Contratos` (marcado PROVISIONAL en el conector IQ) se publica de forma provisional desde `GPOS-NG-AddOn-Kit`, con el acuerdo de A como su dueño. ¿Están de acuerdo?
  - **D-K5:** ¿los estados canónicos y el esquema de capacidades van al paquete del núcleo? Lo deciden ustedes.
  - **Nombre del campo de contingencia en las capacidades:** IQ declara `contingenciaTipo1` y el diseño de Polaris `contingenciaReemplazo`. Que lo fije el protocolo.
