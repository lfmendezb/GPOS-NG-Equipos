# [Informe de Seguridad] Diseño del acta de `sellos --resellar` firmada por GSF y reporte del resellado en L-06/L-07

- **Fecha:** 2026-10-17 · **Auditor:** auditor-seguridad (v3.1.0), equipo C
- **Objeto:** `traspasos/C/blueprint-acta-resellado-gsf-2026-10-17.md` (arquitecto-software, equipo C). Firma de origen: `avisos/A-a-B/2026-10-17-firma-slf01-acta-gsf.md` (precisiones de ADR-83, punto 7).
- **Contexto leído:** `traspasos/A/revision-seguridad-sl-f1-f2-2026-10-17.md` (SLF-01 a SLF-07), `traspasos/A/validacion-sl-f1-f2-2026-10-17.md` (C-2, C-3, R-1, R-3).
- **Código leído (solo lectura, `git show`):**
  - `origin/a/sl-resellar-candado` @ **`130306c0`**. Es posterior al `bc67ec9d` que leyó el blueprint: ya trae SLF-01 (1), `--acta <ref>`, `SelloInicial` con origen `RESELLAR`, la versión en segundos Unix y el método interno (`002e24d9`).
  - `origin/a/rn-cambio-rnc` @ `da474174`: `VerificadorJws.cs`, `ContratosJws.cs` y `AutorizacionRegresoNivel.cs`.
- **Fuera de este equipo:** `GSF.EmisorLicencias`. Todo lo que digo del emisor es sobre el diseño, no sobre su código.
- **Modo:** no compilé, no ejecuté pruebas ni cambié código. [V] = verificado leyendo el código; [I] = inferido. dp = días-persona.
- **Recomendación técnica:** **Aprobado con observaciones**. No hay hallazgos Críticos ni Altos. Antes de que A construya, hay que incorporar AR-01 a AR-04 al blueprint (v1.1). Es una recomendación pendiente de la firma del propietario (C2).

---

## 1. Alcance y superficie revisada

| Superficie | Qué revisé |
|---|---|
| Formato del acta (`gpos-acta-resellado+jws`) | Modelo cerrado, vínculos (instalación, `sec` y SHA-256 de la licencia, `nonce`, huella de las cuentas, 24 h), causa, cupo y exceso (§5.1) |
| Solicitud `.gposresol` y fila `Licencia.ReselladoPendiente` | Contenido, privacidad e integridad en tránsito (§5.2 y §5.3) |
| Verificador JWS | Separación de `typ` entre los propósitos que firma la misma llave: licencia, autorización de nivel y acta (§5.1, §6.1; `VerificadorJws.cs`) |
| Llaves y nivel | Piso de nivel, llaves `latente`, regreso temporal (§5.1; `AutorizacionRegresoNivel.cs`) |
| Verbo `sellos --resellar --acta` | Orden de las comprobaciones, transacción y TOCTOU (§6.2; `SellosService.ResellarAsync`) |
| Uso único y repetición | Las cuatro capas de §6.2 frente a cada actor |
| Emisor (regla 11) | Controles de emisión, revisión de la lista, exceso y frecuencia (§6.4) |
| Reporte en L-06 y L-07 | Integridad de lo que se reporta y comparación en GSF (§5.4 y §6.4) |
| Preguntas AG-01 a AG-06 y estimación | §12 y §14 |

**Actores considerados** (los de `[SEG-SLF]` §1):
- **A1:** `sysadmin` de SQL, sin el anillo ni el disco del servidor.
- **A2:** administrador de Windows con el anillo y acceso SQL. Es el residual R-S2 / CP-4: «no se impide, se detecta».
- **A3:** el propio cliente, que pide el acta a GSF. Es el titular del contacto registrado y quien gana con recuperar cupo (SEG-L2-07).
- **A4:** un tercero en el canal de correo.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| AR-01 | Media | SLF-01, tal como está construida, se elude con una sola escritura SQL: una fila `SelloInicial` que existe y no verifica permite resellar. AG-01 tiene que evaluarse sabiendo esto |
| AR-02 | Media | Con AG-01 (a), la causa `PadronIlegible` firma justo el escenario que SLF-01 quería cerrar, y el acta no recoge el estado que GSF evaluó |
| AR-03 | Media | El acta liga código y nivel, no el contenido sellado: un A1 puede cambiar hashes, perfiles o un SUPER entre la solicitud y el resellado, y la cuenta queda legitimada |
| AR-04 | Media | AG-05 (a) junto con AG-01 (a) convierte el acta en una vía de recuperación de cupo firmada por GSF a pedido del interesado (SEG-L2-07) |
| AR-05 | Baja | TOCTOU dentro de la transacción: falta bloquear la fila pendiente, releer la licencia vigente y garantizar que el conjunto sellado sea el mismo cuya huella se comprobó, en orden ordinal |
| AR-06 | Baja | `SelloInicial`, y la futura `ReselladoPendiente`, quedan fuera de `ReproteccionSecretosSistema`: al revocar las llaves heredadas, SLF-01 se levanta sola y vuelve el 5142 falso |
| AR-07 | Baja | El uso único está sobrestimado frente a A2: `nonce`, `aid` y la hora protegida dependen de filas que A2 puede reescribir. Falta una regla del emisor para un `aid` repetido |
| AR-08 | Baja | El reporte de L-06 no es íntegro (bien reconocido en R-AG4), pero la tabla del emisor lo trata como detección de A2. L-07 `PorResellado` aporta poco frente a su costo |
| AR-09 | Baja | Piso y llaves: la afirmación «durante un regreso temporal existe una llave Avanzada» es falsa con `AusenciaCustodios`. Además, el piso tiene que salir del cálculo efectivo, no de una fila |
| AR-10 | Baja | Confusión de `typ`: está cerrada en el verificador [V]. Faltan vectores de serialización cruzada y la regla de que el emisor fije el encabezado por operación |
| AR-11 | Baja | Privacidad: los códigos de usuario pueden ser datos personales (Ley 172-13). Falta definir la retención en el emisor y la minimización de la solicitud |
| AR-12 | Baja | El flujo legítimo de «instalación nueva» (anillo perdido del todo) no está recorrido de punta a punta en el diseño |

