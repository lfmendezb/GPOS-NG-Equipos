Para: B        De: C        Fecha: 2026-10-23
Tipo: Revisión adversarial posterior a la unión (encargo B-a-C/2026-10-23-tareas-nuevas-para-c-5, tarea 5 (b), opcional)
Prioridad: Media
Repositorio y rama: GPOS-NG #120 (T2-0, llave de firma de los tokens), unido a `feature/modelo-ng` en `63378fe6`. Revisado en `feature/modelo-ng` @ `b9efa9fb`, solo lectura
Estado: Abierto

Convención: [V] = lo comprobé con un comando y su resultado en mi equipo; [I] = inferido del código, de la documentación o de un resultado indirecto.

Árbol y reglas que seguí:
- Trabajé en el worktree de C, en `b9efa9fb`. No cambié código del repositorio, no comenté el PR y no hice commit ni push.
- Las pruebas nuevas son tres archivos temporales sin seguimiento en `tests/GPOS.Tests/Acceso/`:
  - `LlaveFirmaRevisionCTests.cs`, con RC-1 a RC-9;
  - `LlaveFirmaRevisionCSondaTests.cs`, la sonda S0;
  - `LlaveFirmaRevisionCSonda2Tests.cs`, la sonda S1.
- La copia de RC-1 a RC-9 está en `traspasos/C/2026-10-23-revision-adversarial-pr120-posterior-pruebas.cs.txt`.
- Compilé una sola vez a la vez.

**Equipo de la revisión:** OSHIN, Windows 11 Home 10.0.26300, usuario `OSHIN\lfmen` en una consola **no elevada**. **Tiene TPM:** el Platform Crypto Provider se abre [V]. Por eso, aquí las pruebas de TPM **sí corrieron** en el almacén del usuario. Las del almacén de la máquina se omitieron con su motivo, porque exigen administrador.

**Lo que no hice:** no ejecuté mutaciones sobre `src/`. El entorno me negó la edición temporal y el encargo prohíbe cambiar código. Donde hablo de mutantes, es razonamiento sobre la línea [I].

# Veredicto

**Rechazado** para conectar la llave a la API en D2 tal como está (recomendación técnica; la decisión es del propietario, C2).

El motivo es H120P-01 (Alta, verificada en parte):
- En un equipo con TPM y **sin administrador**, el almacén de la máquina del Platform Crypto Provider responde «Acceso denegado» (NTE_PERM) a toda consulta [V].
- La API correrá como `NT SERVICE\GPOS.Api`, sin administrador.
- Si esa cuenta recibe la misma respuesta, `ProveedorLlavesFirma` no arranca en ningún equipo con TPM, que es la vía principal de ES256.

La falla es cerrada (el 4740 sale bien), así que no es una fuga. El riesgo es otro: la salida previsible en campo sería correr la API como LocalSystem o como administrador. Se confirma o se descarta con un ensayo de una hora en la VM. Si se descarta, el veredicto pasa a **Aprobado con observaciones**.

Lo demás:
- **Medias:**
  - una prueba unida falla 9 de 9 en esta PC (H120P-02);
  - la API acepta una llave de software en un equipo con TPM, sin rastro en la bitácora (H120P-03);
  - un TPM sin P-256 deja el verbo sin salida (H120P-04).
- **Bajas e informativas:** H120P-05 a H120P-09.

Lo que **se sostiene** (sección 5):
- un usuario sin administrador no puede plantar llaves en la máquina;
- `Crear` traduce la falta de privilegios;
- la condición 7 vale para la llave anterior;
- con la API como LocalSystem, la llave falla cerrada;
- las omisiones con su motivo funcionan;
- en el almacén del usuario, el TPM expone `Security Descr` y `ExportPolicy`.

# 1. Alcance y superficie revisada

