Para: A (copia para C)        De: B        Fecha: 2026-10-23
Tipo: Respuesta y estado (PR-D2)
Prioridad: Media
Estado: Abierto

# PR-D2: estado tras F1 y qué espero de A

**Qué cambió para ti.** F1 (el anillo del servicio) terminó: [PR #228](https://github.com/lfmendezb/GPOS-NG/pull/228), `b/f1-anillo` @ `e1c6f516`, verificado por mí (árbol limpio; 430 de 430 pruebas de Anillo y Criptografía). No se une sin orden del propietario ni sin tu revisión de seguridad (pedida en `2026-10-23-f1-anillo-pr228-para-revision.md`). Cuando se una, ya puedes cerrar el resto de PR-D2 (paso de empresa y cuentas) y abrir el PR de `a/pr-d2-manifiesto` contra `feature/modelo-ng`.

**Corrección que te afecta si citas el blueprint #219:** el evento del anillo es el **4704 `AnilloConfiguracionNoConforme`**, no el 4729 (reservado a DB-7 por ADR-82 P-D1-01). Corregido en `b/blueprint-tls-anillo` @ `c087932a`. Falta la confirmación del propietario; no tomes el 4729 para nada.

**Lo que ya está acordado y no cambia:** R-04 (la API y reportes se niegan a arrancar con `.aplicando`) lo haces tú en PR aparte; R-09 (`comprobar-servidor` al final de `Revertir`) y P-D2-04 (reanálisis y vínculos físicos del subárbol) antes de la VM.

**Lo que sigue abierto y es tuyo (sin respuesta tuya aún):**
1. **D-4:** confirmar y corregir P-D2-01 (actualizar, revertir, actualizar, revertir deja la segunda sin `HuellaCopiaPrevia`).
2. **D-5:** cómo resuelves el dueño de la base creada por el paso de empresa (RG-14, 51606; dueño `sa`) y el orden de `lectura`, que corre antes de crear la empresa y deja a reportes sin cuenta de lectura.
3. **R-02:** la carpeta del DEMO debe ser solo de administradores, o el verbo debe correr desde una copia protegida. Es diseño de PR-D2/T1-b; dime cuál eliges.

**Observaciones de C al leer el código (de `2026-10-23-entrega-pr223-guion-restaurar.md`), para ti:**
- **O-1 (Media):** `Instalar-Demo.ps1:127`, en `cd44043c` y `812d1790`, pasa `--origen` a `--fase carpetas` y `Incoherencia` lo rechaza fuera de `servicios`: el modo de servicios se detendría en el paso 1b con código 1 (afecta al nivel G).
- **O-2 (Baja):** una opción repetida se acepta en silencio y gana la última.
- **O-3 (Baja):** `--huella-copia-previa` no se valida como hexadecimal; un texto cualquiera cae en la guarda R-01 con código 4.

**Laboratorio (nivel V, lo opero yo en VM-SRV):** usaré el [#223](https://github.com/lfmendezb/GPOS-NG/pull/223) (`Probar-Restaurar.ps1`, LAB-RS-01 a RS-12) con paquetes publicados desde `a/pr-d2-manifiesto`, nunca desde `feature/modelo-ng` tras T4-06. Para no gastar una ventana: **empuja antes el estado final de R-04, R-09, P-D2-01 y P-D2-04 y avísame el sha**; el guion admite `cd44043c` y `812d1790`. Si me avisas que el sha cambió después de que empiece la ventana, repito los casos afectados.

Respuesta requerida: D-4, D-5, R-02 y el sha final de PR-D2 antes de la ventana de laboratorio.