---

## 3. Checklist OWASP (Top 10 2021)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso roto | AR-01, AR-02 y AR-04: la autorización del resellado depende de condiciones locales que A2 controla y de la política de emisión de GSF |
| A02 Fallas criptográficas | ES256, verificador estricto existente, llaves de la función `Licencia`, MAC del anillo en las filas. Sin hallazgos de algoritmo. Observaciones: AR-09 y AR-10 |
| A03 Inyección | No aplica al diseño: no hay SQL dinámico. La referencia `acta` tiene longitud y caracteres de control acotados (§5.1) |
| A04 Diseño inseguro | AR-02, AR-03, AR-04, AR-07 y AR-12 |
| A05 Configuración insegura | Sin interruptores (ADR-60, punto 6), conforme. Debug con `gsf-lic-dev` solo en pruebas (NV-05) |
| A06 Componentes vulnerables | No aplica: no hay paquetes nuevos (CNG, sin bibliotecas JOSE) |
| A07 Identificación y autenticación | AR-03: cuentas resucitadas con hashes alterados; SUPER sin consumo de cupo |
| A08 Integridad de software y datos | AR-05, AR-06 y AR-08 |
| A09 Registro y monitoreo | Eventos `RESELLADO_SOLICITADO`, `ACTA_RESELLADO_RECHAZADA` y `PADRON_RESELLADO` sin secretos, conforme. Observación: AR-08 |
| A10 SSRF | No aplica: no hay llamadas salientes; el canal es el correo |

---

## 4. Hallazgos

### AR-01 · Media · SLF-01 se elude con una sola escritura SQL

- **Riesgo.**
  - `InstalacionNoResellableAsync` niega el resellado en dos casos: si la fila `SelloInicial` existe y **verifica**, o si **falta** y hay alguna licencia aceptada.
  - Si la fila existe y **no verifica**, devuelve `false` (se puede resellar) **sin mirar las licencias**.
  - Por eso basta un `UPDATE` que estropee un byte de `Licencia.SelloInicial` para que SLF-01 deje de aplicar. No hace falta borrar `dbo.Licencias` ni `Procesados`.
  - Ese caso no se puede cerrar sin romper el legítimo: en una instalación nueva, la `SelloInicial` vieja tampoco verifica. Desde el disco no se distingue «la estropearon» de «es de otra instalación o de otra llave».
  - **Consecuencia para AG-01.** Frente a A2, SLF-01 solo frena a quien no sabe reescribir una fila, y la firma de GSF es la única barrera real. Esto ya lo decía `[SEG-SLF]`. Por tanto, AG-01 (a) **no reabre** ninguna protección efectiva de SLF-01. Lo que importa es que, cuando exista esta pieza:
    - el acta sea obligatoria en **todas** las ramas;
    - la política de emisión de GSF (AR-02 y AR-04) haga el trabajo que SLF-01 no puede hacer.
- **Evidencia.**
  - `origin/a/sl-resellar-candado:src/GPOS.Core/Sistema/Usuarios/SellosService.cs`, método `InstalacionNoResellableAsync` (≈ líneas 346-352): `if (fila is not null) return … Leer<FilaSelloInicial>(…) is not null;`.
  - `ConsultasSellos.cs:48`: `LicenciasAceptadas` cuenta todas las filas `Resultado = 'A'`, sin filtrar por instalación.
- **Remediación.**
  1. En el diseño, decir de forma explícita que, con esta pieza, ningún resellado se hace sin acta, tampoco en la rama «existe y no verifica». El blueprint lo implica (§6.2, «No hay interruptor»), pero el paso 7 solo habla de «levantar» condiciones.
  2. Que la solicitud informe el estado observado de `SelloInicial`: `Verifica`, `Ausente` o `NoVerifica`, con y sin licencias aceptadas. Ese estado se liga en el acta (AR-02).
  3. *Opcional, propuesta para el PR de SL-F1/SL-F2, ≈ 0,02 dp:* hasta que exista el acta, tratar «existe y no verifica con licencias aceptadas **de la instalación vigente**» igual que «falta». Precisa el texto firmado de SLF-01, así que necesita la firma del propietario. Con el acta deja de importar.

