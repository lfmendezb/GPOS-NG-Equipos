[Decisión preparada por el Arquitecto Maestro (equipo B)]  Estado: **Pendiente de firma**

# Hoja de firma: RSV-02, RSV-03 y RSV-10/13 (mantenimiento del anillo con sellos e instantánea de la licencia)

- **Fecha:** 2026-10-18
- **Preparado por:** Arquitecto Maestro del equipo B (coordinador)
- **Firma:** el propietario
- **Origen:**
  - revisión de seguridad del PR #73 (`traspasos/A/revision-seguridad-rs01-rs03-2026-10-18.md`, con dos relecturas; veredicto: Aprobado con observaciones);
  - aviso `avisos/A-a-B/2026-10-18-pr73-rs01-rs03.md`;
  - código leído en `origin/a/rs-anillo-sellos` @ `e55a7478` con `git show`, sin checkout.

---

## 1. Contexto y pregunta a decidir

El #73 cierra RS-01 a RS-03, que firmó el propietario el 2026-10-17. Los dos verbos del anillo, `--revocar-heredadas` y `--cambiar-recuperacion`, **fallan cerrados** mientras el padrón o los sellos de ADR-83 dependan de las llaves que se van a revocar (`src/GPOS.Migracion/Anillo/MantenimientoAnillo.cs:147` y `:182`, `ExigirSinSellosAsync`, `:210-218`).

La revisión deja tres cosas para el Maestro:
- **RSV-03:** en una instalación sellada, `--cambiar-recuperacion` **siempre** se niega, porque el sello y el padrón están protegidos con la llave predeterminada, que pertenece a la recuperación anclada. El remedio de 4C.4 bis de H-17 v2, cambiar la recuperación si se compromete o cambia el custodio, **no existe** en ninguna instalación con sellos.
- **RSV-02:** el verbo no exige la API detenida. La API sigue protegiendo con la llave anterior hasta que reinicia (`MantenimientoAnillo.cs:183-194`; caché del anillo de hasta 24 h, *inferido*).
- **RSV-10 y RSV-13:** la instantánea de la licencia no tiene límite de antigüedad. Si el refresco falla de forma persistente, el estado se congela mientras corra la API. Además, la falta del archivo `estado` en el disco no avisa.

**Pregunta:** qué se construye en cada caso, cuándo, a qué costo y con qué figura (precisión de un ADR o ADR nuevo).

**Restricción vigente**, que esta hoja no cambia hasta que se construya lo firmado: **no cambiar la recuperación en una instalación sellada ni con la API en marcha** (RS-01 (a), ADR-83).

## 2. Entregables evaluados

- Revisión de seguridad del #73: RSV-01 a RSV-14. RSV-01, 04, 05, 07 (2 a 4) y 09 están cerrados en el PR.
- Código del #73:
  - `MantenimientoAnillo.cs:166-200` (`CambiarRecuperacionAsync`) y `:274-292` (`ReprotegerAsync`);
  - `EstadoLicenciaService.cs:54-55` (`CalculadaUtc` existe y no se consulta) y `:151-176` (estado leído de la instantánea);
  - `ImportadorCarpetaEntrada.cs:57` (refresco cada **60 s**).
- ADR-83 (sello y padrón, puntos 1, 2 y 7; precisiones SL-F2 (b), SLF-01, AG-01 a AG-07 y RS-01 (a)).
- H-17 v2 (`docs/decisiones/2026-10-04-cierre-h0.md`, 7.3.2: recuperación anclada y verbo con acta).
- ADR-58 (validación en la API; precisión de la huella: máx(`graciaDias`, 72 h) sin lectura correcta → gracia de entorno).
- ADR-62 (INV-8: gracia mínima de 72 h).
- Propuesta del calendario de DB-7 (`traspasos/B/2026-10-18-propuesta-calendario-db7.md`, DB7-05), que cambia la forma del sello y del padrón.

## 3. Evaluación por punto

### 3.1 RSV-03 · Reproteger juntos el padrón y los sellos

