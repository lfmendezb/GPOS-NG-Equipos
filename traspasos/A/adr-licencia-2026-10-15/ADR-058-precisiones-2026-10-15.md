# ADR-58 · Precisiones del 2026-10-15 para registrar (tercera firma de la hoja de licencia)

**Para quien registra (B), no se copia al ADR.**
- **Dónde va:** al final de `docs/adr/ADR-058.md`, después de la nota del registro del 2026-10-09 (módulo `COMANDERA`). El texto firmado de arriba no se toca.
- **Qué recoge:** DL-01 (punto 9, lo pedido). Además, como salen de la misma firma y precisan el mismo ADR, **DL-18** (punto 8) y **DL-19** (punto 5). Si B prefiere registrar solo el punto 9, los bloques 2 y 3 son independientes.
- **Fuente:** hoja DL-01 a DL-22 **v2.13**, `traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md` del área común (no copiada en `master`), secciones 3 y 7; blueprint de la licencia del lote 2, `traspasos/A/blueprint-licencia-lote2-2026-10-14.md`, registros de cambios v2 y v2.6.
- **Fila del índice (`README.md`, fila 58), texto que se agrega:** «precisiones del 2026-10-15 (DL-01, DL-18 y DL-19, tercera firma de la hoja de licencia): el cupo se cuenta desde el padrón de sellos verificado (punto 9); nunca rige una licencia más vieja que la última atestiguada con MAC (punto 8); una huella ilegible por más de máx(`graciaDias`, 72 h) cuenta como entorno distinto (punto 5)».

---

