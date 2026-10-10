```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega | Pregunta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/adr81-fase-a-diseno (6fa1854, desde 42e13b6)
Estado: Abierto
```

# C-3: blueprint de la fase A de ADR-81 (segundo factor TOTP del SUPER)

Entregado por el arquitecto de software de C. Solo es diseño: no se compiló ni se escribió código.

**Documentos (rama `c/adr81-fase-a-diseno`, `6fa1854`):**
- `docs/arquitectura/2026-10-10-adr81-fase-a-blueprint.md`
- `docs/decisiones/2026-10-10-preguntas-adr81-fase-a.md`

Los enlaces relativos a ADR-81 y a su hoja funcionan al llevar estos documentos a `master`.

## Lo que se encontró en el código (42e13b6)
- **SF-01 y SF-02 ya están cerrados** en `feature/modelo-ng` (`87321d5` y `479912b`): el SUPER se rechaza como autorizante antes de comprobar la contraseña, sin contar el intento y con un hash ficticio para que no se note por el tiempo de respuesta. **En `master`, ADR-68 (línea 48) todavía dice «no implementado»**: le toca corregirlo al documentador, en el registro de B.
- **SF-03 sigue abierto:** el comprobante del 409 se puede reutilizar y se emite antes de cualquier factor (`AuthEndpoints.cs:44-57,77-81,158-159`).
- **R-01, riesgo Alto de disponibilidad (inferido de la lectura):** si el reloj protegido queda adelantado, el TOTP falla para **todos** los SUPER, y la inconsistencia del reloj solo la puede resolver un SUPER (`RelojProtegido.cs`, `AdminEndpoints.cs:281-283`). Se lleva a firma como P-81A-02.
- **Hoja CS:** CS-7 y CS-8 ya están unidos (PR #11); CS-1, 2, 5, 9 y 10 no están construidos.
- **M-4 (comando de migración de `GPOS_SYSDATA`) no existe:** el esquema lo sigue actualizando `EsquemaSistema` al arrancar la API (P-81A-03).

## Diseño
- **Inicio de sesión en dos pasos:**
  - `login` responde **202** con un desafío de 5 minutos y un solo uso; un cliente viejo falla sin entrar;
  - después vienen `login/alta` (QR una sola vez) y `login/factor`, que emite el token con `amr` [pwd, otp];
  - el 409 se aplica **después** del factor, con un comprobante v2 de un solo uso, y así se cierra SF-03.
- **Reautenticación:** acciones sensibles listadas una por una sobre las rutas reales.
- **«Mi segundo factor»:** consultar el estado, regenerar los códigos de respaldo y cambiar de teléfono.
- **Restablecimiento:**
  - vía (a): un SUPER con motivo y factor reciente;
  - vía (b): `GPOS.Migracion restablecer-factor`.
- **Filtro en cada petición:** un token SUPER sin `otp` recibe `401`. Va integrado con CS-9 y CS-10 (inactividad de 30 minutos y tope de 4 horas para el SUPER).
- **Esquema idempotente en `EsquemaSistema`:**
  - `UsuariosFactor` y `UsuariosCodigosRespaldo`;
  - `BitacoraSeguridad`, con disparadores: nunca se modifica y solo se borran filas de más de 2 años;
  - **se propone reservar los errores 52001 a 52019 para `GPOS_SYSDATA`**.
- **Custodia del secreto:** Data Protection con el propósito `GPOS.Usuarios.SegundoFactor.v1`. En la Web, el desafío y el URI quedan en la memoria del servidor.
- **Pruebas y criterio de salida:**
  - plan de pruebas PF-01 a PF-30, más PA-1 a PA-14 de CS;
  - criterio de salida: SF-01 a SF-03 en verde por HTTP, el secreto sin aparecer en ningún registro y la revisión del auditor sin hallazgos Críticos ni Altos.

## Estimación (inferida, ±30 %)
- **Fase A con CS:** T1 a T9, **≈ 6,75 sp (de 4,7 a 8,8)**, unas 1,5 semanas.
- **Fase A mínima:** ≈ 5,9 sp, sin MAUI, sin la reautenticación y sin la vía (a).
- **Orden:** después de unir T1, T2 y T4 de ADR-118/119 y antes de la ola 5. CS va junto con la fase A (CS-13).
- **Un solo editor** para T3, T4 y T6.

## Preguntas al propietario (P-81A-01 a 10; recomendación entre paréntesis)
| # | Pregunta | Recomendación |
|---|---|---|
| 01 | Nombre de la entrada en la aplicación autenticadora | «GPOS NG – nombre de la instalación:usuario» (b) |
| 02 | Hora del TOTP con el reloj protegido adelantado | Aceptar el reloj protegido y también el del sistema mientras difieran, con el evento `DERIVA_RELOJ` (c) |
| 03 | Dónde se crean las tablas | En `EsquemaSistema` hasta que exista M-4 (a) |
| 04 | Solo inserción y retención antes de RG-14 | Disparadores y purga diaria en la API (a) |
| 05 | Quién consulta la bitácora de seguridad | Solo el SUPER, de solo lectura (a) |
| 06 | Aviso de un código erróneo con la contraseña correcta | En el siguiente inicio de sesión (a) |
| 07 | Vigilar que haya al menos dos SUPER | Aviso no bloqueante (b) |
| 08 | Que otro SUPER desbloquee el factor sin restablecerlo | Sí, con motivo y factor reciente (a) |
| 09 | Tras usar un código de respaldo, ¿nueva alta? | Ofrecerla, no exigirla (a) |
| 10 | SUPER con contraseña temporal | Primero el factor y después el token restringido (a) |

- **Lo ideal es firmar 01 a 04 antes de T1.**
- No hace falta un ADR nuevo: 02, 03 y 04 son precisiones de ADR-81 (puntos 4, 5 y 12), así que no se usan números de C.

## Otros riesgos
- **R-03:** perder el anillo de Data Protection invalida todos los secretos.
- **R-04:** la cuenta `GSF` está compartida por varios agentes.
- **R-05:** verificar los códigos de respaldo con PBKDF2 cuesta CPU; PF-12 lo mide.
- **R-06:** sin RG-14, los disparadores protegen contra errores del programa, no contra una API comprometida.
- **R-07:** choque de archivos con L1 de la licencia.

## Para B
- **Hoja de firma:** llevar P-81A al propietario.
- **Reportes:** la introspección de la API de reportes (S-15) debe rechazar un token SUPER sin `otp` y respetar el sello, el último token y la inactividad.
- **Revisiones siguientes:** validación del arquitecto de datos (§7.2), revisión del auditor (oráculos, R-01, vía b) y diseño de pantallas (§15). C las puede hacer si B se las encarga.
