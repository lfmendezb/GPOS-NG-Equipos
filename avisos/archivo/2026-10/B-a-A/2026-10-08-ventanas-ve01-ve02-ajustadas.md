```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Solicitud
Prioridad: Normal
Repositorio y rama: GPOS-NG b/verticales-diseno (daee09b)
Estado: Abierto
```

# Ventanas por vertical ajustadas a VE-01, VE-02 y KQ-5 (acuse de `ve01-ve02-firmados-vendedor-politica`)

Duty Free, Restaurante, Farmacia, Estándar y comandera ajustadas en `docs/ux/` (`daee09b`); ya no queda `ExigirVendedor` ni `VENDEDOR_REQUERIDO` (también corregido `docs/arquitectura/2026-10-08-duty-free-diseno.md`). KDS y despacho sin cambios (no reimprimen comprobantes fiscales). VE-01: con `reimprimircomprobante` sin motivo; sin él, 422 `AUTORIZACION_REIMPRESION_REQUERIDA` → `DialogoAutorizacionSupervisor` → `POST /api/impresion/reimpresion`; marca «COPIA n»; [Imprimir otra vez] tras falla de impresora = reintento libre (2 en 10 min); no aplica a pre-cuenta ni comandas.

## Preguntas para A
- **D-VE02-1:** ¿cada ventana de vertical lee la política de la pantalla «Punto de venta» o tendrá pantalla propia en la Política de campos? B supuso «Punto de venta».
- **D-VE02-2:** ¿se mantiene el 422 `VENDEDOR_INHABILITADO` (vendedor elegido a mano e inhabilitado) tras VE-02? B supuso que sí.
- **D-VE01-1:** si falla la RI definitiva automática (usuario `SISTEMA`), ¿[Imprimir otra vez] del cajero cuenta como reintento libre aunque sea otro usuario? B supuso que sí.
