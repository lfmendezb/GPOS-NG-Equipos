# Propuesta de C para B: precisión de ADR-83 por TN-01, 7(b) y 7(d)

**Fecha:** 2026-10-17 · **De:** C · **Para:** B, que la registra en `master` (los ADR se registran solo allí) · **Estado:** borrador para registrar; las tres decisiones ya están **firmadas** por el propietario.

**Fuentes:**
- Firmas: `avisos/C-a-B/2026-10-17-firma-tn01.md` y `avisos/C-a-B/2026-10-17-firma-tn01-7b-7d.md`.
- Informe: `traspasos/C/revision-seguridad-tn-2026-10-17.md`, TN-01.
- Entregas: `avisos/C-a-B/2026-10-17-entrega-tn01.md` y `avisos/C-a-B/2026-10-17-entrega-tn01-7b-7d.md`.
- Código: `c/adr81-tn-sobre-rn` @ `d6a1edba`, en `SellosService.NegativaSuper`, `UsuariosService.IniciarCambioFactorAsync` (`restablecimientoConsola`) y `CodigosLicencia`.

**Cómo registrarla:** el bloque de abajo se pega tal cual al final de `docs/adr/ADR-083.md`, después de las «Precisiones del 2026-10-17» de RN y SL. La línea de ADR-83 en `docs/adr/README.md` suma «precisión TN-01, 7(b) y 7(d) del 2026-10-17». En `ADR-081.md` (punto 7) va una nota de una línea que remite aquí, porque la precisión toca la vía (b).

---

> **Precisión del 2026-10-17: legitimación de los Super Usuarios, TN-01, 7(b) y 7(d)** (firmada por Leonardo Méndez, propietario, el 2026-10-17 en la sesión de C; preparada a partir de la revisión de seguridad de T-n de la fase A de [ADR-81](ADR-081.md), en `traspasos/C/revision-seguridad-tn-2026-10-17.md` del área común; registrada por B). El texto firmado de arriba no cambia: se lee así.
>
> - **Texto literal de las firmas:**
>   - TN-01: «Firmo TN-01 según la recomendación del auditor: la legitimación de un SUPER cuyo sello difiere en FactorAlta o PasswordHash se niega y pasa por el restablecimiento.»
>   - 7(b) y 7(d): «Firmo 7(b) y 7(d) según la recomendación: negar la legitimación de un SUPER sin sello legible con entrada SUPER en el padrón (con salida por la vía b), y negar también el nivel subido a SUPER.»
> - **Principio, precisión de los puntos 5 y 6:** una fila SUPER solo se legitima si **su nivel lo respaldan el sello legible o la entrada del padrón** y **nada indica que se cambiaron su contraseña o su factor**. Si no se cumple, S-02 y `sellos --legitimar` responden 409 sin cambiar nada. La consola se niega ya en la vista previa, antes de pedir `--confirmar`. Las cuentas que no son SUPER se legitiman como antes, con el control del cupo.
> - **Negativas, en este orden:**
>
>   | Fila SUPER | Respuesta | Salida |
>   |---|---|---|
>   | El sello legible o la entrada del padrón dicen un nivel inferior a SUPER (nivel subido por SQL) | 409 `USUARIO_SUPER_SIN_RESPALDO` | Ninguna por la vía (b). Si la cuenta es legítima: devolverle su nivel anterior, legitimarla con ese nivel y que otro SUPER le asigne SUPER desde Administración › Usuarios |
>   | Sin sello legible y sin entrada en el padrón (alta de un SUPER por SQL) | 409 `USUARIO_SUPER_SIN_RESPALDO` | Igual que la anterior: GPOS NG nunca crea un SUPER por esta ruta |
>   | Sin sello legible (`SinSello` o `SelloInvalido`) y con entrada SUPER en el padrón (7(b)) | 409 `USUARIO_EXIGE_RESTABLECIMIENTO` | `GPOS.Migracion restablecer-factor` (vía b) |
>   | El sello legible difiere de la fila en `FactorAlta` (factor borrado o insertado por SQL) o en `PasswordHash` (TN-01) | 409 `USUARIO_EXIGE_RESTABLECIMIENTO` | `GPOS.Migracion restablecer-factor` (vía b) |
>
>   `FactorAlta` se niega en los dos sentidos: un factor borrado y un factor insertado por SQL.
> - **S-01, `verificar` y `sellos`** dicen **qué campos difieren** entre el contenido sellado y la fila, solo por nombre y nunca con valores: `Nivel`, `Inhabilitado`, `RestringirSucursal`, `Sucursal`, `PasswordHash` y `FactorAlta`. En el contrato es el campo aditivo `CuentaSinSelloDto.Campos`, que llega null cuando el sello no se puede leer.
> - **Vía (b), precisión del punto 7 de [ADR-81](ADR-081.md):** `restablecer-factor` es la salida de los Super Usuarios que S-02 no legitima.
>   - Admite un sello propio que difiere de la fila solo en `FactorAlta` o en la huella de `PasswordHash`, con el mismo nivel, habilitación y sucursal, y con la entrada del padrón con MAC.
>   - Admite también una fila sin sello legible, si el padrón con MAC tiene su entrada con nivel SUPER, que sirve como prueba de identidad (7(b)).
>   - Sigue exigiendo que el anillo verifique `Licencia.InstalacionId` y una cuenta SUPER habilitada.
>   - Reemplaza justo lo que no se puede comprobar: pone una contraseña temporal generada en la consola con «Debe cambiar», deja el factor vacío y sella de nuevo.
>   - **Nunca crea un SUPER:** una fila cuyo nivel no respaldan el sello ni el padrón también se niega en la vía (b) (7(d)).
>   - La tolerancia a la huella de `PasswordHash` es **solo de la vía (b)**. La vía (a) y las demás operaciones conservan la contraseña y no la admiten.
> - **Un SUPER inhabilitado** en cualquiera de estos casos queda sin salida, porque la vía (b) exige una cuenta habilitada: falla cerrado. Lo mismo pasa con su legitimación, que sigue negada aunque la fila esté inhabilitada.
> - **Ninguna negativa se registra en `BitacoraSeguridad`**, igual que las demás negativas del sello: no cambian nada y no deben llenar la bitácora.
> - **Riesgo previo que se acepta (con SL-F2 (b)):** `sellos --resellar` crea un padrón nuevo a partir de las filas habilitadas. Un SUPER insertado por SQL antes del resellado quedaría respaldado por el padrón nuevo. Lo mitigan el acta de GSF (AG-01 a AG-07), la lista de cuentas que se muestra antes de `--confirmar` y el evento crítico `PADRON_RESELLADO`.
> - **Alternativas descartadas:**
>   - *Solo avisar en pantalla* (TN-01): el operador legitimaría igual sin saber que se borró el factor.
>   - *Que la legitimación ponga por sí misma una contraseña temporal*: esa sustitución ya la hace la vía (b) en la consola del servidor, con la contraseña temporal mostrada una sola vez y el factor vacío.
>   - *Legitimar como antes una fila SUPER sin sello legible* (antes de 7(b)): sellaría el hash que dejó quien escribió en `GPOS_SYSDATA`.
>   - *Legitimar un nivel subido a SUPER* (antes de 7(d)): sería una manera de crear un SUPER por SQL.
>
> **Estado:** construida en `c/adr81-tn-sobre-rn` (`1c541e3b` y `d6a1edba`), sobre la fase A de ADR-81 (#57). Sin PR y sin unir, a la espera de la suite oficial de B o A. Pruebas: `SellosTn01Tests` 14/14 y `SellosTnRevisionTests` 6/6. **Decidido, no implementado en `master`.**
