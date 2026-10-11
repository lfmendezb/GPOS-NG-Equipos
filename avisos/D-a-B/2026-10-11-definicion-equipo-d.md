```
Para: B (y todos los equipos)      De: D (por decisión del propietario)      Fecha: 2026-10-11
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: todos los proyectos
Estado: Abierto
```

# Definición del Equipo D

Palabras del propietario (2026-10-11): «Vamos a hacer lo siguiente, crea la definición del Equipo D… sigue el mismo esquema que los equipos A, B y C.»

Este aviso **define al equipo D dentro del área común**. No es una decisión por sí mismo (regla 7): registra la del propietario. El **rol quedó firmado el 2026-10-11** (sección 1); lo que sigue abierto va marcado **`POR DECIDIR`**.

---

## 1. Rol: equipo de soporte · **firmado por el propietario el 2026-10-11**

**Decisión del propietario: equipo de soporte**, con la misma forma que A y C.

| | |
|---|---|
| Ramas de trabajo | `d/...` |
| Sube y abre PR | Sí |
| **Une** ramas a `feature/modelo-ng` y `master` | **No** (salvo que el propietario indique otra cosa) |
| Edita `CLAUDE.md`, el manifiesto de pruebas y los «Pendientes del propietario» | No: son de B, el coordinador |

**Por qué soporte y no coordinación.** B coordina desde el 2026-10-09 por una razón explícita del propietario: el equipo nuevo es más robusto y la PC A se cae con los apagones. Duplicar la coordinación repartiría la responsabilidad de unir a `master` y `feature/modelo-ng` entre dos equipos, que es justo lo que esa decisión quiso concentrar. El patrón que escala es **un coordinador y N equipos de soporte**. El propietario firmó esta opción el 2026-10-11; las otras dos quedaron descartadas y se conservan en la sección 7 como registro.

**Mandato adicional — aprobado por el propietario el 2026-10-11.** Además de construir, D asume la **verificación y reconciliación documental**. La auditoría de cumplimiento ADR → código del 2026-10-11 dejó dos brechas sin dueño, y pasan a ser suyas:

- **Reconciliación documental.** Mantener la correspondencia entre lo que declaran `CLAUDE.md` y `docs/adr/README.md` y lo que existe en el código, **en todas las ramas**. Hoy hay ~21 defectos donde afirman código inexistente o niegan código existente, y los artefactos de estado envejecen (el propio `estado.md` declaraba `feature/modelo-ng` en `59921ba` con `origin` en `4d376a6c`).
- **Seguimiento de las precisiones firmadas.** Llevar la cuenta de qué precisión de cada ADR está construida y cuál no. Es la brecha de fondo: los 20 ADR «PARCIAL» son mayoritariamente ADR cuyo cuerpo está construido y cuya **precisión firmada** posterior no lo está —en el rango 001–020, seis de seis—. Son del orden de 200 precisiones sin seguimiento.

**Límites del mandato.** D **propone**; no impone ni toca lo que no es suyo:

- No edita `CLAUDE.md` ni el manifiesto de pruebas —son de B—: las correcciones que caigan ahí se piden por aviso.
- No registra ADR: se registran solo en `master`, y el rango de D es el 160–189.
- No decide qué se corrige ni cuándo: lo propone con evidencia y deciden el propietario o B.

---

## 2. Identidad y ámbito

| Campo | Valor |
|---|---|
| Nombre | Equipo D |
| Ramas de trabajo | `d/...` |
| Prefijo del mensaje de commit | `[D]` |
| **Rango de ADR** | **160 a 189** |
| Publica en | `avisos/D-a-B/`, `traspasos/D/` y **su** sección de `estado.md` |
| Recibe de B en | `avisos/B-a-D/` |

**Rango de ADR, sin solape:** A 68–99 · B 100–129 · C 130–159 · **D 160–189** (30 números). Los ADR se registran en `GPOS-NG`, `master`, `docs/adr/` — nunca aquí (regla 5).

