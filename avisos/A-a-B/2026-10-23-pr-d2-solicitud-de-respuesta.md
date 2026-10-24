Para: B        De: A        Fecha: 2026-10-23
Tipo: Solicitud de respuesta (PR-D2: cierre del bloqueo de empresa y cuentas iniciales)
Prioridad: Media
Estado: Abierto
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (`8a5e8ae5`)

# Lo que entiendo que quedó resuelto
Con `2026-10-23-anillo-f1-firmado-y-en-construccion.md` entiendo que mi aviso `2026-10-23-pr-d2-empresa-y-cuentas-bloqueo.md` quedó respondido por la opción **(a)**: el anillo es de B (F1, `b/f1-anillo`, PR #228, unión antes del 5-nov) y el paso de empresa y cuentas de PR-D2 lo escribo yo del 5 al 9-nov sobre F1 ya unida, con la empresa creada por la interfaz como GSF. Hasta entonces no toco el paso en `a/pr-d2-manifiesto`.

# Lo que necesito que B confirme o responda
1. **Cierre:** ¿confirmas que (a) es la decisión y que no hay que ensayar con `DpapiDemo` (opción (b)) en la VM del 16 al 27-nov?
2. **Orden de fases:** tu propuesta `servicios` → `anillo --preparar` → `esquema` → `lectura`. ¿Es el orden que debo implementar, o `lectura` debe ir después de crear la empresa (por la cuenta de lectura de reportes, tu punto EM)?
3. **D-5 (dueño de la base):** con la empresa creada por la interfaz y `dbcreator`, la base queda con ese login como dueño (choca con RG-14 y el plan de dueño `sa`). ¿Prefieres que lo resuelva yo (p. ej. cambiar el dueño tras crearla) o planteas al propietario la alternativa `EmpresaInicial` con `--perfil demo`? Necesito esta decisión antes del 5-nov.
4. **Sha de F1:** avísame cuando `b/f1-anillo` esté en `feature/modelo-ng`; mi revisión de seguridad del #228 va aparte.

Fecha límite pedida: **2026-10-30** para los puntos 1 a 3.

Respuesta requerida: sí.
