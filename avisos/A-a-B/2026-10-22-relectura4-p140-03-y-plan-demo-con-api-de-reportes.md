```
Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (relectura 4 de la deuda P137/P140; plan del DEMO con la API de reportes, tarea 3) y alerta de alcance
Prioridad: Alta (el plan del DEMO cambia el esfuerzo estimado en la hoja de firma)
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/`
Estado: Abierto
```

# 1. Cuarta relectura de seguridad: rama `b/deuda-pr2-p137-p140`: aprobado con observaciones
`traspasos/A/relectura4-seguridad-p140-03-2026-10-22.md`. Los 9 commits están cherry-picked sin conflicto en el árbol local de A (**no subidos al #140**: esperan tu confirmación con el propietario). Sin Críticos, Altos ni Medios. **P140-03 correcto** (sirve el certificado vigente, el bucle no muere ni se acelera, el `LogError` no filtra mensaje ni rutas, no necesita EventId propio: el 4752 sigue reservado; 4748/4749 conservan su sentido y desaparece el 4748 falso). Las pruebas nuevas prueban lo que dicen; P140-04 es solo prueba. Solo lectura: nadie corrió la suite oficial sobre la rama.
- **R4-01 (Baja, ya existía):** con un solo proveedor del registro roto puede salir un segundo 4748 («AggregateException»); queda para la deuda. **R4-02 (Baja):** calcular `venceTomado` antes del `lock`. **R4-03:** `TargetHost` no tiene efecto ni es explotable.
- **Tus dos preguntas:** (a) constructor interno `(StoreName, StoreLocation)`: **no**; un cambio de la fábrica a `CurrentUser` pasaría la regla de arquitectura y ese almacén lo escribe cualquier proceso de la cuenta del servicio. Alternativa: campo `internal static readonly` con `LocalMachine`/`My` verificado por la prueba. (b) `TargetHost`: **mantener y comentar** (lo sobrescribe `SocketsHttpHandler`; la garantía real son `DireccionApi` y el `ConnectCallback`).
- A hace R4-02, el comentario y el campo en un commit local aparte sobre el #140; al subirlo avisamos.

# 2. Plan del DEMO con la API de reportes (tarea 3): **el alcance sube de 2 a 3 dp a 6,5 a 8 dp**
`traspasos/A/plan-demo-con-api-de-reportes-2026-10-22.md` (solo lectura sobre `origin/feature/modelo-ng`, #124, #136, #139, #152 y `origin/demo/2026-10-15`; nada ejecutado).

**D-1 (Alta):** dar la dirección de reenvío no basta. En Release la introspección de la principal exige que corra como servicio `NT SERVICE\GPOS.Api`, y la API de reportes exige además el SID de esa cuenta en `CuentaServidor` (`ValidadorTokenPrincipal.cs:109-117`, `ServidorIntrospeccion.cs:96-112`). Si no, la principal arranca y toda ruta de reportes da 503. **El DEMO pasa a dos servicios con elevación en cada instalación y actualización**, con arrastres: principal bajo cuenta virtual en modo Amplio sin `sysadmin`, clave JWT sin canal seguro, DPAPI de usuario bajo cuenta virtual, binarios en `Program Files`, y el modo de red del PR-4. La hoja de firma estimaba solo los scripts.

**Qué se rompe:** hoy nada publicado (los DEMO ya publicados salen de `demo/2026-10-15`, sin Q-6); se rompe **la próxima publicación desde `feature/modelo-ng`** (`Publicar-PaqueteDemo.ps1:129-135` y `:118`, `Instalar-Demo.ps1`, `Iniciar-Demo.ps1`, `LEEME.md:19` y `:63-71`) y el ensayo corto (`iniciar-api.ps1:36`). No existen el MSI de reportes ni los verbos `implantar-servidor` y `comprobar-servidor`.

**Secuencia segura:** PR-4 → **PR-D1** → T4-06 → T4-04 → T1-5 → T4-02 → PR-V (verbos) → PR-D2 (DEMO con reportes) → D4. **PR-D1** (0,5 dp, sin compilar): `Publicar` acepta `-ConApiReportes` y, con Q-6 en el árbol, rechaza publicar sin esa bandera. **Debe estar unido antes del 11-nov; T4-06 no debe unirse sin él.** Si el spike falla, respaldo: congelar el DEMO en `demo/2026-10-15` (opción b de la hoja).

**Fechas (A):** nada hasta el 2-nov; PR-D1 del 3 al 6-nov; spike antes del 13-nov; PR-D2 con ensayos del 16 al 27-nov (justo frente a D4, 4-dic). Instala y ensaya el propietario o un técnico en `VM-SRV` de LFMB, con el formato de evidencia de C (casos propios DE-01 a DE-09). Esfuerzo: PR-D1 0,5 + spike 0,5 + verbos 1,5 + PR-D2 2,5 a 3 + sobrecarga D-2 a D-6 de 1 a 1,5 + ensayos 1 = 6,5 a 8 dp [I].

**Preguntas (11 en la sección 7 del plan); las urgentes:**
- **P-1 (B y propietario, antes del 3-nov):** ¿se acepta que el DEMO pase a dos servicios con elevación y 6,5 a 8 dp? Con la capacidad de la PC A (T4-06 y el token ocupan los dos cupos desde el 3-nov) esto compite en capacidad; conviene decidir prioridades.
- **P-4 (B):** T4-06 debe conservar el nombre `CompilacionDepuracion` (la guarda de `Publicar` lo usa) y no unirse antes de PR-D1.
- **P-2 y P-5 (B):** si la principal en modo Amplio con `NT SERVICE\GPOS.Api` y DPAPI de usuario arranca (lo resuelve el spike).
- **P-3 (seguridad de A):** cómo llega la clave JWT al servicio (recomendado: entorno del servicio con DACL restringida, solo DEMO).
- **P-7 (B, T4-01):** el perfil de Chromium va a TEMP; pedir `%ProgramData%\GPOS NG\Reportes\render`.
- **P-8 (B y C):** VM libre en LFMB y quién ejecuta dentro de ella.

Respuesta requerida: B responde P-1 y P-4 antes del 2026-11-03 (P-1 también al propietario), y P-7 antes de que T4-01 se una.
