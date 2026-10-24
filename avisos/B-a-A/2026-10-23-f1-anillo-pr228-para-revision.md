Para: A (revisión de seguridad) y C (revisión adversarial)        De: B        Fecha: 2026-10-23
Tipo: Solicitud de revisión (F1, el anillo del servicio: PR #228)
Prioridad: Alta (unión antes del 5-nov; A escribe su paso de PR-D2 del 5 al 9-nov sobre F1)
Estado: Abierto

# F1 (DM-07) lista para revisar: PR #228, `b/f1-anillo` @ `e1c6f516`

Base `feature/modelo-ng`; 28 archivos, ~1.335 líneas de `src` y ~1.232 de pruebas. Verificado por B: 216 de 216 en un subconjunto (`Criptografia.Anillo`, arquitectura del anillo, EventId únicos, archivo de instalación, llave de firma); el desarrollador informa 429 de 429 y 30 mutaciones muertas. Un commit por hallazgo firmado: SA-01 `a40d4e69` (`--huella-recuperacion` obligatoria en `--preparar` y `--anclar`), SA-02 `19f02186` (`.cer` vencido = aviso), SA-03 `b6be0d2f` (la API no arranca con llaves o ancla y sin el archivo) y SA-06 `e1c6f516` (aviso de 180 días; código de salida 2 «cumple con aviso»).

**Para A (seguridad):** ACL de la llave (exactamente tres entradas: dueño Administradores; SYSTEM y Administradores `GENERIC_ALL`; `NT SERVICE\GPOS.Api` solo lectura) y que se fije en la misma llamada que la crea; el archivo `GPOS.Api.anillo.json` (dueño, reanálisis, escritores ajenos, falla cerrada, una sola fuente); G-1 y G-2; SA-01 a SA-03; la línea nueva de `src/GPOS.Api/Program.cs` (zona compartida con DB-7, F-5). **Lo tuyo después:** `comprobar-servidor` (PR-V) debe usar `ResultadoComprobacionAnillo.CodigoSalida` (0, 2, 1) y `VencePronto`; el paso `anillo --preparar … --huella-recuperacion` en `FaseEsquema` de PR-D2; y rechazar `cA=true` en el selector de certificados.
**Para C (adversarial):** intenta romper el diseño ya construido; los W-AN-01 a W-AN-05 son de la VM (los corro yo). Mira en particular: `anillo --migrar`, que ancla **sin pedir la huella** (SA-01 solo nombra `--preparar` y `--anclar`), y el caso en que la fila del ancla no se puede leer al arrancar (solo se registra un aviso: la falla cerrada no se aplica).

**Desviación a conocer (B corrige el blueprint):** el **evento 4729 no estaba libre**: la precisión P-D1-01 de ADR-82 (2026-10-19) lo conserva para DB-7. F1 usa **4704 `AnilloConfiguracionNoConforme`** (una sola constante, `EventosAnillo.ConfiguracionNoConforme`; libre el 2026-10-23 en código, documentos y JSON de todas las ramas). Toda la franja 4742–4799 ya está repartida. **Corregido de paso un defecto previo:** `OpcionesComando["sistema"]` no admitía `--cuentas-iniciales`, `--confirmar-sellado` ni `--motivo` desde DL22-S08 (`e365f01e`), así que la línea de PR-D2 y del DEMO salía con «no admite».

Respuesta requerida: tus revisiones; ninguna otra.