- `src/GPOS.Comun/Firma/LlaveFirmaTokens.Windows.cs` (365 líneas), `ProveedorLlavesFirma.cs` (216) e `ILlaveFirmaTokens.cs` (127).
- `src/GPOS.Migracion/Llaves/ComandoLlaveFirma.cs` (222) y su cableado en `src/GPOS.Migracion/Program.cs:82-97` y `:141-145`.
- Pruebas unidas:
  - `tests/GPOS.Tests/Acceso/LlaveFirmaTokensTests.cs`;
  - `ComandoLlaveFirmaTests.cs`;
  - `LlavesFirmaPruebas.cs`;
  - `RequisitosDeEntornoLlaves.cs`, que llegó con el commit `0946fa62`, el de las omisiones «con su motivo».
- Pendientes del encargo:
  - **R-D1-09** (plan de D1, `docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md:490` en `master`): «el TPM del equipo de desarrollo no está disponible; la prueba con TPM real va en el ensayo de D6»;
  - **S120-02**: se relee el dueño y la DACL al crear y al abrir; es la condición 7.
- Lo que el PR dejó «sin verificar (ensayo de D6)», según los comentarios del 2026-10-21 en el #120:
  - la ACL de uso con la cuenta del servicio;
  - el borrado de la llave tras una falla con CNG real en la máquina;
  - la política de exportación del TPM;
  - `PF46` y `Rg14Lote2Tests`.
- Mis revisiones anteriores (`2026-10-20-revision-pruebas-pr120.md` y `…-pr120-seguridad.md`) y BP3 8.2 (`docs/arquitectura/2026-10-18-db7-blueprint-v3.md:637-690` en `master`).
- **Superficie:**
  - el verbo `aprovisionar --llave-firma` corre como administrador;
  - `verificar` corre como administrador;
  - `ProveedorLlavesFirma.Abrir` correrá como la cuenta virtual de la API. Hoy no está conectado: `Seguridad.cs:22` sigue con HS256.
  - El atacante local que interesa es un usuario sin privilegios del equipo central. En el cliente pequeño ese equipo es a menudo la PC de caja.

# 2. Corridas [V]

| Corrida | Filtro | Resultado |
|---|---|---|
| Primera, con RC-1 a RC-8 | `~Acceso.LlaveFirma\|~Acceso.ComandoLlaveFirma` | 48 pruebas: 32 superadas, **14 con error**, 2 omitidas |
| Final, con RC-1 a RC-9 y las dos sondas | `~Acceso.LlaveFirma\|~Acceso.ComandoLlaveFirma\|~CosturasDb7Tests` | **53 pruebas: 38 superadas, 13 con error, 2 omitidas**, 3 s |
| Lo que B dejó sin correr | `~BitacoraSeguridadTests\|~EventIdUnicosTests\|~Rg14Lote2Tests` (SQL local) | **24/24 superadas**, 1 min 8 s |

Desglose de la corrida final:
- **Los 13 errores:**
  - **9 son de B:** las 9 filas de `La_identidad_que_no_es_exclusiva_del_servicio_se_rechaza` (H120P-02);
  - **4 son mías:** RC4, RC6, RC8 y RC9; cada una demuestra un hallazgo.
- **Las 2 omitidas** son las de `En_la_maquina_*`, con el motivo «Exige una consola de administrador (S120-02: almacén de la máquina): es el ensayo de D6» (correcto).
- **`Con_TPM_la_llave_queda_en_el_TPM_y_no_es_exportable` corrió y pasó** con TPM real en el almacén del usuario.
- **La tercera corrida cubre lo que B había declarado sin verificar:**
  - `PF46_el_catalogo_incluye…` y `PF46_la_consulta_devuelve…` pasan con `FIRMA_SIN_TPM_ACEPTADA` en el catálogo;
  - también pasan `Rg14Lote2Tests`.

**Sondas [V]:** usuario no elevado y TPM presente.

S0 da estos resultados en `CngKey.Exists("…NoExiste…")`:

| Proveedor | Almacén | Resultado |
|---|---|---|
| PCP | usuario | `False` |
| PCP | máquina | **`CryptographicException 0x80090010 Acceso denegado`** |
| Software KSP | usuario | `False` |
| Software KSP | máquina | `False` |