| Opción | Qué es | Costo | Valoración |
|---|---|---|---|
| **(a) Construirla ahora (A, después del #73)** | Verbo `anillo --reproteger-sellos` y su llamada desde la reprotección de `--cambiar-recuperacion` y de `--revocar-heredadas`, con el diseño del auditor (RSV-03, pasos 1 a 6). Recorre los sellos con una **abstracción de la fuente de sellos**, para que DB7-05 (sello por membresía) solo cambie el recorrido | 1,5 – 2 dp, más ≤ 0,3 dp de ajuste en D3 de DB-7 | **Recomendada** |
| (b) Construirla dentro de D3 de DB-7, sobre la membresía | Una sola vez, sobre la estructura final | 1,5 – 2 dp en noviembre | Ahorra ≤ 0,3 dp, pero ata el remedio al calendario más apretado (DB-7) |
| (c) No construirla; remedio manual de GSF | Restricción operativa permanente | 0 | Sin salida real: `--resellar` se niega con `SelloInicial` (SLF-01, AR-06) y abrirlo debilita SLF-01 |
| *Descartada por el auditor:* excluir los sellos y volver a sellar con `--resellar` | — | — | Debilita SLF-01 |

**Por qué (a).**
- A no tiene tareas que no dependan de B, C o de una firma (`estado.md`, A, 2026-10-18), así que construirla ahora no le quita tiempo a otra tarea.
- Cierra el único estado «sin salida» que queda en el mantenimiento del anillo antes del primer cliente.
- Desbloquea `--revocar-heredadas` en las instalaciones que se sellaron antes de migrar desde DPAPI. El DEMO y los equipos de desarrollo pueden estar en ese caso (*inferido*, supuesto de la revisión).
- La abstracción es la misma que necesita DB7-05.

**Condiciones para la construcción:**
1. Exige la API detenida (RSV-02).
2. Una sola transacción que toma el padrón con `UPDLOCK, HOLDLOCK`.
3. `Unprotect` con las llaves en transición y `Protect` con la predeterminada nueva.
4. Recalcula `HuellaSello` y escribe el padrón con la versión siguiente.
5. Escribe el archivo `padron` de forma atómica **después** de confirmar.
6. **Si un sello no abre, aborta todo y no revoca nada.**
7. Incluye `SelloInicial` y `ReselladoPendiente`.
8. Prueba de la 2.ª comprobación (caso 1 de RSV-07).

**Cuándo.** Después de unir el #73 y **antes de la primera licencia de pago**. Objetivo: PR antes del 2026-11-02, para que no compita con D1 de DB-7.

**Figura:** ADR nuevo (sección 5).

### 3.2 RSV-02 · API detenida durante el mantenimiento del anillo

| Opción | Qué es | Costo | Valoración |
|---|---|---|---|
| (1) Solo procedimiento | El procedimiento y el texto del verbo exigen detener la API (y la de reportes) y reiniciarla después | 0,1 dp (devops) | Necesario, pero depende de que el técnico lo haga |
| **(2a) Procedimiento más una comprobación del servicio** | El verbo se niega si un servicio de Windows `GPOS.Api` o `GPOS.Reportes` instalado no está detenido. Si el servicio no está instalado, solo informa (Debug y DEMO de consola) | 0,1 + 0,15 dp | **Recomendada** |
| (2b) `sp_getapplock` | La API mantiene un bloqueo compartido de sesión en `GPOS_SYSDATA` mientras vive; el verbo lo pide exclusivo con espera cero | 0,5 dp | Más fuerte, pero obliga a una conexión permanente fuera del pool, con reconexión y un hueco al reconectar |
| (3) `UPDLOCK` sobre el padrón | Serializa las escrituras de sellos con el verbo | 0,2 dp | Viene incluida en RSV-03 (a) |

**Por qué (2a).**
- El riesgo es el **olvido del técnico**, no un adversario: quien ya administra el servidor puede hacer cosas peores (RSV-06).
- La instalación es de un solo servidor (ADR-24), con cuentas virtuales `NT SERVICE\GPOS.Api` y `NT SERVICE\GPOS.Reportes` (ADR-82, punto 2; ADR-38, precisión PR-38 (a)), así que el estado del servicio es una señal fiable y barata.
- El verbo corre en el mismo equipo que la carpeta del anillo.

**Alcance:** `--cambiar-recuperacion`, `--revocar-heredadas` y el verbo nuevo de RSV-03. `--anclar` corre en la implantación, antes de que exista el servicio, y queda fuera.

**Cuándo.** En el mismo PR que RSV-03, antes del primer cambio real de recuperación y antes de la primera licencia de pago.

**Revisión:** (2b) queda descartada **por ahora**. Se revisa con los nodos de la entrega 2 (ADR-53), si un nodo comparte servicio.

### 3.3 RSV-10 · Límite de antigüedad de la instantánea de la licencia

**Riesgo (verificado en el código).**
- Si el refresco falla siempre (por ejemplo, con un `DENY SELECT` sobre `dbo.Licencias` para la identidad de la API), el estado de cada empresa se lee de la última instantánea (`EstadoLicenciaService.cs:151-176`) y **ni el vencimiento ni las gracias avanzan**.
- `CalculadaUtc` existe (`:55`), pero nadie lo consulta.
- Es una **falla abierta en el tiempo** frente al adversario de la licencia: el administrador del servidor del cliente.

| Opción | Qué es | Costo | Valoración |
|---|---|---|---|
| **(a) Reevaluación y tope** | Si `CalculadaUtc` tiene más de **15 min** (15 refrescos de 60 s), los estados se recalculan con `MotorEstados` y la hora protegida actual sobre la última cadena conocida, con un evento de advertencia. Si pasan **máx(`graciaDias`, 72 h)** sin un refresco correcto, la instalación pasa a **solo consulta**, con un evento crítico y aviso al SUPER desde el primer fallo | 0,3 – 0,5 dp + pruebas | **Recomendada** |
| (b) Solo la reevaluación, sin tope | El tiempo avanza, pero un `DENY` persistente nunca se castiga | 0,2 – 0,3 dp | Deja abierta la vía de RSV-10 |
| *Descartada por el auditor:* reiniciar la API | — | — | El arranque falla cerrado y el cliente se queda sin servicio |

**Por qué (a).** El plazo de 72 h es el mismo que ya firmó el propietario para la falta de lectura de la huella (precisión de ADR-58: máx(`graciaDias`, 72 h) → gracia de entorno) y que la gracia mínima de INV-8 (ADR-62). No se inventa un plazo nuevo. Un corte real de `GPOS_SYSDATA` ya deja la API sin servicio por otra vía, así que el tope solo afecta a quien bloquea la licencia y deja funcionando el resto.

**Qué rompe:** una instalación con un fallo de lectura que dure más de 3 días (por ejemplo, permisos mal puestos) queda en solo consulta. Esa es la misma consecuencia operativa ya aceptada para la huella.

### 3.4 RSV-13 · Aviso cuando falta la copia en el disco

**Riesgo.** Con la fila `Gracias` presente y el archivo `estado` ausente o ilegible, la licencia se evalúa sin el archivo y no se emite ningún aviso. El efecto es el mismo que borrar el archivo, cosa que el administrador del servidor siempre pudo hacer (RSV-13; no es una exposición nueva). La copia en el disco es la defensa frente a una base restaurada desde una copia vieja.

| Opción | Qué es | Costo | Valoración |
|---|---|---|---|
| **(a) Evento, aviso y reescritura** | Evento crítico `LicenciaFuenteAusente` (**EventId 4723**, el siguiente libre según la revisión) y aviso diario al SUPER. Se reescribe el archivo desde la fila, como hace RA-02 con el piso de nivel, **solo si no está activo el candado de restauración CR-01 de H-11** | 0,1 – 0,2 dp | **Recomendada** |
| (b) Tratar la ausencia como fuente inválida que adelanta la gracia | Más restrictiva | 0,2 dp | Castiga un fallo del disco igual que un ataque. Las gracias ya toman el valor más restrictivo de las fuentes disponibles (relectura de RSV-09) |
| (c) No hacer nada | — | 0 | Deja el hueco sin señal |

**Por qué (a).** Es barata y hace visible el hueco. La condición sobre el candado evita que la reescritura legitime una base restaurada: en ese caso manda el candado CR-01, que ya detecta la restauración de `GPOS_SYSDATA` (*inferido*; lo confirma el auditor de A al revisar el PR).

### 3.5 Cuándo y quién

| Punto | Equipo | Cuándo | ¿Antes del corte? | ¿Antes de la primera licencia de pago? |
|---|---|---|---|---|
| RSV-03 (a) + RSV-02 (2a) | A, PR apilado sobre el #73 | 2026-10-24 → 11-01 | Sí | **Sí, obligatorio** |
| RSV-10 (a) + RSV-13 (a) | A, en el mismo PR o en uno aparte | Igual | Sí | **Sí, obligatorio** |
| Procedimiento de mantenimiento del anillo (RSV-02 (1)) | devops (B) | Antes del primer mantenimiento real | Sí | Sí |
| Bajas RSV-06, 08, 11 y 12 | A, en el mismo PR | Igual | Recomendado | No obligatorio |

**Total:** unos **2,5 a 3,3 dp** (≈ 0,5 a 0,65 sp, inferido ±35 %), todo del equipo A. **Sin costo de infraestructura ni de licencias.**

## 4. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| La reprotección conjunta falla a mitad de camino y deja sellos con llaves distintas | Una sola transacción; el disco se escribe después de confirmar; si un sello no abre, se aborta y no se revoca (condición 6) |
| DB7-05 cambia la forma del sello justo después | Abstracción de la fuente de sellos; ajuste ≤ 0,3 dp en D3 |
| Falso «solo consulta» por un fallo largo y legítimo (RSV-10) | Aviso al SUPER desde el primer fallo y evento cada día; el plazo de 72 h es el ya aceptado para la huella |
| La reescritura de RSV-13 legitima una base restaurada | Solo se reescribe si no está activo el candado CR-01 |
| **Residual aceptado:** estado de transición solo en memoria (alternativa de RSV-01: persistirlo en una fila con MAC, 1 – 1,5 dp) | No se construye ahora. Lo cubren las comprobaciones previas del #73 (RSV-01) y la API detenida (RSV-02). Si el ensayo del primer cambio real muestra que hace falta reanudar, se prepara aparte |

## 5. Figura: ADR o precisión

- **RSV-02 y RSV-03 → ADR nuevo, propuesto ADR-79** (rango de A, libre según `docs/adr/README.md:193`): «Mantenimiento del anillo de Data Protection con sellos vigentes».
  - Agrupa en un solo texto las reglas del mantenimiento: RS-01 (a), API detenida, reprotección conjunta y alcance de los verbos.
  - Hoy esas reglas están repartidas entre H-17 v2, que no tiene archivo de ADR, y una precisión de ADR-83.
  - Uso el rango de A porque el anillo y los sellos son piezas de A.
  - **Alternativa:** ADR-129 del rango de B. Lo desaconsejo: 127 y 128 están apartados para los dos ADR pendientes de la hoja de catering (`README.md:230`), así que 129 es el último libre de B.
  - **Alternativa descartada:** solo precisiones de ADR-83 y de H-17 v2. El procedimiento ya tiene tres controles y dos verbos, y repartirlo en notas hace difícil leerlo.
- **RSV-10 y RSV-13 → precisión de ADR-58**, con una nota en ADR-59 (estado «solo consulta»). Son reglas de la validación de la licencia en la API, no decisiones nuevas.

## 6. Recomendación

**Aprobar** RSV-03 (a), RSV-02 (2a) con (1), RSV-10 (a) y RSV-13 (a), con ADR-79 y la precisión de ADR-58. Hasta que estén unidos sigue la restricción operativa de RS-01 (a).

## 7. Hoja de firma

### RSV-F1 · Reprotección conjunta de padrón y sellos (RSV-03)
- **Recomendación:** (a) construirla ahora, en A, después del #73, con las condiciones 1 a 8 de 3.1 y la abstracción de la fuente de sellos. Debe estar **antes de la primera licencia de pago**.
- **Qué rompe:** nada visible para el usuario. Agrega el verbo `anillo --reproteger-sellos` para el técnico de GSF, con acta.
- **A quién afecta:** a GSF (procedimiento de mantenimiento).
- **Por qué se justifica:** sin ella no hay remedio ante una recuperación comprometida en ninguna instalación sellada.
- **Cómo se migra:** no aplica; se usa en el siguiente mantenimiento.
- [ ] (a) recomendada  [ ] (b) dentro de D3 de DB-7  [ ] (c) solo procedimiento

### RSV-F2 · API detenida (RSV-02)
- **Recomendación:** (2a) el verbo se niega si un servicio `GPOS.Api` o `GPOS.Reportes` instalado no está detenido, más el procedimiento de devops (1). Alcance: `--cambiar-recuperacion`, `--revocar-heredadas` y `--reproteger-sellos`.
- **Qué rompe:** el mantenimiento exige una ventana con la API detenida. Hoy no hay ventas en producción.
- **A quién afecta:** a GSF y al cliente (minutos sin servicio fuera del horario de venta).
- **Por qué se justifica:** evita que la API siga escribiendo con una llave que se va a revocar.
- **Cómo se migra:** no aplica.
- [ ] (2a) + (1) recomendada  [ ] (2b) applock  [ ] Solo (1)

### RSV-F3 · Límite de antigüedad de la instantánea (RSV-10)
- **Recomendación:** (a) reevaluar con la hora protegida si la instantánea tiene más de 15 min, y pasar a solo consulta tras máx(`graciaDias`, 72 h) sin un refresco correcto, con eventos y aviso al SUPER. Debe estar **antes de la primera licencia de pago**.
- **Qué rompe:** una instalación con la lectura de la licencia rota durante más de 3 días queda en solo consulta.
- **A quién afecta:** al cliente y a GSF.
- **Por qué se justifica:** cierra la falla abierta en el tiempo de la licencia frente al administrador del servidor.
- **Cómo se migra:** no aplica.
- [ ] (a) recomendada  [ ] (b) solo reevaluar

### RSV-F4 · Copia en el disco ausente (RSV-13)
- **Recomendación:** (a) evento crítico `LicenciaFuenteAusente` (4723), aviso al SUPER y reescritura desde la fila, salvo con el candado CR-01 activo. Debe estar **antes de la primera licencia de pago**.
- **Qué rompe:** nada.
- **A quién afecta:** al SUPER (ve el aviso).
- **Por qué se justifica:** hace visible la pérdida de la defensa frente a una base restaurada, por unos 0,15 dp.
- **Cómo se migra:** no aplica.
- [ ] (a) recomendada  [ ] (b) fuente inválida  [ ] (c) nada

### RSV-F5 · Figura
- **Recomendación:** ADR-79 nuevo (rango de A) para RSV-F1 y RSV-F2; precisión de ADR-58, con nota en ADR-59, para RSV-F3 y RSV-F4. B los registra en `master`.
- [ ] Recomendada  [ ] Usar ADR-129 (rango de B)  [ ] Solo precisiones

## 8. ADR propuesto (borrador, estado `Propuesto`)

> **ADR-79 · Mantenimiento del anillo de Data Protection con sellos vigentes** · **Estado:** Propuesto · **Precisa:** H-17 v2 (4C.4 bis) y [ADR-83](ADR-083.md) (punto 7 y RS-01 (a)) · **Relacionado:** [ADR-58](ADR-058.md), [ADR-77](ADR-077.md), [ADR-82](ADR-082.md) y [ADR-109](ADR-109.md)
>
> **Contexto.** Los sellos y el padrón de ADR-83 se protegen con la llave predeterminada del anillo. Mientras no exista una reprotección propia para ellos, ningún verbo puede revocar las llaves de las que dependen, así que una instalación sellada no puede cambiar su recuperación (RSV-03). Además, la API en marcha sigue protegiendo con la llave anterior hasta que reinicia (RSV-02).
>
> **Decisión.**
> 1. **API detenida.** `anillo --cambiar-recuperacion`, `--revocar-heredadas` y `--reproteger-sellos` se niegan si un servicio `GPOS.Api` o `GPOS.Reportes` instalado no está detenido. El procedimiento exige reiniciarlos después.
> 2. **Reprotección conjunta.** `--reproteger-sellos`, y la reprotección de los dos verbos, reprotegen en una sola transacción, con el padrón bajo `UPDLOCK, HOLDLOCK`:
>    - cada sello;
>    - `SelloInicial` y `ReselladoPendiente`;
>    - la `HuellaSello` del padrón, con su versión siguiente.
>
>    El archivo `padron` se escribe después de confirmar. Si un sello no abre, no se cambia ni se revoca nada.
> 3. **Red de seguridad.** Las comprobaciones de RS-01 (a) se mantienen antes y después de la reprotección.
> 4. **Fuente de sellos.** El recorrido es independiente de la forma del sello, para el sello por membresía de la versión 1 del acceso multiempresa.
>
> **Alternativas descartadas.**
> - Excluir los sellos y volver a sellar (debilita SLF-01).
> - Un `sp_getapplock` permanente (más costo; se revisa con los nodos).
> - Persistir el estado de transición (aplazado).
>
> **Consecuencias.**
> - (+) Hay remedio ante una recuperación comprometida.
> - (−) El mantenimiento exige una ventana sin servicio.
> - Esfuerzo: 1,65 a 2,15 dp (inferido).
>
> **Decidido, no implementado.**

## 9. Si el usuario firma / si rechaza

- **Si firma:**
  - B registra ADR-79 y la precisión de ADR-58 en `master`;
  - encarga a A el PR detrás del #73, con objetivo antes del 2026-11-02;
  - pide a devops el procedimiento de mantenimiento;
  - agrega RSV-F1, F3 y F4 a la lista de condiciones de la primera licencia de pago.
- **Si rechaza RSV-F1 (a):** con (b), la pieza pasa a D3 de DB-7 y la restricción operativa dura hasta noviembre. Con (c), la restricción queda permanente y GSF documenta el procedimiento manual, sabiendo que hoy no tiene salida técnica.
- **Si rechaza RSV-F3 (a):** con (b), la vía de RSV-10 queda abierta para quien bloquee la licencia de forma persistente; conviene registrarlo como riesgo aceptado por escrito.

---

### Supuestos
1. El refresco del anillo de Data Protection en la API tarda hasta 24 h y no recibe avisos entre procesos (*inferido* para .NET 10; no medido).
2. La API y la API de reportes corren como servicios de Windows con esos nombres en toda instalación de cliente (ADR-82, punto 2; ADR-38, PR-38 (a)).
3. El candado CR-01 detecta una `GPOS_SYSDATA` restaurada antes de que corra la reescritura de RSV-13 (*inferido*; lo confirma el auditor).
4. EventId 4723 sigue libre al construir: la revisión del #73 lo da como el siguiente.
5. El sellado de una instalación real ocurre después de su migración desde DPAPI; en el DEMO puede no cumplirse.

## Firma

**Firmada por Leonardo Méndez, propietario, el 2026-10-18 en la sesión de B:** «Firmo según recomendación. Sobre quien realiza DB-7, entiendo que el equipo B debería asumir esta tarea por ser el equipo principal y mas estable con mayor capacidad de A y mejor estabildiad que C».

- **RSV-F1:** (a). **RSV-F2:** (2a) + (1). **RSV-F3:** (a). **RSV-F4:** (a). **RSV-F5:** según la recomendación: ADR-79 nuevo para RSV-F1 y RSV-F2; precisión de ADR-58, con nota en ADR-59, para RSV-F3 y RSV-F4.
- El PR lo construye **A**, detrás del #73, con objetivo antes del 2026-11-02. La precisión de DB7-06 (DB-7 la asume B) no cambia este reparto.

