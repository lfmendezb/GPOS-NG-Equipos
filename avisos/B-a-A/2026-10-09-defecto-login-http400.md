```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Defecto reportado por el propietario
Prioridad: Alta (afecta el inicio de sesión en la Web)
Repositorio y rama: GPOS-NG (GPOS.Web; el propietario lo ve en su equipo, http://localhost:5054)
Estado: Abierto
```

# Login de la Web: HTTP 400 intermitente al pulsar «Entrar»

**Reporte del propietario:**
- Ocurre en el **DEMO de la segunda ronda** (aclaración del propietario). De forma **intermitente**, al escribir usuario y contraseña en la Web y pulsar **Entrar**, el navegador muestra «Ahora mismo esta página no está disponible — HTTP ERROR 400».
- La URL es `localhost:5054/cuenta/login?retorno=%2F`. Captura en `avisos/B-a-A/adjuntos/2026-10-09-login-http400.png`.
- **Manera de evitarlo:** borrar de la URL `/cuenta/login…` en adelante y cargar la URL base. Así sí entra.

**Hipótesis de B (inferida; no la reprodujimos ni miramos los registros):**
- `Login.razor` es una página estática con `EditForm method="post"` (`FormName="login"`), protegida por `app.UseAntiforgery()` (`Program.cs:102`).
- Un 400 en el POST, que se arregla cargando la página de nuevo, es la señal típica de un **token antifalsificación inválido**. Lo que la URL base resuelve es pedir una página nueva con un token nuevo.
- **Causas probables:**
  1. **«Token meant for a different claims-based user».** La página de login se dibujó con una sesión distinta: por ejemplo, la sesión expiró o se cerró, se redirigió a `/cuenta/login?retorno=/` y la cookie de autenticación cambió entre el GET y el POST. Encaja con el `retorno=%2F` y con que sea intermitente.
  2. **Token que no se puede descifrar,** porque la Web se reinició o cambió el anillo de llaves (`PersistKeysToFileSystem`, `Program.cs:23-24`) con la pestaña abierta.
  3. **Página servida desde la caché o el historial** con un token viejo.
- **Qué revisar:**
  - el registro de la Web en el momento del 400: los mensajes de `Microsoft.AspNetCore.Antiforgery` dicen cuál de las tres causas es;
  - `Cache-Control: no-store` en `/cuenta/login`;
  - si el login debería tolerar ese caso. Por ejemplo, con `[RequireAntiforgeryToken(required: false)]` solo en el login, si su análisis de seguridad lo permite, o volviendo a dibujar el formulario con un token nuevo y un mensaje («La página caducó; vuelva a intentarlo») en lugar del 400 crudo.

B no tocó `GPOS.Web` del núcleo. Lo atiende A.

## Registros del DEMO (agregados el 2026-10-09 a pedido del propietario)

Copias de `C:\GSF\PROYECTO ARGON\GPOS-Demo-Socio-2026-10-07\registros\`: `adjuntos/2026-10-09-login-http400-web.log` y `adjuntos/2026-10-09-login-http400-api.log`. Lectura de B:
- **No hay ninguna línea de antifalsificación ni del 400.** El fallo de validación del formulario se registra por debajo del nivel que escribe el DEMO (Production). Para confirmar la causa, suban `Microsoft.AspNetCore.Antiforgery` y `Microsoft.AspNetCore.Components.Endpoints` a `Debug` en el DEMO y repitan.
- **`web.log`, líneas 11 a 22:** `RemoteNavigationManager` falla al navegar a `cuenta/login?expirada=true` con `TaskCanceledException`, y deja un «Unhandled exception in circuit». Es la redirección por **sesión expirada** (`Program.cs:158`). El circuito se cortó durante la navegación. Encaja con la causa 1: la página de login se dibujó en el contexto de una sesión que ya no vale. Además, la excepción sin manejar en el circuito es un defecto aparte.
- **`api.log`, línea 4:** `RelojInconsistente` («el reloj del sistema salt… más de 2 días hacia adelante sin una hora confiable… la hora más alta del sitio sigue en 2026-10-06»). El reloj protegido (H-16 v2.1) no se fía de la hora del equipo del DEMO. Revisen si eso afecta la vigencia de la sesión o del token, por ejemplo con expiraciones calculadas con horas distintas en la Web y en la API, y si contribuye a la expiración que termina en `expirada=true`.
- `web.log`, línea 9: «Failed to determine the https port» (el DEMO corre por http). Probablemente no tiene relación.
