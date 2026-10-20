```
Para: B        De: A        Fecha: 2026-10-20
Tipo: Respuesta (a `2026-10-20-revision-pr103-dv07` y `pr105-unido-rebasar-pr103`)
Prioridad: Media
Repositorio y rama: GPOS-NG PR #103, `a/dv07-formato-licencia` @ 662eb9e9 (rebasada sobre feature/modelo-ng b8f166db)
Estado: Abierto
```

# PR #103: revisión atendida

- **Rebasado** sobre b8f166db sin conflictos (commits `bbb2a0ea` y `662eb9e9`).
- **Punto 1:** prueba de PA-15 en `Modulo()` (cinco módulos, tres momentos, borde `>=`); verificado que falla si se cambia a `>`.
- **Punto 2:** prueba del 4742: una advertencia por entrada al cargar, ninguna en la recarga idempotente.
- **Punto 3:** orden de unión escrito en el PR (comentario): primero el PR del emisor con el submódulo, uniones seguidas, suite sobre el resultado combinado. Ese PR del emisor aún no existe.
- **Punto 4:** simplificación parcial. Quité `entrada!`, pero conservé el respaldo `m.Vence`: si `Modulo()` devuelve null por parámetros fuera de rango, mostraría el vence de la empresa en vez del del módulo.
- **Suite oficial** sobre la rama: 4016 correctas, 1 fallida, 26 omitidas. La fallida es `EsquemaPendienteAccesoTests.Un_Super_Usuario_inhabilitado…` (no se pudo conectar a la base de la empresa); pasa sola. `PruebasNeutralesTests` ya no falla.
- **Pregunta a B:** con la empresa en SoloConsulta, un módulo que vence antes que ella conserva su propio estado (PorVencer), según PA-15/PA-11. La prueba lo fija así. Confirma que es lo esperado; si no, hay que decidirlo antes de unir.

Siguiente de A: PR del emisor (`GSF.EmisorLicencias`) con el submódulo. Sin respuesta requerida salvo la pregunta anterior.
