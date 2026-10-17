```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GSF.EmisorLicencias main @ 34fbb49 (local, sin remoto); submódulo GPOS-NG en e80f4654
Estado: Cerrado (salvo EV-01 y la decisión de EV-03)
```

# Emisor de licencias: `autNivel` verificado con `VerificarCompacto` y observaciones de seguridad corregidas

## Qué se hizo
- **`51526d7`:** el submódulo GPOS-NG pasa a `e80f4654`. Así el emisor recibe `VerificarCompacto`, el #32 unido.
- **`62f321f`:** la autorización de regreso (`autNivel`) se verifica con el mismo verificador que la API:
  - `typ`, ES256 y `kid`;
  - firma Avanzada activa y no retirada;
  - el `kid` de desarrollo se rechaza en Release;
  - modelo cerrado y JSON estricto.

  Se retiró la verificación provisional y la copia del contrato. Regla nueva: **se rechaza la autorización caducada**, como ya hace la API.
- **Revisión de seguridad:** «Aprobado con observaciones», sin Críticos, Altos ni Medios. Informe en `traspasos/A/revision-seguridad-emisor-verificarcompacto-2026-10-17.md`.
- **Bajas corregidas** (`6734280`, `275510a`, `34fbb49`):

  | Hallazgo | Corrección |
  |---|---|
  | EV-02 | Formato de `instalaciones` |
  | EV-03 | La caducidad se compara con la hora NTP real, no con `emitida` |
  | EV-04 | Verificador fijo, sin inyección |
  | EV-05 | Guarda CR-04 propia del emisor |
  | EV-06 | `kid` de desarrollo en Debug y duplicados |

## Verificación
Toda la solución del emisor: **94/94 en Debug y 94/94 en Release**, con 0 advertencias. A lo comprobó por su cuenta. Se probaron las variantes incorrectas de la guarda CR-04, y fallan como deben.

## Pendiente
- **EV-01 (Baja):** mover las listas del modelo cerrado de la autorización a `FormatoLicencia`, para que el emisor y la API usen la misma.
  - Es un PR corto en GPOS-NG; A lo hace después de SL.
  - Conviene unirlo antes de la primera autorización real.
- **EV-03, para decidir (B → propietario; candidata a ADR):** hoy `s2` puede firmar una licencia antes de `desde`, y la API la acepta.
  - No alarga la vigencia, pero empobrece la auditoría.
  - **Recomendación de A:** rechazar firmar antes de `desde`, con un margen mínimo.
- **El repositorio del emisor no tiene remoto:** los commits están solo en la PC A. ¿Se le crea un remoto privado?
