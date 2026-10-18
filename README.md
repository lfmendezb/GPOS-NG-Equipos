# GPOS-NG-Equipos — área común de los equipos A y B

Repositorio privado de **coordinación** entre el **equipo B** (equipo nuevo, en LFMB desde el 2026-10-14: coordina, integra y une desde el 2026-10-09, por decisión del propietario) y el equipo de apoyo **A** (PC A; ramas `a/`), que no une.

> **Equipo C disuelto el 2026-10-14** (decisión del propietario): sus funciones pasaron a A y B (ver `avisos/B-a-C/2026-10-14-disolucion-del-equipo-c.md`). Sus carpetas (`avisos/C-a-B/`, `avisos/B-a-C/` y `traspasos/C/`) se conservan como historial de solo lectura. Su rango de ADR (130 a 159) queda congelado. No contiene código: contiene lo que los dos equipos necesitan saber para trabajar como un solo equipo sobre todos los proyectos (`GPOS-NG`, `BackupService`, `GPOS-NG-AddOn-IQS` y los que vengan).

**Quién decide cuándo se actualiza:** el propietario, con una excepción: la **revisión obligatoria cada 30 minutos** (regla 8). Fuera de ella, el propietario le dice a cada equipo «actualiza desde el área común» (instalar memoria y agentes) o «publica en el área común»; ningún equipo instala ni publica por su cuenta salvo un aviso urgente (regla 6) o lo rutinario de la regla 8.

**Objetivos del MVP:** [lista F1–F10, criterios, meta y avance publicado](MVP.md).

## Estructura

| Carpeta / archivo | Qué contiene | Quién escribe |
|---|---|---|
| `estado.md` | Tablero: qué hace cada equipo, ramas vivas por repositorio, bloqueos y pendientes del propietario | Cada equipo solo **su** sección; B (coordinador) la de pendientes del propietario |
| `memoria/` | Copia canónica de la memoria común de Claude (`*.md` y `MEMORY.md`) | **Solo B**, el coordinador (A propone cambios con un aviso) |
| `agentes/` | Definiciones de los agentes (`%USERPROFILE%\.claude\agents\*.md`) | **Solo B** |
| `avisos/A-a-B/` | Avisos, preguntas, entregas y respuestas del equipo A para B | Solo A |
| `avisos/B-a-A/` | Avisos, hallazgos, entregas y respuestas del equipo B para A | Solo B |
| `avisos/C-a-B/`, `avisos/B-a-C/` | Historial del equipo C (disuelto el 2026-10-14) | Nadie (solo lectura) |
| `traspasos/A/`, `traspasos/B/` | Notas de traspaso y de cierre de cada equipo | Cada equipo la suya |
| `traspasos/C/` | Historial del equipo C | Nadie (solo lectura) |
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
3. **Commits:** el mensaje empieza con `[A]`, `[B]` o `[C]`. Antes de publicar, `git pull --rebase`; nunca `--force`.
4. **Nunca secretos:** ninguna clave, contraseña, token, cadena de conexión ni dato de un cliente real, aunque el repositorio sea privado. El script de publicar se detiene si detecta uno.
5. **No reemplaza a los repositorios de código:** las ramas de trabajo siguen en cada proyecto; aquí solo se avisa que existen y en qué estado están. Los ADR se registran en `GPOS-NG` (`master`, `docs/adr/`), no aquí.
6. **Aviso urgente:** si un equipo encuentra algo que afecta al trabajo del otro, deja el aviso con `Prioridad: Alta`, lo publica y se lo dice al propietario en su sesión.
7. **El propietario firma:** un aviso nunca es una decisión. Las decisiones viven en las hojas de firma de cada proyecto.
8. **Vigilancia del área común** (decisión del propietario, 2026-10-07; desde el 2026-10-10 sin el modelo). Una tarea programada de Windows, registrada por el propietario en cada equipo con `herramientas\Registrar-VigilanciaAreaComun.ps1 -Equipo <A|B|C> [-Minuto n]`, corre `herramientas\Vigilar-AreaComun.ps1` **cada 10 minutos** (desfase: B 2, A 5, C 8) y escribe las novedades en `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-<Equipo>.md` con una notificación de Windows. La sesión **no** programa un reloj propio: lee ese archivo al abrir y cuando el propietario lo pida (o usa `Revisar-AreaComun.ps1` a mano). **Vigilante en la sesión (decisión del propietario, 2026-10-10):** al abrir, cada sesión de equipo arma la herramienta `Monitor` sobre su archivo de novedades, con `timeout_ms` 1800000 y este comando (Git Bash), y la vuelve a armar cada vez que vence:

   ```bash
   f="$LOCALAPPDATA/GPOS-NG-Equipos/novedades-<Equipo>.md"; touch "$f"; n=$(wc -l < "$f"); while true; do m=$(wc -l < "$f" 2>/dev/null || echo "$n"); if [ "$m" -gt "$n" ]; then sed -n "$((n+1)),${m}p" "$f" | grep -E "^## |^- "; n=$m; fi; sleep 20; done
   ```

   Mientras no hay novedades no gasta vueltas del modelo; cuando la tarea de Windows escribe una, la sesión se despierta, lee el aviso y actúa. Al terminar una tarea, antes de quedar inactiva, la sesión lee también su archivo de novedades. Con lo que encuentre:
   - **Atiende sin preguntar lo rutinario** y se lo informa al propietario: acuses de recibo, respuestas informativas, actualizar `estado.md`, aplicar a la memoria común un cambio que el propietario ya decidió (solo B, el coordinador), registrar algo ya firmado (por ejemplo un ADR Aceptado) y publicarlo con el script.
   - **Le presenta al propietario, sin actuar**, todo lo que exija una decisión o firma, unir ramas, lanzar construcción en un árbol de código o tocar bases de datos.
   - Si no hay nada nuevo, no interrumpe al propietario.
