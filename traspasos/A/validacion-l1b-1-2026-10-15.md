# Validación del arquitecto: PR #35 (L1b-1: `IEstadoLicencia`, `ClaseLicencia`, lista aprobada y corroboración de la hora)

- **Fecha:** 2026-10-15. **Autor:** arquitecto-software, equipo A, como dueño del blueprint.
- **Qué revisé:** rama `a/lic-l1b-1` @ `8a4e86ee`, en el árbol `GPOS-NG-l1b`, en solo lectura: el cuerpo del PR y el diff de `RelojProtegido.cs` e `IEstadoLicencia.cs`. No compilé ni ejecuté las pruebas.
- **Contra qué lo contrasté:** blueprint v2.8, secciones 5.3, 6.1 y 6.2; ADR-59, puntos 6 y 7; `[LIC]` 4.1.3, 4.3, 5.1 y LV-16.

## Dictamen: **Aprobado con observaciones. Nada bloquea la unión de #35**

Las marcas todavía no tienen efecto: el *middleware* `UseLicencia` llega en L1b-2. Por eso, lo que corrijo abajo bloquea **la activación del middleware** en L1b-2, no la unión de este PR.

| # | Punto | Dictamen | ¿Bloquea? |
|---|---|---|---|
| 1 | `POST /api/admin/respaldos` como `Esencial` | **Confirmado.** No está en la lista del punto 6 de ADR-59, pero tampoco cae en el punto 7 («todo lo demás que **crea o cambia datos de negocio**»): un respaldo no cambia datos de negocio, y sirve a la conservación de la información durante 10 años (HC-22). Es una interpretación del punto 7, no una ampliación del punto 6. **Condición:** la ruta solo respalda; restaurar queda fuera y sigue siendo una tarea de una persona en el servidor (RG-14, D-08) | No |
| 2 | `POST /api/notificaciones/documento` como `Consulta` | **Confirmado.** Enviar por correo un documento ya emitido equivale a reimprimirlo o exportarlo, y eso está permitido siempre. **Condición:** la ruta no emite, no toma números y no cambia el estado del documento. Si registra el envío, es solo una bitácora, no un dato de negocio. Enviar un e-CF a la DGII es otra ruta (`Esencial`) | No |
| 3a | La importación mixta (`/api/admin/importaciones/{tipo}/importar`) queda `Operativa` | **Confirmado como falla cerrada.** **Seguimiento:** separar maestros y documentos, ya sea con dos rutas o con la ruta en `Preparacion` y una comprobación dentro del manejador que exija `Operativa` para los tipos de documento. Sin esto, el SUPER no puede importar los maestros de una empresa `NoLicenciada` (LV-16) | No; antes de la primera implantación con migración de maestros |
| 3b | Suspender y dar de baja membresías quedan `Operativa` porque comparten la ruta del alta | **Corregir.** El punto 6 de ADR-59 (firmado) incluye «suspender y dar de baja membresías» entre lo **siempre permitido**: con la licencia vencida, el cliente tiene que poder dejar de cobrar a sus socios. **Texto exacto:** suspender y dar de baja pasan a rutas propias marcadas `Esencial` y en la lista aprobada, o la ruta actual queda `Esencial` con una comprobación en el manejador que exija `Operativa` para el alta y para cualquier otro cambio | **Bloquea la activación del middleware** (L1b-2) |
| 3c | El desbloqueo de H-11 queda `Operativa` | **Confirmado.** Desbloquear vuelve a habilitar la emisión, y en solo consulta no se emite. El candado de H-11 sigue igual en las dos situaciones | No |
| 3d | `POST /api/super/licencia`, la ruta heredada, queda `Operativa` | **Confirmado, con una condición:** L-09 (410) y L-03 (`Esencial`) llegan en el mismo PR que activa el middleware. Si no llegan juntos, una instalación en solo consulta no podría cargar su licencia, que está siempre permitido | Condición de L1b-2 |
| 4 | Unificar `ClaseLicencia(Consulta)` con la marca `SoloConsulta` del candado de H-11 (C-09) cuando se una #24 | **Dos marcas y una sola regla de lectura.** El clasificador lee `SoloConsulta` del candado como `Consulta` (blueprint 5.3). **Prueba de arquitectura:** una ruta con `SoloConsulta` y con un `ClaseLicencia` distinto de `Consulta` hace fallar la prueba; si las dos dicen `Consulta`, se quita la `ClaseLicencia` redundante. **No** se fusionan en una sola marca, porque significan cosas distintas (base restaurada frente a licencia). Al unir, el desarrollador revisa los 12 `POST` de `Consulta` contra el candado: si alguno (ejecutar un reporte, una vista previa) debe pasar también con la base bloqueada, se le agrega `SoloConsulta` y se deja constancia en la lista | No; se hace en el PR que une #24 con L1b |
| 5 | La corroboración: si el reloj está a menos de 48 h de la hora confiable, la hora más alta pasa a la del reloj del sistema | **Confirmado.** `Corroborar` sube la hora más alta hasta mín(reloj, confiable + 5 min). Después, `Observar` aplica la regla de H-16 v2.1 de siempre, en la que un salto de menos de 48 h es coherente y lo sigue. La corroboración no abre nada que la regla de 48 h no admitiera ya; solo sirve para rearmar la referencia después de un salto que se había rechazado. Nunca pasa del reloj del sistema, así que una `emitida` hostil, firmada con una llave básica comprometida y dentro del techo de 48 h de INV-6, no puede dejar la hora más alta por delante del reloj ni provocar el bloqueo de los NCF (C52-3) | No |
| 6 | Rutas anónimas fuera de la evaluación | **Confirmado.** Iniciar sesión está siempre permitido. Emparejar un dispositivo exige un código que genera una ruta autenticada, que sí se evalúa. **Seguimiento:** una prueba de arquitectura con la **lista cerrada** de rutas anónimas (login, emparejar, token de dispositivo), para que una ruta anónima nueva que escriba no se salte la licencia sin que se note | No |

