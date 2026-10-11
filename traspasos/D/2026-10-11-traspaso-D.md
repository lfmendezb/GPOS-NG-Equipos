# Traspaso del equipo D — 2026-10-11

Primera nota de `traspasos/D/`. Es el **punto de entrada** de la primera sesión de trabajo de D: leer esto antes que nada.

Coordinador maestro: el propietario. D es **equipo de soporte** y **no une ramas**.

---

## 1. Qué es D y dónde está su definición

La definición completa es `avisos/D-a-B/2026-10-11-definicion-equipo-d.md`. En resumen:

| | |
|---|---|
| Rol | **Soporte** (firmado por el propietario el 2026-10-11) |
| Ramas | `d/...` — sube y abre PR, **no une** |
| Rango de ADR | **160–189** |
| No toca | `CLAUDE.md`, manifiesto de pruebas, `memoria/`, `agentes/`, `herramientas/`, `README.md` — son de B |
| Mandato adicional | **Aprobado el 2026-10-11:** reconciliación documental y seguimiento de las precisiones firmadas |
| Máquina | **DEVLAB00**, compartida con el equipo A |
| Límite de agentes | El de A: **4** si solo uno compila o prueba, **2** si hay más de uno, y una tarea pesada **sola**. **Es conjunto con A**, no por equipo |
| Norma de trabajo | Sección 5.1 de la definición: traspaso obligatorio al cerrar; subagentes para lo paralelo |

**El vigilante está APAGADO** (`GPOS-NG Vigilar área común (D)` → `Disabled`), por orden del propietario del 2026-10-11. Mientras lo esté, **nadie escribe `novedades-D.md`**: la sesión **revisa el área común a mano al abrir**. El propietario avisará cuándo encenderlo.

---

## 2. Estado exacto al cerrar

`origin/main` = **`155ee84`**. Cinco commits de D, todos publicados:

```
155ee84  Vigilancia registrada pero apagada por orden del propietario
96111a5  Mandato adicional aprobado y vigilancia registrada y probada
d903943  Rol firmado por el propietario: equipo de soporte
4398393  Norma de trabajo de D: traspaso obligatorio y tres mecanismos de contexto
5676741  Definición del Equipo D: rango 160-189, carpetas, scripts e integración
```

**Clon canónico del área común:** `C:\Users\lfmen\source\repos\GPOS-NG-Equipos` (es el que usan las herramientas y la tarea de vigilancia; actualizado a `155ee84`). Existe además un clon duplicado en `Solucion GPOS NG\_repositorio-comun` que creó D y **ya no hace falta**.

---

## 3. Entorno: cinco cosas que cuestan tiempo si se redescubren

Todas verificadas el 2026-10-11.

1. **TLS/red.** El shell confinado **no inicializa TLS**: `schannel: AcquireCredentialsHandle failed: SEC_E_NO_CREDENTIALS`. Afecta a `git fetch`, `git push`, `gh` y `dotnet restore`. **Solución:** pedir el sandbox abierto para ese comando concreto.
2. **CIM/WMI.** Todo lo que pase por WMI falla con `El cliente no tenía acceso disponible a un recurso CIM`: inventario de hardware, **tareas programadas**, `dotnet workload list`. Misma solución.
3. **`dotnet build` normal** falla **reportando 0 errores** (tuberías con nombre entre nodos de MSBuild). **Solución:** `-m:1 -nodeReuse:false`.
4. **MAUI Android** falla con `XAACD7019: UnauthorizedAccessException` al escribir en `%LOCALAPPDATA%\Xamarin\Mono for Android`. Necesita sandbox abierto. El Android SDK está en `C:\Program Files (x86)\Android\android-sdk`.
5. **SQL Server no es alcanzable** desde el shell confinado (`sqlcmd` da el mismo error de TLS). Por eso **PUB-06 y los puntos 4 y 5 de ADR-044 siguen sin verificar**.

Ventana de contexto: **1.000.000 de tokens** por sesión. Releer la base en frío (`CLAUDE.md`, `estado.md`, las 14 definiciones de agente) cuesta del orden de 50.000 tokens.

---