### AR-02 · Media · `PadronIlegible` con AG-01 (a): GSF firmaría el escenario de SLF-01 sin ver el estado

- **Riesgo.**
  - El catálogo admite dos causas, `AnilloIncompleto` y `PadronIlegible` («los dos padrones dañados con el anillo entero»).
  - `PadronIlegible` con `SelloInicial` que verifica es, **literalmente**, el escenario que describe SLF-01: anillo intacto y padrones destruidos.
  - Con un padrón dañado de forma legítima y el anillo entero, la salida correcta es restaurar el respaldo de `GPOS_SYSDATA`: el padrón del respaldo verifica y después se usa `--legitimar`. No hace falta resellar.
  - Además, el acta no lleva el estado que GSF evaluó. Un acta pedida con un estado (por ejemplo, `AnilloIncompleto` con la llave del padrón ausente del anillo) sirve igual si, antes de usarla, la instalación pasa a otro estado.
- **Evidencia.** Blueprint §5.1 (miembro `causa`), §6.2 paso 7 y §12 AG-01 (a) («las dos condiciones de SLF-01 dejan de aplicarse»), sin distinguir por causa.
- **Remediación (≈ 0,1 dp en total; USD 0).**
  1. **Solo `AnilloIncompleto` levanta SLF-01.** `PadronIlegible` no la levanta, o se retira del catálogo: con el anillo entero, el camino es restaurar el respaldo.
  2. **Diagnóstico en la solicitud**, solo informativo. Para cada padrón (base y disco), el resultado de abrirlo:
     - `Ausente`;
     - `LlaveAusente`: el identificador de llave de la cabecera del blob de Data Protection no está en el anillo;
     - `MacInvalido`: la llave está y el MAC falla;
     - `Verifica`.
     A eso se suman el estado de `SelloInicial` (AR-01) y la fecha de la llave más nueva del anillo.
     Como control, A2 lo puede fabricar, por la misma razón que dio `[SEG-SLF]` para descartarlo. Pero le da a GSF un criterio: `AnilloIncompleto` exige `LlaveAusente` en los dos padrones. `MacInvalido` con el anillo entero es un indicio de manipulación y GSF no emite sin el propietario.
  3. **Estado ligado en el acta:** un miembro `estado` (`SelloInicial` y diagnóstico de los dos padrones). La instalación lo vuelve a calcular y lo compara en el paso 6 de 6.1 (`ACTA_NO_COINCIDE`).

### AR-03 · Media · El acta no liga el contenido sellado

- **Riesgo.**
  - La huella cubre `CODIGO\tNIVEL`. El resellado sella **la fila completa tal como esté** (hash de contraseña, perfiles, sucursal, secreto del segundo factor cuando exista).
  - Mientras no hay padrón, la API no detecta cambios en las filas. Un A1 (sin el anillo) que actúe entre la solicitud y el resellado puede cambiar el hash de una cuenta ADMIN o SUPER, o sus perfiles, sin tocar código ni nivel. La huella coincide, el técnico resella y la cuenta queda legitimada con una credencial que el atacante conoce.
  - Las cuentas SUPER **no consumen cupo** (`noSuper`). Un SUPER insertado por SQL antes de la solicitud solo se vería en la lista si GSF lo revisa. El diseño muestra la lista, pero no exige confirmar cada SUPER nuevo.
  - Es el actor que el modelo sí quiere frenar: A1 no debe poder legitimar cuentas.
- **Evidencia.**
  - Blueprint §5.3: la huella es solo código y nivel.
  - `SellosService.ResellarAsync` sella cada usuario habilitado leído dentro de la transacción, sin comparar su contenido con nada.
- **Remediación (≈ 0,1 dp; USD 0).**
  1. **`HuellaContenido` en `ReselladoPendiente`** (fila con MAC, que A1 no puede falsificar): SHA-256 canónico de los campos que cubre el sello de cada cuenta habilitada, calculado al generar la solicitud. Se recalcula dentro de la transacción del resellado; si no coincide, `ACTA_NO_COINCIDE`. No viaja a GSF, así que no cambia AG-04.
  2. **Emisor:** cada cuenta SUPER de la lista que no figure en el último L-07 o L-06 registrado exige una confirmación propia con el contacto registrado. Si no hay registro previo, todas las SUPER la exigen.
  3. **Procedimiento** (documentador, junto con SLF-06): después del resellado, restablecer la contraseña de todas las cuentas SUPER y ADMIN, y la inscripción TOTP cuando exista ADR-81. Así se cubren los cambios hechos **antes** de la solicitud, que la huella de contenido no ve.

### AR-04 · Media · El exceso de cupo, con AG-01 (a), recupera cupo con la firma de GSF

- **Riesgo.**
  - El incentivo de SEG-L2-07 lo tiene A3, el propio cliente, que es también el «contacto registrado» con quien GSF confirma la lista. La confirmación con el contacto no protege contra A3.
  - La secuencia de abuso:
    1. reducción de cupo;
    2. A2/A3 destruye los padrones;
    3. pide un acta `AnilloIncompleto`;
    4. con AG-05 (a), GSF la emite con `enExceso` y un motivo;
    5. todas las cuentas de antes de la reducción vuelven con sesión.
  - `EnExceso` solo impide las **altas**. El diagnóstico de AR-02 lo puede fabricar A2.