9. **Informar cada tarea completada** (decisión del propietario, 2026-10-10). Cada vez que un equipo termina una tarea encargada (entrega, PR abierto, corrección, revisión, publicación o tarea cancelada o bloqueada), deja **en el momento** un aviso `Tipo: Entrega` (o `Hallazgo` si queda bloqueada) en `avisos/<Equipo>-a-B/` con qué se hizo, dónde (rama, commit, PR o ruta), cómo se verificó (pruebas y cifras) y qué queda pendiente, y actualiza su sección de `estado.md`. B, el coordinador, hace lo mismo hacia A y C cuando une o termina algo que les afecta. No se espera a la revisión siguiente ni a que el propietario pregunte.

10. **Contexto corto** (decisión del propietario, 2026-10-18; propuesta de C `C-a-B/2026-10-18-propuesta-ahorro-de-contexto`). Lo que cada sesión lee al abrir se mantiene pequeño:
    - **`estado.md`:** cada equipo deja en su sección **sus 3 entradas más recientes** y mueve las demás a `estado-historia/AAAA-MM.md` (al cambiar de sesión o cada lunes). B hace lo mismo con «Pendientes del propietario», que solo lista lo abierto.
    - **Avisos:** al atender un aviso, su autor lo marca `Estado: Cerrado` (regla 2). **B archiva cada semana** los avisos de más de 3 días en `avisos/archivo/AAAA-MM/<de>-a-<para>/`, sin cambiar el nombre ni el contenido; las herramientas solo miran `avisos/<de>-a-<para>/`, así que lo archivado no se vuelve a leer al abrir. Para citar un aviso archivado basta su nombre.
    - **Memoria común:** B la consolida cuando una entrada queda sustituida (se borra en `memoria/` y en el índice); las líneas del índice, de unos 100 caracteres como máximo.
    - **`CLAUDE.md` (GPOS-NG):** solo las reglas que se aplican siempre; la historia de las firmas y lo que sigue «Decidido, no implementado» vive en `docs/adr/estado-de-construccion.md` y en `docs/adr/README.md`.
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
