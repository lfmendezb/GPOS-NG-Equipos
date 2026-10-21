```
Para: C        De: B        Fecha: 2026-10-21
Tipo: Respuesta
Prioridad: Media
Repositorio y rama: GPOS-NG PR #127 (b/n1-api-modo-servicio); plan `traspasos/C/2026-10-20-plan-pruebas-n1-api-servicio.md`
Estado: Abierto
```

# Respuestas de B a las preguntas P-1 a P-8 del plan de pruebas de N-1

Todas son decisiones técnicas de B (no cambian lo que ve ni hace ninguna persona), salvo P-6, que el propietario confirmó en el chat el 2026-10-21.

| # | Respuesta |
|---|---|
| **P-1 · Costura** | **Sí.** El registro del servicio, las opciones del anfitrión (`ContentRootPath`), la configuración del registro de eventos, el `ShutdownTimeout` y `ARRANQUE_PRIVILEGIOS` pasan a `src/GPOS.Api/Servicio/ModoServicioApi.cs`, con `Opciones(args, esServicio)`, `Registrar(IServiceCollection, ILoggingBuilder)` y `ComprobarArranque()`, siguiendo a `ModoEstacion`. **Hecho** en el commit `8b143377` del #127 (2026-10-21). Hoy el registro está en línea en `Program.cs:31`. Los grupos B y C quedan sin SQL. |
| **P-2 · EventId** | **Franja 4767 a 4770 para N-1.** Cuatro números: `ARRANQUE_PRIVILEGIOS` (Crítico), servicio iniciado, servicio detenido y privilegios presentes (Información). `GPOS.Instalacion` queda con 4771 a 4779 (nueve números); lo comunico a A en la misma fecha. Verifiqué que ninguna rama usa hoy 4767 a 4779. **Aviso:** `b/t1-7-rq-r12` (#119) ya usa **4790** (`EventoImagenOmitida`, `ServicioImpresion.cs:18`) dentro de la reserva de DB-7; esa reserva queda en **4791 a 4799**. `EventIdUnicosTests.Declarados()` debe ver los cuatro números nuevos. |
| **P-3 · Forma de fallar** | **`Environment.Exit(1)`**, como la estación, con el evento Crítico escrito antes de salir. En consola no se comprueba (C-10). **En systemd o Linux (corrección del 2026-10-21, tras construir el #127):** no hay nada que comprobar, porque `AddSystemd` no existe (ADR-129 está decidido, no implementado); la falla cerrada fuera de Windows sigue siendo la de H-L1 y H-L2, y la prueba `La_API_no_tiene_otra_logica_de_servicio` impide agregar systemd sin una decisión. Orden: **identidad y privilegios, luego modo de red, luego anillo, luego datos** (`ExigirArranque` de A después de la comprobación de privilegios). El código de salida es 1 en ambos casos; la prueba E-04 lo fija. |
| **P-4 · Escucha** | Hasta que entren PR-2 y PR-4 de A, el `appsettings.json` del servicio fija `urls` en `http://localhost:5071` (el puerto que espera `GPOS.Web/appsettings.json:14`). Es un valor de configuración, no una tecnología nueva. L-03 lo comprueba con `GET /api/salud`. |
| **P-5 · Tiempo de arranque** | **Sí**, se mide en L-07 y L-08 y se decide allí entre dependencia de SQL, inicio diferido o reintento. Umbral: **20 s o menos en frío con SQL listo**. |
| **P-6 · Paquete de systemd** | ADR-129 B.1 lo cubre, **en 10.0.13** y no en 10.0.12. El propietario confirmó (2026-10-21) subir toda la familia a 10.0.13; lo hace el PR #131 (seis paquetes en `master`). El #127 rebasa sobre él y sube `Hosting.WindowsServices` (y `AgenteImpresion`) a 10.0.13. |
| **P-7 · Reparto** | **De acuerdo.** C escribe los grupos A y B (solo texto y reflexión) en un PR apilado sobre `b/n1-api-modo-servicio`, listo el 2026-10-27. El desarrollador de B escribe C y D con el código. El devops de B escribe F y ejecuta el laboratorio L-01 a L-16. El grupo E se agrega al unir PR-4 de A. |
| **P-8 · `Use…` y la sesión** | Verificado con búsqueda en `origin/feature/modelo-ng` (2026-10-21): los seis leen la identidad autenticada del token (`ctx.User`): `UseFiltroFactor` (`Claims.Usuario`, `MetodosSesion`), `UseAutenticacionReciente` (`ctx.User.Identity?.IsAuthenticated`, `MetodosSesion.Desde(ctx.User)`), `UseCambioClaveObligatorio` (`Claims.CambiarClave`), `UseModoEsquemaPendiente` (`ClaimsSesion.EsquemaPendiente`), `UseVersionEsquemaEmpresa` (`Claims.Empresa` y servicios) y `UseModoCandadoRestauracion` (`IsAuthenticated` y `ICandadoRestauracionSistema`). Se quedan en la regla R6. Límite: leí las líneas que casan con la búsqueda, no los seis archivos completos; si la prueba R6 encuentra una excepción, se saca de la regla. |

## Calendario que queda
- B: #127 ajustado (`8b143377`): costura, EventId 4767 a 4770, escucha 5071 y paquetes en 10.0.13. Los grupos A y B de C ya pueden apilarse sobre `b/n1-api-modo-servicio`.
- C: grupos A y B el 2026-10-27, apilados sobre `b/n1-api-modo-servicio`.
- Hallazgos de C que B toma: el arranque de Chrome o Edge para el PDF (`ConvertidorPdf.cs:66-82`) se pasa a A para la justificación de privilegios (R-3); la carga de SQL, el anillo y la licencia antes de `app.Run()` se mide en L-07 y L-08.
- No se une nada sin orden expresa del propietario.
