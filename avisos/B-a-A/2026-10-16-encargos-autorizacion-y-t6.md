```
Para: A        De: B (coordinador)            Fecha: 2026-10-16
Tipo: Encargo
Prioridad: Alta
Repositorio y rama: GPOS-NG feature/modelo-ng @ ce33b2a8; b/prep-27oct @ 3b04495f
Estado: Abierto
```

# Encargos: autorización propia (SEG-CORP-08) y lo que salió de T6

## 1. Hallazgo «autorización de otra persona con la credencial propia»
- **Decisión del propietario:** «A, PR corto».
- **El cambio:** en el servidor, `AutorizacionesSupervisor.cs` (líneas 73 y 109) rechaza que el autorizante sea el mismo usuario de la sesión. No basta con `PermitirPropio = false` en el diálogo.
- **La prueba:** una por cada operación que exige otra persona (reversos, reimpresión con autorización, descuentos y las demás que encuentres).
- **Rama:** `a/autorizacion-otra-persona`, desde `ce33b2a8`. PR contra `feature/modelo-ng`.
- **Ojo con el error que devuelva:** si cambia el código de error que espera la UI, la Web y MAUI deben mostrar el mensaje que corresponde.
- **Las copias del ticket sin NCF y el alcance del cierre Z** (los otros dos puntos del informe) quedan para la vertical Corporativa. Si alguno es un defecto del núcleo actual, sepáralo en otro aviso.

## 2. T6, segunda tanda (informe `traspasos/B/2026-10-16-t6-segunda-tanda.md`)
- **A-N2 no bastaba:** con `FORCESEEK`, UF-05 seguía pidiendo 1.024 KB por un **bucle anidado optimizado** (batch sort). B lo completó en `3b04495f`:
  - UF-05 queda como `SELECT ... WHERE EXISTS ... OPTION (USE HINT ('DISABLE_OPTIMIZED_NESTED_LOOP'))`;
  - **T-28 da Correcto en el candidato.**
  - **Regla para disparadores:** `FORCESEEK` no evita la concesión de un bucle anidado optimizado.
- **N6-02 no cumple:** la venta de 20 renglones con T1 sale a 1,137 × la base, con dispersión alta.
  - B repite 2 corridas por lado con la máquina sola.
  - Si se confirma, se perfila el costo por renglón de T1. Puede que se te pida apoyo del arquitecto de datos.

## 3. Vertical Corporativa
B registra en `master` ADR-85, ADR-86 y ADR-88 (Aceptados) y ADR-87 (Propuesto, hasta H-04), con los textos de la §9. También precisa CE-04 y CE-06 y renumera el ADR de catering que chocaba con el 126.

## Agregado: vertical Corporativa registrada (`master` `229fbd45`)
- ADR-85, 86 y 88 quedaron **Aceptados**; ADR-87, **Propuesto** hasta H-04. Todos «Decidido, no implementado (entrega 3)».
- **A, relee los textos.** El documentador de B los redactó a partir de la §9 y las casillas firmadas, porque la hoja solo traía resúmenes.
- **Asignaciones que hizo el documentador** (la hoja no las fija): H-08 en ADR-88; H-09 y H-10 en ADR-85; F-5 en ADR-86, con la cita literal.
- **Catering:** los ADR de la hoja del 2026-10-09 (consumo corporativo y combo `K`) nunca se registraron. Quedan pendientes con número del rango 127 a 129 (sugerido: 127 y 128). La forma de CE-04 y CE-06 quedó precisada en ADR-88.
