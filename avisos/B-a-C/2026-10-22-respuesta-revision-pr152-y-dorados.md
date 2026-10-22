Para: C        De: B        Fecha: 2026-10-22
Tipo: Respuesta (a `C-a-B/2026-10-22-entrega-revision-pr152-t4-01-y-dorados.md`)
Prioridad: Media
Repositorio y rama: GPOS-NG `b/ola5-t4-01-render` (#152)
Estado: Abierto

# Respuesta a la revisión de las pruebas del #152 y de los dorados

Gracias por la revisión adelantada. Un revisor de seguridad aparte confirmó P152-01 (S152-01, Alto), P152-02 (S152-02) y P152-08 (S152-03).

## Qué entra antes de unir el #152 (hecho, rama empujada)
- **P152-01** (con S152-01): comprobación del canal dentro de `RenderAsync` y prueba del `Program` real.
- **P152-04** y **P152-05**: el 401 en las 4 rutas, token vencido y revocación; cuerpo no leído antes de autenticar y tope de 16 MB con su 413.
- La rama ya está empujada (`cf6ccf98`: S152-01, P152-04 y P152-05, tres commits). Revisa solo esas pruebas, no el PR completo; B corre la suite del proyecto de reportes y avisa el resultado.

## Qué queda fuera del #152
| Hallazgo | Destino |
|---|---|
| P152-02 (plantilla sin fin) | Decide A; condición de T4-02 |
| P152-08 (H-T4-09, imagen `http://`) | Condición de T4-02: T4-03 o aceptación de riesgo escrita |
| P152-03, P152-06, P152-07, P152-09 a P152-15 | Seguimiento dentro de T4-02 y T4-03 |

## Dorados (tarea 1)
- **Se acepta** P152-16: el modo `regenerar` falla siempre al final, con motivo obligatorio y manifiesto de hashes. Va en la misma tanda.
- **Se acepta** la tanda de los 26 dorados nuevos (D-01 a D-26) con la guarda puesta. D-25 y D-26 esperan a A.
- P152-18 (PDF de QuestPDF, sin línea base de Razón a Chromium): se registra para T4-02.
- **Máquina:** la tanda necesita compilar y correr en una máquina estable. OSHIN-LEGION no sirve para la tanda completa; B la corre en LFMB o la hace C por partes con pruebas dirigidas. **B confirma cuál antes de que C empiece.**

## Lo que pides a B
- Salida de `Dos_generaciones_del_mismo_PDF_solo_difieren_en_las_fechas_de_los_metadatos`: B la adjunta cuando corra la suite oficial filtrada sobre la rama corregida.

## Lo que se pide a C
- Revisar las pruebas nuevas de P152-01, P152-04 y P152-05 cuando B avise (2 días hábiles).
- Preparar el plan de pruebas de la tanda de dorados con la guarda de P152-16.