- **Evidencia.** Blueprint §6.2 («Exceso de cupo»), §6.4 control 5 y §12 AG-05 (a). `SellosService.EstadoResellado.EnExceso` (`ConsumoNoSuper > Cupo`).
- **Remediación (≈ 0,05 dp en el emisor).**
  - **AG-05 (b) por omisión:** el acta nunca autoriza un exceso que GSF no haya visto antes. Las cuentas sobrantes se excluyen (`--excluir`) y se legitiman después, dentro del cupo.
  - **Única excepción:** el último L-06 registrado ya reportaba un `PadronConsumoNoSuper` mayor o igual que el `noSuper` del acta. Así el cliente que ya estaba en exceso de forma legítima (con cuentas selladas antes de una reducción, como permite SL-F2 (b)) no pierde servicio por el incidente. GSF lo decide con un dato que ya tiene, no con la palabra del cliente.
  - La huella del acta y la de `ReselladoPendiente` se calculan sobre la lista **después** de las exclusiones (precisarlo en §5.3; hoy dice «solo cuentas habilitadas»).

### AR-05 · Baja · TOCTOU dentro de la transacción

- **Riesgo.** El paso 9 de §6.2 dice «repite los pasos 5 a 7 con el padrón tomado y relee `ReselladoPendiente` y `SelloInicial`». Quedan cuatro huecos:
  - (i) la serializable con `UPDLOCK, HOLDLOCK` sobre la fila del padrón no bloquea las filas `Licencia.ReselladoPendiente` ni `Licencia.SelloInicial`. Un `--solicitud` concurrente puede reemplazar la fila pendiente entre la relectura y el borrado. Hoy `SelloInicial` se lee con `LeerFilaAsync` sin pista de bloqueo [V];
  - (ii) la licencia vigente se lee en el paso 4, fuera de la transacción. El arranque de la API puede aceptar una licencia de `vigente.gposlic` o de `Procesados` [V, `EstadoLicenciaService.cs:290-298`] mientras el padrón no está disponible [I];
  - (iii) el conjunto que se sella tiene que ser exactamente el conjunto cuya huella se comprobó;
  - (iv) `OrderBy(u => u.Codigo)` en EF ordena en SQL con la intercalación CI de `GPOS_SYSDATA`, no en orden ordinal. Si la huella se calcula sobre esa secuencia sin reordenar, diverge del emisor, que ordena en ordinal. Eso falla cerrado (R-AG8), pero corta el servicio.
- **Evidencia.** `SellosService.ResellarAsync`: transacción, `TomarAsync`, `db.Usuarios…OrderBy(u => u.Codigo)` y `InstalacionNoResellableAsync`, que usa `LeerFilaAsync`.
- **Remediación (≈ 0,05 dp).**
  - Leer `ReselladoPendiente` y `SelloInicial` con `UPDLOCK, HOLDLOCK` después de tomar el padrón. `--solicitud` también toma el padrón antes de escribir la fila pendiente, así que los dos se serializan sobre el mismo recurso.
  - Releer dentro de la transacción la `sec` y el SHA-256 de la licencia vigente y compararlos con el acta.
  - Calcular la huella y la `HuellaContenido` (AR-03) **desde la misma lista** de usuarios que se va a sellar, leída una sola vez en la transacción y ordenada en memoria con `StringComparer.Ordinal`.
  - Prueba: una `--solicitud` concurrente con `--confirmar` deja exactamente uno de los dos efectos.

### AR-06 · Baja · Filas del resellado fuera de la reprotección del anillo

- **Riesgo.**
  - `ReproteccionSecretosSistema.FilasConfiguracion` reprotege `InstalacionId`, `SecMax`, `PisoNivelFirma` y otras filas. **No** incluye `Licencia.SelloInicial` [V], y el diseño no agrega `ReselladoPendiente`.
  - Después de una reprotección y de revocar las llaves heredadas (H-17 v2, punto 9), `SelloInicial` deja de verificar. Por AR-01, SLF-01 se levanta sola y la API vuelve a registrar el 5142 en cada arranque (SLF-03).
  - La premisa de AG-01 (anillo anterior: «verifica `InstalacionId` y `SelloInicial`, no el padrón») depende de **cuándo** se ejecutó la reprotección:
    - si se ejecutó después de la llave más nueva, `InstalacionId` tampoco verifica con un anillo anterior, y el caso se convierte en el de «instalación nueva» (AR-12);
    - el proveedor principal rota las llaves con los valores por omisión: solo el de solo lectura llama a `DisableAutomaticKeyGeneration` [V `AnilloDataProtection.cs:277`].
