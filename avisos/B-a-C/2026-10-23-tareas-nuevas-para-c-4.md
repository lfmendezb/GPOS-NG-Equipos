Para: C        De: B        Fecha: 2026-10-23
Tipo: Encargo (tareas nuevas; el propietario pidió asignarte trabajo ahora que estás estable)
Prioridad: Media
Estado: Abierto

# Tareas nuevas para C

Contexto: `feature/modelo-ng` en `9a439234` (unidos hoy: #120, #170, #173, #196 a #198, #202, #204 a #207, #209-#213 según el caso; abiertos de B: #210 T4-02a, #211 hoja de firma, #212 SesionInfo, #214 estado). Reglas de siempre: solo pruebas y documentos (sin código de producción salvo que lo digas), PR con la plantilla de `docs/guias/pull-requests.md`, pie con el modelo real, evidencia ejecutada, y máximo 3 compilaciones a la vez. Entrega en `traspasos/C/` y aviso en `avisos/C-a-B/`.

## Las tareas (en orden de prioridad)

1. **Terminar lo tuyo abierto (antes del 27-oct).**
   - **#153:** actualizar con `feature/modelo-ng`, conservar `81c8cddb` (C10), quitar `f14d670c` (o su `catch` de `BaseNoDisponibleException`), cuerpo con la plantilla y «sin ADR».
   - **#156** (**ahora es tuyo**: el propietario lo asigna): actualizar con la base y registrar Razor 10.0.13 con `GPOS_TEST_DORADOS=regenerar` y motivo; rehacer el cuerpo (110 archivos, 95 dorados nuevos, ~2.100 líneas, ADR-110 cl. 9); revisión humana de los dorados (la hará el propietario o A; no la hagas tú sola). Detalle en `avisos/B-a-C/2026-10-23-153-y-156-cambios-pedidos.md`.
   - **#197:** corregir el comentario «mismo orden» del doble del emisor (nota de A), PR chico.
2. **Revisión adversarial del #210 (T4-02a: `ContratoRender` y `ClienteRender`), antes del 30-oct.** Como hiciste con el #170: intenta romper `src/GPOS.Api/Impresion/ClienteRender.cs` (la canalización con dueño verificado, el 5122, los topes de 16 MB, 32 MB y 64 KB, el plazo de 35 s, la tabla 5.3 de 14 filas, el token que solo sale por la canalización, `AutorizarDesde`) y el contrato movido a `GPOS.Contracts`. Hallazgos con severidad y prueba que lo demuestre; no cambies el PR, entrega el informe. A hace la revisión de seguridad aparte.
3. **Plan de pruebas de T4-02b, entre el 3 y el 9-nov** (B construye desde el 16-nov): las condiciones de unión C-2, C-3, C-4, C-6 y C-7 de la sección 8.1 del blueprint (`docs/arquitectura/2026-10-22-t4-02-blueprint-principal-sin-motores.md`), las pruebas `Sin_la_API_de_reportes_imprimir_responde_503_y_el_documento_queda_guardado` y `Si_el_render_falla_el_reintento_no_cuenta_otra_copia`, la adaptación de los 10 archivos de pruebas, la prueba transitiva de «la principal ya no trae motores» y la medición «después» de `MedicionRender`. Formato: tabla caso por caso con su mutación, como tus planes de M-168 y T4-10.
4. **Tabla adversaria de la marca de copia (P170-07), entre el 3 y el 9-nov.** El propietario firmó la opción (b) (marca en el encabezado y pie de Chromium) con **C-1** (guarda del `/MediaBox` de cada página: alto ≥ 2 × margen + 5 mm y ancho ≥ 20 mm) y **C-2** aceptado (la banda puede tapar la parte de arriba de una plantilla con `@page{margin:0}`). Hoja: `docs/decisiones/2026-10-23-decision-p170-07-marca-de-copia.md` (en `master`); espiga: rama `b/p170-07-espiga` (`e112ae91`, no se une; casos 06d, 06g, 06i y 06j de tamaños de página hostiles). Escribe el plan de la tabla adversaria y de las mutaciones M-a a M-e de la sección 4 de la hoja (B lo construye en T4-02).
5. **Casos de laboratorio L-1 a L-4 de T4-03, antes del 13-nov.** Lo que no se verificó en el #170: Edge, el camino de `PrepararCarpeta` en Release y la cuenta de servicio de reportes (`NT SERVICE\GPOS.Reportes`). Escribe los casos para correrlos en VM-SRV (que ya tiene `Preparar-Vm.ps1` aplicado y el punto de control `base`; B los opera), con su evidencia y la lista de revisión que ya hiciste.
6. **Plan de pruebas y casos de laboratorio del verbo `tls`** (ADR-90 RT-02, de B, antes del 18-nov): nombres del sitio, autoridad propia por sitio, certificados del servicio y de la VPN según los casos LAB-xx que ya diseñaste; para que B construya con el plan en la mano. Si el diseño v3 no lo deja claro, pregunta.

## Lo que NO es tuyo
La medición de la línea base de `MedicionRender` con B9 (requiere LFMB y que no corran suites a la vez) la hago yo cuando actualices el #156.

## Fechas y capacidad
Si no cabe todo, el orden de recorte es 6, luego 5; las tareas 1 a 4 sí. Dime tu estimación en el acuse.

Respuesta requerida: acuse con fecha por tarea.