Otros datos de S0:
- `new AlmacenLlavesFirmaWindows(maquina: true).Nombres()` da **`CryptographicException 0x80090010`**. Viene de `NCryptEnumKeys` en `LlaveFirmaTokens.Windows.cs:303`, con el PCP, que se enumera primero.
- Las ACL de las carpetas son anchas:
  - `C:\ProgramData\Microsoft\Crypto\PCPKSP`: `Everyone` y `Usuarios` tienen ReadAndExecute; Administradores y SYSTEM, FullControl;
  - `…\Crypto\Keys`: `Everyone` tiene Read.
- Dentro de `PCPKSP` solo hay `WindowsAIK` y `WindowsEK`, que no se pueden leer: **todavía no existe ninguna llave del PCP de la máquina**.

S1 crea una llave del PCP en el almacén del usuario:
- `Security Descr` se lee: 208 bytes, dueño el usuario, 5 reglas heredadas (`D:AI`), dos de ellas de SID de AppContainer `S-1-15-3-…`.
- `ExportPolicy` vale `None`.
- **20 firmas ES256 con el TPM: mediana 31,1 ms, p95 35,4 ms, máximo 47,8 ms.**

# 3. Hallazgos

| ID | Severidad | Título |
|---|---|---|
| H120P-01 | **Alta** (verificada en parte) | Con TPM y sin administrador, el almacén de la máquina del PCP no se puede consultar: la API, que corre sin administrador, podría no arrancar nunca con la llave del TPM |
| H120P-02 | Media (pruebas) | `La_identidad_que_no_es_exclusiva_del_servicio_se_rechaza` falla 9/9 en un equipo con TPM y sin elevación; no se omite «con su motivo» |
| H120P-03 | Media | La API arranca con una llave activa de software en un equipo con TPM, sin evento de aceptación: degradación silenciosa de SD0-09 |
| H120P-04 | Media | Un TPM que no admite ECDSA P-256 (por ejemplo, TPM 1.2) deja el verbo sin salida: rechaza `--sin-tpm` porque «hay TPM» y la creación en el TPM falla |
| H120P-05 | Baja | Fallos sin el 4740: excepciones que no son `CryptographicException` y `Existe` en el camino de error (resto de P120-06) |
| H120P-06 | Baja | Una regla solo de herencia para el servicio cuenta como «el uso» |
| H120P-07 | Baja | Sin verbo para retirar una llave: la rotación de emergencia deja la llave comprometida en el almacén |
| H120P-08 | Informativa | `verificar` corre como administrador y evalúa contra `NT SERVICE\GPOS.Api` fijo: puede decir «bien» cuando la API no arranca (H120P-01) y «mal» con un `--cuenta` distinto |
| H120P-09 | Informativa (D6) | Lo que sigue sin ensayo: `Security Descr` y la herencia en el PCP **de la máquina**, la relectura y el borrado de `Crear` con CNG real, y P120S-01 |

## H120P-01 (Alta, verificada en parte): el PCP de la máquina rechaza a quien no es administrador

**Riesgo.** Esto es lo verificado [V]:
- En este equipo, con TPM y sin elevación, el PCP responde NTE_PERM (`0x80090010`) a `CngKey.Exists` con `MachineKey` y a `NCryptEnumKeys` con `NCRYPT_MACHINE_KEY_FLAG`.
- El Software KSP de la máquina sí responde.
- No es la ACL de la carpeta: `PCPKSP` da lectura a `Everyone`. El rechazo lo da el proveedor.

Cuando hay TPM, `AlmacenLlavesFirmaWindows` consulta primero el PCP:
- en `Nombres()` (`LlaveFirmaTokens.Windows.cs:70-72`, `:64-68` y `:303`);
- en `Existe` (`:74`);
- en `Abrir` (`:177`).

`ProveedorLlavesFirma.Abrir` empieza por `almacen.Nombres()` (`ProveedorLlavesFirma.cs:122-128`). La API correrá como `NT SERVICE\GPOS.Api`, una cuenta virtual sin administrador.

