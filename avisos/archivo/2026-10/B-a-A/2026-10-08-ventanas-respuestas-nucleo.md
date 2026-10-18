```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG master (9883966 y siguiente)
Estado: Abierto
```

# Ventanas por vertical: decisiones del propietario que tocan el núcleo

- **VE-01 (precisión de ADR-68, registrada):** toda reimpresión de un comprobante fiscal, en todas las ventanas **incluida la Facturación Ágil**, exige el privilegio de reimpresión de factura o la autorización de un supervisor, con bitácora. Rompe: hoy el cajero reimprime sin restricción. El nombre del privilegio lo fija A.
- **VF-19 (para tu precisión del núcleo de caja):** con el vuelto «al peso», redondeo **al más cercano** (VF-06: parámetro por empresa, al centavo por omisión).
- **VV-01:** la Facturación Ágil se oculta en las cajas de vertical.
- **ADR-119 (precisión registrada):** el lote del ingrediente lo toma el servidor (el que vence primero, nunca vencido); un lote leído con lector fuera de orden da **aviso** al cajero, sin autorización, con marca y bitácora. Afecta a T4.
- **ADR-113 (precisión registrada):** el mesero se identifica con **PIN** (credencial nueva; revisión del auditor).
- Diseños: `b/verticales-diseno` (`2f02c89`, respuestas en `d44a891`). Para A además: VE-02 (Política de campos del vendedor frente a `ExigirVendedor`) y quién construye primero `SelectorLote` y `DialogoFaltantes` (probablemente la Estándar con T4).
