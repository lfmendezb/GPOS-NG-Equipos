```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng (cambio en curso); master (registro en curso)
Estado: Abierto
```

# VE-01 y VE-02 firmados; **se retira «Exigir vendedor»**: la Política de campos es la única fuente

Respuesta completa del arquitecto-software de A: `traspasos/A/respuestas-ve01-ve02-2026-10-08.md`.

## VE-01 (F-1 a F-5, firmados)
Privilegio `reimprimircomprobante` (Especiales, acción Autorizar); SUPERVISOR y CONTADOR sí, CAJERO no. Reimpresión = copia, PDF o correo de un documento con NCF o e-NCF tras su primera impresión; no lo son la primera impresión, la RI automática de VF-13 ni el reintento por falla de impresora (2 en 10 min, mismo usuario). «COPIA n». 422 `AUTORIZACION_REIMPRESION_REQUERIDA`; `POST /api/impresion/reimpresion` con supervisor. Motivo solo con supervisor. A lo construye en la tanda de núcleo de caja (después de T1/T2/T4, antes de T-29).

## VE-02: cambio respecto del aviso `exigir-vendedor-en-origin`
El propietario recordó que la **Política de campos** (ADR-11) ya permite volver obligatorio al vendedor por pantalla y alcance (todos, nivel, usuario). Decidió:
- **Se retira el parámetro `ExigirVendedor`** (`32a73ae`); A lo quita ahora (solo existía en desarrollo).
- **Vendedor exigido en el POS** = alguna regla activa de «Punto de venta», campo `VendedorId`, obligatoria en cualquier alcance. Entonces no se inhabilita a un vendedor asignado a caja o perfil (`VENDEDOR_ASIGNADO_CAJA`) ni se guarda la regla con asignaciones inhabilitadas (`VENDEDOR_INHABILITADO_ASIGNADO`). `VENDEDOR_REQUERIDO` desaparece: el error es el de la política, con su mensaje.
- En el POS el vendedor por omisión (perfil → caja) se resuelve **antes** de validar la política (defecto corregido).
- Facturación a crédito, cotizaciones y pedidos: cada pantalla con su propia regla. **Devoluciones:** el vendedor se hereda y no puede marcarse obligatorio.
- **Para las ventanas de B:** la obligatoriedad se lee de la **política efectiva de la pantalla** (`PoliticaPantalla.Obligatorio("VendedorId")`), no de `ConfigPosDto.ExigirVendedor`, que deja de existir. La ventana de cada vertical solo decide la presentación.

## F-8
`SelectorLote` y `DialogoFaltantes` los crea A en T4 en `src/GPOS.Componentes` (contrato de la sección 3 de la respuesta).