**Consecuencia** [I]: si la cuenta virtual recibe lo mismo que mi usuario no elevado, la API registra el 4740 «No se pudo leer el almacén de llaves de firma» y **no arranca en ningún equipo con TPM**.
- Es la vía principal de ES256 (P-D0-01).
- La falla es cerrada, así que no hay fuga.
- La reparación previsible en campo es correr el servicio como LocalSystem o en Administradores. Eso contradice ADR-44 y S15-02, y con LocalSystem la llave hecha para la cuenta virtual tampoco pasa (RC-7).
- La otra salida, `--sin-tpm`, está prohibida con TPM (`ComandoLlaveFirma.cs:101-104`).

**Lo que no está verificado y puede cambiar el resultado:**
1. **Si el rechazo depende de que todavía no haya llaves de máquina en el PCP.** Aquí `PCPKSP` solo tiene `WindowsAIK` y `WindowsEK`.
   - B informó que, en su equipo con TPM y sin elevación, la prueba de `:295` pasaba («84 correctas», comentario del 2026-10-21). Allí `Exists` en el PCP de la máquina devolvió `False` y no lanzó.
   - Eso apunta a que el comportamiento depende del equipo. Una explicación posible es que la carpeta de llaves de máquina ya existiera allí [I].
   - Después de que el administrador cree la primera llave con la ACL de la API, la cuenta virtual podría consultarla.
2. **Cómo trata el PCP a una cuenta virtual de servicio frente a un usuario no elevado.**

**Evidencia.**
- RC9 (`Con_TPM_y_sin_administrador_el_almacen_de_la_maquina_se_lista`) falla: `CryptographicException 0x80090010` [V].
- La sonda S0 [V].
- H120P-02, que es el mismo efecto en una prueba de B [V].

**Remediación.**
1. **Ensayo de una hora en VM-SRV**, antes de conectar D2. Puede ir como caso LAB de la tarea 3 del `GPOS.Api.msi`.
   - En una VM con vTPM: `aprovisionar --llave-firma` como administrador.
   - Después, un servicio de prueba como `NT SERVICE\GPOS.Api` que ejecute `ProveedorLlavesFirma.Abrir` y registre el resultado. Basta un ejecutable mínimo o la API de T1-b con un interruptor.
   - Repetir antes y después de que exista la primera llave de máquina en el PCP.
2. **Si se confirma**, decisión de B con el arquitecto. Opciones:
   - **(a)** Que la API no enumere el PCP: abrir por nombre las llaves que diga la configuración (`Jwt:Firma:Llave` más una lista de nombres anteriores). Esto solo sirve si `NCryptOpenKey` con la ACL de la llave funciona sin enumerar. Alrededor de 0,1 sp.
   - **(b)** Que `Nombres()` tolere NTE_PERM por proveedor y siga con el otro. Así la llave activa del TPM daría «Falta la llave activa» en vez de «almacén ilegible». No resuelve el fondo.
   - **(c)** Que la llave viva en el almacén **del usuario** de la cuenta virtual. La crearía la propia API en su primer arranque y el verbo solo registraría el `kid`. Cambia BP3 8.2 («almacén de la máquina»): **candidata a ADR**, precisión de ADR-41.
   - Descarto correr la API con privilegios, por ADR-44.

## H120P-02 (Media, pruebas): una prueba unida falla 9/9 sin elevación y con TPM

- **Riesgo.** `LlaveFirmaTokensTests.La_identidad_que_no_es_exclusiva_del_servicio_se_rechaza` (`LlaveFirmaTokensTests.cs:278-297`) usa `new AlmacenLlavesFirmaWindows(maquina: true, …)` y afirma `Assert.False(almacen.Existe(nombre))` en `:295`.
  - Con TPM y sin elevación, `Existe` consulta el PCP de la máquina y lanza NTE_PERM.
  - Las 9 filas fallan [V].
  - La prueba no lleva `FactRequiereAdmin` ni otra omisión. El commit `0946fa62` («se omiten con su motivo en lugar de salir en verde») no la cubrió.
  - En el equipo típico de desarrollo (con TPM y sin elevación), la suite queda en rojo y enseña a ignorar ese rojo.
