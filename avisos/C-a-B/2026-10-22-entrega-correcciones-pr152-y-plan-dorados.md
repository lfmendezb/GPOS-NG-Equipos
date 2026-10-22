```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (revisión de las correcciones del #152 `cf6ccf98`; plan de la tanda de dorados)
Prioridad: Media
Repositorio y rama: GPOS-NG `b/ola5-t4-01-render` (#152)
Estado: Abierto
```

# Correcciones del #152 y plan de dorados

## Revisión de las pruebas nuevas (2 días hábiles: entregada el mismo día)
Informe: `traspasos/C/2026-10-22-revision-correcciones-pr152.md`. Lectura con git sobre `cf6ccf98`; **no se compiló ni ejecutó nada**, no sé si pasan.

- **P152-01/S152-01, P152-04 y P152-05 quedan cerrados en lo esencial.** La prueba del cableado arranca el `Program` real (`WebApplicationFactory<Program>`, Kestrel): detectaría quitar `UsarRutasInternasSoloPorCanal` o moverla tras `UseAuthentication`, quitar `MapRender` o `AgregarRender`. El 401 se prueba en las 4 rutas con 4 tokens cada una; el cuerpo tiene control por `ContentLength` y en streaming (chunked no lo evade), y los 16 MB exactos fijan `>` frente a `>=`.
- **Solo hallazgos Bajos nuevos (5):**
  - P152b-01: la revocación se prueba con un verificador falso sin caché; el real cachea 15 s.
  - P152b-02: «no se lee antes de autenticar» se prueba solo por el estado; falta el caso de tubo crudo sin cuerpo con token inválido.
  - P152b-03: la prueba del `Program` real depende de `#if DEBUG` y falla en Release.
  - P152b-04 (inferido): conteos exactos (`conexiones == 1`, `validaciones == 2×4`) y ~9 transferencias de 16 MB pueden ser frágiles.
  - P152b-05: de P152-04 siguen sin prueba que el render no cruza la empresa del token con la del modelo y que el token no sale en el registro.
- Pendiente de B: la suite filtrada del proyecto de reportes sobre `cf6ccf98` (yo no la corrí).

## Plan de la tanda de dorados
`traspasos/C/2026-10-22-plan-tanda-dorados-t4-01.md`. Primero la guarda de P152-16 (G-1..G-6: regenerar falla siempre al final, motivo obligatorio, `CAMBIOS.md`, manifiesto de hashes, no en CI), luego los grupos 1 a 6, con doble corrida y prueba de mutación por dorado. El grupo 7 (D-07, D-25, D-26) espera a A; **D-25 no se captura** hasta decidir si A4/Oficio/MediaCarta con `size: letter` es un defecto.

## Lo que bloquea a C
**Máquina de la tanda:** B confirma cuál antes de que C empiece. Recomiendo `LFMB`; en OSHIN-LEGION solo la guarda. También: si el PR va sobre `b/ola5-t4-01-render` o espera a la unión del #152; D-12 (cultura); y coordinar el archivo del comparador con quien corrige el #152.

Respuesta requerida: máquina y base del PR de la tanda.
