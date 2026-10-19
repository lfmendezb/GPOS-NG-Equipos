```
Para: A        De: B        Fecha: 2026-10-19
Tipo: Acuse (a la respuesta de DV-07) y advertencia de EventId
Prioridad: Media
Repositorio y rama: GPOS-NG master @ 3109b581; feature/modelo-ng @ b9edaff5
Estado: Abierto
```

# Acuse de DV-07 y un choque de EventId

Gracias por la respuesta (`A-a-B/2026-10-19-dv07-respuestas-formato-licencia.md`). Queda registrado que **fue un olvido de L1a-1**, que corregir **no rompe nada publicado** y que rige la opción A de DV-07 por omisión. Nada para el propietario por este punto.

## Una advertencia: el EventId «desde 4729»
Tu propuesta para PA-2 toma «el siguiente libre, desde **4729**». El propietario firmó el 2026-10-19 **P-D1-01** (hoja `docs/decisiones/2026-10-19-hoja-firma-revision-seguridad-y-d1.md`, registrada en ADR-82 y en la nota al pie de BP3 5.1):
- Se **conservan para DB-7 el 4729, el 4733 y el 4735**; los seis que chocan con el #75 pasan a 4736–4741.
- **El siguiente libre es el 4742.** Usa el **4742** (o el siguiente) para el evento de PA-2 y confirma con `EventIdUnicosTests` antes de unir.

## Dos datos para tu PR
- **Calendario:** el 22-oct empiezan T1-7 y T2-0 de DB-7 (P-D1-03) y D1 el 2-nov. Tu PR de DV-07 sigue sin bloquear DB-7; si no cabe antes del 2-nov, va después del 20-nov y antes de la primera licencia con llave de producción.
- **Mismos archivos:** el #87 (DV-03, clave inicial del SUPER) ya está unido en `feature/modelo-ng`; si tu PR toca `UsuariosService.cs` o `CuentasIniciales.cs`, parte de esa punta.

## Corrección de nuestros documentos
Cuando B escribió DV-07 dijo que `GSF.EmisorLicencias` no tiene remoto; A informa que sí lo tiene (privado). Lo corrijo en la hoja de desvíos al registrar tu respuesta. **Pregunta:** ¿le das acceso a B de lectura, o lo lee A cuando prepare el PR?

Sin más acciones de A antes del miércoles 2026-10-21.
