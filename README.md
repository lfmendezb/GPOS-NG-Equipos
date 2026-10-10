# GPOS-NG-Equipos — área común de los equipos A, B y C

Repositorio privado de **coordinación** entre el **equipo B** (equipo nuevo: coordina, integra y une desde el 2026-10-09, por decisión del propietario) y los equipos de apoyo **A** (PC A; ramas `a/`) y **C** (antigua PC B, desde el 2026-10-09; ramas `c/`), que no unen. No contiene código: contiene lo que los dos equipos necesitan saber para trabajar como un solo equipo sobre todos los proyectos (`GPOS-NG`, `BackupService`, `GPOS-NG-AddOn-IQS` y los que vengan).

**Quién decide cuándo se actualiza:** el propietario, con una excepción: la **revisión obligatoria cada 30 minutos** (regla 8). Fuera de ella, el propietario le dice a cada equipo «actualiza desde el área común» (instalar memoria y agentes) o «publica en el área común»; ningún equipo instala ni publica por su cuenta salvo un aviso urgente (regla 6) o lo rutinario de la regla 8.

## Estructura

| Carpeta / archivo | Qué contiene | Quién escribe |
|---|---|---|
| `estado.md` | Tablero: qué hace cada equipo, ramas vivas por repositorio, bloqueos y pendientes del propietario | Cada equipo solo **su** sección; B (coordinador) la de pendientes del propietario |
| `memoria/` | Copia canónica de la memoria común de Claude (`*.md` y `MEMORY.md`) | **Solo B**, el coordinador (A y C proponen cambios con un aviso) |
| `agentes/` | Definiciones de los agentes (`%USERPROFILE%\.claude\agents\*.md`) | **Solo B** |
| `avisos/A-a-B/` | Avisos, preguntas, entregas y respuestas del equipo A para B | Solo A |
| `avisos/B-a-A/` | Avisos, hallazgos, entregas y respuestas del equipo B para A | Solo B |
| `avisos/C-a-B/` | Avisos del equipo C para B | Solo C |
| `avisos/B-a-C/` | Avisos del equipo B para C | Solo B |
| `traspasos/A/`, `traspasos/B/`, `traspasos/C/` | Notas de traspaso y de cierre de cada equipo | Cada equipo la suya |
| `herramientas/` | Scripts para actualizar, revisar y publicar (parámetro `-Equipo` con A, B o C) | Solo B |

## Reglas

1. **Cada equipo escribe solo en sus carpetas.** Así nunca hay conflictos de Git entre equipos.
2. **Avisos:** un archivo por tema, `AAAA-MM-DD-tema-corto.md`, con este encabezado:

   ```
   Para: B            De: A            Fecha: 2026-10-07
   Tipo: Aviso | Pregunta | Entrega | Hallazgo | Respuesta
   Prioridad: Alta | Normal
   Repositorio y rama: GPOS-NG feature/modelo-ng (si aplica)
   Estado: Abierto
   ```

   Una respuesta es un aviso nuevo en la carpeta del otro sentido que cita el original. El original lo marca `Estado: Atendido por <equipo> el <fecha>` **solo quien lo escribió**.
3. **Commits:** el mensaje empieza con `[A]` o `[B]`. Antes de publicar, `git pull --rebase`; nunca `--force`.
4. **Nunca secretos:** ninguna clave, contraseña, token, cadena de conexión ni dato de un cliente real, aunque el repositorio sea privado. El script de publicar se detiene si detecta uno.
5. **No reemplaza a los repositorios de código:** las ramas de trabajo siguen en cada proyecto; aquí solo se avisa que existen y en qué estado están. Los ADR se registran en `GPOS-NG` (`master`, `docs/adr/`), no aquí.
6. **Aviso urgente:** si un equipo encuentra algo que afecta al trabajo del otro, deja el aviso con `Prioridad: Alta`, lo publica y se lo dice al propietario en su sesión.
7. **El propietario firma:** un aviso nunca es una decisión. Las decisiones viven en las hojas de firma de cada proyecto.
8. **Revisión obligatoria cada 30 minutos** (decisión del propietario, 2026-10-07). Mientras una sesión de equipo esté abierta, revisa el área común cada 30 minutos con `herramientas\Revisar-AreaComun.ps1 -Equipo <A|B|C>` (trae lo nuevo y lista los avisos abiertos, marcando los nuevos), aunque el propietario no lo pida. Al abrir la sesión, la programa con una tarea recurrente de la sesión. Con lo que encuentre:
   - **Atiende sin preguntar lo rutinario** y se lo informa al propietario: acuses de recibo, respuestas informativas, actualizar `estado.md`, aplicar a la memoria común un cambio que el propietario ya decidió (solo B, el coordinador), registrar algo ya firmado (por ejemplo un ADR Aceptado) y publicarlo con el script.
   - **Le presenta al propietario, sin actuar**, todo lo que exija una decisión o firma, unir ramas, lanzar construcción en un árbol de código o tocar bases de datos.
   - Si no hay nada nuevo, no interrumpe al propietario.

## Cómo se usa

Clonar una vez en cada PC:

```powershell
cd "C:\Users\lfmen\source\repos"
```
```powershell
git clone https://github.com/lfmendezb/GPOS-NG-Equipos.git
```

**«Actualiza desde el área común»:**

```powershell
& "C:\Users\lfmen\source\repos\GPOS-NG-Equipos\herramientas\Actualizar-Desde-AreaComun.ps1" -Equipo B
```

Trae lo nuevo, guarda una copia de la memoria y los agentes locales, instala los del área común y lista los avisos **abiertos** para ese equipo. Luego la sesión de Claude del equipo lee esos avisos y `estado.md`.

**«Publica en el área común»:**

```powershell
& "C:\Users\lfmen\source\repos\GPOS-NG-Equipos\herramientas\Publicar-En-AreaComun.ps1" -Equipo A -Mensaje "tema"
```

Con `-Equipo A` copia además la memoria y los agentes locales al área común. Publica solo las carpetas del equipo.

Si los scripts no corren, en esa ventana de PowerShell: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned`.
