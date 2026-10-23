# Revisión adversarial del diseño: blueprint del anillo del servicio y del verbo `tls` (PR #219)

- **Fecha:** 2026-10-23 · **Equipo:** C (auditor de seguridad) · **Encargo:** punto 5 del backlog de B (`avisos/B-a-C/2026-10-23-backlog-autonomo-para-c-tanda-7.md`).
- **Fuentes leídas con `git show`, sin cambiar el checkout:**
  - blueprint `docs/arquitectura/2026-10-23-blueprint-tls-y-anillo-del-servicio.md` en `origin/b/blueprint-tls-anillo` (`b5328331`);
  - hoja firmada `docs/decisiones/2026-10-23-hoja-firma-tls-y-anillo-del-servicio.md` en `origin/b/hoja-firma-tls-anillo` (PR #221);
  - código de `origin/feature/modelo-ng` (`ComprobacionAnillo.cs`, `ProteccionDatosInstalacion.cs`, `MantenimientoAnillo.cs`, `OrigenCertificadosAnillo.cs`, `RecuperarAnillo.cs`, `ClienteApiLocal.cs`);
  - `instalador/Api/Package.wxs` e `instalador/Comun/Fragmentos/RaizGposNg.wxs` en `origin/b/t1b-api-msi` (`57ba6585`).
- **Para no repetir:** mis planes `traspasos/C/2026-10-23-plan-pruebas-anillo-dm07.md` (QA-AN-01 a 08, D-AN-01 a 15) y `traspasos/C/2026-10-23-plan-pruebas-verbo-tls.md` (QT-01 a 08, D-01 a D-19). Aquí solo van huecos nuevos o que cambian de severidad; cuando un hallazgo amplía uno anterior, lo cito.
- **Marcas:** **[V]** verificado en el texto o en el código citado; **[I]** inferido o conocimiento general de Windows y .NET, que se confirma en el laboratorio.
- **Sin compilar ni ejecutar nada.** Sin commit ni push. No incluyo pasos de explotación (C10).

## 1. Alcance y superficie revisada

| Superficie | Quién la toca | Revisada |
|---|---|---|
| `anillo --preparar` (elevado) y su entrada `--recuperacion <.cer>` | Técnico; en el futuro, el *bundle* | Sí |
| `config\GPOS.Api.anillo.json` y `config\GPOS.Api.recuperacion.cer` | Escribe `--preparar`; leen la API (servicio) y `GPOS.Migracion` (elevado) | Sí |
| Llave CNG y certificado del anillo en `LocalMachine\My` | Administradores; uso de `NT SERVICE\GPOS.Api` | Sí |
| Guardas G-1 y G-2 en `GPOS.Migracion` | Técnico | Sí |
| Recuperación (3.4), rotación (3.5) y par de recuperación (P-2, P-3) | Propietario y técnico | Sí |
| `tls` (CA, hojas, registro, tarea de SYSTEM, mutex, avisos) | Técnico, tarea programada | Sí, en lo que no cubre QT-01 a 08 |
| Orden de PR-D2: `carpetas` → `servicios` → `anillo` → `esquema` → `lectura` | A (PR-D2) | Sí |
| *Bundle* (Burn), VPN, Linux | B (T1-b), tanda LN | Sí, en lo que toca a este diseño |
| Endpoints HTTP | — | No aplica: el diseño no agrega ni cambia endpoints [V, blueprint §1] |

## 2. Tabla resumen

| ID | Severidad | Título | Amplía |
|---|---|---|---|
| SA-01 | **Alta** | El `.cer` de recuperación se acepta y se ancla sin comprobación fuera de banda (confianza en el primer uso) | — |
| SA-02 | **Alta** | Un `.cer` de recuperación vencido bloquea el procedimiento de recuperación, y la herramienta de P-2 lo emite por omisión con 1 año | D-AN-10 (a) |
| SA-03 | Media | Si `GPOS.Api.anillo.json` desaparece, las protecciones del archivo se apagan y el camino de reparación pide una ceremonia de recuperación innecesaria | QA-AN-02, D-AN-03 (c) |
| SA-04 | Media | La privada de recuperación toca el equipo del propietario y el servidor, y nada obliga a rotarla después de usarla; custodio único | D-AN-08b |
| SA-05 | Media | Rotación del certificado del anillo (F4): el orden «reenvolver → publicar» deja una ventana en la que las llaves no abren | — |
| SA-06 | Media | Vencimiento del certificado del anillo: el aviso de 180 días no llega a nadie, y el reloj puede invalidarlo antes | — |
| SA-07 | Media | La restauración de un sitio pierde la CA TLS (no exportable), y el orden de PR-D2 no incluye `red` ni `tls` | — |
| SA-08 | Media | Cualquier cuenta puede ocupar el mutex `Global\GPOS.Migracion.tls`: la renovación y los avisos callan | QT-01 (otro eje) |
| SA-09 | Media | Con VPN o IP cambiante, las Name Constraints en /32 obligan a reemplazar la CA en cada cambio de IP | P-7 (firmada), D-03 |
| SA-10 | Baja | `GPOS.Migracion` elevado consume variables de entorno del usuario (HKCU), escribibles sin elevación | — |
| SA-11 | Baja | El mensaje del conflicto de fuentes (regla 4, 4729) puede volcar valores de configuración | — |
| SA-12 | Baja | Con el archivo presente, la carpeta no conforme sigue sin impedir el arranque en el modo Amplio del servicio | — |
| SA-13 | Baja | Tarea de SYSTEM: binario ausente tras desinstalar, directorio de trabajo y nadie que corra `comprobar-servidor` | QT-01 |
| SA-14 | Baja | En la restauración, el registro dice «la fila del ancla no verifica» (suena a manipulación); matiz de QA-AN-01 | QA-AN-01 |
| SA-15 | Baja | Linux: el cargador del archivo no define su regla de permisos; entrega 2: la fila del ancla no debe replicarse entre sitios | H-L1 |

Ningún hallazgo Crítico.

## 3. Checklist OWASP (aplicado al diseño)

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Bien en lo esencial: descriptor de la llave en la creación, `GENERIC_READ` para la cuenta, `config\` sin escritor de servicio [V, `RaizGposNg.wxs:22-23, 60`]. Observaciones: SA-10 y SA-12 |
| A02 Fallas criptográficas | Algoritmos correctos (RSA 3072, OAEP-SHA256 en el transporte, firma PKCS#1 v1.5 solo en la autofirma). Fallan el ciclo de vida y la distribución de llaves: SA-01, SA-02, SA-04, SA-05 y SA-06 |
| A03 Inyección | No aplica: sin SQL nuevo ni plantillas. La configuración es JSON estricto con esquema cerrado |
| A04 Diseño inseguro | SA-01, SA-03, SA-07 y SA-08 |
| A05 Configuración insegura | SA-10 y SA-12; la regla 4 («una sola fuente») es un buen control |
| A06 Componentes vulnerables | No aplica: no hay tecnología nueva (solo la BCL de .NET 10 y herramientas de Windows) |
| A07 Identificación y autenticación | No aplica: no toca el inicio de sesión ni los tokens |
| A08 Integridad de software y datos | SA-01 (integridad de la llave pública de recuperación); SA-13 (binario de la tarea) |
| A09 Registro y monitoreo | SA-06, SA-08 y SA-11; el repudio Medio por el 4716 que va a la consola ya lo asume B (STRIDE R) |
| A10 SSRF | No aplica: `tls` no sale a la red (TLS-C17) y el cliente de la Web conecta por *loopback* sin DNS [V, `ClienteApiLocal.cs:15-18`] |

## 4. Hallazgos

### SA-01 · Alta · El `.cer` de recuperación se acepta y se ancla sin comprobación fuera de banda

- **Riesgo.** La llave pública de recuperación viaja del propietario al técnico por un canal que el diseño no especifica (correo, mensajería o USB). `--preparar` valida el formato, el tamaño y la vigencia, «muestra su SHA-256, que va al acta» y la copia; `anillo --anclar` ancla la que esté configurada y solo informa la huella. Nadie compara esa huella con un valor que el propietario haya dado por otro canal. Si alguien sustituye el `.cer` en tránsito, o en la carpeta de donde lo lee el técnico, cada llave del anillo queda envuelta también para una llave pública ajena. **Quien tenga entonces una copia de `Api\anillo` y de `GPOS_SYSDATA` (los respaldos que H-17 v2 manda guardar con otra custodia) descifra sin el servidor todas las cadenas de conexión y las filas protegidas.** Además, el ancla con MAC fija la llave equivocada como la legítima: lo que debía detectar el cambio lo consagra. Probabilidad baja (hace falta el canal y el respaldo) e impacto crítico (confidencialidad de toda la instalación, en silencio y por años).
- **Evidencia.**
  - Blueprint §3.1, paso 2 («Muestra su SHA-256, que va al acta») y paso 10 («Copia el `.cer`»): no hay un valor esperado.
  - `src/GPOS.Migracion/Anillo/MantenimientoAnillo.cs:97-107` [V]: `AnclarAsync` toma `HuellaRecuperacionConfigurada()` y solo informa «Anótela en el acta».
  - Contraste: ADR-63, punto 6, ya exige un segundo canal para el SHA-256 del manifiesto («El SHA-256 del manifiesto viaja por un segundo canal») [V, `docs/adr/ADR-063.md:15` en `a/pr-d2-manifiesto`]. El anillo no aplica el mismo criterio.
  - TOCTOU [I]: el paso 2 lee el archivo y el paso 10 lo vuelve a copiar. Si `--recuperacion` apunta a una carpeta escribible por otros, lo validado y lo publicado pueden no ser lo mismo.
- **Remediación** (≈0,1 a 0,15 dp dentro de F1):
  1. `--preparar` exige `--huella-recuperacion <sha256>` (el mismo nombre que ya usa `--recuperar`), que el propietario dicta por un canal distinto del que trajo el `.cer` (teléfono o acta firmada). Si no coincide, sale con 4 sin tocar nada.
  2. `--anclar` exige la misma huella esperada y la compara con la configurada antes de fijar el ancla.
  3. El `.cer` se lee **una sola vez** a memoria y se escriben esos mismos bytes; la huella del paso 10 se compara con la del paso 2.
  4. Defensa en profundidad: el acta lleva las dos huellas (la dictada y la calculada) y GSF las coteja con su registro.
- **Al propietario:** cambia lo que hace el técnico (un parámetro obligatorio más). Lo recomiendo como precisión de F1, **antes de construir el 26-oct**. Alternativa descartada: incluir el `.cer` dentro del *bundle* firmado. No sirve con P-3 (un par por sitio) y no cubre la instalación manual.

### SA-02 · Alta · Un `.cer` de recuperación vencido bloquea la recuperación, y P-2 lo emite por omisión con 1 año

- **Riesgo.** El paso 2 de §3.1 rechaza la recuperación «vencida». El procedimiento ante la pérdida del servidor (§3.4, paso 2) exige `--preparar --recuperacion <el mismo .cer>`, porque el ancla solo admite esa huella. P-2 (firmada) usa `New-SelfSignedCertificate`, que sin `-NotAfter` emite el certificado **por 1 año** [I; es el valor documentado del cmdlet]. Así, **desde el segundo año, la recuperación documentada falla en el paso 2, justo el día del desastre**. Con otro `.cer` no se puede seguir: el ancla lo rechaza (`AnilloRecuperacionCambiada`) y `--cambiar-recuperacion` necesita un anillo que funcione. La única salida sería editar a mano el archivo, que el diseño prohíbe, o cambiar el código bajo presión.
- **Evidencia.**
  - Blueprint §3.1, paso 2 («está vencido» → rechazo) y §3.4, paso 2 [V].
  - Hoja P-2 [V].
  - El resto del sistema **no** exige la vigencia de la recuperación: `ComprobacionAnillo.cs:155-163` solo comprueba que esté presente [V]. Un `git grep` de `NotAfter` en `src/GPOS.Criptografia` no da resultados [V]. La regla del paso 2 es la única que la exige, y en el sentido equivocado.
  - D-AN-10 (a) preguntaba por la vigencia **mínima**; esto es lo contrario y cambia la severidad.
- **Remediación** (≈0,05 dp más el procedimiento):
  1. En `--preparar`, una recuperación vencida es un **aviso**, no un rechazo. Para cifrar hacia un destinatario, la vigencia no aporta seguridad; la protección real es la huella anclada (SA-01).
  2. El procedimiento de P-2 fija explícitamente `-NotAfter` (recomiendo 30 años), `-KeyLength 3072` (el valor por omisión es 2048 [I], que el paso 2 rechazaría) y `-CryptoAlgorithmOption AES256_SHA256` en `Export-PfxCertificate` (el [I] que ya marca B).
  3. Una prueba F: `Preparar_con_la_recuperacion_anclada_vencida_continua_con_aviso`.

### SA-03 · Media · Qué pasa si `GPOS.Api.anillo.json` desaparece

- **Riesgo.** La regla 1 del cargador dice: «si el archivo no existe, todo sigue como hoy». Todas las protecciones nuevas (DACL comprobada, una sola fuente, rechazo de `DpapiDemo`) dependen de que el archivo **exista**: su ausencia apaga las protecciones en lugar de impedir el arranque. Escenarios:
  1. **Con el servicio en marcha:** nada hasta el próximo reinicio (sin recarga).
  2. **Al reiniciar (Release):** la API no arranca (AN-05, falla cerrada, bien). Pero el mensaje dice «configure `GPOS:DataProtection:Anillo:CertificadoServidor` y `GPOS:DataProtection:Carpeta`… Solo el DEMO usa DPAPI, con `DpapiDemo = true`» [V, `ProteccionDatosInstalacion.cs:76-80`]. Empuja al técnico a configurarlo en el entorno del servicio o en `appsettings` (fuera de la regla 4) o a encender `DpapiDemo`. Con `DpapiDemo` la API arranca, crea llaves DPAPI en la ubicación por omisión y no descifra ninguna cadena de conexión.
  3. **Si el técnico repite `--preparar`:** el paso 5 exige el archivo para la idempotencia. Sin él, el verbo crea un **segundo principal** y, como `Api\anillo` tiene llaves de otro principal, termina en el caso de 3.1 «recuperación en otro servidor» (salida 2: «ejecute `--recuperar` con el custodio»). Eso exige la privada de recuperación (SA-04) **aunque el principal original siga intacto en `My`**. El primer principal queda huérfano.
  4. **Causas probables:** un borrado manual, un antivirus, la restauración de `config\` desde un respaldo anterior a `--preparar` o un `restaurar --fase carpetas` que no lo contemple [I, no verifiqué PR-D2 en este punto].
- **Evidencia.** Blueprint §3.2, regla 1, y §3.1, paso 5 [V]. Amplía QA-AN-02 y D-AN-03 (c), que planteé para una ejecución interrumpida; aquí la causa es otra y la consecuencia, más cara.
- **Remediación** (≈0,3 a 0,4 dp en F1):
  1. **Marcador independiente:** si `Api\anillo` tiene llaves conformes envueltas por el `CifradorAnillo` (o si existe la fila del ancla), la ausencia del archivo es **falla cerrada** con un mensaje propio: «falta `config\GPOS.Api.anillo.json`; ejecute `anillo --preparar --reparar-archivo`». Y en ese estado se rechaza `DpapiDemo` aunque falte el archivo.
  2. **Reparación sin ceremonia:** `--preparar` sin archivo busca en `LocalMachine\My` un certificado con llave cuya huella sea el principal de las llaves de `Api\anillo`. Si existe, regenera el archivo con esa huella (con acta) y no crea otro principal. La salida 2 queda solo para cuando no hay ninguna privada del principal.
  3. El mensaje de AN-05 en Release, con el servicio instalado, nombra `anillo --preparar` y no las claves sueltas.
  4. Respaldo: `config\GPOS.Api.anillo.json` y el `.cer` entran en el respaldo de `Api\anillo` (H-17 v2, punto 1), para que una restauración no deje el uno sin el otro.

### SA-04 · Media · La privada de recuperación toca equipos en línea y no se rota después de usarla

- **Riesgo.**
  1. **En el equipo del propietario (P-2):** `New-SelfSignedCertificate` crea el par en el almacén del usuario, con la llave en su perfil y marcada como exportable para poder sacar el PFX [I]. Si el procedimiento no la borra, la privada «fuera de línea» queda en un equipo de uso diario conectado a Internet.
  2. **En el servidor (§3.4, pasos 3 a 5):** se importa en `CurrentUser\My` de la cuenta de soporte y se borra a mano. Borrar el certificado no garantiza que desaparezcan el archivo de la llave del perfil, las instantáneas de volumen ni la copia que haga la herramienta de respaldo si respalda perfiles [I]. `OrigenCertificadosAnillo.ConPrivada` también la busca en `LocalMachine` [V, `:106`]: si alguien la importa ahí, queda en el equipo. D-AN-08b (quién borra) sigue abierta.
  3. **Después de una recuperación, el procedimiento no rota el par.** La misma privada, ya expuesta, sigue protegiendo el anillo.
  4. **Disponibilidad:** el propietario es el **único custodio** de N pares (P-3, uno por sitio). Si no está disponible, ningún sitio se recupera y la tienda no abre (las cadenas de conexión no se descifran). El diseño no declara un RTO.
- **Remediación:**
  1. **Procedimiento de P-2** (0,1 dp, documento): generar el par en un equipo sin red o borrarlo del almacén justo después de exportarlo, y comprobar que no queda; PFX con AES-256; dos copias en medios distintos; la contraseña separada del medio.
  2. **Rotación obligatoria después de cada `--recuperar`:** el procedimiento termina con `--cambiar-recuperacion` hacia un par nuevo (sin código nuevo; ya existe).
  3. Importar sin marcar como exportable y solo en `CurrentUser`; `--recuperar` rechaza la privada si la encuentra en `LocalMachine\My` (≈0,05 dp).
  4. **Alternativa más fuerte** (≈1 a 1,5 dp, después de F1): un reenvoltorio **fuera del servidor**. Se llevan los sobres de `Api\anillo` al equipo del custodio, se reenvuelven allí hacia la pública del principal nuevo y se devuelven, de modo que la privada nunca toca el servidor. Pregunta al propietario.
  5. **Custodia:** un segundo custodio o un sobre sellado (en una caja fuerte, por ejemplo) con un RTO declarado. Pregunta al propietario.

### SA-05 · Media · Rotación del certificado del anillo (F4): ventana en la que las llaves no abren

- **Riesgo.** El orden de §3.5 es: (1) certificado nuevo, (2) reenvolver cada llave para el principal **nuevo** y la recuperación, (3) publicar el archivo con el principal nuevo y (4) borrar el anterior. `Reenvolver` cambia los destinatarios: el sobre deja de servir para el principal anterior [I, «solo cambia la envoltura»]. Si el paso 2 se interrumpe (corte de luz o error a mitad), las llaves ya reenvueltas solo abren con el principal nuevo, pero el archivo todavía publica el anterior. Al arrancar el servicio, esas llaves son ajenas y no se usan. B cita `CertificadosServidorAnteriores` como red de seguridad, pero en el orden escrito la lista se actualiza **después** de reenvolver, no antes.
- **Remediación** (diseño de F4, 0,1 dp):
  - (a) publicar primero un archivo intermedio, con el principal anterior como vigente y el nuevo en `certificadosServidorAnteriores`;
  - (b) reenvolver;
  - (c) publicar el nuevo como vigente y el anterior en la lista;
  - (d) comprobar;
  - (e) quitar el anterior de la lista y borrar su llave.

  Cada paso deja un estado que arranca. Se prueba con una interrupción inyectada en el doble.

### SA-06 · Media · El vencimiento del certificado del anillo avisa a nadie

- **Riesgo.**
  1. Con el principal vencido, `ComprobacionAnillo` lo marca no válido y **no crea llaves** [V, `ComprobacionAnillo.cs:150-151, 240-245`]. La llave vigente dura 90 días. Como mucho 90 días después del vencimiento ya no hay llave predeterminada, y la API deja de proteger datos nuevos: empresas, credenciales, sellos [I, el comportamiento de Data Protection sin llave predeterminada].
  2. El aviso a 180 días sale solo de `anillo --comprobar` y de `comprobar-servidor`. Ninguno de los dos corre solo. El arranque de la API no avisa antes del vencimiento.
  3. El reloj: si el servidor arranca con la hora adelantada (BIOS o una VM restaurada) y la sincronización la corrige después, el `NotBefore` de −1 h no alcanza y el principal es «no válido» desde el primer día. Si la hora se adelanta años, se adelanta el vencimiento. H-16 v2.1 (reloj protegido) no lo cubre en este camino.
  4. La hoja dice que `--renovar-certificado` «debe existir antes de la primera instalación real», pero no es condición de publicación.
- **Remediación** (≈0,1 dp en F1):
  1. La API registra un evento de aviso al arrancar, y cada día si sigue en marcha (reutiliza el 4717 con nivel de aviso o un id de la franja del anillo), cuando quedan menos de 180 días.
  2. `--preparar` rechaza (4) un reloj que la sincronización del sistema no confirma o que difiere de la hora del SQL Server en más de 5 minutos [I sobre cómo consultarlo].
  3. `--renovar-certificado` (F4) se registra como condición de publicación, junto a PUB-06.

### SA-07 · Media · La restauración de un sitio pierde la CA TLS, y el orden de PR-D2 no incluye `red` ni `tls`

- **Riesgo.**
  1. La llave de la CA es no exportable (TPM o software) y no se respalda [V, §4.2]. Si se pierde el servidor de un sitio en «servidor de sitio», hay que crear una CA nueva y **volver a distribuirla a cada puesto y volver a emparejar MAUI** (QR, RT-10): de 5 a 10 minutos por puesto, según P-7 [I].
  2. El orden de §3.3 (`carpetas`, `servicios`, `anillo`, `esquema`, `lectura`) no tiene `red` ni `tls`. El selector exige `HuellaApi` para arrancar en «servidor de sitio» (4747). Por eso W-AN-03 («después del paso 4, el servicio arranca») solo vale en el DEMO por HTTP.
  3. El blueprint no dice nada de esto. Ni el RTO de un sitio ni el procedimiento de restauración cuentan la redistribución.
- **Remediación:**
  1. El blueprint y PR-D2 declaran la posición de `red` y `tls --crear-ca --emitir` en el orden (después de `lectura` y antes del primer arranque en «servidor de sitio»), y la consecuencia de restaurar.
  2. Un procedimiento de redistribución, medido en el laboratorio (LABT), con el número de puestos de un cliente típico.
  3. Pregunta al propietario: ¿se acepta ese RTO o se adelanta PT-04 (CA sucesora, P-6) en la forma de una **CA de respaldo** pregenerada fuera de línea y distribuida desde el primer día? Se estima en 1,5 dp, la misma cifra que B da para la sucesora.

### SA-08 · Media · Cualquier cuenta puede ocupar el mutex de `tls`

- **Riesgo.** `Global\GPOS.Migracion.tls` es un objeto con nombre del espacio global. Crear un mutex en el espacio `Global\` no exige `SeCreateGlobalPrivilege` (ese privilegio aplica a las secciones de memoria compartida) [I]. Un usuario interactivo o la cuenta del servicio, si la comprometen, puede crearlo antes y retenerlo. Entonces cada corrida de la tarea espera 60 s y **sale con 1** (§4.1). Los avisos de PT-10 se emiten dentro de esa misma corrida, así que también callan. A los 30 días vencen las hojas. El STRIDE lo califica como «Bajo, la tarea reintenta al día siguiente», pero la ocupación persiste. El mismo patrón se propondría para el anillo (D-AN-04).
- **Remediación** (≈0,15 dp en F2):
  1. Usar como cerrojo un archivo en una carpeta que solo escriben los administradores (`Servidor\tls\.cerrojo`, abierto sin compartir) o un mutex creado con una DACL de SYSTEM y Administradores, que rechaza al dueño ajeno.
  2. Si no obtiene el cerrojo, emite el **4784 crítico** con el motivo.
  3. Los avisos de vencimiento se calculan y se emiten **antes** de intentar tomar el cerrojo, porque son de solo lectura.

### SA-09 · Media · Con VPN o IP cambiante, las Name Constraints en /32 obligan a reemplazar la CA

- **Riesgo.** PT-07 fija las IP del servidor en /32 y /128. P-7 (firmada) hace que un nombre o una IP fuera de las restricciones lleve a la salida 3 y al reemplazo de la CA con redistribución. En una sucursal con IP pública dinámica, o con una VPN que asigna direcciones por DHCP, **cada cambio de IP es un reemplazo de la CA**. El diseño no impide declarar IP inestables en `NombresServidor` ni avisa de ellas.
- **Remediación:**
  1. Guía para el técnico: en «servidor de sitio», usar nombres DNS estables y no IP de VPN dinámicas.
  2. `red` avisa (no rechaza) cuando una IP de `NombresServidor` no está fija en el adaptador [I sobre cómo detectarlo].
  3. Pregunta al propietario, sin cambiar P-7: ¿se admite en las Name Constraints una subred declarada explícitamente para la VPN? Cuesta perder parte del acotamiento (QT-03). No lo recomiendo por omisión.

### SA-10 · Baja · `GPOS.Migracion` elevado consume variables de entorno del usuario

- **Riesgo.** `GPOS.Migracion` agrega `AddEnvironmentVariables()` [V, blueprint §3.2]. Un proceso elevado hereda el entorno del usuario (`HKCU\Environment`), que un programa sin elevación de la misma sesión puede escribir [I]. La regla 4 protege las claves del archivo, pero no otras que pesan en el anillo y en G-2: `ConnectionStrings:Sistema`, el modo de identidad (Estricto o Amplio) y `DpapiDemo` cuando falta el archivo (SA-03). Es una entrada que cruza el nivel de integridad.
- **Remediación** (≈0,1 dp): en `GPOS.Migracion`, rechazar (salida 4) las variables `GPOS__*` y `ConnectionStrings__*` que vengan solo del ámbito del usuario, o leer solo el entorno de la máquina y del proceso iniciado por el *bundle*. Pregunta para A, que es dueño del `Program.cs` de `GPOS.Migracion`.

### SA-11 · Baja · Secretos en el mensaje del conflicto de fuentes

- **Riesgo.** La regla 4 recorre los proveedores de configuración para detectar el conflicto. En el DEMO, el entorno lleva `Jwt__Clave` [V, blueprint §3.2 (c)]. Si el mensaje del 4729 o la excepción incluyeran los valores o el volcado de un proveedor, un secreto llegaría al Visor.
- **Remediación:** el mensaje nombra la clave y el tipo de proveedor, nunca el valor. Prueba U: el texto del 4729 no contiene ningún valor de la configuración de prueba (un centinela). Lo mismo vale para el registro de Burn cuando el *bundle* llame a `--preparar`: solo la ruta y la huella del `.cer`.

### SA-12 · Baja · Carpeta no conforme y modo Amplio

- **Riesgo.** `ComprobacionAnillo` solo impide el arranque por la carpeta no conforme en el modo Estricto [V, `ComprobacionAnillo.cs:131-137`], y el entorno del servicio de PR-V lleva el modo Amplio [V, blueprint §1]. Si una restauración deja `Api\anillo` con la DACL heredada, la API arranca. No crea llaves, pero usa las que hay. El impacto es acotado: las llaves están envueltas y las no conformes se descartan.
- **Remediación:** con el archivo del anillo presente (instalación de producción), una carpeta no conforme impide el arranque en cualquier modo (0,05 dp).

### SA-13 · Baja · Robustez de la tarea de SYSTEM

- **Riesgo.**
  1. Si se desinstala el MSI que trae `GPOS.Migracion` sin pasar por `--quitar-tarea`, la tarea apunta a un ejecutable que no existe y falla todos los días sin evento propio.
  2. El directorio de trabajo no está fijado en la definición [I: si `GPOS.Migracion` resuelve algún archivo relativo al directorio actual, corriendo como SYSTEM lo buscaría en `System32`].
  3. `comprobar-servidor`, el respaldo independiente de los avisos (§4.5), no corre solo.
- **Remediación:** `WorkingDirectory` fijo en la carpeta del ejecutable; `--comprobar` verifica que la acción de la tarea exista y esté firmada; el MSI quita la tarea al desinstalar con `--quitar-tarea` (devops, T1-b).

### SA-14 · Baja · Mensaje engañoso en la restauración; matiz de QA-AN-01

- **Riesgo.** El ancla se protege con el anillo [V, `AnclaRecuperacionAnillo.cs:49`]. En el escenario de §3.4, antes de `--recuperar`, la API no abre las llaves restauradas, así que el ancla no verifica. Lo más probable [I] es que `ComprobacionAnillo` termine en `NoVerifica` (`ComprobacionAnillo.cs:198-202`) **antes** de llegar a `CreateNewKey`. Eso **matiza QA-AN-01**: la llave nueva se crearía solo si alguna llave abre. Pero el registro dice «la fila del ancla no verifica con el anillo», que el SUPER leerá como una manipulación de la base durante una restauración legítima.
- **Remediación:** distinguir en el mensaje el caso «ninguna llave abre (¿falta `--recuperar`?)» del caso «hay llaves que abren y el MAC no verifica». Confirmar QA-AN-01 con una prueba F antes de cerrarlo.

### SA-15 · Baja · Linux y entrega 2

- **Linux:** la API y la Web no arrancan fuera de Windows [V, `ProteccionDatosInstalacion.cs:55-56`], y los verbos salen con 1. Es falla cerrada, bien. Pero `ArchivoAnillo` se presenta como portable (§3.2, «por qué (a)») y no define su regla 3 en Linux (dueño `root`, modo 0644, sin ACL extendidas, sin enlaces simbólicos). Recomiendo que, fuera de Windows, el cargador falle antes de interpretar el archivo, hasta que la tanda LN fije la regla.
- **Entrega 2:** con P-3 (recuperación por sitio), las filas del ancla y de las heredadas de `GPOS_SYSDATA` son **de cada sitio**. Si el nodo replica alguna parte de `GPOS_SYSDATA` desde la central, esas filas deben quedar fuera. Va como nota para el diseño del nodo.

## 5. Controles bien implementados (en el diseño o en el código)

- El descriptor de la llave CNG se fija **en la misma llamada** que la crea, con el patrón probado de `LlaveSitio`. No queda ventana entre crearla y protegerla [V, §3.1, paso 6].
- La publicación del archivo es el **último paso** y es atómica. Un solo escritor y un solo cargador para la API y `GPOS.Migracion` (O-8 por construcción).
- Regla 4 («una sola fuente») y rechazo de `DpapiDemo` y `DpapiMaquina` cuando el archivo está presente.
- `config\` con SDDL protegido y sin escritor de servicio, componente `Permanent` [V, `RaizGposNg.wxs:22-23, 58-60`]: coincide con la regla 3 del cargador. El MSI deja el servicio **detenido** [V, `Package.wxs:12-13`], lo que encaja con el orden `servicios` → `anillo`.
- El certificado del anillo no tiene `serverAuth` ni `cA` y la CA vive fuera de `My`: el selector TLS no puede tomarlos.
- La CA tiene Name Constraints críticas, la cuenta virtual no lee su llave y hay una CA por sitio. Se agrega la recomendación de rechazar `cA = true` en el selector (QT-03).
- La Web llega a la API por *loopback* sin consultar DNS y con el SNI del nombre del sitio [V, `ClienteApiLocal.cs:15-18`]. Se evita `localhost` en el SAN sin depender del DNS.
- La contraseña de un PFX nunca pasa por Burn (P-5).
- Fuera de Windows, falla cerrada [V].
- Los avisos de vencimiento no guardan estado en archivos. Lo asume B: un evento falsificado puede suprimir un aviso (residual Bajo, coincido).

## 6. Remediaciones priorizadas

| Prioridad | ID | Acción | Esfuerzo [I, ±40 %] | Cuándo |
|---|---|---|---|---|
| 1 | SA-01 | `--huella-recuperacion` obligatoria en `--preparar` y `--anclar`; una sola lectura del `.cer` | 0,1 a 0,15 dp | F1, antes de construir (26-oct) |
| 2 | SA-02 | Recuperación vencida = aviso; procedimiento de P-2 con `-NotAfter` de 30 años, 3072 bits y AES-256 | 0,05 dp más el procedimiento | F1 |
| 3 | SA-03 | Falla cerrada por el marcador de `Api\anillo` o la fila del ancla; reparación del archivo sin crear un segundo principal; mensaje de AN-05 | 0,3 a 0,4 dp | F1 |
| 4 | SA-06 | Aviso de 180 días en el arranque y a diario; guarda del reloj; `--renovar-certificado` como condición de publicación | 0,1 dp | F1 (aviso); F4 |
| 5 | SA-04 | Procedimiento de P-2 y de recuperación con rotación obligatoria; segundo custodio y RTO | 0,1 dp (documento); 1 a 1,5 dp la alternativa | Antes del primer cliente |
| 6 | SA-07 | Orden completo con `red` y `tls`; procedimiento y medida de la redistribución de la CA | 0,25 dp (B y A) | Antes del 16-nov (VM) |
| 7 | SA-08 | Cerrojo con DACL o por archivo; 4784 si no se obtiene; avisos antes del cerrojo | 0,15 dp | F2 |
| 8 | SA-05 | Orden de la rotación en cinco estados que arrancan | 0,1 dp | Diseño de F4 |
| 9 | SA-09 a SA-15 | Guía de VPN, entorno de usuario, mensajes, modo Amplio, tarea, Linux | ≈0,4 dp en total | F1 a F4 según el caso |

Lo que entra en F1 (SA-01, SA-02, SA-03 y el aviso de SA-06) suma unos **0,6 dp** sobre los 2,75 dp firmados (unos USD 180 a 240 a la tasa del blueprint [I]).

## 7. Recomendación

**Rechazado** como diseño, mientras SA-01 y SA-02 (Altas) no se incorporen a F1. Las dos se cierran con unos 0,2 dp, sin tecnología nueva, y conviene decidirlas antes del 26-oct. Con SA-01 y SA-02 incorporadas y SA-03 asumida en F1, mi recomendación pasaría a **Aprobado con observaciones**. Es una recomendación técnica: F1 está firmada por el propietario, y lo que cambia lo que hace el técnico (SA-01, SA-04 y SA-07) va como pregunta con recomendación.

## Supuestos

- La hoja del PR #221 es la versión firmada vigente (P-1 a P-8 y F1).
- `New-SelfSignedCertificate` emite por omisión 1 año y RSA de 2048 bits.
- Crear un mutex en el espacio `Global\` no exige privilegio.
- `Reenvolver` deja de envolver la llave para el principal anterior.
- Todo lo marcado [I] se confirma en el laboratorio o al construir.

### Cierre
- Estado: Rechazado (recomendación técnica sobre el diseño; con SA-01 y SA-02 incorporadas: Aprobado con observaciones).
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-revision-adversarial-blueprint-anillo-tls.md`.
- Supuestos: los de la sección anterior.
- Decisiones candidatas a ADR: (1) huella de recuperación obligatoria por un segundo canal en `--preparar` y `--anclar` (precisión de H-17 v2; alternativa descartada: `.cer` embebido en el *bundle*); (2) falla cerrada por la ausencia del archivo del anillo cuando hay llaves o ancla (precisión de P-1); (3) rotación obligatoria del par de recuperación después de cada uso y segundo custodio (precisión de H-17 v2 y P-3).
- Entregas a otros agentes: B (arquitecto-software) → SA-01, SA-02, SA-03, SA-05, SA-06, SA-08 y SA-12 en el blueprint antes de F1; A → SA-07 (orden de PR-D2 con `red` y `tls`), SA-10 (`Program.cs` de `GPOS.Migracion`) y SA-14 (mensaje); devops (T1-b) → SA-13 (`--quitar-tarea` al desinstalar); Arquitecto Maestro → preguntas al propietario de SA-01, SA-04 (custodio y RTO), SA-07 (CA de respaldo) y SA-09.
- Próximo paso recomendado: que B incorpore SA-01 y SA-02 al blueprint y que el propietario confirme la huella obligatoria antes de empezar F1 el 26-oct.