## Otras observaciones

- **Sustituto `EstadoLicenciaHeredado`.** No bloquea nada, así que en producción sería un interruptor. **Condiciones:** se retira en el mismo PR que registra `EstadoLicenciaService`, y una prueba sobre Release comprueba que `IEstadoLicencia` resuelve a `EstadoLicenciaService` (sin interruptores, ADR-60, punto 6). SL puede usarlo en sus pruebas, no en su registro de producción.
- **`ReglaClaseLicencia.Permite`.** Coincide con `[LIC]` 4.3, 4.4 y 5.1 y con LV-16: `Preparacion` solo para el SUPER en `NoLicenciada`, y el SUPER tampoco opera en solo consulta.

## Resumen para el desarrollador

| # | Qué | ¿Bloquea? |
|---|---|---|
| 1 | Suspender y dar de baja membresías como `Esencial`, separadas del alta (3b) | Bloquea la activación del middleware (L1b-2) |
| 2 | L-03 `Esencial` y L-09 410 en el mismo PR que activa el middleware (3d) | Condición de L1b-2 |
| 3 | Sustituto retirado al registrar `EstadoLicenciaService`, con su prueba sobre Release | Condición de L1b-2 |
| 4 | Importación separada por tipo (3a) | Secundaria |
| 5 | Lista cerrada de rutas anónimas en una prueba (6) | Secundaria |
| 6 | Unificación con `SoloConsulta` al unir #24 (4) | Al unir #24 con L1b |