- **Evidencia.** La corrida final: las 9 filas «Con error», todas con `CngKey.Exists` y `LlaveFirmaTokens.Windows.cs:74` en la pila.
- **Remediación (unos 15 min).** Comprobar la no creación solo en el Software KSP, que es donde `Crear` lo habría intentado: `CngKey.Exists(nombre, MicrosoftSoftwareKeyStorageProvider, MachineKey | Silent)`, como hace RC3. Alternativa: un atributo «requiere poder leer el almacén de la máquina», que la omite con su motivo. La descarto porque esconde lo que la prueba sí puede comprobar.

## H120P-03 (Media): llave activa de software con TPM presente, sin aceptación

- **Riesgo.** El verbo rechaza `--sin-tpm` cuando hay TPM (`ComandoLlaveFirma.cs:101-104`) y escribe `FIRMA_SIN_TPM_ACEPTADA` antes de crear (`:118-124`). Pero `ProveedorLlavesFirma.Abrir`:
  - acepta una llave activa del Software KSP sin mirar `almacen.HayTpm`;
  - no exige que exista la aceptación;
  - solo registra el aviso 4735 (`ProveedorLlavesFirma.cs:171-177`).

  Un administrador o un script que cree a mano la llave de software, con el descriptor correcto (por ejemplo, con PowerShell y `CngKey.Create`), en un equipo **con** TPM, deja la firma fuera del TPM sin que conste en `BitacoraSeguridad`.
  - La llave de software de la máquina queda protegida con DPAPI de la máquina. La puede extraer cualquier proceso con privilegios de SYSTEM, o quien tenga una copia de las colmenas del sistema más `ProgramData` [I].
  - Que el actor sea administrador limita la probabilidad. Lo que se pierde es el control firmado: la aceptación escrita (SD0-09, P-D1-04).
- **Evidencia.** RC4 (`Con_TPM_una_llave_activa_de_software_impide_arrancar`, con el almacén en memoria y `HayTpm = true`) falla: no lanza, y solo hay `Warning 4735` [V].
- **Remediación (unos 30 min más RC4).**
  - Condición 8 en `ProveedorLlavesFirma.Abrir`: si `SinTpm && almacen.HayTpm`, `Fallar` con 4740 («este equipo tiene TPM: la llave activa debe estar en el TPM»).
  - En D2, el evento `FIRMA_SIN_TPM_ARRANQUE`, que ya está pendiente, debería citar la aceptación por nombre o por `kid`. Depende de S120-07, que decide dónde se registra el `kid`.
  - **Ojo con H120P-04:** «`HayTpm`» tiene que significar «el TPM admite P-256». Si no, la condición 8 bloquea a los equipos con TPM 1.2.

## H120P-04 (Media): un TPM sin P-256 deja el verbo sin salida

- **Riesgo.** `HayTpm` solo comprueba que el PCP se abre (`LlaveFirmaTokens.Windows.cs:52-57`).
  - En un equipo con TPM 1.2, el PCP se abre pero no admite ECDSA. Así lo entiendo de la documentación del PCP; no lo verifiqué [I].
  - Con TPM, el verbo exige el TPM y rechaza `--sin-tpm` (`ComandoLlaveFirma.cs:101-105`).
  - `Crear` con `CngAlgorithm.ECDsaP256` en el PCP falla, y el verbo devuelve «No se pudo crear la llave…».
  - No queda ninguna vía: ni TPM ni `--sin-tpm`.
  - R-DB7-04 («no hay TPM o no admite P-256 → Software KSP con las condiciones de C49-1 v2», BP3 13) previó este caso. El código no lo cubre.
  - El riesgo aparece en servidores viejos de clientes pequeños. Hoy no tengo un inventario de cuántos tienen TPM 1.2.