## 4. Material de trabajo del mandato

Lo que D hereda para su mandato de reconciliación documental. **Es el resultado de una auditoría de los 100 ADR contra el código**, hecha el 2026-10-11 con evidencia `ruta:línea`. No hay que repetirla para empezar a actuar.

### 4.1 Recuento

| Veredicto | ADR |
|---|---|
| IMPLEMENTADO | **45** — de ellos solo **30 en `master`**; **15 solo en ramas sin unir** |
| PARCIAL | **20** |
| NO IMPLEMENTADO | **26** |
| N/A (fuera de este repositorio) | 7 |
| SUSTITUIDO | 2 |

Además: en `origin/master` hay **dos ADR registrados que la copia local no tiene** — **ADR-102** (Aceptado, clase de movimiento 8, **NO IMPLEMENTADO**) y **ADR-125** (producción de elaborados y merma de cocina, sin auditar).

Siete de los «PARCIAL» o «NO IMPLEMENTADO» son de conectores y viven fuera de este repositorio: **ADR-116, 117, 123 y 124** en los repositorios privados `GPOS-NG-AddOn-*`, y **ADR-063 y 065** en la pista del agente de actualización y en la herramienta de respaldos.

### 4.2 Los ocho defectos más graves: afirman código inexistente o niegan el existente

1. **`CLAUDE.md` y `docs/adr/README.md`** dicen que `GPOS.Comun`, `GPOS.Reportes` y `GPOS.Reportes.Api` «todavía no existen en el código». **Están unidos a `origin/feature/modelo-ng`** (commit `9fe5476c`), con su `GPOS-NG.slnx` y `tests/GPOS.Reportes.Tests`.
2. **`docs/adr/README.md:108`** (fila de ADR-041) afirma que `amr` y `auth_time` «ya» están en el token HS256 y que hay un filtro que rechaza al SUPER sin `otp`. **Cero coincidencias en `src` de ninguna rama.** El propio `ADR-041.md:32` se contradice dos frases seguidas.
3. **`docs/adr/README.md:168` y `:161`** dan ADR-121 y la estación de ADR-114 por «no implementados». Están **construidos** en `origin/b/kds-k1` y propagados a `origin/feature/modelo-ng`.
4. **`CLAUDE.md` y el índice** dan ADR-118 y 119 por «no implementados, los construye **A** en `feature/modelo-ng`». Los construyó **B** en `origin/b/adr118-119-t1` y `-ui`, y están unidos en `origin/b/ola3b`. Los propios ADR se contradicen: cabecera «Equipo: B» frente al cuerpo «lo construye el equipo A».
5. **`ADR-007.md:8,15`** dice «secciones numeradas 1–33» y «la última sección del script hoy es la 33… la sección nueva aún no está incorporada». El script tiene las secciones **34, 35 y 36**.
6. **`ADR-033.md:16`** dice que `construir.ps1` «aún no tiene el parámetro» `-Firmar`. **Lo tiene**, y además firma, sella y verifica.
7. **`ADR-069.md:25` y `README.md:134`** (precisión HC-06, fotos versionadas) las declaran no implementadas citando el código como prueba. **Existen** `inv.CierrePeriodoReemplazado` y el disparador `inv.TR_CierrePeriodo_Reemplazo`, con el comentario literal «HC-06: la foto de un mes reabierto no se pierde».
8. **`docs/adr/README.md:4`** declara la solución con **7 proyectos**; el `GPOS-NG.slnx` tiene **10**.

### 4.3 El resto, hasta ~21