- **Evidencia.** `ReproteccionSecretos.cs`, líneas 30-40 (lista) y comentario «El padrón de sellos (SL) se agrega cuando se una».
- **Remediación (≈ 0,03 dp).**
  - Agregar `Licencia.SelloInicial`, `Licencia.ReselladoPendiente` y el padrón a la lista, con una prueba: «después de reprotegerla y revocar la heredada, `SelloInicial` verifica».
  - *Alternativa más barata para el caso del anillo anterior* (devops y documentador, ≈ 0,05 dp): avisar para respaldar el anillo cada vez que se crea una llave nueva, o integrarlo en el respaldo de Backup Tool (MD-54). Reduce la probabilidad del caso que motiva AG-01 (a). No sustituye el acta.

### AR-07 · Baja · El uso único está sobrestimado frente a A2

- **Riesgo.** Las cuatro capas de §6.2 resisten a A1, a A4 y a la repetición accidental, pero **no** a A2:
  - A2 puede reescribir `ReselladoPendiente` con el `nonce` de un acta ya usada, porque tiene el anillo y calcula el MAC;
  - puede borrar `SelloInicial` para quitar `AidYaConsumido`, que con AG-01 (a) ya no bloquea;
  - y quizá retroceder el reloj protegido hasta la ventana de 24 h, si su piso no sale de algo firmado [I, H-16 v2.1].
  
  Para eso le basta con no cambiar de licencia. El blueprint presenta estas capas como «de la más fuerte a la más débil frente al actor R-S2», y frente a ese actor ninguna es fuerte. Es el mismo residual que R-AG1 y conviene decirlo así, para que nadie lo tome por un control.
- **Evidencia.** Blueprint §6.2 («Uso único») y §4 (fila con MAC).
- **Remediación (≈ 0,05 dp, emisor).**
  - Reescribir el párrafo: «las capas 1 a 4 impiden la repetición por A1, por A4 y por error; frente a A2, la repetición se detecta en GSF, no se impide».
  - Regla del emisor: un `UltimoResellado.Aid` ya marcado como consumido que llega con otro `ReselladoUtc` u otro `PadronVersionInicial` → `RESELLADO_REPETIDO`, con detención y AP-03.
  - En el acta: `sec` mayor que la `secLicencia` y no mayor que la hora protegida + 48 h (el techo de INV-6), como en `AutorizacionRegresoNivel`.

### AR-08 · Baja · L-06 no es íntegro; L-07 `PorResellado` aporta poco

- **Riesgo.**
  - R-AG4 lo reconoce bien: la instalación no firma nada. Pero la tabla de comparación de §6.4 se lee como detección de A2. Un A2 omite `UltimoResellado` (o reescribe `SelloInicial` con origen `MIGRACION`) y reporta una `PadronVersion` creíble. Solo lo detectan las actas emitidas que nunca se reportan, y esas se cierran como «no usada» y **sin alerta**.
  - La regla «se detiene» ante un `aid` desconocido sí sirve contra A3 sin conocimientos técnicos y contra los errores, que es lo que vale la pena cubrir.
  - L-07 `PorResellado`:
    - su derivación por `HabilitadoUtc` es [I];
    - no viaja a GSF salvo en una visita;
    - es informativo para un SUPER que, en el escenario de abuso, es parte interesada.
- **Evidencia.** Blueprint §5.4 y §6.4 (tabla); §13.1 R-AG4.
- **Remediación.**
  1. Con las versiones en segundos Unix (R-1, ya construida [V `ResellarAsync`, `cambio.Crear(…ToUnixTimeSeconds())`]): una `PadronVersion` ≥ 10⁹ cuya marca de tiempo sea posterior al último reporte, sin un `aid` emitido → `RESELLADO_NO_AUTORIZADO`. Un A2 que programa lo evita, pero cuesta 0 y atrapa el uso del verbo con un acta borrada a mano.
  2. Que el acta «emitida, vencida y sin reportar» genere un **aviso** al soporte en la siguiente renovación, no un cierre silencioso: o el cliente no la usó (se confirma) o la usó y no la reporta.
  3. Aplazar L-07 `PorResellado` (−0,05 dp) hasta que L confirme la derivación. No es un control.
  4. Mantener el registro de eventos de Windows (SLF-01, punto 3). Borrarlo deja el evento 1102, que A2 no evita sin más privilegios [I].

### AR-09 · Baja · Piso de nivel y llaves en el regreso temporal

- **Riesgo.**
  - §5.1 afirma que, durante un regreso temporal, «existe al menos una llave Avanzada (la que firmó la autorización)». Con la causa `AusenciaCustodios`, la autorización se firmó al empezar la ventana, y los custodios pueden faltar hasta 30 días, con un acumulado de 60 [V `AutorizacionRegresoNivel.VentanaMaxima`, `TopeAcumulado`].
  - En esa ventana, una instalación con piso Avanzado **no puede recibir un acta**. Falla cerrada, que es lo correcto para la seguridad, pero es una pérdida de servicio que el diseño no declara.
  - `ContextoActa.PisoNivelFirma` es un `string`. Si se llena desde la fila `Licencia.PisoNivelFirma`, en el caso del anillo anterior esa fila puede no verificar.
- **Evidencia.**
  - `AutorizacionRegresoNivel.cs`: causas, ventana y la exigencia de `EsAvanzadaPropia`.
  - `EstadoLicenciaService.cs:756-761`: el piso efectivo se eleva desde las licencias (`PisoNivelFirma.EleveDesdeLicencia`) y combina la fila con el disco.
