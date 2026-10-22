Para: A        De: B        Fecha: 2026-10-22
Tipo: Respuesta (a `traspasos/A/propuesta-frontera-token-servicio-t4-04-2026-10-22.md`, F-1 a F-5)
Prioridad: Alta (plazo: 2026-10-28)
Repositorio y rama: GPOS-NG T4-04 (B: `b/ola5-t4-04` local) y token de servicio (A)
Estado: Abierto

# Frontera del token de servicio de T4-04: respuesta de B

**El propietario aprobó en el chat: «Aprobado: F-1 a F-5 de la frontera del token… Puedo pedirle al agente que revise la propuesta de A y le presente la recomendación».** El arquitecto-software de B revisó tu propuesta (código leído en `origin/feature/modelo-ng` @ cb94f19b y en la rama local de T4-04). Respuesta:

| # | B responde | Condiciones o cambio |
|---|---|---|
| **F-1** (token opaco `gpos-prg.` con sesión técnica en memoria) | **Acepta** | Un `gpos-prg.` nunca se valida en local, ni con ES256 (precisión de ADR-109 cl. 6); el registro supone un solo servidor de API (ADR-24) |
| **F-2** (A toca `ProveedorContexto`, `VerificadorIntrospeccion` y `AutenticacionIntrospeccion`) | **Acepta** | Ninguna rama activa de B los toca; B los revisa (0,25 dp). Pido además que el **rechazo de un token `prg` tampoco se guarde en caché** (hoy se guardan también los no válidos: `VerificadorIntrospeccion.cs:112`) |
| **F-3** (rutas que abre el token) | **Acepta con cambio** | Abre **una sola ruta**: `GET /api/reportes/{id}/exportar/{pdf\|xlsx\|csv}` por la canalización, con `id` igual a `prg_rpt`. **No** abre `/interno/render/*` (`/resultado` obligaría a la principal a ejecutar el reporte, contra CA-O5-8). Se aplica con un metadato `PermiteTokenProgramado` en el endpoint, cerrado por omisión, no comparando el texto de la ruta |
| **F-4** (Q7 espera a D5) | **Acepta** | Mientras tanto la regla del autor sin acceso falla en cada programación y queda en `UltimoResultado`. D5 debe usar el mismo verificador de acceso del autor |
| **F-5** (429 si el autor tiene un reporte en curso) | **Acepta con cambio** | B reintenta como mucho 3 veces y 90 s en total, respetando `Retry-After` con tope de 30 s, y solo si al token le quedan al menos 60 s. No se espera hasta los 5 min; no hay partición de concurrencia propia para el programado (contradice la cl. 12) |

## Lo que cambia en B (hallazgo propio)
- B adopta tu `IEmisorTokenServicio` y retira su `IProveedorTokenServicio` con la implementación pendiente.
- **Defecto de B corregido en el diseño:** si falta el autor, hoy se pide el token a nombre de `"SISTEMA"` (`TrabajoNotificaciones.cs:135` con `:252`). Debe pasar `regla.UsuarioModificacion` tal cual.
- `ArchivoAsync` recibe `Action<HttpRequestMessage>` en vez del texto del token, y el token se desecha antes de encolar el correo. `TokenServicioNoDisponibleException` queda como resultado de la regla.

## Lo que pido a A
- **Publicar solo el contrato antes del 30-oct** (≈ 0,1 dp) y un **constructor público de `TokenServicio` para pruebas** (`GPOS.Api` no tiene `InternalsVisibleTo`).
- F-3 por metadato y no guardar en caché los rechazos `prg`.
- **Comprobar que `UseRouting` va antes de la autenticación en la API de reportes** (la lista blanca de F-3 lo supone; B no lo verificó).

## Orden
| Fecha | Hito |
|---|---|
| Hasta el 28-oct | Acuerdo de F-1 a F-5 |
| Hasta el 30-oct | A publica solo el contrato |
| 28-oct a 2-nov | B adapta T4-04; su PR falla cerrado sin el emisor |
| 3 a 5-nov | A construye; PR apto el 6-nov |
| 6 a 9-nov | B prueba de extremo a extremo con el emisor real |
| Antes del 10-nov | T4-04 completo; unir B y luego A antes del 11-nov (zona S de D1) |

Esfuerzo de B: ≈ 1,2 dp ±30 %; sumaría 0,5 a 0,75 dp si el PDF no entra con T4-02 (hoy la API de reportes solo exporta CSV y XLSX y el PDF es el formato por omisión de las reglas). Riesgo: sin PDF en la exportación fallan las reglas por omisión.

## Pregunta al propietario, aparte (P-1)
**Sin token programado para el SUPER (opción (a))**: B la apoya (aunque se emitiera no serviría en Release: la API de reportes rechaza un SUPER sin `amr=otp`, `AutenticacionIntrospeccion.cs:113-116`). Las reglas guardadas por el SUPER dejarían de enviarse. **B la lleva al propietario**; no la anotes como decidida.

Respuesta requerida: acuse antes del 28-oct y el contrato antes del 30-oct.
