Para: C        De: B        Fecha: 2026-10-23
Tipo: Encargo (tanda 8; el propietario pidió asignar más tareas porque terminaste las anteriores)
Prioridad: Alta
Estado: Abierto

# Tareas nuevas para C (tanda 8)

Tus entregas de hoy (planes, guiones del MSI y de `restaurar`, `preparar-vm.sh`, las revisiones adversariales del #210, de `restaurar`, del #120, del blueprint del anillo y del MSI) están leídas. Lo firmado a partir de ellas: SA-01, SA-02 y SA-03 dentro de F1; la segunda pasada del MSI (`b/t1b-api-msi` @ `1232d0af`: `MajorUpgrade` después de instalar, restart, restart, none, `Start="auto"`); **F1 lleva 6 commits locales del agente de B** y te aviso con el sha. Mismas reglas: solo pruebas y documentos, PR con la plantilla, evidencia ejecutada, máximo 3 compilaciones a la vez, nada se une sin orden del propietario.

## Revisiones adversariales nuevas
1. **#225 (T4-06, de A):** la lista P-2 queda vacía y los 11 reportes corren en la API de reportes. Contrástalo con tu plan de T4-06 versión 3: ¿están los ~70 casos? ¿`Caracterizacion_pendiente_hoy_…` se invierte (T6-46b)? ¿qué sobrevive? Tu informe dice si T4-06 se puede unir (M-2 del #217 se cierra con él).
2. **#217 después de los cierres de A** (`11a1e822`): tercera mirada, ahora con M-1, B-1 y B-2; foco en lo que el auditor de A y el de B pudieron no ver (caché, orden de comprobaciones, el nivel del token: S217-02 sigue en decisión del propietario).
3. **La cadena del tablero ya unida (#202, #205, #206, #212; #220 abierto):** revisión adversarial del conjunto con foco en la fuga entre sucursales (existencias, CxC, avisos), la caché por alcance, TBS-04 (empresa asignada) y el 403 en todas las rutas; nadie la ha hecho de punta a punta.
4. **F1 (el anillo)** cuando te dé el sha (ya asignada; llevará los commits SA-01, SA-02, SA-03 y SA-06).

## Calidad de lo firmado
5. **Barrido de ADR-91 de las hojas de hoy:** audita la consistencia documental de lo firmado el 2026-10-23: las hojas `2026-10-23-*` en `docs/decisiones/` (de PR-D2 y T4-06, de `tls` y anillo, de M-2 y guarda C-1, de P170-07, de T4-02, de D-03 del tablero), el blueprint del anillo (#219) y `docs/adr/estado.json`. ¿Alguna frase dice «pendiente de firma» de algo firmado? ¿alguna referencia viva no lleva la marca? ¿alguna hoja contradice a otra (por ejemplo `Start` del MSI, F1 en 2,75 o 3,35 dp)? Informe con la lista y el remedio; no edites las hojas.
6. **La guarda `ManifiestoAdrTests`** (solo existe en `master` y hoy falla ahí porque cita pruebas de `feature/modelo-ng` que no existen en `master`): diseña y, si cabe, implementa en un PR de pruebas que cada columna del manifiesto (`master` y `feature/modelo-ng`) se valide contra el árbol de su rama, de modo que la guarda sea verde en cada una. Dímelo antes de tocar `tests/` si choca con ADR-89.

## Planes y laboratorio
7. **Plan de pruebas de PR-V** (los verbos `red`, `lectura` y `FaseServicios`; rama `a/pr-v-verbos-servidor` @ `a3c71ce1`, A abrirá su PR): si no tienes plan, escríbelo (con T1-10 estricta y la constante del SDDL de Q-5); es la base de F2 de `tls`.
8. **Plan de T4-08 y T4-09** (consulta de facturas, existencias y kárdex; enero): adelántalo si no lo entregaste (opcional 10(b) de tu tanda 7).
9. **Plan del laboratorio del spike DE-01 (Amplio, 23-nov):** casos y evidencia a partir del #173 (`Probar-Spike-Amplio.ps1`, ya unido) y de tus A5, D3 y R2 «Bloqueados» del MSI.
10. **Opcionales:** (a) una **lista de revisión y una hoja de contacto de los 95 dorados nuevos** del #156 para que el propietario o A hagan la revisión humana en poco tiempo (el propietario decide `CODEOWNERS`; sin herramientas nuevas); (b) revisa mi `construir.ps1:65` (código muerto, C15) y propón el PR chico.

## Para el laboratorio de hoy
Ya tengo tus guiones del MSI (#226); en cuanto F1 termine corro la primera ventana. Si encuentras una discrepancia entre `Probar-GposApiMsi.ps1` y el MSI de `1232d0af` (tabla `Wix4ServiceConfig` ahora «restart, restart, none»; usa `-AccionesEsperadas 'restart,restart,none'`), corrígela en tu PR.

Respuesta requerida: acuse con fecha por punto.
