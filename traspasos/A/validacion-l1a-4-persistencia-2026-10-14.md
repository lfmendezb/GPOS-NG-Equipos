# Validación del arquitecto: PR #33 (L1a-4 «Persistencia y arranque»)

- **Fecha:** 2026-10-14. **Autor:** arquitecto-software, equipo A, como dueño del blueprint.
- **Qué revisé:** rama `a/lic-l1a-4` @ `9e4326c8`, en el árbol `GPOS-NG-lic3`, solo en lectura. Revisé los siete puntos pedidos con lecturas dirigidas a `EstadoLicenciaService.cs` (arranque, reinserción, carga y situación) y a `ComandosLicencia.cs`. No hice una revisión completa del código ni compilé.
- **Contra qué lo contrasté:** blueprint v2.4 (§4.1, §4.3, §6.1.1 reglas 12 y 13, §7, §8), `datos-licencia-l1a4-2026-10-14.md` (4.1 y 4.2), `[PSF]` 4A.4, 4A.5 y 4B.5, y ADR-61, punto 5.
- **Etiquetas:** [V] verificado; [I] inferido.

## 1. Dictamen por punto

| # | Punto | Dictamen | Motivo |
|---|---|---|---|
| 1 | SQL en `Infraestructura/Motor` en lugar de `Data/Sistema` | **Confirmado** | La regla del proyecto (CA-0.8, `SqlSoloEnLugaresPermitidosTests`) prevalece sobre el blueprint (C1.3). Corrijo [BP] §7 en la v2.5 |
| 2 | Nada registrado en DI y sin rutas L-03, L-05 ni L-06 | **Confirmado: van en L1b** | [BP] §4.3: `Program.cs` lo toca L solo en L1a-1 y L1b. §4.1, L1b: «L-01 a L-09». La exigencia «L-03 de punta a punta en Amplio» de L1a-4 se cumple con el servicio y sus pruebas sobre base real (27 pruebas). En L1b van el registro de `TrabajoLicencia` y del servicio, el mapeo con su clase y el limitador de 10 por hora |
| 3 | NV-08: una licencia firmada solo con un `kid` que los binarios marcan como retirado no verifica y no recibe la gracia `LlaveRetirada` | **Hace falta la opción de re-verificación (corrección 3).** No bloquea este PR, pero **sí bloquea la publicación de la versión que retire un `kid` en los binarios** | ADR-61, punto 5 (firmado): la licencia ya aceptada sigue hasta el retiro efectivo. [PSF] 4A.5 dice que la gracia también aplica al «retiro por los binarios». Datos 4.2, regla 3: la re-verificación comprueba «firma e integridad, no caducidad ni retiro». Hoy ningún `kid` está retirado en el recurso (solo existe `s1`), así que no tiene efecto antes del corte |
| 4 | SEG-L2-05 comprobado solo al arrancar | **Corregir (corrección 2, secundaria)** | La ventana dura hasta el siguiente reinicio. El remedio es barato: rechazar la carga en caliente en Amplio. DL-02 sigue pendiente de firma |
| 5 | Reinserción sin sello `.acept` | **Confirmado** | Es datos 4.1: se trata como un archivo nuevo con las reglas de hoy (`CargarInternoAsync` con `comoNuevo`) [V]. Si hoy se rechazaría (por ejemplo, por caducidad), la instalación queda sin esa licencia, que es la falla cerrada |
| 6 | `PerfilMin` resultante como perfil vigente | **Confirmado en la carga normal; corregir en la reinserción (corrección 1) y en las fuentes (corrección 4)** | La carga normal guarda `PerfilMinResultante` (INV-4 con D-2) [V]. La reinserción con sello guarda en cambio el valor **crudo** del contenido, `m.C.PerfilMin ?? basica` [V, `EstadoLicenciaService.cs:251`]. Con un archivo sin firma Avanzada propia, eso puede subir el perfil (contra D-2) o bajarlo (falla abierta). Además, la columna es una caché que un `sysadmin` puede editar, y el perfil es un piso de seguridad: [PSF] 4A.4 dice «se hereda de la última licencia que lo fijó con firma Avanzada» |
| 7 | Rechazos contados por día UTC de la hora protegida | **Confirmado** | Es un tope contra abusos (LV-15), no una fecha civil del formato; la regla de RD de 6.1.2 no aplica. `ahora.Date` sobre la hora protegida en UTC [V] |

## 2. Correcciones