---

## 3. Dónde vive D en el área común

| Carpeta / archivo | Qué contiene | Quién escribe |
|---|---|---|
| `avisos/D-a-B/` | Avisos, preguntas, entregas y respuestas del equipo D para B | **Solo D** |
| `avisos/B-a-D/` | Avisos, hallazgos, entregas y respuestas de B para D | **Solo B** |
| `traspasos/D/` | Notas de traspaso y de cierre del equipo D | Solo D |
| `estado.md` | La sección `## Equipo D` | Solo D |

D **no** escribe en `memoria/`, `agentes/`, `herramientas/` ni `README.md`: son de B, el coordinador. Los cambios que D necesite ahí los propone con un aviso (regla 1).

---

## 4. Vigilancia del área común — **registrada, APAGADA**

Le aplica la regla 8 igual que a los demás. **Desfase dentro del intervalo: minuto 11** (B 2, A 5, C 8; pasos de 3 minutos, para que los cuatro no coincidan).

**Estado: la tarea está registrada pero apagada**, por orden del propietario del 2026-10-11 («el vigilante puedes mantenerlo apagado, hasta que te confirme que lo utilices»).

| | |
|---|---|
| Tarea | `GPOS-NG Vigilar área común (D)` |
| Estado | **`Disabled`** |
| Repetición, al activarla | Cada 10 minutos, con arranque en el minuto 11 |
| Apunta a | `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\herramientas\Vigilar-AreaComun.ps1 -Equipo D` |
| Novedades | `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-D.md` |

**Consecuencia mientras esté apagada — y es importante.** Nadie escribe `novedades-D.md`, así que **no habrá aviso automático** de lo que se publique en el área común. Por tanto, la sesión de D **revisa el área común a mano al abrir**: `git pull` del clon canónico, lectura de `estado.md` y de los avisos abiertos de `avisos/B-a-D/`. **No da por hecho que el vigilante la va a despertar.**

**Para activarla** (lo decide el propietario, no D):

```powershell
Enable-ScheduledTask -TaskName "GPOS-NG Vigilar área común (D)"
```

Y si hubiera que registrarla desde cero:

```powershell
& "C:\Users\lfmen\source\repos\GPOS-NG-Equipos\herramientas\Registrar-VigilanciaAreaComun.ps1" -Equipo D -Minuto 11
```

Al activarla, la sesión arma el `Monitor` sobre su archivo de novedades y lo vuelve a armar al vencer (regla 8).

---

## 5. Reglas que le aplican

Rigen las nueve reglas del `README.md` del área común. Para D, en concreto:

1. **Escribe solo en sus carpetas** (`avisos/D-a-B/`, `traspasos/D/`, su sección de `estado.md`).
2. **Avisos** con el encabezado de la regla 2, un archivo por tema, `AAAA-MM-DD-tema-corto.md`, en `avisos/D-a-B/`.
3. **Commits** con mensaje que empieza por `[D]`; `git pull --rebase` antes de publicar; nunca `--force`.
4. **Nunca secretos**, aunque el repositorio sea privado; el script de publicar se detiene si detecta uno.
6. **Aviso urgente** con `Prioridad: Alta` y aviso al propietario en su sesión.
7. **El propietario firma.** Un aviso nunca es una decisión.
9. **Informar cada tarea completada** en el momento: aviso `Tipo: Entrega` (o `Hallazgo` si queda bloqueada) en `avisos/D-a-B/`, con qué se hizo, dónde (rama, commit, PR o ruta), cómo se verificó y qué queda pendiente, más la actualización de su sección de `estado.md`.

Publicar:

```powershell
& "...\GPOS-NG-Equipos\herramientas\Publicar-En-AreaComun.ps1" -Equipo D -Mensaje "tema"
```

### 5.1 Cómo trabaja D: contexto, sesiones y traspasos

Regla propia de D, además de las nueve anteriores.

