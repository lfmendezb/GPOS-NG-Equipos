```
Para: B (copia a A)            De: C            Fecha: 2026-10-10
Tipo: Entrega | Pregunta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/adr81-fase-a-diseno (b324267)
Estado: Abierto
```

# Blueprint de la fase A de ADR-81, versión 3: PC-1 (a) y precisión C-1 incorporadas

Responde a `B-a-C/2026-10-10-reparto-pc1-y-siguientes.md` y `B-a-C/2026-10-10-c1-reautenticar-otp.md`. Es solo diseño.

**Dónde:** `docs/arquitectura/2026-10-10-adr81-fase-a-blueprint.md` y `docs/decisiones/2026-10-10-preguntas-adr81-fase-a.md`, en `b324267`.

## PC-1 (a)
- **§13.1 nueva**, con la división de la tabla §13.2 de A.
  - **A construye el núcleo:** detección y vigilancia cada 15 s, bloque B, reconciliación v1 sin factor, tabla y disparadores de `BitacoraSeguridad`, 5.14 sin factor, P-81A-11, `SistemaRestaurado` y la pantalla sin factor.
  - **C agrega:** la reconciliación v2, la purga y su trabajo, `BitacoraSeguridadService` (D81-10 y 5.11), `otp` y `RequiereAutenticacionReciente` en 5.14.2 y R3, `SuperConFactor`, `MinutosInactividad`, P-D81-01 y los errores 52001, 52002 y 52010 a 52019.
- **Orden de unión:** el segundo PR de H-11 entra primero y C rebasa T2 a T5b sobre él; **T1 puede empezar antes**, porque no toca archivos comunes.
- **Un solo editor:** el SQL de C va en `EsquemaSistema.SegundoFactor.cs`, que corre después del `EsquemaSistema.Restauracion.cs` de A.

## Precisión C-1 (UX-V-01)
- **Motivo único del 401: `factor`.** Es el que envía hoy la API de reportes (`ProtocoloIntrospeccion.MotivoFactor`, `origin/b/ola5`). `factor-requerido` solo existía en el diseño, así que la elección no cambia ninguna línea de código.
- **Contrato común (§5.15):** 401 con `X-GPOS-Sesion: factor` y `WWW-Authenticate: Bearer`. La principal agrega el cuerpo `FACTOR_REQUERIDO`. El cliente decide solo por el encabezado.
- **API principal:**
  - `OnTokenValidated` ya no rechaza el token del SUPER sin `otp`: lo marca.
  - El middleware nuevo `FiltroFactor` responde el 401 a todo salvo `POST /reautenticar`, `POST /salir`, `GET /sesion` y `GET /factor`.
  - `/reautenticar` emite en la misma sesión un token con `amr` más `otp`.
- **Clientes:** el `ApiClient` de la Web y el de MAUI distinguen `REAUTENTICAR` y `factor` **antes de cerrar la sesión**, abren P6 y repiten la petición una vez.
- **Visor de reportes:** sin cambios de código en la API de reportes, porque la principal responde el 401 antes de reenviar.

## Estimación (±30 %)
**≈ 8,25 sp** (de 5,8 a 10,7), antes 8,55: T5b baja −0,55 y C-1 suma +0,25.
- **Costo:** de USD 12.400 a 16.500.
- **Calendario:** unas 1,8 semanas de un desarrollador.
- **Fase A mínima:** 7,35 sp.

## Discrepancias con el diseño de A (DC-01 a DC-09): todas resueltas, sin firma
- **DC-01:** A ya cumple D81-06 en su diseño de datos (`CREATE OR ALTER` más `ENABLE TRIGGER` dentro de `EXEC`). La frase de su §13.2 era solo un resumen. **Retiro la observación de `C-a-B/2026-10-10-pc1-acuerdo-de-c.md`**; C adoptó la versión de A, porque la suya fallaba en una base nueva.
- **DC-02 a DC-09:** C adopta lo de A:
  - DC-02: el fork esperado nulo ya no se salta la comprobación (DD-16);
  - DC-03: 5.14.2 responde 200;
  - DC-04: la vigilancia corre cada 15 s;
  - DC-05: 503 también en las consultas para los usuarios que no son SUPER;
  - DC-06: la guarda de versión del procedimiento (A crea la v1, C la v2);
  - DC-07: A usa 52008 y 52009;
  - DC-08: la interfaz `ICandadoRestauracionSistema` de A;
  - DC-09: R-D13 de A es el mismo que R-15 de C.

## Pregunta nueva al propietario
- **P-81A-14:** un SUPER con la sesión abierta y sin factor dado de alta (por ejemplo, un ADMIN ascendido) no puede usar «Confirmar su Identidad».
  - **Recomendación (a):** cerrar la sesión y llevarlo al inicio para el alta (P-81A-10), sin costo adicional.
  - **Alternativa (b):** dar el alta dentro de la sesión, +0,15 sp.
  - **Mientras no se firme:** el diseño sigue (a), con un 409 `ALTA_REQUERIDA`. **Conviene firmarla antes de T7.**

## Para B (severidad Baja)
- Agregar `factor`, `amr` y `otp` a `DuplicacionClaimsTests`.
- Que la API de reportes responda `factor` también por el nivel de la cuenta (caso del ADMIN ascendido).
- Llevar `inactiva` y `renovada` al protocolo de introspección, porque hoy llegarían al visor como `revocada`.
- Que el visor reutilice P6 (`DialogoConfirmarIdentidad`).
- **R-21:** `b/ola5` ya trae `OpcionesSegundoFactor` y la constante `factor`. Avisar si la ola 5 se une antes que la fase A.

**En curso en C:**
- el diseñador actualiza P6 y P10 de las pantallas al motivo `factor` y al flujo sin cerrar la sesión;
- C-10 (compra).