- **Remediación (≈ 0,02 dp).**
  - Tomar el piso de `PisoNivelFirma.Efectivo`. Como también sale de las licencias firmadas, A2 no lo baja sin borrarlas. Si no se puede calcular, se trata como Avanzado (falla cerrada).
  - Declarar en R-AG6 el caso `AusenciaCustodios` con piso Avanzado y su salida (procedimiento de GSF). No admitir llaves `latente` para el acta, como dice el diseño.

### AR-10 · Baja · Confusión de `typ` entre propósitos

- **Verificado.**
  - `VerificarCompacto` exige que el `typ` del encabezado protegido sea igual, en comparación ordinal, al esperado. El esperado se fija por llamada y tiene que estar en `FuncionPorTypCompacto` [V `VerificadorJws.cs`, líneas 41-44, 115-136 y 262].
  - `Verificar` (serialización general) solo admite `gpos-licencia+jws` (líneas 32-35).
  - El `typ` va dentro de la entrada firmada, así que pasar un acta de compacta a JSON general, o una firma de licencia a compacta, no cambia el `typ` y se rechaza.
  - Meter un acta en `autNivel` falla porque el esperado allí es `gpos-autorizacion-nivel+jws`. El miembro `tipo` y los modelos cerrados agregan defensa en profundidad.
  - La decisión de un `typ` por propósito (§6.3) es la correcta (RFC 8725, 3.11).
- **Riesgo residual.** El riesgo real está en el **emisor**: si el encabezado protegido se arma con algún dato de la entrada, o si el resumen que confirma el custodio no muestra el `typ`, un mismo PIN podría firmar un propósito por otro.
- **Remediación (≈ 0,03 dp, dentro de 0,1 de QA).**
  - El emisor construye el encabezado desde una constante por operación, nunca desde la solicitud. La confirmación desde los bytes (regla 6) muestra el `typ` decodificado.
  - Agregar a los vectores:
    - V-03b: acta en serialización general presentada a `Verificar` como licencia;
    - V-03c: acta dentro de `autNivel`;
    - V-03d: autorización de nivel presentada como acta;
    - V-03e: `typ` con otra capitalización.
    Los cuatro deben ser rechazados.

### AR-11 · Baja · Privacidad de lo que viaja a GSF

- **Riesgo.**
  - Los códigos de usuario suelen ser nombres o iniciales («LMENDEZ») y entonces son datos personales para la Ley 172-13 de la República Dominicana.
  - La solicitud viaja por correo, sin cifrar.
  - El diseño no fija qué conserva el emisor de la lista. El registro encadenado guarda totales y huella, que es lo correcto, pero no se dice qué pasa con el archivo `.gposresol`.
  - `huellaEntorno` va en la solicitud y no se usa en el acta.
- **Evidencia.** Blueprint §5.2 y §6.4, control 10.
- **Remediación (≈ 0,02 dp, procedimiento).**
  - El emisor no conserva la lista ni el archivo después de emitir (solo la huella y los totales del registro).
  - Quitar `huellaEntorno` de la solicitud si el emisor no la compara (minimización).
  - El procedimiento de AP-03 indica el mismo canal y la misma retención que la solicitud de licencia.
  - AG-04 (a) es aceptable con estas condiciones.

### AR-12 · Baja · El flujo legítimo de «instalación nueva» no está recorrido

- **Riesgo.**
  - `[SEG-SLF]` identificó como caso legítimo principal la pérdida total del anillo. Entonces hay que generar una instalación nueva, y la licencia anterior queda inválida.
  - Pero la solicitud exige «licencia vigente legible». Para tenerla, GSF tiene que emitir primero una licencia para la instalación nueva, y nadie entra a la API (`PADRON_NO_DISPONIBLE`).
  - El arranque acepta `vigente.gposlic` desde el disco [V `EstadoLicenciaService.cs:290-298`], así que el camino parece posible [I], pero el diseño no lo describe ni lo prueba.
  - En ese caso, la regla 2 del emisor (`sec` y SHA-256 iguales a los de la última licencia emitida) se cumple con la licencia nueva. Bien, siempre que GSF la emita antes del acta.
- **Remediación (≈ 0,03 dp).**
  - Describir en §6.2 el orden: licencia nueva para la nueva `InstalacionId` → copia en la carpeta → arranque → `--solicitud` → acta.
  - Agregar una prueba dirigida de punta a punta con la licencia aceptada desde el disco.

---

## 5. Controles bien diseñados

