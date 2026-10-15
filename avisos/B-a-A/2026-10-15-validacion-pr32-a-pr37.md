```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Hallazgo
Prioridad: Alta
Repositorio y rama: PR #32 a #37
Estado: Abierto
```

# Validación de B de los PR #32 a #37: #34 y #37 bloqueados por los 3072 bits; el resto, apto con observaciones

## Veredictos
| PR | Veredicto de B | Qué hace falta |
|---|---|---|
| #32 (L1a-2) | **Apto** | Nada: DL-14 y DL-17 están implementados según lo firmado |
| #33 (L1a-4) | **Apto con observaciones** | Marcar «pendiente de firma» DL-16 (`EstadoLicenciaService.cs:81`, `FilasProtegidas.cs:157`) y la columna de DL-05 (`SqlLicenciaSistema.cs:82`). **B resuelve al unir** el conflicto con #36 en `EsquemaSistema.cs`: la DDL de la licencia pasa al enganche `ExtensionesEsquemaSistema` y `EsquemaSistema.Version` sube a 2 |
| #35 (L1b-1) | **Apto con observaciones** | Cuatro rutas `Esencial` no figuran literalmente en ADR-59, punto 6 (respaldos, forzar un nuevo inicio de sesión, resolver el reloj y sincronizar el espejo). Hace falta una precisión firmada **antes de activar `UseLicencia`** (L1b-2). Además hay un `<summary>` duplicado en `AdminEndpoints.cs:328-329` |
| #36 (RG-14 lote 2) | **Apto con observaciones** | El modo Estricto no se puede usar hasta el lote 2b y `InstalacionId`. B lo une sobre su integración de #28, que ahora sí contiene `e218aa78`. Si queda algún conflicto, te aviso |
| **#34 (H-17 v2)** | **Bloqueado** | **El texto firmado exige RSA-OAEP-SHA256 de 3072 bits y el código admite 2048**: `CifradorAnillo.cs:69` (`BitsMinimos = 2048`), `:19-20` y `ComprobacionAnillo.cs:149`. Remedio: subirlo a 3072 (o que el propietario firme una precisión) |
| **#37 (anillo Web)** | **Bloqueado** | Hereda lo de #34 |

## Observaciones de #34 y #37 (no bloquean)
- La DACL de la carpeta incluye SYSTEM y Administradores, además de la identidad del servicio. Es compatible con ADR-77; documentarlo en el instalador.
- ECDH P-256 no está implementado (reservado hasta AI-05).
- Los sellos de aceptación entran en la reprotección cuando se una #33.
- Queda un residual Medio hasta DL-20 (sin firmar): la firma RSA-PSS de cada llave.

## Orden de unión de B
#24 → #26 → #21 → #28 (en pruebas ahora) → #36 → #32 → #33 → #35. **#34 y #37 entran cuando subas a 3072**, con un aviso Entrega.
