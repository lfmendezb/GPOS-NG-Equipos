Para: A        De: B        Fecha: 2026-10-22
Tipo: Aviso (rama lista para la relectura de seguridad e incorporación al #140)
Prioridad: Alta (desbloquea la unión de #137, #139 y #140)
Repositorio y rama: GPOS-NG `b/deuda-pr2-p137-p140` @ 8e2d6ef8be644789a31b575ac3a31c8de69b7471 (9 commits sobre `a/adr90-rt05-tls-escucha` @ 89f03411)
Estado: Abierto

# Deuda de pruebas P137-01 a P137-05 y P140-01 a P140-04: rama lista

El propietario pidió cerrar la deuda. Rama rebasada sobre tu punta del #140 (con P139-01). `git log origin/a/adr90-rt05-tls-escucha..b/deuda-pr2-p137-p140` muestra los 9 commits, uno por observación. Pruebas dirigidas (`GPOS.Tests.Red` y `OrdenProgramaApiTests`) sobre la rama rebasada: **885 correctas, 0 con error, 3 omitidas**. No se corrió la suite completa.

| Obs. | Estado | Mutación que hace fallar la prueba |
|---|---|---|
| P137-01 | Cubierta | `Environment.GetEnvironmentVariable` → `_ => null` en `EscuchaServidor.cs:68` |
| P137-02 | Cubierta | rama sin modo de `Revisar` anulada; `Detener()` al inicio; sin `ComprobarEfectivas()` final |
| P137-03 | Cubierta | catch de `ComprobarEfectivas` / de `Revisar` tragados |
| P137-04 | Cubierta (corre siempre) | sin `Detener()` en `ComprobarEfectivas` (el agente vio fallar 4 de 5 casos; el 5.º no se vio) |
| P137-05 | Cubierta | `LocalMachine`→`CurrentUser`; `Registry64`→`Registry32`; otra subclave |
| P140-03 | Cubierta + **arreglo de producción** | el bucle del refresco moría si el registro lanzaba al escribir 4748; 4749 fallido daba un 4748 falso |
| P140-04 | Cubierta | validación propia que acepta todo; «localhost» derivado en servidor de sitio |
| P140-02 | **Parcial** | RSA y llave que no se abre cubiertas (llave CNG borrada del almacén del usuario); **falta la ACL real de la cuenta del servicio (laboratorio)** |
| P140-01 | **Parcial** | prueba contra `LocalMachine\My` en solo lectura, omitida si no hay certificados; para cubrirla del todo hace falta un constructor interno `(StoreName, StoreLocation)` en `AlmacenCertificadosServidorWindows` |

## Lo que pide B a A
1. **Relectura de seguridad** del único cambio de producción: `src/GPOS.Comun.Servidor/Red/SelectorCertificadoServidor.cs` (P140-03; `LogError` con el tipo de la excepción, sin mensaje y sin EventId). Decide si necesita EventId propio (el agente no usó el 4752, reservado).
2. **Incorporar** los 9 commits al #140 (`git cherry-pick 89f03411..HEAD` de la rama), o pídenos que abramos un PR aparte sobre `a/adr90-rt05-tls-escucha`.
3. **Decidir** el constructor interno de P140-01 (cambio de producción tuyo) y si se mantiene `TargetHost` en `ClienteApiLocal.Crear`: el agente halló que no tiene efecto (la garantía real la dan `DireccionApi` y el `ConnectCallback`); la prueba de propiedad existente comprueba un valor que no se usa. No es un defecto.
4. P140-02 (ACL real) queda para el laboratorio de LFMB.

Nada se une sin orden del propietario.

Respuesta requerida: acuse con fecha de la relectura (5 días hábiles).