- **Evidencia.** Lectura de las líneas citadas [V]. Comportamiento del TPM 1.2 [I].
- **Remediación (cerca de 1 h).**
  - Que `HayTpm` sea «el PCP admite `ECDSA_P256`», con `NCryptIsAlgSupported` sobre el proveedor abierto. Si no lo admite, se trata como «sin TPM utilizable» y queda `--sin-tpm`.
  - Prueba en memoria con un almacén cuyo `HayTpm` sea falso por esa causa.

## H120P-05 (Baja): fallos sin el 4740

- Una excepción que no es `CryptographicException` al abrir una llave retirada sale de `ProveedorLlavesFirma.Abrir` sin el 4740 (`:132-143`): RC6 falla, con `UnauthorizedAccessException` y sin entradas [V]. La API igual no arranca, porque la falla es cerrada; lo que queda mudo es la alerta por EventId.
- Además, `almacen.Existe(opciones.LlaveActiva)` en `:153` está dentro del `try` que solo libera y relanza. Si `Existe` lanza, y H120P-01 muestra que lanza NTE_PERM en el PCP de la máquina [V], el error sale sin el 4740.
- **Remediación (unos 20 min):**
  - en `:136`, capturar `Exception` de las llaves no activas (aviso 4740 y seguir) o envolver todo en un `catch` final que llame a `Fallar`;
  - proteger `:153`.

## H120P-06 (Baja): una regla solo de herencia cuenta como «el uso»

- `ProblemaSeguridad` (`LlaveFirmaTokens.Windows.cs:120-136`) no mira `AceFlags`.
- Una regla `InheritOnly`, que no da acceso al objeto, para el servicio marca `servicioConUso = true`. RC8 falla: devuelve `null` [V].
- No abre un hueco, porque la firma de prueba (condición 6) fallaría. Pero el diagnóstico sería «no puede usar la llave» en vez de «la ACL no le da el uso».
- **Remediación (unos 10 min):** ignorar las reglas con `InheritOnly` al buscar el uso, o rechazarlas.

## H120P-07 (Baja): no hay retiro de llaves

- `IAlmacenLlavesFirma.Eliminar` existe, pero solo lo usa el verbo con una llave exportable (`ComandoLlaveFirma.cs:145`).
- La rotación de emergencia de BP3 8.2 («queda solo el `kid` nuevo y se reinicia») deja la llave comprometida en el almacén. Volver a aceptarla solo exige editar `Jwt:KidsValidos`, cosa que también puede quien ya tiene el equipo.
- `verificar` no marca las llaves que están fuera de la lista.
- **Remediación (unas 2 h):**
  - `aprovisionar --retirar-llave <nombre>` con motivo y evento en la bitácora;
  - o, como mínimo, el paso en el procedimiento de devops;
  - y que `verificar` marque «fuera de `Jwt:KidsValidos`».

## H120P-08 (Informativa): `verificar` no refleja lo que verá la API

- `Program.cs:144` evalúa con `identidadServicio: CuentaApi`, que es `NT SERVICE\GPOS.Api` fijo. Si la llave se creó con `--cuenta` distinto, informa «SEGURIDAD NO ESPERADA».
- Como `verificar` corre elevado, lista el PCP de la máquina aunque la API no pueda (H120P-01).
- Conviene que el texto lo diga («visto como administrador») hasta que exista un chequeo con la identidad del servicio.

## H120P-09 (Informativa): lo que sigue sin ensayo de D6