| # | Corrección (texto exacto) | ¿Bloquea? |
|---|---|---|
| 1 | En `RestaurarDesdeDiscoAsync` con sello válido, la columna `PerfilMin` se calcula con la misma regla que la carga: si el archivo trae firma Avanzada propia, `c.PerfilMin ?? basica`; si no, el perfil vigente (`SituacionInstalacion.PerfilMinVigente`). Prueba: reinsertar un archivo Básico con `perfilMin: "avanzada"` no sube el perfil | **Secundaria.** Antes de unir, si es posible (≈ 0,05 dp) |
| 2 | En `CargarInternoAsync`, en modo Amplio, un archivo que las reglas aceptarían y cuyo `anillo` es `Produccion` o `Beta` se rechaza: fila `R` con `ANILLO_NO_ADMITIDO` y el detalle «instalación en Amplio: ejecute GPOS.Migracion sistema (Estricto) antes de cargar esta licencia», más el evento crítico `ArranqueAmplioBloqueado`. La comprobación al arrancar se mantiene, por los archivos que llegan por el disco. Prueba con L-03 y con el importador | **Secundaria.** Recomendada en este PR (≈ 0,05 dp) |
| 3 | **Re-verificación con `kid` retirados en los binarios.** `GPOS.Criptografia` agrega un modo de verificación de integridad, por ejemplo `Verificar(jws, typ, llaves, ModoVerificacion.Integridad)`. En ese modo, una firma válida de un `kid` con estado `retirada` en el recurso **verifica** y vuelve marcada como `Retirada`. El modo normal no cambia. Core lo usa **solo** en la re-verificación (LV-20, refresco y `Anteriores`) y en la reinserción (LV-21), **nunca** en la aceptación. Una licencia cuyas firmas son todas de `kid` retirados se trata como vigente o anterior con `RetiroEfectivoUtc` (regla 12) y con la gracia `LlaveRetirada` (NV-08), contando el conocimiento desde el primer arranque con esos binarios (`RetirosConocidos`). **Condición del recurso:** un `kid` retirado conserva su llave pública en `LlavesGsf.json`. Entra en la revisión del auditor (SEG-L2-08) | **No bloquea este PR.** Bloquea la versión que marque un `kid` como retirado en los binarios (≈ 0,3 dp, con pruebas) |
| 4 | **El perfil vigente sale de fuentes verificables.** Igual que el piso (INV-11): se recalcula al arrancar desde los JWS de `Licencias` que verifican con firma Avanzada propia, y la columna queda solo como caché. Se agrega la fila con MAC `Licencia.PerfilMin` y un archivo en el disco, cada uno con la `sec` de la licencia que lo fijó. Gana la fuente que verifica con la mayor `sec`. Hasta entonces, el perfil efectivo es `basica` mientras ninguna licencia tenga firma Avanzada propia, que es el caso de hoy | **No bloquea.** Antes de la versión con las llaves Avanzadas (≈ 0,2 dp; formato: arquitecto-datos) |
| 5 | En los comentarios y en el PR, la ubicación queda `Infraestructura/Motor` (CA-0.8). Lo recojo en [BP] §7, v2.5 | Documental |

**Resumen:** ninguna corrección bloquea la unión para el corte. Las correcciones 1 y 2 conviene hacerlas en este PR. La 3 y la 4 son condiciones de versiones posteriores.

### Cierre
- Estado: Aprobado con observaciones.
  - Confirmados: 1, 2, 5 y 7.
  - Necesita una opción nueva en `GPOS.Criptografia`: 3 (corrección 3).
  - Corregir: 4 (corrección 2).
  - Confirmado con correcciones: 6 (correcciones 1 y 4).
- Artefactos:
  - `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-l1a-4-persistencia-2026-10-14.md`;
  - `C:\Users\lfmen\source\repos\Solucion GPOS NG\blueprint-licencia-lote2-2026-10-14.md` (v2.5).
- Supuestos:
  - La revisión cubre los siete puntos y lecturas dirigidas, no todo el PR.
  - El recurso conserva la llave pública de un `kid` retirado [I].
- Decisiones candidatas a ADR: ninguna. Son precisiones de ADR-61, punto 5, y de INV-4 / INV-11.
- Entregas a otros agentes:
  - **desarrollador-backend (L):** correcciones 1 y 2 en este PR; la 3 y la 4 en su versión; registro y rutas en L1b.
  - **arquitecto-datos:** la fila `Licencia.PerfilMin` y el archivo de disco (corrección 4).
  - **auditor-seguridad:** el modo de integridad de la corrección 3.
- Próximo paso recomendado: aplicar las correcciones 1 y 2, unir el PR #33 después del #32 y planificar la 3 y la 4 con la versión de las llaves Avanzadas.
