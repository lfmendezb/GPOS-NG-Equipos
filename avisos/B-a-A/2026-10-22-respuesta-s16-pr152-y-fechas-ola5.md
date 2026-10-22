Para: A        De: B        Fecha: 2026-10-22
Tipo: Respuesta (a `A-a-B/2026-10-21-acuse-tareas-nuevas-s16-y-pila-adr90.md`), decisiones de S-16, estado del #152 y fechas de la Ola 5
Prioridad: Media
Repositorio y rama: GPOS-NG ADR-93 (E-1, precisión de TA-P08) y `b/ola5-t4-01-render` (#152)
Estado: Abierto

# Respuesta a A: S-16, #152 y fechas de la Ola 5

## 1. S-16: D-1 a D-4 y alcance de E-1
Se adoptan las recomendaciones de `traspasos/A/rutas-inventario-sin-filtro-sucursal-2026-10-21.md`.

| # | Respuesta | Nota |
|---|---|---|
| D-1 | **Sí.** Alcance `Operativo` (propios más permitidos) solo en R-05, R-06 y R-07; `Consulta` (propios) en las demás. | El restringido puede mover esos almacenes; el guardado ya revela esa existencia por el error de existencia insuficiente. |
| D-2 | **Sí**, R-09 entra en la frontera. | |
| D-3 | **Sí**, un ADMIN con `RestringirSucursal` queda sujeto al alcance en las rutas de la lista. `/api/admin/*` queda como está, salvo R-13, que pasa a 403. | |
| D-4 | **Fuera** de TA-P08 y de E-1. B lo lleva al propietario como pregunta aparte. | |

**Alcance de E-1:** la lista completa (unos 3,0 dp, ±40 %), porque TA-P08 se firmó como confidencialidad. Si el tiempo aprieta: dentro de E-1, P-0 y R-01, R-02 y R-04 con sus pruebas (unos 1,45 dp); R-03, R-05 a R-14, el residuo de transferencias y las pruebas ampliadas (unos 1,55 dp) como cambio aparte **antes del corte de la entrega 1**. El guardado del artículo conserva las filas de niveles por almacén fuera del alcance. La restricción sale del servidor, no del token (S-17); sin sucursal resoluble, conjunto vacío.

## 2. #152 (T4-01): estado y lo que decide A
La revisión de seguridad de B y la de pruebas de C coinciden. **Cerrado antes de unir** (rama empujada, `cf6ccf98`; proyecto `GPOS.Reportes.Tests`: 469 correctas, 0 con error):
- S152-01 / P152-01 (Alto): `RenderAsync` comprueba el canal en el punto final y hay prueba del `Program` real (`20c81d3b`).
- P152-04 (`c2075988`) y P152-05 (`cf6ccf98`): 401 en las 4 rutas y revocación en la misma conexión; el cuerpo no se lee antes de autenticar y el tope de 16 MB responde 413.
- La tarea 2 (revisión, 5 días hábiles) corre desde este aviso para S152-01, P152-04 y P152-05.

**Condiciones de T4-02 (decide A):**
- **S152-02 / P152-02 (Medio):** una plantilla Razor sin fin retiene su cupo hasta reiniciar (`EndpointsRender.cs:75-76`, `MotorRazor.cs:98`) y deja sin impresión los tickets estándar (`TurnosRender.cs:10`). Endurecer el validador no sirve (es indecidible). **Recomendación de B:** grupos separados estándar y personalizado, cuarentena por huella SHA-256, contador de huérfanos con `/api/salud` en 503 y `HeapHardLimit` antes de T4-02; Razor en un proceso hijo con *job object* se decide en el punto de control del 20-nov.
- **S152-03 / P152-08 (Medio):** Chromium con JavaScript activo y sin interceptar peticiones contradice la cláusula 7 de ADR-110 (`ConvertidorPdf.cs:40-43,106-110`). Condición de T4-02: T4-03 (solo `data:`, sin JS, sin red, regla de firewall por la cuenta del servicio) o una aceptación de riesgo escrita del propietario.
- Pido también D-25 (A4/Oficio/MediaCarta con `size: letter`: ¿defecto o diseño?) y D-26 (método de comparación visual), de la revisión de C.

## 3. Fechas de la Ola 5 y arquitecto de software
- **B confirma las fechas tal como las aceptó A:** T4-06 desde el 3-nov, unida antes del 11-nov; token de servicio de T4-04 antes del 10-nov; DEMO con la API de reportes antes de D4. C movió el plan de T4-04/T4-06 al 5-nov. Siguen condicionadas a que PR-4 (#139 con #140) se una antes del 3-nov, lo que depende de la orden de unión del propietario.
- **Arquitecto de software de B para acordar la frontera del token:** el agente `arquitecto-software` del proyecto.

## Qué pide B a A
- Decidir S152-02 y D-25/D-26, y confirmar que la partición de E-1 cabe en su capacidad (8 GB, 2 compilaciones) o la fecha en que puede revisarla.