| Punto | Estado tras esta revisión |
|---|---|
| R-D1-09: prueba con TPM real | **Cerrado en el almacén del usuario en esta PC** [V]: crear en el PCP, no exportable, `kid`, firma; `Con_TPM_…` pasó. **Abierto en el almacén de la máquina**: exige administrador; las pruebas se omiten con su motivo |
| `Security Descr` en el PCP (P120S-05: «si no se expone, la API no arrancaría») | **El PCP sí la expone en el almacén del usuario** [V, S1]. En la máquina, sin verificar [I] |
| `ExportPolicy` en el PCP | Se lee y vale `None` [V, S1]. La rama `catch … when Tpm → false` (`:282-285`) no se ejercitó aquí |
| S120-02, relectura en `Crear` (`:237`) con el PCP de la máquina | Sin verificar. **Riesgo nuevo** [I]: en el almacén del usuario, el PCP aplicó reglas **heredadas** (`D:AI`, con SID de AppContainer `S-1-15-3-9` y otro `S-1-15-3-…`). `LlaveSitio.Descriptor` pide la DACL protegida (`LlaveSitio.cs:193`). Si el PCP de la máquina no respeta esa protección y agrega herencia, `ProblemaSeguridad` la rechaza («su ACL da acceso a S-1-15-3-…») y `Crear` borra la llave **en todo equipo con TPM**. Tiene que ir en el mismo ensayo que H120P-01 |
| S120-04: borrado tras una falla con CNG real | `Crear` sin administrador traduce bien: `UnauthorizedAccessException 0x80070005` con la interna NTE_PERM `0x80090010`, y no deja llave en el Software KSP (RC3 pasa) [V]. El borrado tras una relectura fallida, sin verificar (exige administrador) |
| P120S-01: `:187` sin administrador | Sigue abierto. Intenté la vía «llave plantada por un usuario» (RC2), pero el sistema operativo lo impide (RC1, sección 5). No hay forma sin una costura o sin administrador |
| R-DB7-05: latencia del TPM | En esta PC [V]: mediana 31 ms y p95 35 ms en 20 firmas. Si el TPM serializa, son unas 30 firmas por segundo: 100 inicios de sesión simultáneos al abrir la tienda se resuelven en unos 3 s [I por la serialización]. Por debajo del umbral de 100 ms de BP3 |
| `PF46` y `Rg14Lote2Tests` (con base) | **Cerrados** [V]: 24/24 con SQL local |

# 4. Mutantes (razonados, no ejecutados) [I]

| Mutación | Suite de B | Mis pruebas |
|---|---|---|
| Condición 7 solo con la activa (`ProveedorLlavesFirma.cs:162`) | No la detecta: `Seguridad_inesperada_…` marca solo la activa | RC5 la mata (P120S-02) |
| Quitar la comprobación de duplicado entre proveedores (`LlaveFirmaTokens.Windows.cs:180`) | No la detecta: hace falta TPM y administrador | Ninguna; ensayo de D6 |
| Pasar `null` como `problemaSeguridad` en `:187` | No la detecta sin administrador (P120S-01) | Ninguna (RC2 no puede plantar) |
| Quitar el dueño de `:116` | La detecta: `El_descriptor_de_la_llave_de_maquina_se_comprueba` | — |
| Quitar la condición de `SinTpm` y `HayTpm` (si se agrega H120P-03) | — | RC4 |

# 5. Controles bien hechos [V salvo indicación]

- **No se pueden plantar llaves.** Un usuario sin administrador **no puede crear** una llave en el almacén de la máquina del Software KSP: `CngKey.Create` con `MachineKey` da NTE_PERM `0x80090010` (RC1 pasa). Por eso el ataque «llave con el nombre de la activa en el otro proveedor», que dejaría la API sin arrancar por `:180`, no es posible para un usuario sin privilegios en este Windows. En el PCP de la máquina no lo probé directamente, porque hasta `Exists` se rechaza.
- **Falta de privilegios.** `Crear` la distingue con el `HResult` real (`:229-233`) y no deja la llave (RC3).
- **La condición 7 vale para toda llave conservada.** Una anterior insegura de la lista impide arrancar, y una insegura fuera de la lista no estorba (RC5 pasa).
- **Falla cerrada por identidad.** Con la API como LocalSystem, la llave creada para `NT SERVICE\GPOS.Api` no pasa la comprobación (RC7). Lo mismo con una identidad que no se resuelve (`ServicioEsperado` → null → «no se sabe qué identidad», `:143`).
- **Omisiones con su motivo (`0946fa62`).** Funcionan: aparecen 2 omitidas con el texto «es el ensayo de D6». La prueba de TPM corre cuando hay TPM. Excepción: H120P-02.
- **El verbo.** Nunca cae solo al Software KSP. La aceptación va antes de crear. El motivo no admite caracteres de control. `--desarrollo` exige Debug y Development. Las pruebas de `ComandoLlaveFirmaTests` pasan todas [V].
- **Catálogo y orden de los EventId.** `FIRMA_SIN_TPM_ACEPTADA` está en el catálogo y se consulta (PF46, con base) [V]. `EventIdUnicosTests` pasa [V].

