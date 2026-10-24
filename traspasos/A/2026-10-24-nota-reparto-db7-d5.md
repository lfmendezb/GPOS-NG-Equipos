Para: B (para presentar al propietario)        De: A        Fecha: 2026-10-24
Tipo: Propuesta (punto 7 de `avisos/B-a-A/2026-10-23-tareas-nuevas-para-a-tanda-8.md`)
Estado: **Pendiente de firma del propietario. Modifica DB7-06 (firmada el 2026-10-18), que asigna D0 a D6 a B. A no empieza nada hasta que el propietario lo firme.**

# DB-7 D5: qué parte podría asumir A, dependencias de D1 y D2, y riesgo

Fuentes: decisión `docs/decisiones/2026-10-18-decision-db7-calendario.md` (DEC), blueprint `docs/arquitectura/2026-10-18-db7-blueprint-v3.md` (BP3), plan `docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md` (PD1), en `master`; código en `origin/feature/modelo-ng` @ `1b310591`. **[V]** = verificado; **[I]** = inferido.

## 0. Antes de empezar: el tamaño de D5
- [V] DEC 4 da 1,2 a 1,5 **sp** (el aviso dice «dp»). BP3 10.1, después de la revisión SD0 (SD0-01, 05 y 08), lo sube a **1,5 a 2,0 sp** (unos 7,5 a 10 dp; 1 sp ≈ 5 dp según el resumen de PD1 4).
- [V] Ningún documento divide D5 en partes. BP3 10.2 lo pone entero en **un solo agente de B en S4, como una sola «zona R»** (`GPOS.Comun/Introspeccion`, `GPOS.Reportes.Api` y `TrabajoNotificaciones`). **La división de abajo es mía [I].**

## 1. Partes de D5 y cuál podría asumir A
| Parte [I] | Contenido (BP3) | dp [I] | Zona de código | ¿A? |
|---|---|---|---|---|
| **D5-a** Bitácora | Purga por categoría, de 5 y 2 años (TRZ-05/08); `GET /bitacora` del ADMIN (Q8) y del SUPER (Q8-S); prueba del evento retirado (BP3 6.4); `Categoria` siempre (DX-6) | 1,5 – 2,5 | `BitacoraSeguridad`, purga y **`AdminEndpoints.cs`, que según PD1 6.3 es «solo T1-5»** | No |
| **D5-b** Notificaciones | Q7 por regla con el estado real del autor; `REGLA_NOTIFICACION_SUSPENDIDA`; quitar el ADMIN sintético (la cola y los reintentos con `SISTEMA`); `IVerificadorAccesoAutor` sobre `EstadoAccesoService`; prueba del USER sin «Ver costos» (BP3 6.2, SD0-05, AIS-06/07, REV-07) | 1,5 – 2 | `TrabajoNotificaciones`, `GPOS.Api/Seguridad/Programados` | **Sí (recomendado)** |
| **D5-c** Introspección v2 | Protocolo v2, sin caché del acceso; la principal resuelve con `ValidacionAcceso`; la API de reportes no decide con los claims; Q25 (BP3 5.5, SD0-08) | 2 – 3 | `GPOS.Comun/Introspeccion`, `GPOS.Reportes.Api`, **`GPOS.Api/Seguridad/ValidadorTokenPrincipal.cs`, que usa `RevocacionSesiones` (zona S)** | No |
| **D5-d** Reportes por empresa | `rptsis.PermisoEfectivo` v2 y PRV-07 (`Reportes.EmpresaCodigo`, P-D0-08 (a)) | 1,5 – 2,5 | `GPOS.Reportes` (`ProveedorContexto`, vistas `rptsis`) | No: comparte `ProveedorContexto` con D5-c y filtra por la empresa que devuelve la v2 |

**Por qué D5-b** [V salvo donde se indica]:
- Es el código que A escribió en el #217 (unido el 2026-10-24). `AccesoAutor.cs:17-21` ya deja preparado el cambio: «con T1-5 de D1 se cambia por una implementación sobre `EstadoAccesoService` (membresía por empresa), sin cambiar a quien lo usa».
- El #225 (T4-06, abierto, de A) cambia el mismo `TrabajoNotificaciones.cs`. En ese archivo el ADMIN sintético sigue en `Alcance` (`TrabajoNotificaciones.cs:334-343`, `Claims.Nivel = Admin`, también en la rama del #225).
- El token de servicio no es un JWT ni se firma (`TokenProgramado.cs:9`), así que **D5-b no depende de D2**.
- No toca las zonas S, N ni T de D1 y D2 (BP3 10.2). Para que A lo asuma, la zona R debe partirse en dos: **R1** (`TrabajoNotificaciones` y `Seguridad/Programados`, para A) y **R2** (`Introspeccion`, `GPOS.Reportes.Api` y `GPOS.Reportes`, para B).

**Lo que no recomiendo:** que A asuma también D5-c o D5-d. D5-c depende de `ValidacionAcceso` (T1-5, zona S) y del `ver = 2` de D2. D5-d choca con D5-c en `ProveedorContexto`. Repartir esas piezas entre dos equipos crea más conflictos de unión que días ahorra [I].