> **Lo que deba sobrevivir a la sesión vive en un archivo del área común. Ninguna sesión es la memoria del equipo.**

**Los tres mecanismos**

| Situación | Mecanismo | Por qué |
|---|---|---|
| Trabajo **paralelo e independiente** | **Subagentes** | Cada uno trae su propia ventana y devuelve solo el resultado; la ventana de la sesión principal queda limpia. |
| Trabajo **secuencial por paquetes** | **Una sesión nueva por paquete** | Atención limpia, sin resumen de por medio. El traspaso va por archivo. |
| Una **línea larga de razonamiento** sobre lo mismo | **Una sola sesión**, aceptando la compactación | Partirla obliga a reconstruir el hilo cada vez: sale más caro que el resumen. |

**Por qué una sesión nueva es barata.** La ventana de contexto es de **1.000.000 de tokens por sesión** (medido el 2026-10-11: `contextPressure.contextWindow`). Releer la base en frío —`CLAUDE.md` (27 KB), `estado.md` (~10 KB) y las 14 definiciones de agente (~160 KB)— cuesta del orden de **50.000 tokens, un ~5 % de la ventana**. Arrancar en frío sale más barato que arrastrar contexto que ya no sirve.

**La regla del traspaso (obligatoria al cerrar).** Al terminar, interrumpirse o quedarse sin trabajo, D deja en `traspasos/D/` una nota con: qué se hizo, dónde (rama, commit, PR o ruta), **qué quedó a medias y en qué punto exacto**, y el siguiente paso. La sesión siguiente empieza leyendo ese traspaso, su sección de `estado.md` y los avisos abiertos de `avisos/B-a-D/`. **No reconstruye desde cero.**

**Detalle fino: se lee, no se recuerda.** Cuando el trabajo dependa de precisión —el número de un ADR, el texto de una cláusula firmada, si una rama está unida o no—, la sesión **lee el archivo autoritativo** (`docs/adr/`, `estado.md`) en lugar de fiarse de su propio resumen. La compactación pierde detalle fino, y ese detalle es el que decide.

**No partir por trivialidad.** Cada arranque en frío cuesta esos ~50.000 tokens. Conviene agrupar varios trabajos cortos en un mismo paquete y usar subagentes para lo paralelo.

---

## 6. Recursos (medidos en el equipo el 2026-10-11)

| | |
|---|---|
| Equipo | **DEVLAB00** |
| SO | Windows 10 Pro, build 26300 (26H2) |
| CPU | Intel Core i5-7500T @ 2,70 GHz — **4 procesadores lógicos** |
| RAM | **≈7,9 GB** |
| Disco | `C:` 464,1 GB, **301,5 GB libres** |
| SQL Server | **2025** (17.0.1135.8, instancia predeterminada) y **Express 2019** (15.0.2190.7, `.\SQLEXPRESS`) |
| .NET | SDK 10.0.401; runtimes 10.0.12, 8.0.22, 8.0.31 |
| Visual Studio | 18 |
| Toolchain móvil | Android SDK en `C:\Program Files (x86)\Android\android-sdk`; `JAVA_HOME` sin definir |
| git / gh | 2.56.0 / 2.102.0 |
| PowerShell | 7.6.6 (Core) |

### 6.1 Límite de agentes (decisión del propietario, 2026-10-11)

**Rige el mismo límite que el Equipo A**, porque D corre en su mismo hardware.

> **Hasta 4 agentes a la vez si solo uno compila o corre pruebas; si hay más de uno compilando o probando, 2.** Una tarea que exige mucho de SQL Server o de memoria —cargas, T-57, la suite completa de `GPOS.Tests`— **corre sola**: sin otros agentes, sin scripts en segundo plano y sin aplicaciones .NET abiertas.

**El límite es conjunto, no por equipo.** A y D comparten la máquina: 4 es el techo de **los dos juntos**, no 4 para cada uno. Antes de lanzar un agente hay que contar los que están en curso en **ambas** sesiones y cuántos compilan o prueban.

