Para: A        De: B        Fecha: 2026-10-23
Tipo: Respuesta con las decisiones del propietario (PR-D2, T4-06) y órdenes (#173 unido; abrir el PR del emisor)
Prioridad: Alta
Estado: Abierto

# Decisiones del propietario del 2026-10-23 («Aprobado según recomendaciones») y órdenes

Hoja: `docs/decisiones/2026-10-23-hoja-firma-pr-d2-anillo-restaurar-y-t4-06.md` (PR #211 a `master`).

## Órdenes
1. **#173 unido** a `feature/modelo-ng` (merge `99b07419`, cabeza `f37af1df`).
2. **Abre el PR del emisor (`a/t4-04-emisor`)**: orden del propietario. Tu condición de pruebas (P175-02 con el emisor real) está cumplida. Haz el rebase que ya probaste (conservar `SucursalAjena` y `EsProgramado`/`Restringe` en `RevocacionSesiones.cs` y `ProveedorContexto.cs`) y revisa también `EventosSeguridad.cs` (el #120 añadió `FirmaSinTpmAceptada`). `feature/modelo-ng` está en `99b07419`. Debe unirse antes del 11-nov. Incluye la nota de que el token de servicio no pasa por `SucursalAjena`.

## PR-D2
- **Empresa y cuentas iniciales: (a).** Primero el anillo del servicio (DM-07); después una fase `cuentas` o `esquema` ejecuta `sistema --cuentas-iniciales --confirmar-sellado` con ese anillo. La empresa: el DEMO la crea por la interfaz como GSF (`dbcreator`, paso 4 de la escalera) o PR-V acepta `EmpresaInicial` en el entorno solo con `--perfil demo` (elige tú la más simple y dilo). **No** `DpapiDemo=true`.
- **Dueño de la pieza del anillo: B** (`tls`/anillo y `GPOS.Criptografia`). Es propuesta de B: el propietario aprobó sin que tu aviso trajera una recomendación sobre el dueño; si ves un choque con PR-V, dímelo. B lo construye antes del 16-nov. Mientras tanto escribe el resto de PR-D2 que no lo necesita (la fase `restaurar` y lo demás).
- **Fase `restaurar`: aprobada y firmada por el propietario (Q-R3: sí, firma suya, dada aquí).** Q-R1: el cambio de `CopiarBinarios` va en **PR-D2**; con copia `no-verificada` se detiene sin opción de forzar. Q-R2: solo la última marca revertible. Empieza (~1,0 dp), con revisión de seguridad antes del PR; no se une sin orden del propietario.

## T4-06
- **P-1 (a):** validar columnas en la API de reportes con el token del ADMIN; propagar el 403 `DISENO_NO_PERMITIDO`.
- **P-2 (a):** falla cerrada para programados y «Ejecutar ahora» en Release si T4-06 se une antes que T4-04.
- **P-3 (a):** la principal Release no arranca en Linux hasta el socket Unix (falla cerrada de ADR-129).
- **P-4, primera parte:** el devops de A adapta el ensayo corto con la tarea 3; **no se publica ningún DEMO de `feature/modelo-ng` desde la unión de T4-06 hasta la tarea 3**; el ensayo puede compilar Debug mientras tanto.
- **Sin firmar todavía (propuesta de B):** **Q-A4, segunda pregunta** (Debug sin reenvío): 403 `SUCURSAL_NO_PERMITIDA` también en Debug, no «Debug sin filtro». **P-4, marcador:** conservar `CompilacionDepuracion`. No empieces esas dos partes hasta que el propietario firme.
- T4-06 debe rebasar sobre el #202 y reutilizar `ReenvioReportes.NoDisponible()` (ya están unidos #202 y #205).

## Otros
- **G-PR4, T1-09 y el §7 de la guía (tu pregunta de P-07):** no existen en ninguna rama: son piezas del `GPOS.Api.msi` que construye B (T1-b), aún sin construir. P-07 queda cerrado con tu documento.
- **T4-07-01:** cerrado en la interfaz (#205 unido); te queda la línea de la guía del DEMO.
- **`SesionInfo.RestringirSucursal`:** lo añado yo (opción (a), decisión del propietario del 2026-10-23) y te aviso del PR para el menú.

Respuesta requerida: acuse; y dime si PR-D2 prefiere `EmpresaInicial` con `--perfil demo` o la creación por la interfaz.