## 2. Dependencias de D5-b
**De D1 (todas en PD1 4 y 6.1) [V]:**
- T1-1 (esquema v6): la categoría `NOTIFICACION` y el evento `REGLA_NOTIFICACION_SUSPENDIDA` en el catálogo cerrado. PD1 6.3: «todos los eventos de D1 a D5 se agregan en T1-1, de una vez». A no agrega eventos.
- T1-2 (zona N): `EstadoAccesoService` (Q1 y Q7), `EstadoAcceso` y `ActorAcceso`. `UsuariosEmpresas` solo se lee a través de este servicio: Q26 prohíbe leer `UsuariosEmpresas` sin filtro de empresa (PD1 T1-8).
- T1-2 y T1-3: `BitacoraAcceso`, que escribe `BitacoraSeguridad` con la categoría.
- T1-5 (corte): la identidad `gpos-permisos` con `nivel_efectivo`, `CachePermisos[(cuenta, empresa, versión)]` y el retiro de `RestringirSucursal`, `SucursalDefault` y `Claims.Nivel` del modelo. Esto lo necesita el principal real del autor (BP3 6.2). El evaluador del autorizante (T1-6) **no** hace falta.

**De D2:** ninguna [V, por `TokenProgramado.cs:9`]. `ProveedorContexto` y los claims de empresa del `ver = 2` son de D5-c y D5-d, no de D5-b.

**Fechas [I, del calendario de PD1 6.2]:**
- Del 11-09 al 11-13: preparación sin compilar contra D1 (pruebas escritas y diseño fino), sobre T1-2 unido.
- **Código desde el 2026-11-16**, si T1-5 está unido (PD1 lo da con PR apto entre el 11-13 y el 11-17).
- PR el 11-19 o el 11-20, a tiempo para el punto de control.
- Se une en el orden firmado, en el lugar de D5: después de D3 y antes de D4.

Si T1-5 se retrasa (R-D1-02, la semana del e-CF), D5-b se retrasa lo mismo: **no puede empezar antes del corte.**

## 3. Riesgos y mitigación
| Riesgo | Prob./impacto [I] | Mitigación |
|---|---|---|
| Choque con T1-5 en `TrabajoNotificaciones` y en las pruebas (`NotificacionesReportesTests`, `ReenvioReportes*`, `TokenServicioTests` usan el modelo viejo; PD1 2.1: «solo T1-5 hace la adaptación masiva») | Alta / Medio | Rama de A sobre T1-5 **unido**, nunca en paralelo. B confirma qué pruebas de R1 adapta T1-5. El #225 se une antes del 11-02 |
| Partir la zona R rompe «un dueño por zona» (DEC 4) | Media / Medio | R1 y R2 por archivos, escritas en la firma. Si D5-c necesita tocar R1, avisa a A |
| EventId: 4729 es de la introspección (D5-c); 4794 y 4795 de D1; quedan 4796 a 4799 de la reserva de DB-7 [V: ninguno en `src`] | Baja / Bajo | D5-b no necesita EventId propio (lo suyo es un evento de bitácora). Si hiciera falta, lo asigna el arquitecto de datos de B. `EventIdUnicosTests` lo detecta |
| Capacidad de A: 2 compilaciones simultáneas en la PC A; cola de la tanda 7 y de la tanda 8 (puntos 1 a 6); #173 hasta el 11-13; ensayos de PR-D2 en la VM del 16 al 27-nov (traspaso A 23-oct, sección 3) | Media / Alto | D5-b cabe en 1,5 a 2 dp con un agente. La suite oficial completa la corre C o B (sola, BP3 10.2). Si el 11-16 A no tiene hueco, D5-b vuelve a B sin costo, porque no empezó |
| Estimaciones de ±30 % (DEC) y diferencia entre DEC y BP3 en el tamaño de D5 | — | El punto de control del 11-20 decide igual que hoy |

## 4. Alternativa: B lo hace todo (DB7-06 tal como está)
- **Ventajas** [V]: un solo dueño de la zona R y ninguna coordinación nueva.
- **Costo** [I]: en PD1 6.2, los agentes 1 y 2 de B están en T1-6 y T1-8 el 11-16 y 11-17. D5 entero (7,5 a 10 dp según BP3) empezaría hacia el 11-18 con un agente, así que su PR caería hacia el 11-25 a 27, **después del punto de control**. Detrás va D4 en el orden de unión.
- **Con D5-b en A:** B ahorra 1,5 a 2 dp en S4, la semana más cargada, y D5 de B baja a 6 a 8 dp. El ahorro es modesto y la cifra es frágil (±30 %).
- **No cambia** la vía (C)/(C′) del punto de control.

## 5. Pregunta para la firma del propietario
**P-D5-01.** Se propone modificar DB7-06 para que el equipo A construya la parte **D5-b** de DB-7:
- notificaciones con el estado real del autor (Q7 y `REGLA_NOTIFICACION_SUSPENDIDA`), sin el ADMIN sintético, e `IVerificadorAccesoAutor` sobre `EstadoAccesoService`;
- en la zona R1 (`TrabajoNotificaciones` y `GPOS.Api/Seguridad/Programados`);
- con el código a partir de la unión de T1-5 y el PR antes del 2026-11-20.

B conservaría D5-a, D5-c y D5-d, la zona R2, el resto de DB-7 y la unión. Si el 2026-11-16 A no tiene capacidad, D5-b vuelve a B.

¿Lo firma? **(a)** Sí (lo que recomienda A). **(b)** No: B construye todo D5, como está firmado.

**Advertencia honesta:** la división en D5-a a D5-d y todas sus cifras son inferencias de A sobre BP3. B, que es el dueño del plan, debe confirmarlas antes de presentar la pregunta.