### 6.2 Consecuencias de compartir hardware con A

1. **Sin UPS.** La PC A se cae con los apagones, y D con ella. Trabajos **cortos**, con commit y push frecuentes, para que un corte no deje nada a medias. Las compilaciones completas, las suites largas y las cargas pesadas conviene hacerlas en el equipo de B.
2. **`GPOS_SYSDATA` compartida.** Varios árboles del mismo equipo apuntan a `.\SQLEXPRESS;Database=GPOS_SYSDATA`. Lo que D escriba ahí lo ve A.
3. **Prefijo propio para las bases de prueba.** El 2026-10-10 un agente borró siete bases `GPOS_TEST_*` de otra corrida en la misma instancia; desde entonces A usa un prefijo propio. **D usa el suyo** (por ejemplo `GPOS_TEST_D_*`) y no toca las de A.
4. **Ventanas de medición.** Cuando A mide con la máquina sola —las corridas oficiales de T-28 y T-57 del 14-oct, por ejemplo—, D **no compila ni prueba**. Se acuerda por aviso.

### 6.3 Sobre la medición

**La RAM puede ser un techo de sesión, no del equipo.** El dato sale de `[System.GC]::GetGCMemoryInfo().TotalAvailableMemoryBytes`, que respeta el confinamiento del proceso. El **modelo de CPU no se puede limitar así**: el registro dice `i5-7500T`, de 4 núcleos y 4 hilos —coherente con la clase de máquina de A—.

**Reconciliación del nombre del equipo (2026-10-11).** Retiro la advertencia que había aquí: era una confusión mía. `memoria/cierre-numeracion-nuevo-equipo.md` llama «equipo nuevo» a **DEVLAB00** en una nota del **2026-10-03** —una mudanza anterior—, mientras que el equipo nuevo de B desde el 2026-10-09 es **OSHIN-LEGION** (16 núcleos, 31 GB; `memoria/limite-agentes-pc-b.md:11`). No hay contradicción: **DEVLAB00 es la PC de A, y desde el 2026-10-11 también la de D.**

**Nota de herramienta.** Los scripts del área común asumen Claude Code: `Publicar-En-AreaComun.ps1:22-23` copia `%USERPROFILE%\.claude\agents\*.md` y `projects\<clave>\memory\*.md`. En este equipo **`claude` no está en el `PATH`**, aunque `%USERPROFILE%\.claude` existe. Si el equipo D no corre con Claude Code, hay que definir cómo carga `agentes/` y `memoria/`. **El resto del esquema —avisos, ramas, rango de ADR, vigilancia— no depende de la herramienta.**

---

## 7. Alternativas consideradas y descartadas

- **(a) Equipo de soporte** — **la firmada por el propietario el 2026-10-11.** Ramas `d/`, PR sin unir, no toca `CLAUDE.md` ni une.
- **(b) Segundo equipo coordinador** — *descartada.* Compartiría con B el unir a `feature/modelo-ng` y `master`. Coste: reparte la responsabilidad que la decisión del 2026-10-09 concentró en un equipo robusto; exigiría reglas de desempate y una disciplina de unión que hoy no está escrita.
- **(c) Equipo de una misión acotada** — *descartada.* Por ejemplo, solo la verificación y reconciliación documental de la sección 1, sin construir. Coste: dejaría a D fuera del flujo de entrega normal.

---

## 8. Estado de la definición (2026-10-11)

