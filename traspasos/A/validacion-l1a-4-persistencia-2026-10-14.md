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

---

## Adenda: hallazgos del auditor (`revision-seguridad-pr33-persistencia-2026-10-14.md`, PA-01 y PA-02)

| # | Dictamen | ¿Cambia algo firmado? |
|---|---|---|
| **PA-02** | **Lo acepto con un ajuste.** El auditor propone pasar a `Ilegible` ante **cualquier** fila `'A'` de `sec` mayor que no verifique. Lo descarto como disparador: con las credenciales de la API bastaría insertar una fila basura de `sec` alta para llevar a toda la instalación a `Ilegible` y, 72 h después, a `SoloConsulta`, que es una denegación de servicio barata. El disparador es solo la `sec` máxima **atestiguada con MAC** (fila `Licencia.SecMax` o archivo `secmax`). **Descarto también el `DENY INSERT` con un procedimiento de aceptación:** el procedimiento no puede verificar el JWS (eso se hace en .NET), y quien tiene las credenciales de la API puede llamarlo con los mismos parámetros, así que no protege nada y añade una pieza | **Sí, el punto 2:** cambia el orden de recuperación de `[LIC]` 4.1.2, que es texto firmado («por `sec` descendente, la última del historial que sí verifique, y después las copias en disco»). Va a la hoja del propietario como **DL-18**. El punto 1 no cambia nada firmado: es la propia «última que sí verifique» aplicada fila a fila |
| **PA-01** | **Acepto los puntos 1, 2 y 4.** Persistir la última huella aplica lo que ya está firmado («se conserva la última huella calculada», `[LIC]` 3.3.1). El punto 3 lo propongo también, como decisión aparte | **Sí, el punto 3:** `[LIC]` 3.3.1 firma que «un error no cuenta como cambio de entorno». Tratar una lectura fallida que se prolonga como un entorno distinto contradice esa letra. Va a la hoja como **DL-19**. Hasta la firma: alerta diaria `EntornoLecturaFallida` al SUPER, sin cambiar el estado |

**Texto exacto para el desarrollador (se suma a la lista de correcciones):**

6. **(PA-02, punto 1; bloquea la unión)** Elegir la vigente dentro de cada `sec`.
   - Para cada `sec`, en orden descendente, se verifican **todas** sus filas `'A'` y se elige la que verifica.
   - Si verifican dos o más filas con distinto `Sha256Contenido`, la `sec` cuenta como **no verificable**: se registra `FilaLicenciaInvalida` y se aplica la corrección 7.
   - Las filas que no verifican se ignoran y registran `FilaLicenciaInvalida`.
   - `Anteriores` sigue la misma regla y se corta en la primera `sec` sin ninguna fila que verifique.
   - La consulta 4.2 devuelve **todas** las filas de cada `sec`, no una sola por `sec` con `ROW_NUMBER`.
   - Prueba: insertar una fila `'A'` con la `sec` de la vigente y otro contenido, o con `NivelFirma = 'avanzado'` y un JWS que no verifica. Sigue rigiendo la vigente.
7. **(PA-02, punto 2; pendiente de DL-18; se construye detrás de esa firma)** No volver en silencio a una licencia anterior.
   - Sea `S` la `sec` máxima atestiguada con MAC: el máximo de `Licencia.SecMax` y `secmax`, excluidas las de `kid` todos retirados.
   - Si la vigente encontrada tiene `sec < S`, se busca en el disco (`vigente.gposlic` y `Procesados`) el JWS de `sec = S` cuyo SHA-256 del contenido coincide con el atestiguado.
     - Si verifica, es la vigente y se reinserta (LV-21).
     - Si no, se evalúa como `Ilegible` (72 h, con el tope de `Gracias`), con el evento crítico `FilaLicenciaInvalida`.
   - Nunca se rige por una `sec` menor que `S`.
   - Las filas `'A'` de `sec` mayor que no están atestiguadas con MAC **no** disparan `Ilegible`: se ignoran con el evento.
   - Prueba: con `S` igual a la vigente, borrar su fila (con `sysadmin`, sin disparadores) y quitar el archivo del disco. El resultado es `Ilegible`, no la anterior.
8. **(PA-01, puntos 1, 2 y 4; bloquea la unión)** Persistir la huella.
   - `Licencia.Gracias` y el archivo `estado` guardan `UltimaHuella` (SHA-256 hex) y `UltimaHuellaUtc`.
   - Si la lectura falla, también después de reiniciar, se usa la `UltimaHuella` más reciente que verifique entre la fila y el disco, y se registra `EntornoLecturaFallida`.
   - **Nunca** se escribe `Entorno = null` sobre una marca guardada, salvo que una lectura **correcta** coincida con la `huella` de la vigente. Si la lectura falla, la marca existente (la más antigua de las dos fuentes) se arrastra tal cual.
   - Prueba: con la marca guardada, reiniciar con la lectura fallando. La marca se conserva y la gracia sigue contando.
9. **(PA-01, punto 3; pendiente de DL-19; se construye detrás de esa firma)** Si con una vigente no hubo ninguna lectura correcta de la huella durante más de `máx(graciaDias, 72 h)` desde `UltimaHuellaUtc` (o desde la primera falla si nunca hubo una), se trata como entorno distinto. La primera detección es el inicio de las fallas, y se avisa al SUPER. Hasta la firma, solo el aviso diario.

**Costo [I]:** correcciones 6 y 8, ≈ 0,3 dp; 7 y 9, ≈ 0,2 dp cuando se firmen. **Ninguna toca el formato del archivo de licencia.**

**Adenda 2 (`48e22905`): extensión de la corrección 6 a la carga. Confirmada.**

En la aceptación, la `sec` máxima efectiva y el perfil vigente salen solo de fuentes que verifican:
- **`sec` máxima efectiva:** las filas de `Licencias` cuyo JWS verifica (regla de la corrección 6, fila a fila), la fila con MAC `Licencia.SecMax` y el archivo `secmax`.
- **Perfil vigente:** las filas cuyo JWS verifica (y la corrección 4 cuando llegue).

Una fila sin firma válida no cuenta para ninguno de los dos. Es la misma regla de las fuentes verificables que INV-11 aplica al piso y que DL-18 aplica a la vigente. Evita que con las credenciales de la API se bloqueen cargas legítimas o se fije un perfil distinto. Precisa la sección 4.3 de los datos de L1a-4, que contaba todas las filas `'A'`. No cambia nada firmado.
