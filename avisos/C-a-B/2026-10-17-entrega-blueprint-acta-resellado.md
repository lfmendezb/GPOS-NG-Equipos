```
Para: B y A        De: C            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos traspasos/C (solo diseño)
Estado: Abierto: AG-01 a AG-07 firmadas (aviso 2026-10-17-firma-ag01-ag07); B las registra
```

# Entrega, tarea 4 del encargo: blueprint del acta firmada por GSF y de L-06/L-07 (v1.1)

- **Blueprint v1.1:** `traspasos/C/blueprint-acta-resellado-gsf-2026-10-17.md`, contra `a/sl-resellar-candado` @ `130306c0` (#68).
- **Revisión de seguridad:** `traspasos/C/revision-seguridad-acta-resellado-2026-10-17.md`, «Aprobado con observaciones», con 0 Críticos ni Altos, 4 Medios y 8 Bajos. La v1.1 incorpora AR-01 a AR-12.

## Diseño
- **Formato del acta:** un JWS compacto con `typ: "gpos-acta-resellado+jws"`, que verifica el `VerificarCompacto` actual. Usa las mismas llaves de licencia y respeta el piso de nivel.
- **Vínculo:** queda ligada a `InstalacionId`, a la `sec` y al SHA-256 de la licencia vigente. Lleva además:
  - un `nonce` de un solo uso que genera la instalación;
  - la huella de la lista de cuentas, calculada después de `--excluir`;
  - el estado observado de los dos padrones y de `SelloInicial`;
  - una vigencia de 24 h.
- **Flujo:** `--resellar --solicitud` → GSF revisa y firma → `--acta <archivo> --confirmar`. Con esta pieza, **ningún resellado ocurre sin acta**.
- **Atención a la revisión de seguridad:**
  - solo `AnilloIncompleto` levanta SLF-01 (AR-01 y AR-02);
  - `HuellaContenido` con MAC en `ReselladoPendiente`, la confirmación de GSF de cada SUPER nuevo y el restablecimiento de las contraseñas después del resellado (AR-03);
  - ningún exceso de cupo que GSF no haya visto en el último L-06 (AR-04).
- **L-06:** suma `UltimoResellado`, `PadronVersion` y el consumo. El emisor detecta un acta repetida (`RESELLADO_REPETIDO`) o un resellado sin autorizar. **L-07 `PorResellado` queda aplazado.**
- **Estimación:** unos 1,6 dp (±30 %), más 0,25 dp de revisión, sin costo en dólares. Reparto: L 0,5, núcleo del sello 0,55, emisor e instalador 0,45, QA 0,1 y documentador 0,05. Recorte posible: diferir el registro de eventos de Windows, unos 0,1 dp.

## Para firma (B → Arquitecto Maestro → propietario)
| N.º | Pregunta | Recomendación |
|---|---|---|
| AG-01 | ¿Un acta válida levanta SLF-01? | **(a′)**: solo con `AnilloIncompleto`, con el estado ligado en el acta, sin exceso que GSF no haya visto y con acta obligatoria en toda rama |
| AG-02 | ¿Acta completa o reducida? | Completa: solicitud, `nonce` y lista |
| AG-03 | ¿Vigencia del acta? | 24 h |
| AG-04 | ¿Qué recibe GSF? | Código y nivel de cada cuenta, sin nombres y con lo mínimo conservado |
| AG-05 | ¿Qué pasa con un exceso de cupo? | **(b) por omisión**: se niega, salvo que el último L-06 ya lo reportara |
| AG-06 | ¿Límite de actas por año? | Más de una al año por instalación exige la confirmación del propietario |
| AG-07 | ¿Se aplica la precisión opcional AR-01 (3)? | **No**: cerraría la única salida de la instalación nueva en DEMO y en desarrollo |

## Supuestos y pendientes
- El emisor no está en OSHIN-LEGION, así que los nombres de sus clases son inferidos. A los confirma al construir.
- El procedimiento para generar una `InstalacionId` nueva puede no existir. Si falta, es una entrega al núcleo del sello.
- **Para A, AR-06:** `SelloInicial` y `ReselladoPendiente` deben entrar en la reprotección del anillo. Puede ir ya en el #68.
- **Para A, AR-01:** el hallazgo de código está en el aviso `C-a-B/2026-10-17-hallazgo-ar01-slf01-para-a`.
- La construcción la hace A después de la firma, antes de la primera licencia de pago.
