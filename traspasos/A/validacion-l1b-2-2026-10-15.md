# Validación del arquitecto: PR #42 (L1b-2: registro, `UseLicencia` y rutas L-01 a L-09)

- **Fecha:** 2026-10-15. **Autor:** arquitecto-software, equipo A, como dueño del blueprint.
- **Qué revisé:** rama `a/lic-l1b-2` @ `b24ffe5f`, en el árbol `GPOS-NG-l1b`, en solo lectura. Leí el cuerpo del PR (alcance, verificación y los pendientes 1 a 9). No compilé ni ejecuté pruebas, ni hice una revisión completa del código.
- **Contra qué lo contrasté:** blueprint de la licencia v2.9 (4.1, 5.1, 5.3, 6.1 y 6.2), `validacion-l1b-1-2026-10-15.md` (con LB-02 y LB-06), ADR-60 punto 6, NV-07 y `validacion-pr41-h11-s1-s2-2026-10-15.md`.

## Dictamen: **Aprobado con observaciones. Dos condiciones bloquean la unión**

| Tema | Dictamen | ¿Bloquea? |
|---|---|---|
| Registro (`EstadoLicenciaService` como singleton e `IEstadoLicencia`, importador, `TrabajoLicencia`) y LB-01 (sustituto borrado, con prueba sobre Release) | **Confirmado.** Cumple la condición de L1b-1 | No |
| `UseLicencia`, 403 con `codigo` y encabezado `X-GPOS-Licencia` (sin días para el USER, LV-18) | **Confirmado** | No |
| LB-04 (en `/empresas/{codigo}` se evalúa la empresa destino; el alta solo la pasa el SUPER, o una clase `Consulta` o `Esencial`) | **Confirmado.** Es el aislamiento entre empresas de `[LIC]` 9 y LV-16 | No |
| Rutas L-01 a L-09 (L-03 `Esencial`, 10 por hora por cuenta, 64 KB; L-08 solo para el SUPER; L-09 con 410 y `Esencial`) | **Confirmado.** Cumple la condición 3d de L1b-1: L-03 y L-09 llegan juntas. **Falta:** los límites de LB-06 en `POST /api/admin/respaldos` y `POST /api/notificaciones/documento`. Si no están, se agregan aquí | Los límites de LB-06 son condición para la activación, no para la unión |
| LB-05 (`GetSinEscrituraTests` sobre el IL) | **Confirmado.** La autoprueba con L-03 y las excepciones de borrador y de apertura son razonables. Para la reimpresión, ver la decisión 1 | No |
| **Interruptor `GPOS:Licencia:Aplicar`, apagado por omisión** | **Corregir.** Va contra ADR-60 punto 6, firmado («sin interruptores»), y LB-01. Con la clave en el código unido, cualquier compilación podría apagar la licencia desde la configuración. **Texto exacto:** quitar la clave y la lectura de la configuración. En este PR, `app.UseLicencia()` **no se llama**; la activación es un PR de una línea que se une cuando se firmen C-5 y DL-21. QA-L06 se amplía a `Program.cs`: falla si `UseLicencia` queda condicionado a la configuración o al entorno | **Sí** |
| Pendiente 5: la Web usa GET y POST `/api/super/licencia`, que este PR retira o cambia (`ApiClient.Modulos.cs:340-341`, `LicenciaUsuarios.razor`) | **Corregir antes de unir.** Con este PR solo, la página de la licencia de la Web queda rota en `feature/modelo-ng`: el GET devuelve otro DTO y el POST responde 410. El blueprint (5.1, L-02 y L-04) pide sustituir la ruta **en el mismo PR**. **Texto exacto:** la página pasa a L-02 y L-04 (lectura) y a L-03 (carga), en este PR o en un PR de frontend que se una **junto** con este | **Sí** |
| Pendiente 4: Estricto sin `InstalacionId` | **Ya resuelto** por el PR #39, que genera la fila en `GPOS.Migracion sistema`. Basta con rebasar | No |
| Pendientes 2, 3, 6 y 7 (`Corroborar` sin `emitida`; `DpapiDemo` con #34; LV-17 en `UsuariosService`, de SL; piso en null) | **Aceptados** como dependencias declaradas: DL-21, #34, SL (DL-01) y la exposición del piso en la instantánea | No |

## Decisión 1: las tres rutas GET de reimpresión que escriben

**Pasan a POST.** Escriben la fila de control `doc.Impresion`, consumen la autorización y escriben en la bitácora. Un GET con efectos se puede disparar con una precarga, una caché o un enlace, y entonces infla el contador de copias y consume autorizaciones. Además rompe la garantía que LB-05 quiere fijar.

**Texto exacto:**
- `POST /api/impresion/{documento|ticket|nota}/...`, con el mismo cuerpo de parámetros que hoy viaja en la consulta. La autorización va en el cuerpo, nunca en la URL.
- Se marcan `ClaseLicencia(Consulta)` y entran en `RutasLicenciaAprobadas.json`, porque reimprimir está siempre permitido (ADR-59, punto 6; `[LIC]` 4.3).
- La Web y MAUI cambian a la vez, en el mismo PR. Los GET se eliminan sin período de transición, porque no hay clientes fuera de esos dos.
- La excepción de `ReimpresionService.RegistrarAsync` sale de LB-05.

**¿Bloquea?** No bloquea #42. Va en un PR propio **antes de activar `UseLicencia`** (≈ 0,4 dp, con los clientes). Hasta entonces, la excepción queda documentada en la prueba con la referencia a esta decisión.

## Decisión 2: `TrabajoLicencia` y la lectura del RNC

**Mecanismo [I].** Tal como está, la lectura usa el pool normal, así que después de leer la conexión **queda abierta y en reposo en el pool**. Si eso ocurre después del `SET SINGLE_USER`, esa conexión ocupa la única plaza y el `RESTORE` falla hasta que el pool la cierre, unos minutos después. Es más grave que robar el acceso en el instante del cambio.

**Texto exacto:**
1. `ComandosLicencia.RncEmpresaAsync` abre con `CadenaConexion.ParaTrabajo(cadena)` y **`Pooling = false`**: abre, lee y cierra, y no deja ninguna conexión ocupando la base.
2. **Caché por empresa** `(Rnc, LeidoUtc)` en `EstadoLicenciaService`. Se vuelve a leer:
   - al arrancar;
   - al aceptar una licencia (L-03 o el importador);
   - con `Invalidar(empresa)`, que llaman S-03 y la API ante un cambio de configuración de la empresa;
   - **cada 15 minutos**.

   El refresco de 60 s del motor usa el valor en caché.
3. **Si la lectura falla:** se conserva el valor en caché, se reintenta en el siguiente ciclo de 60 s y se registra una advertencia, sin evento de cambio de RNC. **Si nunca hubo lectura** (arranque con la base en restauración), la empresa **no opera** hasta la primera lectura correcta (motivo interno `RncNoLeido`, falla cerrada). No se registra `Invalida` ni `RNC_NO_COINCIDE`, y se reintenta cada 60 s. En la práctica, mientras tanto el candado ya responde 503 a esa base (S-1).
4. **NV-07:** el cambio legítimo de RNC pasa por S-03 o por su verbo y se ve al instante, porque S-03 llama a `Invalidar`. El verbo de `GPOS.Migracion` corre en otro proceso y se ve en 15 minutos como máximo. Un RNC editado en la base sin la fila con MAC se detecta en **15 minutos como máximo**: es una ventana pequeña frente a las gracias de días y no cambia nada firmado.
5. **Prueba:** con la API en marcha, `SET SINGLE_USER WITH ROLLBACK IMMEDIATE` y `RESTORE` de una empresa mientras corre `TrabajoLicencia`; el `RESTORE` no falla por acceso exclusivo. Además, una prueba unitaria de la caché: un cambio por `Invalidar` se ve en el ciclo siguiente.

**¿Bloquea?** No bloquea la unión (≈ 0,15 dp). Puede explicar las fallas del candado bajo carga, así que conviene hacerlo **en este PR**.

## Resumen

| # | Qué | ¿Bloquea? |
|---|---|---|
| 1 | Quitar el interruptor `GPOS:Licencia:Aplicar`; `UseLicencia` sin llamar hasta un PR de activación; QA-L06 sobre `Program.cs` | **Sí** |
| 2 | La página de la licencia de la Web pasa a L-02, L-04 y L-03 (mismo PR, o uno de frontend unido a la vez) | **Sí** |
| 3 | La lectura del RNC sin pool, con caché, invalidación y 15 minutos (decisión 2) | No (mejor en este PR) |
| 4 | Reimpresión por POST con `ClaseLicencia(Consulta)` (decisión 1) | No; antes de la activación |
| 5 | Límites de LB-06 en respaldos y notificaciones | No; antes de la activación |

### Cierre
- Estado: Aprobado con observaciones.
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\validacion-l1b-2-2026-10-15.md`.
- Supuestos:
  - Revisé el cuerpo del PR, no todo el código.
  - El mecanismo de la conexión en reposo que ocupa la base en `SINGLE_USER` es inferido.
  - «C-5» es la condición que nombra el coordinador; no la encontré en el blueprint v2.9.
- Decisiones candidatas a ADR: ninguna. Pasar la reimpresión a POST es un cambio de contrato, no de arquitectura.
- Entregas a otros agentes:
  - **desarrollador-backend (L):** puntos 1 y 3 en este PR; 4 y 5 antes de la activación;
  - **desarrollador-frontend:** el punto 2 y el cliente de la reimpresión (punto 4);
  - **coordinador:** el interruptor se sustituye por un PR de activación de una línea, que espera a C-5 y DL-21.
- Próximo paso recomendado: quitar el interruptor, ajustar la página de la Web y unir #42.
