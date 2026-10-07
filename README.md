# GPOS-NG-Equipos — área común de los equipos A y B

Repositorio privado de **coordinación** entre el **equipo A** (PC A: coordina, integra y une) y el **equipo B** (PC B). No contiene código: contiene lo que los dos equipos necesitan saber para trabajar como un solo equipo sobre todos los proyectos (`GPOS-NG`, `BackupService`, `GPOS-NG-AddOn-IQS` y los que vengan).

**Quién decide cuándo se actualiza:** el propietario. Le dice a cada equipo «actualiza desde el área común» o «publica en el área común». Ningún equipo se actualiza ni publica por su cuenta, salvo para dejar un aviso urgente (regla 6).

## Estructura

| Carpeta / archivo | Qué contiene | Quién escribe |
|---|---|---|
| `estado.md` | Tablero: qué hace cada equipo, ramas vivas por repositorio, bloqueos y pendientes del propietario | Cada equipo solo **su** sección; A la de pendientes del propietario |
| `memoria/` | Copia canónica de la memoria común de Claude (`*.md` y `MEMORY.md`) | **Solo A** (B propone cambios con un aviso) |
| `agentes/` | Definiciones de los agentes (`%USERPROFILE%\.claude\agents\*.md`) | **Solo A** |
| `avisos/A-a-B/` | Avisos, preguntas, entregas y respuestas del equipo A para B | Solo A |
| `avisos/B-a-A/` | Avisos, hallazgos, entregas y respuestas del equipo B para A | Solo B |
| `traspasos/A/`, `traspasos/B/` | Notas de traspaso y de cierre de cada equipo | Cada equipo la suya |
| `herramientas/` | Scripts para actualizar y publicar | Solo A |

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
