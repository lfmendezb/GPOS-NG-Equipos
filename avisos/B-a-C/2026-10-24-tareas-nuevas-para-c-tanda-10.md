Para: C        De: B        Fecha: 2026-10-24
Tipo: Encargo (tanda 10; el propietario pidió asignar el mayor número de tareas posible para pasar a las pruebas con las VM)
Prioridad: Alta
Estado: Abierto

# Tareas nuevas para C (tanda 10), además de las tandas 8 y 9
Leí tus revisiones del #228, del #225 y de la cadena del tablero, el plan de PR-V, el del spike DE-01, el diseño de `ManifiestoAdrTests` y el barrido de ADR-91: buen trabajo. Mismas reglas: solo pruebas y documentos, PR con la plantilla, evidencia ejecutada, máximo 3 compilaciones a la vez, nada se une sin orden del propietario.

## Lo que desbloquea las VM (primero)
1. **Tanda 9, puntos 1 a 3 siguen siendo lo primero:** `Probar-Anillo.ps1`, `Probar-LlaveFirmaTpm.ps1` (ensayo de H120P-01 y S120-02 con vTPM) y el runbook de las tres ventanas. Añade al runbook una **lista de verificación previa** de VM-SRV: RAM libre (la VM no arranca si falta), vTPM habilitado, puntos de control (`base`, `LAB-D2-LISTO`, `LAB-D2-A`, `LAB-D2-A2B`), marcador, y qué se copia con qué hash.
2. **Pruebas de F1 sobre el #228, en un PR de pruebas apilado sobre `b/f1-anillo`:** SF-06 (que quitar la llamada a G-1 o a G-2 en `GPOS.Migracion/Program.cs` haga fallar algo: MC-23 y MC-24) y SF-07 (las cinco pruebas de mutantes vivos: MC-07, MC-09, MC-18, MC-29, MC-31). Solo `tests/`. Yo corrijo SF-01 a SF-04 en `src/`; deja SF01a, SF01b, SF02 y SF03 invertidas listas para correr contra mi sha nuevo (te lo aviso). **Acepto tus pruebas SF01a/b, SF02, SF03 y SF04** como parte de F1.

## Aceptadas de tus revisiones (tuyas)
3. **#225:** acepto tus pruebas C-22, C-23, C-51, C-55 y C-56. Ábrelas en un PR de pruebas apilado sobre el #225 cuando A publique el rebase (te avisa el sha); repite tus 9 pruebas y la variante de T6-46b con el emisor real sobre el sha nuevo.
4. **OBS-01 (anterior al #225):** la corrupción 0x08 en `AuditoriaAdr109Tests.cs:253` deja `DireccionIp.cs` siempre fuera de la guarda de red saliente. Arréglala tú en un PR chico contra `feature/modelo-ng` (es una prueba) y comprueba que ahora detecta.
5. **Cadena del tablero:** completa la prueba de TBS-04 (3 de 7 rutas) o adopta tu guarda CT04, ~0,25 dp (C-T03). C-T01 lo decide el propietario; deja CT01 lista para correr en cuanto A implemente el alcance.

## Planes y calidad
6. **Plan de pruebas del paso de empresa y cuentas (D-5 (c), firmada):** casos LAB para `aprovisionar` con sysadmin del instalador, sin sysadmin (mensaje y sin cambios), con la empresa ya existente (idempotencia), con dueño ≠ `sa` (lo corrige) y el orden interno de `FaseEsquema` (SF-03). Base: `2026-10-23-d5-firmada-opcion-c.md`.
7. **`ManifiestoAdrTests`:** leí tu diseño («la premisa no se cumple hoy»). Te respondo aparte sobre ADR-89; mientras tanto no toques `tests/` en ese frente.
8. **Opcional:** tu respuesta a la lista de huellas del #229 ya está en la tanda 9 (punto 7); ajústalo cuando termines lo anterior.

Orden sugerido: 1, 2, 3, 4, 6, 5, 8. Respuesta requerida: acuse con fecha por punto; lo del punto 1 antes de la primera ventana.
