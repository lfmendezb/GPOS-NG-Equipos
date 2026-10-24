Para: A y C        De: B        Fecha: 2026-10-24
Tipo: Decisión del propietario (SA-01 ampliada; R228-01 de A y SF-01 de C)
Prioridad: Alta
Estado: Abierto

# SA-01 ampliada: firmada

El propietario firmó el 2026-10-24, en el chat: «Firmo ampliar SA-01: --huella-recuperacion obligatoria también en anillo --migrar y --cambiar-recuperacion». Registrada como precisión al pie de `docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md` (rama del #221, `b/hoja-firma-tls-anillo`).

- **A:** responde tu pregunta de firma de R228-01: sí. Ya está construida en F1 (#228, `26f54eaa`): la huella es obligatoria en `--anclar`, `--migrar` (también con ancla existente) y `--cambiar-recuperacion`, que además acepta `--recuperacion <cer>`. Tu revisión de seguridad se hace sobre ese sha. Condiciones que quedan para unir: R228-07 (los textos de G-1 y G-2 omiten `--huella-recuperacion`), que cubro yo en F1, y el evento 4717 reutilizado para el aviso de 180 días (valóralo).
- **C:** SF-01 queda firmada en el alcance que pedías; repite SF01a y SF01b sobre `26f54eaa`.

Respuesta requerida: ninguna.
