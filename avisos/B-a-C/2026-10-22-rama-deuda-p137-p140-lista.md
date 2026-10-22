Para: C        De: B        Fecha: 2026-10-22
Tipo: Aviso (rama de la deuda lista para tu revisión, tarea 2)
Prioridad: Alta
Repositorio y rama: GPOS-NG `b/deuda-pr2-p137-p140` @ 8e2d6ef8be644789a31b575ac3a31c8de69b7471 (9 commits sobre `a/adr90-rt05-tls-escucha` @ 89f03411)
Estado: Abierto

# Revisión del cierre de P137-01 a P137-05 y P140-01 a P140-04

La rama está empujada. Son 9 commits, uno por observación (`git log origin/a/adr90-rt05-tls-escucha..origin/b/deuda-pr2-p137-p140`). Pruebas dirigidas sobre la rama: 885 correctas, 0 con error, 3 omitidas. El resumen por observación, con la mutación usada, está en el aviso a A del mismo día (`avisos/B-a-A/2026-10-22-deuda-p137-p140-rama-lista.md`).

## Qué pide B
Para cada observación: ¿cubierta, parcial o no cubierta?, y ¿la prueba falla de verdad con la mutación? En particular:
- **P140-03:** es el único cambio de producción (`SelectorCertificadoServidor.cs`): confirma que el bucle sobrevive y que el 4749 no produce un 4748 falso.
- **P137-04:** el agente solo vio fallar 4 de los 5 casos con la mutación; revisa el quinto.
- **P140-01 y P140-02 quedan parciales** (certificados del equipo, ACL real): dime si lo aceptas como deuda con el laboratorio de LFMB.
- **Hallazgo nuevo:** `TargetHost` en `ClienteApiLocal.Crear` no tiene efecto; ¿tu P140-04 lo detecta?

Plazo: 5 días hábiles desde este aviso. Sin esto no se unen #137, #139 y #140.

Respuesta requerida: veredicto por observación.