- Firma de GSF como único control que A2 no fabrica, con la **misma llave** de licencias. Coste USD 0. El descarte de una llave propia está bien razonado (R-B11).
- Doble vínculo: instalación, licencia vigente (`sec` y SHA-256 del contenido, que no depende de la maleabilidad de ECDSA, V-02) y `nonce` guardado con MAC. Frente a A1 y A4 cierra la repetición y el traslado a otra instalación.
- La huella la recalcula el **emisor** desde la lista, sin copiarla de la solicitud. La instalación la compara con su fila con MAC: alterar la solicitud en el correo (A4) falla cerrado.
- `typ` por propósito, modelo cerrado, catálogo cerrado de causas, tope de 8 KB antes del verificador, hora protegida (lección EV-03) y `ACTA_NO_APLICA` sin decir qué vínculo falló (C10).
- SL-F2 **manda siempre**: un acta nunca sustituye un padrón que verifica.
- Verificación pura e `internal`, con `InternalsVisibleTo` restringido (SLF-07). La API no verifica actas.
- Listas del modelo cerrado solo en `GPOS.Contracts`, con vectores compartidos (EV-01).
- Reporte por L-06 sin telemetría (Q-08). El blueprint dice con honestidad (R-AG4) que no es a prueba de manipulación.
- Registro encadenado del emisor, anclado fuera (E-12), con el `nonce` solo en hash.

---

## 6. Postura recomendada sobre AG-01 a AG-06

| Pregunta | Postura | Condiciones y motivo |
|---|---|---|
| **AG-01** | **(a) condicionada, «(a′)»** | Frente al riesgo que cerró SLF-01: SLF-01 solo frena a quien no reescribe una fila (AR-01), así que la barrera real frente a A2/A3 es el acta y la política de emisión. AG-01 (a) no debilita nada efectivo **siempre que**:<br>1. solo `AnilloIncompleto` levante SLF-01; `PadronIlegible` no la levanta o sale del catálogo (AR-02);<br>2. el estado observado (`SelloInicial` y diagnóstico de los padrones) viaje en la solicitud y quede ligado en el acta (AR-02);<br>3. el acta no autorice un exceso que GSF no haya visto antes (AR-04);<br>4. con esta pieza, ningún resellado se haga sin acta, en ninguna rama (AR-01).<br>**(b)** deja sin salida el caso del anillo anterior (R-S1) a cambio de una protección que A2 ya salta con un `UPDATE`: no compensa |
| **AG-02** | **(a)** | La lista y el `nonce` son los que frenan a A1 entre la emisión y el uso. La (b) deja sellar cuentas insertadas por SQL en esa ventana. Sumar `HuellaContenido` (AR-03), que no viaja a GSF |
| **AG-03** | **(a) 24 h** | La ventana de repetición es pequeña y la reemisión no cuesta nada. Con AR-09, declarar la excepción de servicio con piso Avanzado |
| **AG-04** | **(a)** con minimización | Código y nivel, sin nombres; el emisor no retiene la lista; sin `huellaEntorno` si no se usa (AR-11). La (b) obliga a firmar a ciegas, y eso es justo lo que hay que evitar contra A3 |
| **AG-05** | **(b) por omisión**, con la excepción de AR-04 | Exceso solo si el último L-06 ya lo reportaba. Así el acta no recupera cupo (SEG-L2-07) y el cliente que ya estaba en exceso de forma legítima no pierde servicio |
| **AG-06** | **(a)** | Contar las actas **emitidas**, no solo las usadas. Una segunda acta en 365 días, o una con diagnóstico `MacInvalido`, exige al propietario |

---

## 7. Estimación: 1,45 dp frente a 0,85

- **Los 0,85 dp de `[SEG-SLF]` eran un orden de magnitud:** 0,5 de desarrollo, 0,25 de la herramienta de GSF y 0,1 de detección. No incluían la solicitud con `nonce` y lista, la revisión de la lista en el emisor, los vectores compartidos ni L-07. El desglose del blueprint es razonable y **1,45 dp (±35 %) es creíble**.
- **Ajustes de esta revisión:**
  - suman ≈ +0,2 dp:
    - `HuellaContenido`: 0,05;
    - estado y diagnóstico ligados: 0,05;
    - bloqueos y relectura en la transacción: 0,03;
    - reprotección de las filas: 0,03;
    - reglas del emisor (SUPER, exceso con histórico, `aid` repetido, versión Unix): 0,05;
    - vectores de `typ` cruzado: dentro de QA;
  - restan ≈ −0,05 dp: aplazar L-07 `PorResellado`.
  - **Total recomendado: ≈ 1,6 dp (±30 %)**, más 0,25 dp de revisión de seguridad del código, aparte. Coste en dinero: USD 0.
- **Opción reducida (AG-02 (b), ≈ 0,9 dp):** no la recomiendo. El ahorro de unos 0,55 dp deja abierto el único actor que el modelo exige frenar (A1 legitimando cuentas) y quita el uso único frente a errores.
- Si hay presión de plazo, el recorte aceptable es **diferir** al menos 0,1 dp sin pérdida de seguridad: el registro de eventos de Windows (0,05 más el instalador) y L-07 `PorResellado`. El registro de eventos sí aporta detección frente a A2, así que conviene que entre antes de la primera licencia de pago si cabe.

---

## 8. Remediaciones priorizadas