### Cierre
- Estado: Aprobado con observaciones.
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-l1b-1-2026-10-15.md`.
- Supuestos:
  - Revisé el cuerpo del PR y el diff del reloj y del contrato, no las 24 rutas una por una.
  - Las rutas de membresías y de importación son las que describe el PR.
- Decisiones candidatas a ADR: ninguna. Los puntos 1 y 2 interpretan el punto 7 de ADR-59.
- Entregas a otros agentes:
  - **desarrollador-backend (L):** puntos 1 a 3 en L1b-2; 4 y 5 como seguimiento.
  - **especialista-pos:** confirmar con AI-07 que suspender y dar de baja membresías no cambian saldos ni cobros pendientes.
- Próximo paso recomendado: unir #35 y llevar los puntos 1 a 3 a L1b-2.

---

## Adenda: revisión del auditor (`revision-seguridad-pr35-l1b-1-2026-10-15.md`)

### LB-02 (Media, diseño): elijo la opción (a)

Elijo la opción (a), que es también la que recomienda el auditor. **Texto exacto:**
- `ICorroboracionHora.Corroborar` con la fuente `emitida` **solo se llama con una licencia vigente que tenga firma Avanzada propia** (`LicenciaAceptada.FirmaAvanzadaPropia`, la misma definición de INV-5 y CW-02).
- Con una licencia solo Básica, también con la de un regreso temporal con `autNivel`, **no hay corroboración por `emitida`**.
- La cabecera `Date` que obtiene el agente (L4, `agente-date`) sigue corroborando siempre.
- La hora de evaluación de la licencia, máx(hora protegida, `emitida`), no cambia: es otro valor (`[LIC]` 4.1.3).
- **Prueba de QA:** con la llave básica y el reloj del sistema adelantado, cargar tres licencias con una `emitida` que crece 47 h cada vez. La tercera tiene que dar `LICENCIA_FECHA_FUTURA`, y la hora protegida no se mueve con ninguna de las tres.

**Por qué (a) y no (b) ni (c):**
- (a) cierra el ciclo con una sola condición, en el punto donde se llama a la corroboración, y no agrega estado al reloj.
- (b) obliga a llevar dos horas protegidas: una para INV-6 y otra para lo demás, con su persistencia y su recálculo al arrancar (LV-05). Es más superficie para el mismo efecto.
- (c) es más compleja de razonar y de probar.

**Costo operativo de (a):** mientras no haya llaves Avanzadas (todo el corte), un salto del reloj de más de 48 h no se corrobora hasta que exista el agente (L4). Es la falla del lado seguro que ya describe el blueprint en 6.4. El estado de la licencia no se ve afectado, porque su evaluación ya usa `emitida`.

**¿Cambia algo firmado?** **Sí.** H-16 v2.1 (firmada) nombra `emitida` de la licencia vigente como hora confiable sin distinguir el nivel de la firma; esto la restringe. DL-17 **no** cambia: se mantiene tal cual, y esta decisión impide justamente que se la rodee.
- Va a la hoja del propietario como **DL-21**, Pendiente de firma.
- Hasta la firma, el cableado de L1b-2 se construye con la restricción y se marca «PENDIENTE DE LA FIRMA DE DL-21». Antes de la ceremonia equivale a no corroborar con `emitida`. Si el propietario no firma, se vuelve al texto literal.

**¿Bloquea?** No bloquea #35, que no cablea la corroboración. **Es condición del PR de L1b que la cablea.**

### LB-06 (Informativa)

- **`POST /api/admin/numeracion/espejo/sincronizar`: confirmado que no consume números.** E12 solo sube los contadores del espejo `_CNumeracion` y nunca escribe `num.Serie` (`NumeracionService.cs:283-296` [V]). Es `Esencial` y solo para el SUPER.
- **Límites de peticiones: hay que corregirlos (secundario).**
  - `POST /api/admin/respaldos` (`AdminEndpoints.cs:125`) no tiene `RequireRateLimiting`, ni en la ruta ni en el grupo `/api/admin` [V].
  - `POST /api/notificaciones/documento` (`NotificacionesEndpoints.cs:23`) tampoco, ni en la ruta ni en el grupo `/api/notificaciones` [V].
  - No comprobé si existe un limitador global [I].

  **Texto exacto:**
  - respaldos: `.RequireRateLimiting(...)` con un límite propio de 1 cada 10 minutos por empresa, más un solo respaldo a la vez (409 si hay otro en curso);
  - notificaciones/documento: `.RequireRateLimiting(LimitesPeticiones.Reportes)`, además de aceptar solo documentos emitidos (condición del punto 2).

  No bloquea #35. Se hace antes de activar el middleware (L1b-2), porque desde entonces estas dos rutas quedan abiertas también en solo consulta.