- **`ADR-050`** declarado «Implementado (B7e)»; **tres sitios lo incumplen** (parámetros de texto sin tipo): `ReportesService.cs:275` —incluido el `LIKE` de `:293`— y `:305`, y `Comun.cs:557-559`. **Causa raíz:** el contrato automático (`ContratoConsultasTests`) solo cubre las consultas registradas de `GPOS.Core.Consultas.*`, así que el SQL dinámico queda fuera de la red.
- **`ADR-052.md:10,13`** dice «pendiente de MD-07» mientras el documento de origen la da por **firmada el 2026-10-04**.
- **`ADR-100.md:11` y `ADR-106.md:11`** dan los códigos **51360** y **51376**; el código usa **51440** y **51451**, y esos dos números son hoy `NOTA_DESCUADRADA` y `MOTIVO_EN_USO`.
- **`README.md:5`** declara «todas las decisiones aceptadas y vigentes»; `ADR-051.md:5` dice «aceptado **en principio**» y de `ADR-054.md:7-10` solo se firmaron dos puntos.
- **`docs/adr/README.md`** no marca «no implementado» en las filas de **ADR-34, 35, 37 y 39**, a diferencia de 36 y 38 — y los cuatro lo están.
- **`ADR-022.md:13`** dice caché de revocación de 30 s; el código usa **15 s** (lo que firma ADR-030).
- **`ADR-111.md:35`** cita `rpt.Formato607` como existente en `master`; solo está en el diseño y en `origin/feature/modelo-ng`.
- **`CLAUDE.md`** presenta QRCoder como dependencia ya aprobada «que no suma un paquete nuevo»; **no está en ningún `.csproj` de `master`**.
- La ola 3b figura como «decidido, no implementado»; está **construida** en `origin/b/ola3b`.

### 4.4 El patrón de fondo, que es el hallazgo más útil

De los 20 «PARCIAL», **seis de seis** en el rango 001–020 son ADR cuyo **cuerpo está implementado** y cuya **precisión firmada posterior no lo está** (ADR-004, 010, 011, 012, 016, 017).

**El riesgo de GPOS NG no son los ADR que faltan: son las del orden de 200 precisiones firmadas que modifican ADR ya implementados y que nadie vigila.** Son invisibles porque el ADR dueño dice «implementado» y el índice no lista la precisión. Ese es el seguimiento que D tiene que construir.

### 4.5 Mapa de ramas, para no repetir un error de línea base

- **`master` describe el modelo viejo.** No es el estado del proyecto.
- **`origin/feature/modelo-ng` es la rama de integración:** olas 3 y 4, `FactorUnidad` (ADR-078), KDS K1, ADR-068 a 072, **ADR-121**, y **ADR-109/110/111 unidos**. Estaba en `4d376a6c` al hacer el barrido, **212 commits por delante de la copia local**.
- **`origin/b/ola3b`** tiene la ola 3b (ADR-100 a 107) y es donde el T1 de ADR-118/119 quedó unido; **la UI (`b/adr118-119-ui`) no está unida**.
- **Tres familias:** `a/*` (soporte, no une), `b/*` (B, coordinador, sí une), `c/*` (soporte). Unas **61 ramas remotas** al momento del barrido.
- **Lección que costó tiempo:** auditar contra el árbol de trabajo sin comprobar la línea base produjo veredictos falsos en ambos sentidos. **Antes de concluir nada sobre una rama, comprobar los refs con `git fetch` y comparar con `git rev-list --left-right --count`.**

---

## 5. Pendientes, y de quién son

**Del propietario (coordinador maestro):**
- Avisar cuándo **encender el vigilante**.
- Decidir el destino del clon duplicado `Solucion GPOS NG\_repositorio-comun`.

**De B, cuando retome el 14:**
- Entrada de D en `memoria/` (solo el coordinador publica memoria).
- Rango **160–189** en el registro de `docs/adr/README.md` de `GPOS-NG`.
- Revisar los dos archivos compartidos que D tuvo que tocar: `herramientas/*.ps1` (sin `D` en el `ValidateSet`, D **no podía publicar**) y `README.md` (la portada omitía a D y la regla 3 omitía a C desde el 9-oct).

**De D:**
- **Cola recibida el 2026-10-11 (17:20):** las asignaciones que dejó pendientes el equipo C, por decisión del propietario. Registrada en `avisos/D-a-B/2026-10-11-traspaso-pendientes-de-c.md`. El plan está en la sección 7 de este traspaso.
- Antes de esa decisión, la definición quedaba cerrada y `traspasos/D/` se estrenaba con el primer paquete de trabajo real.

---

## 6. Lo primero que debe hacer la sesión siguiente