| Prioridad | Acción | Hallazgo | Responsable | Esfuerzo | Momento |
|---|---|---|---|---|---|
| 1 | Blueprint v1.1: solo `AnilloIncompleto` levanta SLF-01; estado y diagnóstico en la solicitud y ligados en el acta; acta obligatoria en toda rama | AR-01, AR-02 | arquitecto-software (C) | 0,1 dp de diseño | Antes de la firma de AG-01 |
| 2 | `HuellaContenido` en `ReselladoPendiente`; confirmación de cada SUPER nuevo en el emisor; restablecer contraseñas tras el resellado | AR-03 | Núcleo del sello; I (emisor); documentador | 0,1 dp | Con la construcción |
| 3 | AG-05 (b) por omisión con la excepción del histórico de L-06; huella después de las exclusiones | AR-04 | I (emisor); L | 0,05 dp | Con la construcción |
| 4 | Bloqueos de la fila pendiente y de `SelloInicial`; relectura de la licencia; huella desde la lista sellada, en orden ordinal | AR-05 | Núcleo del sello | 0,05 dp | Con la construcción |
| 5 | `SelloInicial`, `ReselladoPendiente` y el padrón en `ReproteccionSecretosSistema` | AR-06 | Núcleo del sello / L | 0,03 dp | Puede ir ya en el PR de SL-F1/SL-F2 |
| 6 | Reglas del emisor: `aid` repetido, versión Unix sin acta, aviso de acta sin reportar; texto honesto del uso único | AR-07, AR-08 | I (emisor); arquitecto-software | 0,05 dp | Con la construcción |
| 7 | Piso efectivo; excepción `AusenciaCustodios` declarada | AR-09 | L; documentador | 0,02 dp | Con la construcción |
| 8 | Encabezado constante en el emisor; vectores V-03b a V-03e | AR-10 | I; qa-automatizado | 0,03 dp | Con los vectores |
| 9 | Retención y minimización de la solicitud | AR-11 | documentador; I | 0,02 dp | Procedimiento AP-03 |
| 10 | Flujo de «instalación nueva» descrito y probado | AR-12 | arquitecto-software; qa-automatizado | 0,03 dp | Con la construcción |

---

## 9. Recomendación

**Aprobado con observaciones** (recomendación técnica; pendiente de la firma del propietario).
- El diseño es sólido en lo criptográfico y en el vínculo con la instalación. El `typ` por propósito está bien cerrado [V] y la honestidad sobre R-AG1 y R-AG4 es correcta.
- Los cuatro hallazgos Medios no son defectos de implementación. Son de **política de autorización**: qué estado y qué cupo firma GSF. Hay que resolverlos en el blueprint v1.1 antes de que A construya. No hace falta una nueva revisión completa del diseño: basta con verificar esos cuatro puntos en la revisión del código.
- Sobre AG-01: un acta válida **puede** levantar SLF-01 sin reabrir el riesgo que SLF-01 pretendía cerrar, porque ese riesgo frente a A2 ya no lo cerraba la regla local (AR-01) y pasa a cerrarlo la política de emisión, con las cuatro condiciones de la sección 6.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\revision-seguridad-acta-resellado-2026-10-17.md`
- Supuestos:
  - no compilé ni ejecuté pruebas;
  - el código leído es `a/sl-resellar-candado` @ `130306c0` (posterior al del blueprint) y `a/rn-cambio-rnc` @ `da474174`;
  - `GSF.EmisorLicencias` no está en este equipo: lo que digo del emisor es sobre el diseño;
  - son [I]:
    - que A2 pueda retroceder el reloj protegido (H-16 v2.1);
    - que el arranque acepte una licencia mientras el padrón no está disponible;
    - la viabilidad del flujo de «instalación nueva»;
    - el evento 1102 al borrar el registro de Windows;
    - la rotación de llaves por omisión del proveedor principal (solo vi `DisableAutomaticKeyGeneration` en el de solo lectura).
- Decisiones candidatas a ADR (precisión de ADR-83, punto 7, junto con las de §13.2 del blueprint):
  - (i) solo la causa `AnilloIncompleto` levanta SLF-01, y el acta liga el estado observado (descartada: levantarla para toda causa);
  - (ii) el acta no autoriza un exceso de cupo que GSF no haya visto en un L-06 anterior (descartada: AG-05 (a) con motivo);
  - (iii) `HuellaContenido` local en `ReselladoPendiente` (descartada: enviar hashes a GSF).
- Entregas a otros agentes:
  - arquitecto-software (C) → blueprint v1.1 con AR-01 a AR-05, AR-07, AR-09 y AR-12;
  - Arquitecto Maestro → hoja de firma de AG-01 a AG-06 con la postura de la sección 6 y la precisión opcional de AR-01 (3);
  - desarrollador I (núcleo del sello) → AR-05 y AR-06;
  - desarrollador L → AR-09 y la derivación de L-07;
  - emisor (I) → AR-03 (2), AR-04, AR-07, AR-08 y AR-10;
  - qa-automatizado → vectores V-03b a V-03e, prueba de `--solicitud` concurrente con `--confirmar` y prueba de punta a punta de «instalación nueva»;
  - documentador-tecnico → AR-03 (3), AR-09 y AR-11 en los procedimientos;
  - devops → respaldo del anillo al crear una llave (AR-06, alternativa).
- Próximo paso recomendado: C produce el blueprint v1.1 con AR-01 a AR-04 y el Maestro lleva AG-01 a AG-06 a firma con la postura (a′) de AG-01 y la (b) por omisión de AG-05.
