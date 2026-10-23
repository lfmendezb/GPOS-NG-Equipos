Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (revisión de seguridad de la fase `restaurar`, PR-D2)
Prioridad: Media
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (`cd44043c`, empujada, sin PR)

Informe completo: `traspasos/A/revision-seguridad-fase-restaurar-2026-10-23.md` (auditor de seguridad, solo lectura sobre `f1b2374d`). **Aprobado con observaciones; sin Críticos ni Altos.**

## Corregido en `cd44043c` (23 pruebas de `RestaurarServidorTests`, 1142 de 1142 en Servidor, Instalador, Arquitectura y valores de terceros)
- **R-01 (Media):** la copia previa no estaba atada a la actualización que se revierte (una actualización que no cambia binarios, o una fase detenida antes de la copia previa, hacía que revertir devolviera los binarios dos versiones atrás). Ahora `Actualizar-Demo` anota `HuellaCopiaPrevia` (SHA-256 del `.anterior\manifiesto.sha256`) solo si la fase la renovó; `Revertir` la exige y la pasa a la fase con la opción nueva `--huella-copia-previa` (solo con `restaurar`). Sin huella anotada, `Revertir` restaura bases y demás programas y dice que no restaura binarios. Mutación en rojo.
- **R-03 (Media):** si `api\` o `reportes\` del destino es un punto de reanálisis, la fase se detiene antes de borrar nada. Mutación en rojo.
- **R-05 (Baja):** `Revertir` comprueba la copia previa (la de la actualización y `verificada`) **antes** de restaurar las bases; si no, no cambia nada.

## Abierto
- **R-04 (Media, tuyo/nuestro):** si la restauración falla a medias queda `.aplicando` y nada impide que el usuario que instala arranque los servicios con bytes no verificados. El remedio barato es que la API y reportes se nieguen a arrancar si existe `.aplicando` en su carpeta de binarios (código de arranque de `GPOS.Api`/`GPOS.Reportes.Api`, fuera de PR-D2). ¿Lo incluyes en tu trabajo de arranque/anillo o lo hago yo en un PR aparte?
- **R-02 (Media, preexistente):** el guion elevado ejecuta `GPOS.Migracion.exe` y `.ps1` de la carpeta del DEMO, donde el usuario que instala tiene control total (patrón de todos los guiones). Lo correcto es exigir la carpeta del DEMO solo de administradores o ejecutar el verbo desde una copia protegida; es decisión de diseño para PR-D2/T1-b.
- **R-06 a R-09 (Bajas):** la ventana entre dos lecturas del estado `verificada`; `.aplicando` sin validar antes de borrarla; nombres rechazados por el validador (`~` + cifra) que bloquearían la reversión; falta un `comprobar-servidor --sin-red` al final de `Revertir`. Sin acción por ahora; las dejo en el informe.

## Siguiente
PR de `a/pr-d2-manifiesto` a `feature/modelo-ng` cuando el anillo permita cerrar el resto de PR-D2 (hoy contiene `restaurar` más lo anterior del borrador); no se une sin orden del propietario. Ahora sigo con el PR del emisor.

Respuesta requerida: sí, sobre R-04 (¿quién lo hace?).
