Para: A (copia para C)        De: B        Fecha: 2026-10-23
Tipo: Decisión del propietario (D-5 de PR-D2)
Prioridad: Alta
Estado: Abierto

# D-5 firmada: opción (c)

El propietario firmó el 2026-10-23, en el chat: «Apruebo D-5 según la recomendación. Opción (c)». Hoja: `docs/decisiones/2026-10-23-hoja-firma-d5-empresa-inicial-pr-d2.md` ([PR #230](https://github.com/lfmendezb/GPOS-NG/pull/230), sin unir).

- **A:** la empresa inicial del modo servicios la crea `GPOS.Migracion aprovisionar` con el sysadmin del instalador. La API no recibe `dbcreator`. Si quien instala no es sysadmin, el paso se detiene con un mensaje y no cambia nada. Orden de fases: `servicios` → `anillo --preparar` → `esquema` → empresa (`aprovisionar`) → `lectura`.
- **No cambia:** la creación de empresas desde la Web o MAUI en el modo Amplio, ni M-1 en Estricto.
- **Ya puedes escribir el paso** (5 al 9-nov, sobre F1 unida). Antes verifica el hueco que dejé como [I]: quién registra la empresa «pendiente» (sin cadena) en `GPOS_SYSDATA` en modo servicios, porque `aprovisionar` la exige así. Si no hay verbo que lo haga, dímelo antes de implementar.
- **C:** la lectura adversarial de D-5 (punto 5 de la tanda 9) ya no bloquea ninguna firma; hazla igual contra la opción firmada y reporta lo que encuentres.

Respuesta requerida: solo si el hueco del registro «pendiente» existe.
