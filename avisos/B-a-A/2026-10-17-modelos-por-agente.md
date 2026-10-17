Para: A y C        De: B (coordinador)            Fecha: 2026-10-17
Tipo: Aviso
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos `agentes/` y `memoria/` (no aplica a código)
Estado: Abierto

# Nuevo modelo por agente (decisión del propietario del 2026-10-17)

El uso se estaba consumiendo muy rápido porque todos los agentes corrían con Opus 5.5: la memoria `agentes-con-opus` obligaba a pasar `model: "opus"` en cada lanzamiento, aunque la definición dijera otra cosa. El propietario aprobó «tal cual» esta asignación por tipo de trabajo:

| Modelo | Agentes |
|---|---|
| **Opus 5.5** (`opus`) | arquitecto-maestro, arquitecto-datos, arquitecto-software, auditor-seguridad, especialista-contable, desarrollador-backend (por omisión) |
| **Sonnet 5.5** (`sonnet`) | arquitecto-integraciones, especialista-pos, desarrollador-frontend, disenador-ux-ui, documentador-tecnico, qa-automatizado, devops |
| **Haiku 5.5** (`haiku`) | orquestador; agentes Explore y búsquedas de solo lectura |

Cambian 6 definiciones: integraciones, especialista-pos, frontend, UX y documentador pasan de `opus` a `sonnet`; el orquestador pasa de `sonnet` a `haiku`.

## Reglas

1. **Se retira la regla de forzar Opus.** Manda el `model:` de la definición; en la llamada a `Agent` no se pasa `model: "opus"` por costumbre.
2. **desarrollador-backend con Sonnet** para lo mecánico: rebase, renombres, SQL idempotente ya diseñado, correcciones de una o dos líneas.
3. **Escalar a Opus** cualquier agente cuando la tarea toque el orden de bloqueos, NCF o e-CF, costos o kárdex, aislamiento entre empresas, criptografía o licencia, o cuando un agente con Sonnet falle dos veces en lo mismo. Integraciones: Opus para diseñar el contrato de un tercero nuevo. QA: Opus para analizar concurrencia o carga.
4. **Fable 5.1** sigue reservado para la revisión general al cerrar las olas.

## Qué debe hacer cada equipo

- Al terminar lo que tenga en curso (sin interrumpir agentes activos), correr `herramientas\Actualizar-Desde-AreaComun.ps1 -Equipo <A|C>` para instalar las definiciones de `agentes/` y la memoria `agentes-con-opus` actualizada (y `fable-revision-general-tras-olas`).
- Comprobar con `Select-String '^model:' $env:USERPROFILE\.claude\agents\*.md` que los modelos coinciden con la tabla.
- Los agentes ya lanzados terminan con su modelo actual; los que se lancen desde ahora siguen la tabla.
- Acusar recibo en `avisos/<Equipo>-a-B/`.
