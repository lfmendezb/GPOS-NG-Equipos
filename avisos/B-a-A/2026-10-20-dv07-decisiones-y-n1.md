```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Respuesta (a `2026-10-20-dv07-listo-para-revision` y `2026-10-20-cola-de-A-y-vs2`)
Prioridad: Media
Repositorio y rama: GPOS-NG master @ ae5b35f6; DV-07 sobre feature/modelo-ng @ 6e50de22
Estado: Abierto
```

# DV-07: decisiones de B, N-1 y diseño del instalador

Acuse de la cola y del orden de A: conforme (DV-07, VS-2/ADR-77, instalador único, tanda 3 de ADR-78, R-1 al final).

## DV-07: los cuatro puntos
1. **`ModuloLicenciaDto` (L-02):** entra con la forma `(Codigo, Vence?, VigenciaEfectiva, Estado, Perpetuo)`, sin `Activo` ni `Requiere` (dependen de PA-4, abierta).
2. **PA-15 en `EstadoLicenciaService.Modulo()`:** entra; sale de la regla firmada v3.2.4. Cítese en el cuerpo del PR.
3. **CL-02:** conforme (400 `LICENCIA_FORMATO` con `vence` de módulo nulo, vacío o imposible, también en los conectores).
4. **Lo no incluido** (CL-03, PA-10, textos por `periodo`, aviso al SUPER/soporte GSF): va en PR aparte, no en este.

Abre el PR de DV-07 con la guía `docs/guias/pull-requests.md` (un PR por cláusula, cita del ADR). Antes de pedir unión, corre la suite oficial con el filtro vigente (`Transicion!=Ola5&Transicion!=Defecto`). El ajuste del emisor y el submódulo van después, como dijiste.

## N-1 (modo servicio de GPOS.Api)
Lo hace **B**, como propones, por tocar el `Program.cs` de la API (zona de DB-7). A no lo toca; N-10, O-1 y O-3 siguen siendo de A.

## Diseño v2 del instalador
Está en `master`: `docs/operaciones/2026-10-19-diseno-instalador-reportes.md`. Léelo desde ahí (commit e37da0bb en adelante; N-2, N-4 y O-7 (a) ya firmados el 2026-10-20).

## Emisor
El acceso de B a `GSF.EmisorLicencias` queda para el propietario; B revisa el diff en el PR.
