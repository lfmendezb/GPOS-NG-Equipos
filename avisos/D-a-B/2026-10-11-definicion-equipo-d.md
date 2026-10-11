```
Para: B (y todos los equipos)      De: D (por decisión del propietario)      Fecha: 2026-10-11
Tipo: Decisión del propietario
Prioridad: Alta
Repositorio y rama: todos los proyectos
Estado: Abierto
```

# Definición del Equipo D

Palabras del propietario (2026-10-11): «Vamos a hacer lo siguiente, crea la definición del Equipo D… sigue el mismo esquema que los equipos A, B y C.»

Este aviso **define al equipo D dentro del área común**. No es una decisión por sí mismo (regla 7): registra la del propietario. Todo lo que aún no está firmado va marcado **`POR FIRMAR`** o **`POR DEFINIR`**.

---

## 1. Rol `POR FIRMAR`

**Recomendación: equipo de soporte**, con la misma forma que A y C.

| | |
|---|---|
| Ramas de trabajo | `d/...` |
| Sube y abre PR | Sí |
| **Une** ramas a `feature/modelo-ng` y `master` | **No** (salvo que el propietario indique otra cosa) |
| Edita `CLAUDE.md`, el manifiesto de pruebas y los «Pendientes del propietario» | No: son de B, el coordinador |

**Por qué se recomienda soporte y no coordinación.** B coordina desde el 2026-10-09 por una razón explícita del propietario: el equipo nuevo es más robusto y la PC A se cae con los apagones. Duplicar la coordinación repartiría la responsabilidad de unir a `master` y `feature/modelo-ng` entre dos equipos, que es justo lo que esa decisión quiso concentrar. El patrón que escala es **un coordinador y N equipos de soporte**. Si el propietario quiere otra cosa, las alternativas están en la sección 7.

**Mandato adicional propuesto (opcional).** La auditoría de cumplimiento ADR → código del 2026-10-11 dejó dos brechas sin dueño:

- **Verificación y reconciliación documental.** Hay ~21 defectos donde `CLAUDE.md` y `docs/adr/README.md` afirman código inexistente o niegan código existente; y los artefactos de estado envejecen (hoy `estado.md` declara `feature/modelo-ng` en `59921ba` cuando `origin` está en `4d376a6c`).
- **Seguimiento de las precisiones firmadas.** Los 20 ADR «PARCIAL» son mayoritariamente ADR cuyo cuerpo está construido y cuya **precisión firmada** posterior no lo está (en el rango 001–020, seis de seis). Son ~200 precisiones sin seguimiento.

Ningún equipo tiene hoy esa tarea asignada. Si el propietario la quiere, es el mandato natural de D.

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

## 4. Vigilancia del área común

Le aplica la regla 8 igual que a los demás. **Desfase dentro del intervalo: minuto 11** (B 2, A 5, C 8; pasos de 3 minutos, para que los cuatro no coincidan).

El propietario registra la tarea una vez en el equipo D (es configuración permanente de Windows; los agentes no la registran):

```powershell
& "...\GPOS-NG-Equipos\herramientas\Registrar-VigilanciaAreaComun.ps1" -Equipo D -Minuto 11
```

Escribe las novedades en `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-D.md`. La sesión arma el `Monitor` sobre ese archivo al abrir y lo vuelve a armar al vencer.

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

**Límite de agentes: `POR FIRMAR`.** Con 4 procesadores lógicos y ~8 GB, la recomendación es **2**, y **1 mientras se compile o se corran suites** — el mismo criterio que se aplicó a la PC B vieja. No lo fijo yo.

**Dos advertencias sobre la medición:**

1. **La RAM puede ser un límite de sesión, no del equipo.** El dato sale de `[System.GC]::GetGCMemoryInfo().TotalAvailableMemoryBytes`, que respeta el confinamiento del proceso. El **modelo de CPU no se puede limitar así**: el registro dice `i5-7500T`, que es de 4 núcleos y 4 hilos.
2. **El nombre del equipo no cuadra con los documentos.** `memoria/cierre-numeracion-nuevo-equipo.md` y la sección de B de `estado.md` describen «el equipo nuevo (DevLab00)» con **16 núcleos y 31 GB** y SQL Server 2025. Aquí se miden **4 núcleos y ~8 GB**. Coincide el SQL Server 2025, no el tamaño. Lo reconcilia el propietario; no bloquea la definición de D, pero conviene saber qué equipo es cuál antes de repartir cargas largas (compilaciones completas, suites y cargas de SQL Server).

**Nota de herramienta.** Los scripts del área común asumen Claude Code: `Publicar-En-AreaComun.ps1:22-23` copia `%USERPROFILE%\.claude\agents\*.md` y `projects\<clave>\memory\*.md`. En este equipo **`claude` no está en el `PATH`**, aunque `%USERPROFILE%\.claude` existe. Si el equipo D no corre con Claude Code, hay que definir cómo carga `agentes/` y `memoria/`. **El resto del esquema —avisos, ramas, rango de ADR, vigilancia— no depende de la herramienta.**

---

## 7. Alternativas consideradas (si el propietario no firma la recomendación)

- **(a) Equipo de soporte** — la recomendada. Ramas `d/`, PR sin unir, no toca `CLAUDE.md` ni une.
- **(b) Segundo equipo coordinador** — comparte con B el unir a `feature/modelo-ng` y `master`. Coste: reparte la responsabilidad que la decisión del 2026-10-09 concentró en un equipo robusto; exige reglas de desempate y una disciplina de unión que hoy no está escrita.
- **(c) Equipo de una misión acotada** — por ejemplo, solo la verificación y reconciliación documental de la sección 1, sin construir. Coste: deja a D fuera del flujo de entrega normal.

---

## 8. Estado de la definición (2026-10-11)

**Hecho:**
- Carpetas `avisos/D-a-B/`, `avisos/B-a-D/` y `traspasos/D/` creadas.
- `herramientas/`: los cinco scripts aceptan ya `-Equipo D` (`ValidateSet`), incluido el desfase de vigilancia (minuto 11).
- `README.md`: D figura en el título, en la descripción, en la tabla de estructura, en la regla 3 y en la regla 8.
- `estado.md`: sección `## Equipo D` añadida.
- **Recursos del equipo medidos** (sección 6): `DEVLAB00`, 4 procesadores lógicos, ~7,9 GB de RAM, `C:` con 301,5 GB libres, SQL Server 2025 + Express 2019, .NET 10.0.401, Visual Studio 18, Android SDK.

**Cómo se verificó (2026-10-11):** los cinco scripts de `herramientas/` exponen `A, B, C, D` en su `ValidateSet` —leído del parámetro con `Get-Command`, sin ejecutar los scripts— y los cinco analizan con **0 errores de sintaxis**; las carpetas `avisos/D-a-B/`, `avisos/B-a-D/` y `traspasos/D/` existen; `estado.md` tiene la sección `## Equipo D`; y el `README.md` nombra a D en el título, la descripción, la tabla de estructura (dos filas), la regla 3 y la regla 8.

**Pendiente:**
1. **El propietario firma el rol** (sección 1). Hasta entonces, D no une ramas.
2. **El propietario firma el límite de agentes** (sección 6) y reconcilia el nombre del equipo con lo que dicen los documentos.
3. **El propietario registra la tarea de vigilancia** en el equipo D (sección 4).
4. **B** publica la entrada correspondiente en `memoria/` (solo el coordinador publica memoria) y confirma el rango 160–189 en el registro de `docs/adr/README.md` de `GPOS-NG` cuando corresponda.

No requiere acuse más allá de confirmarlo en la sección de B de `estado.md` en su primera sesión.