1. `git pull` del clon canónico `C:\Users\lfmen\source\repos\GPOS-NG-Equipos` y leer `estado.md` (sección de D) y los avisos abiertos de `avisos/B-a-D/`.
2. Leer este traspaso y la definición.
3. Recibir del propietario la asignación; **si toca código, rama `d/...` y PR sin unir**.
4. Antes de tocar `master` o cualquier rama como línea base: `git fetch` y comprobar la punta real.
5. Al cerrar: **nota nueva en `traspasos/D/`**, aunque el trabajo quede a medias.

---

## 7. Plan de trabajo: la cola heredada del equipo C (2026-10-11)

**Decisión del propietario del 2026-10-11:** D toma las asignaciones que C dejó pendientes y publica en **ramas `d/...` propias**. El registro público es `avisos/D-a-B/2026-10-11-traspaso-pendientes-de-c.md`; aquí queda el plan operativo.

**Regla de continuidad.** D **no continúa** las ramas `c/...`. Parte de `feature/modelo-ng` en ramas `d/...` nuevas y usa el contenido de C como referencia.

| Orden | Rama `d/...` propuesta | Base | Primer paso exacto | Bloqueada por |
|---|---|---|---|---|
| 1 | `d/demo-leeme-vencimiento` | `feature/modelo-ng` (punta real, con `git fetch`) | Llevar la nota de `instalador/Demo/datos-demo/LEEME.md` de `c/demo-plantillas-lote` (`033c4d7`) a la rama de integración. Es solo documentación: no requiere pruebas | Nada. Es el trabajo más corto y desbloquea el PR #15 |
| 2 | `d/c13-revision-lote-correo` | `feature/modelo-ng` | **Rehacer la parte de destinatarios** del diseño (`docs/arquitectura/2026-10-10-c13-aviso-correo-revision-lote.md`) según la firma del propietario: correo general de la empresa con el origen en el asunto (ADR-11, punto 6). Confirmar con B qué preguntas C13-P01 a C13-P04 siguen vivas **antes** de construir | Respuesta de B a las preguntas; después, el diseño ajustado |
| 3 | `d/c10-compra-variable-tabla` | `feature/modelo-ng` | Solo si el 2.º PR de H-11 de A se une antes: **regenerar la migración** `20261010155005_Ola4CompraVariableTabla` con fecha posterior, con el guion acumulado. El PR #21 **lo une B**, no D | Que B confirme el orden de unión y el reinicio del 14-oct |
| 4 | `d/adr81-fase-a` | 2.º PR de H-11 de A, una vez unido | Construir la fase A, **T1 primero** si B lo encarga, con **T5b (≈0,35 sp)** —lo que depende del factor (§13.2)—. Tiene que rebasar sobre el PR de A | El 2.º PR de H-11 de A (`a/h11-p7-candado`; el PR #24 ya está entregado) |
| 5 | `d/adr118-119-ux` | `feature/modelo-ng` | Mantener y rebasar el diseño de pantallas (`b7be058`) y **entregarlo a B como base de T4** | Nada para rebasar; T4 lo construye B |

**Fuera de la cola, a decisión:** los cuatro repositorios WIP del rescate de C (`c/horizon-wip` `2958674`, `c/gsf-sync-transfer-wip` `c33ce3d`, `c/conector-iq-instalador-wip` `6429b2d`, `c/gsf-synctoiqs-wip` `515a80c`). D propone un triaje; **no los asume en bloque**.

**No entra:** los tres casos de secretos (solo en la máquina de C, son del propietario), C2-01 a C2-07 (ya encargados a A) y la configuración local de C.

**Antes de tocar cualquier rama:** `git fetch` y comprobar la punta real. La lección del 2026-10-11 fue que auditar contra el árbol de trabajo sin comprobar la línea base produjo veredictos falsos en ambos sentidos.

**Nota de entorno:** el shell confinado no inicializa TLS (`schannel: AcquireCredentialsHandle failed`), así que `git fetch`, `git push` y `gh` fallan; hay que pedir el sandbox abierto para ese comando concreto. El `pull --rebase` de la publicación del 2026-10-11 se resolvió así.
