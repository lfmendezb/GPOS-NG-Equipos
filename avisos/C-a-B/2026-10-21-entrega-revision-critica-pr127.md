```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Entrega (tarea 4: revisión crítica del #127, incluido el #136)
Prioridad: Media
Repositorio y rama: no aplica (informe en el área común y comentario en el #127)
Estado: Abierto
```

# Entrega: revisión crítica del #127 (y el diff del #136)

Informe completo: `traspasos/C/2026-10-21-revision-critica-pr127-y-pr136.md`. Comentario con el resumen en el [#127](https://github.com/lfmendezb/GPOS-NG/pull/127).

## Resumen de las 3 preguntas que hizo
1. **Quitar `ComprobarArranque`:** falla (la arquitectura lo exige por texto exacto).
2. **Invertir identidad/privilegios:** falla en `Comprobar`. Hallazgo **P127-01 (Baja)**: dentro de `Decidir`, nada impide mover la lectura de privilegios antes del corte de identidad sin que ninguna prueba lo note (el resultado final no cambiaría, pero se leería el token de más). Sugerí un `Assert` con `NoDebeLeerse` para esa combinación exacta; no bloquea.
3. **`Rechazar` sin salir con 1:** se prueba por texto fuente, no por ejecución (no se puede ejecutar sin terminar el proceso de pruebas); es la misma técnica que ya usa el proyecto, no una debilidad nueva.
4. **Sin ninguna prueba:** `CicloDeVidaServicio` completa (los eventos 4768/4769/4770 y la rama `catch (Win32Exception)`). No es un descuido: `GPOS.Api` no da `InternalsVisibleTo` a `GPOS.Tests`, y el propio comentario de la clase ya deja esto para el ensayo de devops (L-04/L-05). Para que decida: dejarlo así, o agregar `InternalsVisibleTo` si quiere la prueba unitaria.

Compilé y corrí con el filtro de clases de Servicio y Arquitectura: 548/549 (la omitida, `PF12`, es a propósito y sin relación). Ningún hallazgo bloquea el #127 ni el #136.

Antes del 29-oct, como estaba previsto. Sigo con la tarea 3 (revisión de pruebas del #130 y correcciones del #122), con plazo 28-oct.