> **Precisión del 2026-10-15 del punto 9: el cupo se cuenta desde el padrón de sellos (DL-01 (a)+(b) de la hoja de firma DL-01 a DL-22 v2.13, en el área común `traspasos/A/hoja-firma-dl01-dl13-licencia-2026-10-14.md`\*; firmada por Leonardo Méndez, propietario, el 2026-10-15 en la sesión de B, respuesta literal: «Aprobado según la recomendación: Las firmas de licencia DL-01, 02, 03, 05 y las demás de la lista.»; cierra SEG-L2-01 (Alta) y SEG-L2-07 de la revisión del auditor-seguridad del blueprint de la licencia del lote 2).** Sin cambiar el texto firmado de arriba:
> 1. **El consumo del cupo de cada empresa se calcula desde las entradas no SUPER del padrón de sellos verificado**, la fila con MAC `Licencia.PadronSellos` de `dbo.Configuracion`, y nunca desde las columnas `Inhabilitado` y `Nivel` de `dbo.Usuarios`, que se editan por SQL. Cada entrada guarda el nivel de la cuenta.
> 2. El padrón se actualiza **por diferencias** y solo con acciones de la API (alta, rehabilitación, cambio de nivel, inhabilitación y legitimación), en la misma transacción que el sello de la cuenta. Nunca se reconstruye a partir de las filas.
> 3. Una fila borrada o alterada **sigue contando** mientras su entrada esté en el padrón, y esa cuenta no entra. Solo la retira una purga del SUPER, con motivo y segundo factor. **Hasta que esté unida la fase A de [ADR-81](ADR-081.md)**, la purga y la legitimación se hacen en el servidor con los verbos provisionales `GPOS.Migracion sellos --purgar` y `sellos --legitimar`, cada uno con un evento crítico visible al SUPER.
> 4. **Copia completa del padrón en el archivo `Licencia\padron`** de la carpeta de la licencia (`%ProgramData%\GPOS NG\Licencia\`, [ADR-77](ADR-077.md)), separado del archivo `estado`. Se escribe después de confirmar la transacción, de modo que el disco nunca adelanta a la base. Prevalece la versión mayor que verifique; si la de la base es menor, se usa la del disco, se registra `PadronRetrocedido` y se avisa al SUPER.
> 5. «Si el cupo queda por debajo del consumo, la empresa pasa a estar en exceso» (cuarta viñeta del punto 9 y Q-07) no cambia: el consumo es el del padrón.
> 6. **Riesgo residual:** un administrador de Windows con `sysadmin` que llegue al anillo y al disco puede rehacer el padrón y su copia. Se detecta, no se impide (residual de CP-4, que se acepta por escrito con AP-04).
>
> El sello, el padrón y la legitimación están en [ADR-83](ADR-083.md) (puntos 2 y 5). Costo: unos 1,5 dp del desarrollador de identidades (pieza SL). **Decidido, no implementado.**
>
> \* *La hoja vive en el área común; no está copiada en `master`.*

> **Precisión del 2026-10-15 del punto 8: nunca rige una licencia más vieja que la última atestiguada con MAC (DL-18 (a) de la misma hoja y la misma firma; PA-02 de la revisión de seguridad del PR #33; precisa también el orden de recuperación de `[LIC]` 4.1.2).** Sin cambiar el texto firmado de arriba, la viñeta «Al arrancar» del punto 8 se lee así:
> 1. Sea `S` la `sec` máxima atestiguada con MAC: la fila `Licencia.SecMax` o el archivo `secmax` del disco, sin contar las de licencias cuyas llaves están todas retiradas. **Nunca rige una licencia con `sec` menor que `S`.**
> 2. Orden de recuperación:
>    1. la fila de `Licencias` con esa `sec` que verifica, elegida fila a fila (si en una misma `sec` verifican dos contenidos distintos, esa `sec` cuenta como no verificable);
>    2. si no la hay, la copia del disco (`vigente.gposlic` o `Procesados`) cuyo SHA-256 del contenido coincide con el atestiguado, que se vuelve a insertar con origen `RESTAURACION`;
>    3. si tampoco la hay, la instalación pasa a `Ilegible` (72 h, con el tope por empresa) con el evento crítico `FilaLicenciaInvalida`.
> 3. Una fila de `sec` mayor que no está atestiguada con MAC no dispara `Ilegible`: se ignora con su evento. Así, quien solo tiene las credenciales de la API no puede llevar la instalación a `Ilegible` insertando filas basura (denegación de servicio).
> 4. *Descartados:* `Ilegible` ante cualquier fila de `sec` mayor que no verifique (propuesta del auditor; abre esa denegación de servicio) y un `DENY INSERT` con un procedimiento de aceptación (el procedimiento no puede verificar el JWS y las credenciales de la API lo llaman igual).
>
> Cierra la vuelta silenciosa a una licencia anterior, que deshacía un corte, una baja de empresa o una reducción de cupo. Costo: unos 0,1 dp (L1a-4, corrección 7). **Decidido, no implementado.**

> **Precisión del 2026-10-15 del punto 5: una huella ilegible por mucho tiempo cuenta como cambio de entorno (DL-19 (a) de la misma hoja y la misma firma; PA-01 de la revisión de seguridad del PR #33; precisa también `[LIC]` 3.3.1).** Sin cambiar el texto firmado de arriba, la viñeta «Una lectura fallida conserva la última huella y genera una alerta» se completa así:
> 1. La última huella se guarda en las filas con MAC y en el disco. Una lectura fallida nunca borra una marca de entorno.
> 2. Si, con una licencia vigente, **no hubo ninguna lectura correcta de la huella durante más de máx(`graciaDias`, 72 h)**, contado desde la última lectura correcta o desde la primera falla, la instalación se trata como **entorno distinto**: la gracia de entorno de [ADR-59](ADR-059.md) empieza al inicio de las fallas y se avisa al SUPER.
> 3. Un error pasajero sigue sin contar como cambio de entorno. Mientras dura, el SUPER recibe el aviso diario `EntornoLecturaFallida`.
> 4. *Sustituye,* en lo que exceda ese plazo, la regla de `[LIC]` 3.3.1 «un error no cuenta como cambio de entorno», que dejaba operar sin límite a un clon cuyo dueño le negara a la API la lectura de la huella.
>
> **Consecuencia operativa:** una instalación con los permisos de la huella mal puestos entra en gracia de entorno y, si no se corrige, llega a solo consulta. El aviso diario lo hace visible antes, y lo corrige el técnico. Costo: unos 0,1 dp (L1a-4, corrección 9). **Decidido, no implementado.**
