```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: PR #46 — a/reimpresion-post @ f8e4f6bf (base a/lic-l1b-2); PR #45 — a/lic-activar @ 063b2e88 (base cambiada a a/reimpresion-post)
Estado: Abierto — suite oficial sobre #45 (incluye #46 y UseLicencia activa) en curso
```

# PR #46: reimpresión por POST (decisión 1 de la validación de L1b-2); #45 rebasado encima

## Qué cambia en el #46
- **Impresión fiscal por POST:** `POST /api/impresion/documento/{tipo}/{numero}`, `ticket/{numero}` y `nota/{numero}`.
  - El cuerpo nuevo es `ImpresionFiscalRequest { formato, papel, reintento }`, en `GPOS.Contracts`.
  - Las tres rutas llevan `ClaseLicencia(Consulta)` y `SoloConsulta`.
  - **Los GET se retiran sin transición** y ahora responden 405.
- **Copia con autorización:** sigue en `POST /api/impresion/reimpresion`, con la autorización en el cuerpo.
- **Siguen por GET:** recibo, formato, cierre y estado, porque no escriben.
- **Web y MAUI:**
  - Usan los POST.
  - El reenvío `/imprimir/{**ruta}` de la Web y `RutasArchivos` de MAUI rechazan documento, ticket y nota.
  - Las pantallas usan `ImpresionDocumentos`, que también atiende el 422 de la autorización.
- **LB-05:** se quitó la excepción de `ReimpresionService.RegistrarAsync` en `GetSinEscrituraTests`.
- **LB-06:** ya estaba desde L1b-1 (`7dd3f00d`). `POST /api/admin/respaldos` usa `Respaldos` (uno cada 10 min por empresa, con 409) y `POST /api/notificaciones/documento` usa `Reportes`. Lo cubre `MembresiasLicenciaHttpTests`.

## Verificación
| Proyecto | Resultado |
|---|---|
| Web | 656/656 |
| MAUI | 565/565 |
| GPOS.Tests, clases afectadas (Arquitectura, Licencia, Reimpresion*, InventarioCandado, ImpresionDocumentos…) | 631 correctas, 1 omitida |

**La suite oficial está en curso sobre #45 (`063b2e88`).** Esa cabeza incluye #42, #46 y `UseLicencia` activa. Envío el resultado con un aviso aparte.

## Orden de unión
**#42 → #46 → #45.** La base del #45 ya es `a/reimpresion-post`.

## Para el arquitecto-software (opcional)
Absorber `POST /api/impresion/reimpresion` en las tres rutas nuevas, con la autorización en el cuerpo. La decisión 1 no lo pedía.
