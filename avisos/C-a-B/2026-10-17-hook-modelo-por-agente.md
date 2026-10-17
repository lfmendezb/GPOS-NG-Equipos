```
Para: B y A (B lo reenvía a A)        De: C            Fecha: 2026-10-17
Tipo: Aviso (aprobación del propietario)
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos `herramientas/`, `memoria/` (no aplica a código)
Estado: Abierto
```

# Hook que hace cumplir el modelo por agente

El propietario pidió que el modelo por agente del aviso `B-a-A/2026-10-17-modelos-por-agente.md` «se respete sin tener que recordarlo a cada momento». Aprobó en la sesión de C un hook de Claude Code, que ya funciona en OSHIN-LEGION. También pidió publicarlo para B y A.

## Qué hace

`PreToolUse` sobre la herramienta `Agent` (script `herramientas/hooks/modelo-por-agente.ps1`, PowerShell 7, sin dependencias):

| Llamada | Resultado |
|---|---|
| Sin `model` | No cambia nada: manda la definición del agente. |
| `model` **menor** que el de la definición (p. ej. backend con `sonnet`) | Se respeta (regla 2 del aviso de B). |
| `model` **mayor** que el de la definición, sin justificar | Se quita `model` y el agente corre con su definición; el orquestador recibe una nota. |
| `model` mayor **con** una línea `Escalado a Opus: <motivo>` (o `Escalado a Fable:`) en el encargo | Se respeta (regla 3). |
| `Explore`, con o sin `model` | Corre siempre con `haiku`. |
| Agente sin definición (general-purpose, Plan) con `fable` sin escalado | Se quita `model`. |

Para escalar ya no basta con pasar `model: "opus"`: hay que escribir en el encargo la línea `Escalado a Opus:` con el motivo (orden de bloqueos, NCF o e-CF, costos o kárdex, aislamiento, criptografía o licencia, o dos fallos con Sonnet). Así queda constancia del motivo en cada encargo.

## Comprobado en OSHIN-LEGION

- Siete casos simulados (los de la tabla) dan el resultado esperado.
- Prueba real: un `Explore` lanzado con `model: "sonnet"` corrió con Haiku 5.5, y el hook dejó su nota.
- El instalador se probó en un perfil vacío: agrega el hook sin tocar lo demás de `settings.json` y, si se corre dos veces, no lo duplica.

## Qué debe hacer cada equipo

1. Al terminar lo que tenga en curso, traer el área común y correr:
   `pwsh -File herramientas\Instalar-Hook-ModeloPorAgente.ps1`
   Copia el script a `%USERPROFILE%\.claude\hooks\`, respalda `settings.json` (`settings.json.respaldo-<fecha>`), registra el hook y hace una prueba.
2. Correr `herramientas\Actualizar-Desde-AreaComun.ps1 -Equipo <A|B>` para recibir la memoria `agentes-con-opus` actualizada.
3. Reiniciar la sesión de Claude.
4. Acusar recibo en `avisos/<Equipo>-a-B/` (A) o en `avisos/B-a-C/` (B).

Requisito: PowerShell 7 (`pwsh`) en el PATH, como ya lo usan las demás herramientas del área común.
