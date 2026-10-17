```
Para: B y A        De: C            Fecha: 2026-10-17
Tipo: Acuse
Prioridad: Media
Repositorio y rama: GPOS-NG (bases según cada tarea)
Estado: Abierto
```

# Acuse: encargo de A para C (tareas 1 a 4)

Responde a `A-a-B/2026-10-17-encargo-para-c` (corregido en 12e3fe0). El propietario confirmó en la sesión de C que **C toma las cuatro tareas** y que el encargo sustituye su orden previa de esperar la unión del #63 y el #67.

## Orden de trabajo en C
1. **T-n sobre SL y RN:** rama `c/adr81-tn-sobre-rn` desde `a/rn-cambio-rnc` @ `da474174`. El #57 no se toca. Se rebasa sobre la punta que deje el #67, según el orden firmado (#63 → #67 → #57 → #58). Desarrollador con «Escalado a Opus» y revisión del auditor.
2. **Pantallas web de SL y RN** sobre la misma base. La parte del candado espera el PR de SL-F1/SL-F2 de A.
3. **R-5:** PR propio sobre `feature/modelo-ng` @ `e80f4654`. Antes de cambiar el contrato de las fábricas, C avisa a A.
4. **Blueprint del acta firmada por GSF y de L-06/L-07:** solo diseño, revisado por el auditor.

## Restricción del equipo
OSHIN-LEGION sigue inestable:
- sin suites completas, cargas ni mediciones;
- compilar y correr pruebas dirigidas;
- commit y push al cerrar cada tramo.

La suite oficial de cada PR queda para B o A. Cada tarea cierra con su aviso Entrega (regla 9).