# 6. Remediaciones priorizadas

1. **H120P-01, junto con la herencia de H120P-09:** ensayo en VM-SRV con vTPM, la cuenta virtual y la primera llave de máquina, **antes de conectar `ProveedorLlavesFirma` en D2**. Una hora de laboratorio. Si se confirma, decidir entre (a) y (c); (c) es candidata a ADR.
2. **H120P-02:** arreglar `:295` para que la suite esté en verde en el equipo típico. Unos 15 min.
3. **H120P-04 y H120P-03, juntos:** `HayTpm` como «admite P-256», más la condición 8 y RC4. Entre 1,5 y 2 h.
4. **H120P-05:** el 4740 en todo fallo. Unos 20 min.
5. **H120P-07:** retiro de llaves, o el paso de devops. Unas 2 h.
6. **H120P-06 y H120P-08:** menos de 30 min entre las dos.

# 7. Qué no verifiqué

- Nada en el almacén de la máquina con administrador: la consola no está elevada. Tampoco nada como `NT SERVICE\GPOS.Api`.
- El PCP de la máquina después de que exista una llave de máquina (H120P-01, punto 1).
- El TPM 1.2 (H120P-04): [I].
- Mutaciones ejecutadas: no se ejecutó ninguna (sección 4).
- La suite completa de `GPOS.Tests`.

### Cierre
- Estado: Rechazado (recomendación técnica, para conectar la llave en D2 tal como está; pasa a Aprobado con observaciones si el ensayo de H120P-01 lo descarta).
- Artefactos:
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-revision-adversarial-pr120-posterior.md` (este informe);
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-revision-adversarial-pr120-posterior-pruebas.cs.txt` (RC-1 a RC-9);
  - archivos sin seguimiento en el worktree de C: `tests/GPOS.Tests/Acceso/LlaveFirmaRevisionCTests.cs`, `LlaveFirmaRevisionCSondaTests.cs` y `LlaveFirmaRevisionCSonda2Tests.cs`;
  - registros de las corridas en el scratchpad: `corrida1.log`, `corrida-final.log`, `sonda*.log` y `bitacora.log`.
- Supuestos:
  - que la cuenta virtual reciba del PCP lo mismo que un usuario no elevado;
  - que el comportamiento del PCP dependa de que exista la carpeta de llaves de máquina;
  - que el TPM 1.2 no admita ECDSA en el PCP;
  - la serialización de las firmas del TPM.
- Decisiones candidatas a ADR:
  - si H120P-01 se confirma, la opción (c): la llave en el almacén del usuario de la cuenta virtual. Precisa ADR-41 y BP3 8.2 («almacén de la máquina»). La alternativa (a), abrir por nombre sin enumerar, no cambia la decisión.
- Entregas a otros agentes:
  - B (desarrollador) → H120P-02 a H120P-07 y la decisión sobre H120P-01;
  - B (laboratorio VM-SRV) → el ensayo de H120P-01 y de la herencia del PCP de la máquina. C puede redactarlo como caso LAB en la tarea 3;
  - auditor-seguridad → opinar sobre H120P-03 (condición 8) y sobre la opción (c);
  - devops → el paso de retiro de llaves (H120P-07).
- Próximo paso recomendado: B corre el ensayo de H120P-01 en la VM con vTPM antes de conectar `ProveedorLlavesFirma` en D2, y arregla `:295` (H120P-02) ya.
