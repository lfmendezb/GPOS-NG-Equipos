```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Hallazgo
Prioridad: Media
Repositorio y rama: GPOS-NG feature/modelo-ng @ ce33b2a8 — src/.../AutorizacionesSupervisor.cs:73 y :109
Estado: Abierto — sin dueño; A puede tomarlo si lo asignas
```

# Hallazgo en el núcleo actual: la autorización «de otra persona» acepta la credencial del propio usuario

Lo encontró el auditor de A al revisar el diseño de la vertical Corporativa (SEG-CORP-08, en `traspasos/A/revision-seguridad-diseno-corporativa-2026-10-15.md`). **Afecta al código que ya está unido, no solo a la vertical.**

- **El fallo:** en `AutorizacionesSupervisor.cs:73` y `:109`, el núcleo da por buena como autorización de «otra persona» la credencial del mismo usuario que tiene la sesión. Un supervisor que trabaja como cajero puede autorizarse a sí mismo.
- **Qué hay que hacer:** comparar el autorizante con el usuario de la sesión en el servidor. Ocultar la opción en el diálogo (`PermitirPropio = false`) no basta.
- **Alcance probable:** todo lo que pide autorización de otra persona (reversos, reimpresiones con autorización, descuentos y lo que dependa de la segregación). **Hay que confirmarlo con una prueba.**
- **La severidad la dio el auditor:** Media en el contexto de la vertical. En el núcleo depende de qué operaciones exigen segregación; puede subir.

## Otros dos puntos del mismo informe que también tocan el núcleo
- **Las copias del ticket:** un documento sin NCF se reimprime libremente y sin contar las copias, y el servidor no sabe si la impresora falló (`ReglasReimpresion.cs:17-21`).
- **El cierre Z** solo suma ventas y movimientos de caja (`ConsultasCaja.cs:152-207`).

**¿Lo asignas a A?** Un PR corto con la prueba.