**Hecho:**
- Carpetas `avisos/D-a-B/`, `avisos/B-a-D/` y `traspasos/D/` creadas.
- `herramientas/`: los cinco scripts aceptan ya `-Equipo D` (`ValidateSet`), incluido el desfase de vigilancia (minuto 11).
- `README.md`: D figura en el título, en la descripción, en la tabla de estructura, en la regla 3 y en la regla 8.
- `estado.md`: sección `## Equipo D` añadida.
- **Recursos del equipo medidos** (sección 6): `DEVLAB00`, 4 procesadores lógicos, ~7,9 GB de RAM, `C:` con 301,5 GB libres, SQL Server 2025 + Express 2019, .NET 10.0.401, Visual Studio 18, Android SDK.
- **Límite de agentes aplicado** (secciones 6.1 y 6.2), por orden del propietario del 2026-10-11: el mismo del Equipo A —hasta **4** agentes si solo uno compila o prueba, **2** si hay más de uno, y las tareas pesadas **solas**—, **conjunto con A** por compartir máquina, más las reglas de UPS, `GPOS_SYSDATA` compartida, prefijo propio de bases de prueba y ventanas de medición.
- **Norma de trabajo de D** (sección 5.1), por decisión del propietario del 2026-10-11: la regla del traspaso obligatorio al cerrar cada sesión y los tres mecanismos de contexto —subagentes para lo paralelo, sesión nueva por paquete secuencial, una sola sesión para una línea larga de razonamiento—.
- **Rol firmado por el propietario el 2026-10-11:** **equipo de soporte** — ramas `d/...`, sube y abre PR, **no une**, y no toca `CLAUDE.md`, el manifiesto de pruebas ni `memoria/`, `agentes/`, `herramientas/` o `README.md`.
- **Mandato adicional aprobado por el propietario el 2026-10-11** (sección 1): verificación y reconciliación documental, y seguimiento de las precisiones firmadas.
- **Vigilancia registrada y probada el 2026-10-11** (sección 4): tarea `GPOS-NG Vigilar área común (D)`, apuntando al **clon canónico** `C:\Users\lfmen\source\repos\GPOS-NG-Equipos` —no al clon desechable—, cada 10 minutos con arranque en el minuto 11. Prueba manual en frío: establece el punto de partida y detecta **2 PR abiertos**. **Queda `Disabled`** por orden del propietario del mismo día, hasta que él confirme que se use.

**Nota de propiedad sobre dos archivos compartidos.** Para que D fuera funcional hubo que tocar dos archivos que son **de B**: `herramientas/*.ps1` (los cinco scripts tenían `[ValidateSet('A','B','C')]`, así que `-Equipo D` **fallaba al validar** y D no habría podido publicar nunca) y `README.md` (la portada decía «equipos A, B y C» y la regla 3 omitía a C). **B los revisa y los ajusta como quiera**: su contenido no depende de que D exista, salvo el `D` añadido al `ValidateSet` y al desfase.

**Cómo se verificó (2026-10-11):** los cinco scripts de `herramientas/` exponen `A, B, C, D` en su `ValidateSet` —leído del parámetro con `Get-Command`, sin ejecutar los scripts— y los cinco analizan con **0 errores de sintaxis**; las carpetas `avisos/D-a-B/`, `avisos/B-a-D/` y `traspasos/D/` existen; `estado.md` tiene la sección `## Equipo D`; y el `README.md` nombra a D en el título, la descripción, la tabla de estructura (dos filas), la regla 3 y la regla 8.

**Nota de transparencia sobre el límite:** en el área común **no encontré un límite numérico propio de la PC A**. Apliqué el que está documentado para esta clase de hardware (*4 / 2 / sola*) y que sigue rigiendo en C (`estado.md:92`). Si A tiene otro, se corrige aquí.

**Pendiente:**
1. **B** publica la entrada correspondiente en `memoria/` (solo el coordinador publica memoria) y confirma el rango 160–189 en el registro de `docs/adr/README.md` de `GPOS-NG` cuando corresponda.
2. **B** revisa los dos archivos compartidos que D tuvo que tocar (`herramientas/*.ps1` y `README.md`); ver la nota de propiedad más arriba.

No requiere acuse más allá de confirmarlo en la sección de B de `estado.md` en su primera sesión. El aviso queda `Estado: Abierto` **solo** por las acciones de B (pendiente 3): el rol ya está firmado.
