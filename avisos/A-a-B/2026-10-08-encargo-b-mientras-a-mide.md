```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Solicitud (aprobada por el propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG origin/feature/modelo-ng (f21b788) para la ola 5; diseños en ramas b/
Estado: Abierto
```

# Encargo para B mientras A termina el rendimiento de la ola 4

El propietario aprobó el 2026-10-08 que B adelante lo siguiente, según la directriz `prioridad-ventas-inventario`. **Orden: 1 → 2 → 3; el 4 en paralelo.** Respeta tu límite de agentes ([[limite-agentes-pc-b]]).

1. **Diseño de las existencias negativas en tres niveles y de la corrección del lote** (núcleo de inventario). Arquitecto-datos y arquitecto-software de B, con la opinión contable y CO-04: empresa → grupo → artículo, gana el más específico, prohibidos por omisión; Duty Free, lotes con vencimiento y series nunca negativos (`ConsultasInventario.cs:37-47`, `Empresa.cs:45`, `CfgConfiguracion.cs:111`). Incluir qué pasa con las empresas existentes (todas de desarrollo), los cambios masivos por filtro o plantilla, el orden de bloqueos (ADR-45/72, sin cambiarlo) y las pruebas. Entregar **hoja de firma** con números del rango de B. **A lo construye** en la tanda posterior al rendimiento, junto con el vendedor asignado a una caja.
2. **Diseño de las ventanas de facturación por vertical, primero Duty Free** (ADR-112 a 115, [[ventana-facturacion-por-vertical]]): diseñador UX y especialista POS de B; navegación, teclado y lector, estados (carga, vacío, error, sin conexión, «pendiente de validación» con la espera de 3 a 60 s). Solo documentos y HTML estático.
3. **Construcción de la ola 5 solo con archivos nuevos** en `b/ola5`, desde `origin/feature/modelo-ng` (`f21b788`): proyecto aparte de la API de reportes, canalización con ACL (S-15) y motor de formatos v2. Sin tocar archivos existentes de A; los reportes fiscales están aplazados. El commit de partida definitivo lo avisa A después de la ola 4; entonces B rebasa o une.
4. **Vector de ADR-77 v2:** B lo redacta con sus tres observaciones; A lo revisa.

**Fuera de este encargo:** A-11 (sin costos) y las piezas de AdmCloud, que van después del corte.

## Decisión del propietario de este mismo día (CE-04)
Los umbrales **siguen al plazo parametrizable** de ADR-116: aviso **24 h antes de vencer** y confirmación del supervisor **al vencer** (con 72 h por omisión equivale a 48 y 72). A lo pone en la precisión de ADR-51.
