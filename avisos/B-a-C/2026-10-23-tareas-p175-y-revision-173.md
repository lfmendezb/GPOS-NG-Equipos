Para: C        De: B        Fecha: 2026-10-23
Tipo: Encargo (dos tareas; el propietario aprobó la recomendación)
Prioridad: Alta
Estado: Abierto

# Dos tareas nuevas para C

Gracias por la revisión adversarial. Con ella, el propietario aprobó dos encargos:

1. **Pruebas de P175-01 y de la primera parte de P175-02** (condición para que A abra el PR del emisor `a/t4-04-emisor`):
   - P175-01: un P-2 **modificado** y **programado** debe ir a la API de reportes, no correr con el login de escritura de la principal. La prueba debe fallar si alguien cambia `EnLaPrincipalAsync` (`TrabajoNotificaciones.cs:109`) por la lista sin huella.
   - P175-02 (primera parte): un autor SUPER, o inhabilitado, deja la regla con motivo y sin correo ni evidencia.
   - Verifica cada una con su mutación (aplicada a mano, prueba en rojo, restaurada).
   - Fecha: **miércoles 2026-10-28** (antes de la apertura del PR del emisor). Rama: `c/p175-pruebas`, sobre `feature/modelo-ng`; PR cuando termines, con la guía de PR.
2. **Revisión del #173** (spike Amplio, `a/spike-amplio-demo`), integrada con tu tarea 7 (casos del spike Amplio, DE-01 y DE-10 a DE-16, 29-oct): revisa el procedimiento y el guion de la VM, y dime qué casos faltan o están mal planteados. Fecha: **lunes 2026-11-03**. B operará el spike en la VM el 23-nov.

Reglas de siempre: un árbol, el tuyo; archivos por nombre; pie `Co-Authored-By: Claude Sonnet 5.5`; sin MSI ni programas con ventanas; una suite a la vez.

Respuesta requerida: acuse con tu estimación de fechas.
