# Hoja de firma: diseño de la vertical Corporativa (entrega 3)

[Decisión preparada por el Arquitecto Maestro (equipo A)] · 2026-10-15 · **Estado: Firmada el 2026-10-15 (D-01 a D-28 en la opción (a), con D-02 precisado; H-04 abierta)** · Sin commit · No toqué código, configuración ni bases.

**Qué se firma:** el **diseño** de la vertical Corporativa, que se construye en la entrega 3. El requerimiento ya está firmado: H-01 a H-03 y H-05 a H-11, F-1 a F-5, PF-1, PF-3 y PF-4. **H-04 sigue abierta** y esta hoja no la decide. Esta hoja junta en **una sola lista** (D-01 a D-28) las 15 decisiones de datos (FD), las 18 de software (SW) y las 9 preguntas de UX (UQ), y les incorpora las remediaciones del auditor-seguridad.

**Cómo firmar:** marque una casilla por punto, o la casilla «Todo según recomendación» de la sección 10. Los puntos del bloque A (D-01 a D-15) cambian el diseño o la seguridad. Los del bloque B (D-16 a D-23) son operativos. Los del bloque C (D-24 a D-28) son menores y se pueden corregir después sin rehacer nada.

**Convención:** *verificado* = leído en esta sesión, con `ruta:línea`; *inferido* = estimación sin medir (los sp llevan ±40 %). Cito los documentos de entrada así:
- **[HF]** `traspasos/A/hoja-firma-vertical-corporativa-2026-10-15.md`;
- **[DAT]** `traspasos/A/datos-vertical-corporativa-2026-10-15.md`;
- **[BP]** `traspasos/A/blueprint-vertical-corporativa-2026-10-15.md`;
- **[UX]** `traspasos/A/ux-vertical-corporativa-2026-10-15.md`;
- **[SEG]** `traspasos/A/revision-seguridad-diseno-corporativa-2026-10-15.md`;
- **[NG]** el repositorio `GPOS NG`, rama `origin/feature/modelo-ng` en `ce33b2a8`, leído con `git show` y `git grep`, sin tocar el árbol de trabajo.

---

## 1. Contexto y pregunta a decidir

**Pregunta:** ¿se firma el diseño de datos, de software y de pantallas de la Corporativa, con las correcciones de seguridad incorporadas, como base para construir el tramo de la entrega 3?

**Estado de la revisión de seguridad ([SEG] 7):**
- El auditor **rechaza el texto actual de SW-02 y SW-09** por SEG-CORP-02 (Alta) y SEG-CORP-07 (Media), y exige que SEG-CORP-01 (Alta, DB-7) quede como requisito comprobable.
- Pasa a **«Aprobado con observaciones», sin una ronda completa nueva**, si se cumplen dos condiciones: que esta hoja incorpore su §6.1, y que DB-7 y las demás condiciones de §6.2 a §6.4 queden escritas como requisitos de la puesta en marcha.
- **Esta hoja cumple las dos:**
  - la §6.1 está incorporada en D-01, D-02, D-08, D-09, D-10, D-11 y D-12, con la matriz de la sección 4;
  - las condiciones de §6.2 a §6.4 están en la sección 5.
- Falta un paso: que el auditor confirme solo esas diferencias ([SEG] 7, último párrafo).

**No hay contradicción con un ADR vigente.** Las precisiones que este diseño necesita están en la sección 8.

---

## 2. Entregables evaluados

| Entregable | Ruta | Estado que declara | Evaluación |
|---|---|---|---|
| Requerimiento firmado | `traspasos/A/hoja-firma-vertical-corporativa-2026-10-15.md` | Firmado, salvo H-04 | Fuente de verdad |
| Blueprint de datos | `traspasos/A/datos-vertical-corporativa-2026-10-15.md` | FD-01 a FD-15 pendientes | Coherente con [HF]. Le faltan las piezas de [SEG] (D-01, D-02, D-05, D-06, D-08) |
| Blueprint técnico | `traspasos/A/blueprint-vertical-corporativa-2026-10-15.md` | SW-01 a SW-18 pendientes | Coherente con [HF] y con [DAT]. SW-02 y SW-09 se reescriben aquí |
| Diseño UX/UI | `traspasos/A/ux-vertical-corporativa-2026-10-15.md` | UQ-1 a UQ-9 pendientes | Alineado con [BP] 16. Los nombres de [BP] mandan |
| Revisión de seguridad | `traspasos/A/revision-seguridad-diseno-corporativa-2026-10-15.md` | Rechazado en el texto actual de SW-02 y SW-09 | 2 Altas, 13 Medias, 5 Bajas; ninguna Crítica. Todas tienen destino en esta hoja (sección 4) |

**Evidencia que verifiqué en esta sesión:**
- **SEG-CORP-08** existe en el núcleo actual:
  - `[NG] src/GPOS.Core/Servicios/Nucleo/AutorizacionesSupervisor.cs:73` trata como «propio» solo el caso sin contraseña;
  - `:109` devuelve `PorCredencial = true` con el autorizante que dio la credencial, aunque sea el mismo usuario de la sesión;
  - `:137` lo anota en la bitácora como «(supervisor presente)»;
  - ningún consumidor de la rama compara al autorizante con el usuario de la sesión (`git grep` de `Autorizante`, `PorCredencial` y `MISMO_USUARIO` en `src`).
- `PermisosService.EfectivosAsync` existe (`[NG] src/GPOS.Core/Sistema/PermisosService.cs:16`). Lo usan la sesión (`AuthEndpoints.cs:241`), la autorización del POS (`PosEndpoints.cs:63`), el filtro del servidor (`PermisosServidor.cs:23`) y el autorizador (`AutorizadorSupervisor.cs:39`). Es el punto único que pide [SEG] para la lista de permitidos.
- Hoy el ADMIN tiene «todos los permisos» (`[NG] src/GPOS.Contracts/Seguridad/Permisos.cs:45`). Por eso la lista de permitidos **no basta sola**: los cortocircuitos que leen el nivel del token no pasan por el mapa. De ahí la invariante «el externo nunca es ADMIN» de D-01.
- **ADR-67** está «decidido, no implementado; ola 3b (bloque separable 3b-A)» (`origin/master:docs/adr/ADR-067.md`, encabezado). El punto 9 dice que «su KEK nunca sale del nodo» (línea 25). Esto confirma DB-8 y la precisión de D-15.
- **ADR-112:** el mecanismo de verticales «pasa de 3a a 3c» (`[NG] docs/adr/ADR-112.md:33`). [HF] 8.1 decía «después de 3a». Vale el tramo **3c**, como dice [BP] 13.
- **ADR-85 a 88** no están todavía en `origin/master/docs/adr/` (verificado con `git ls-tree`): los registra B.

---

## 3. Lista única de decisiones (D-01 a D-28)

### 3.0 Tabla de procedencia

| Punto | Recoge | Hallazgos de [SEG] incorporados | Bloque |
|---|---|---|---|
| **D-01** | SW-09; [BP] 8.2; [DAT] 2.13 (merma); H-09 | SEG-CORP-02, 08 (autorizante), 11 (en parte) | A |
| **D-02** | SW-02, SW-06; [BP] 8.1 y 6.1 (idempotencia) | SEG-CORP-07 | A |
| **D-03** | SW-17, UQ-2; [BP] C-6 y C-7 | SEG-CORP-03 (vía sin foto), 08 (`SIN_CARNE`), 17 (búsqueda) | A |
| **D-04** | FD-03, SW-08; [BP] 8.5 | SEG-CORP-05, 17 (EC-03) | A |
| **D-05** | **UQ-7**; [UX] AC-05 | SEG-CORP-03 | A |
| **D-06** | FD-03 (retención); [DAT] 8 | SEG-CORP-04 | A |
| **D-07** | FD-04, SW-07; [BP] 8.4 y 8.6 | SEG-CORP-06, 12, 16 | A |
| **D-08** | [DAT] 9 (privilegios de la base); [DAT] 8 (cuadre) | SEG-CORP-15 | A |
| **D-09** | [BP] 6.4 (C-11); [DAT] 2.13; H-06 | SEG-CORP-10, 11 | A |
| **D-10** | SW-18, UQ-6; [BP] C-12 y C-13 | SEG-CORP-11 | A |
| **D-11** | SW-11, UQ-3; [BP] 10.2 | SEG-CORP-09 | A |
| **D-12** | SW-03, SW-16, FD-09, FD-10, UQ-9; [BP] 7 | SEG-CORP-20 | A |
| **D-13** | SW-01, FD-01, FD-02, FD-08 | — | A |
| **D-14** | SW-04, FD-11 | — | A |
| **D-15** | SW-15; [BP] 9; [DAT] 5 | SEG-CORP-13, 14, 04 (borrado en el nodo) | A |
| **D-16** | SW-05, FD-06, FD-15 | — | B |
| **D-17** | FD-05, FD-07 | — | B |
| **D-18** | FD-13 | — | B |
| **D-19** | SW-12 | — | B |
| **D-20** | SW-14; [BP] 6.5 | SEG-CORP-18 | B |
| **D-21** | UQ-1; [BP] C-5 | — | B |
| **D-22** | SW-13 | — | B |
| **D-23** | FD-14; [DAT] 7 | SEG-CORP-17 (RC-01, motivo libre), CA-13 automática | B |
| **D-24** | FD-12 | SEG-CORP-17 (cupo impreso) | C |
| **D-25** | SW-10 | — | C |
| **D-26** | UQ-4, UQ-5 | — | C |
| **D-27** | UQ-8 | — | C |
| **D-28** | [BP] 6.7 (carga de la foto) | SEG-CORP-19 | C |

**Comprobación de cobertura:** las 15 FD, las 18 SW y las 9 UQ aparecen una sola vez. Los 20 hallazgos de [SEG] tienen destino. SEG-CORP-01 va como condición PM-01 (sección 5), no como punto de diseño.

---

### Bloque A · Lo que cambia el diseño o la seguridad

#### D-01 · Segregación del personal del administrador externo (SW-09 reescrito) — seguridad, Alta

**Qué se decide:** cómo garantiza el servidor que el cajero y el supervisor del tercero nunca tengan poderes de la empresa, aunque alguien les arme mal un perfil.

| Opción | Consecuencia |
|---|---|
| **(a) Invariante en la cuenta + lista de permitidos + inventario de la empresa + «otra persona» por comparación** (texto de abajo) | Control cerrado: falla cerrada ante un perfil mal hecho y ante un privilegio nuevo del futuro. Cierra SEG-CORP-02 y la parte de la vertical de SEG-CORP-08 |
| (b) SW-09 original: recorte por lista de exclusión | **El auditor lo rechaza:** el ADMIN entra por al menos seis sitios del código y la lista no cubre ajustes, mermas, conteos ni los privilegios futuros |
| (c) Solo control procedimental y RC-05 | Depende de que nadie se equivoque. El error no se ve hasta la auditoría |

**Texto para firmar (sustituye a SW-09 de [BP] 8.2 y 15):**

> **SW-09 v2 · Personal del administrador externo.**
> 1. **Invariante de nivel.** Una cuenta marcada «Personal del administrador externo» (y su membresía, cuando exista el acceso multiempresa v1) **nunca tiene nivel ADMIN ni SUPER**. La regla se comprueba en el alta, en la edición y en la emisión del token de sesión. Si el almacén de usuarios lo admite, se agrega además como `CHECK`. Un token con un nivel mayor que el de la cuenta se invalida con la `RevocacionSesiones` vigente. Así el nivel del token es USER y los cortocircuitos del ADMIN (`Seguridad.cs`, `PermisosServidor.cs`, `FiltroCostos.cs`, `AutorizadorSupervisor.cs`, citados en [SEG] SEG-CORP-02) nunca se activan para un externo.
> 2. **Lista de permitidos en `PermisosService.EfectivosAsync`.** Es la fuente común del mapa de la sesión y del autorizador. Para una cuenta externa, el mapa efectivo es la intersección del perfil con esta lista, y nada más: `corp-consumo` (y su acción Autorizar en el supervisor), `corp-reverso` (ídem), `pos` (visitante), la apertura, la X y el cuadre de su caja, el Z y el arqueo para el supervisor, `rep-corporativa` y, si la empresa lo decide, `corp-contingencia` (D-10). Todo lo demás se descarta aunque un perfil lo dé (falla cerrada), y cada descarte deja una línea en la bitácora y en RC-05. **Un privilegio nuevo del sistema queda fuera por omisión.**
> 3. **Inventario de la empresa.** Las mermas, los ajustes y el cierre del conteo los **confirma un usuario de la empresa**. El tercero solo registra borradores, incluido el borrador de merma del reverso «servido» de [DAT] 2.13. Se agrega a H-09 un **conteo físico periódico de la empresa**, por ejemplo semanal en los artículos de mayor costo, con el conteo ciego vigente.
> 4. **«Otra persona» por comparación.** En toda autorización de la vertical (reverso, identificación sin carné, lote de contingencia), la regla compara `AutorizacionValidada.Autorizante` con el usuario de la sesión, normalizados con `Trim` y `ToUpperInvariant`, y **rechaza si coinciden** con 422 `AUTORIZANTE_MISMO_USUARIO`. No basta con mirar `PorCredencial`, porque hoy el núcleo devuelve `true` cuando el usuario escribe su propia contraseña (sección 7). La forma B (privilegio propio) se rechaza en estos casos.
> 5. **Un externo no autoriza a un usuario de la empresa** ni lo que D-09 reserva a la empresa (los reversos de otro día o posteriores al Z).
> 6. **Prueba (CA-09 ampliado).** Un perfil que concede de más (incluidos ADMIN, «ajustes», «mermas», «usuarios» y un privilegio inventado) recibe 403 en todo lo que no está en la lista. Un externo que intenta autorizarse a sí mismo o a otro externo fuera de su caja recibe 422. Un externo con nivel ADMIN no se puede crear ni editar.

**Recomendación: (a).** **Costo:** 0,25 sp en lugar de 0,2, es decir +0,05 sobre lo estimado; la comparación del autorizante suma 0,05 sp más (inferido). El conteo físico cuesta 0 sp en el sistema y algunas horas al mes de la empresa cliente. **Riesgo residual:** Bajo, con la condición PM-07.

- [x] (a) SW-09 v2 · [ ] (b) SW-09 original · [ ] (c) Solo procedimental

---

#### D-02 · Tokens de la caja sin carrito en el servidor (SW-02 reescrito, con SW-06) — seguridad, Media

**Qué se decide:** cómo viajan la lectura, la identidad confirmada y la cotización entre la caja y el servidor sin guardar un carrito, y cuánto vale una línea validada dentro de su franja.

| Opción | Consecuencia |
|---|---|
| **(a) Tokens firmados de vida corta, un propósito por tipo, identificación de un solo uso al emitir** (texto de abajo) | Conserva la ventaja de SW-02 (no escribir en la base en cada lectura) y cierra la confusión de tipo, la reutilización de la identidad y el cambio de líneas |
| (b) SW-02 original: un propósito para los tres tokens, identificación reutilizable durante 10 minutos | **El auditor lo rechaza** (SEG-CORP-07): con una sola lectura del carné se pueden emitir varios tickets y vaciar la bolsa |
| (c) Tabla de identificaciones confirmadas | Unas 700 filas por sede y día que nadie consulta y que hay que sincronizar |

**Texto para firmar (sustituye a SW-02 de [BP] 8.1 y 15, y precisa SW-06 de [BP] 5.4):**

> **SW-02 v2 · Tokens de la caja.**
> 1. **Un propósito de Data Protection por tipo:** `GPOS.Corporativa.Caja.Lectura.v1`, `GPOS.Corporativa.Caja.Identificacion.v1` y `GPOS.Corporativa.Caja.Cotizacion.v1`, cada uno más el identificador inmutable de la empresa. Cada token lleva además un campo `tipo` obligatorio y un `Id` aleatorio de 128 bits. Un token de un tipo nunca se abre como otro: falla la protección y, si no fallara, falla el campo.
> 2. **Atados a** usuario, caja, empresa, comensal y sesión (`sid`). El de cotización, además, a la jornada. Vidas de 2, 10 y 3 minutos, sin cambio.
> 3. **Identificación de un solo uso en la emisión.** Columna `corp.Consumo.IdentificacionUid uniqueidentifier NULL` (el `Id` del token de identificación), con un índice **único** filtrado `WHERE IdentificacionUid IS NOT NULL`. El lote de contingencia no lleva token y queda en `NULL`. Un segundo ticket con el mismo token responde 409 `IDENTIFICACION_USADA` y la caja vuelve a leer el carné. Es persistente, viaja con el ticket al sincronizar y no necesita una tabla nueva. El índice filtrado es legal según RG-14 D-04 (a), porque `corp.Consumo` no tiene columnas calculadas ([DAT] 1.2).
> 4. **Orden con la idempotencia.** Primero se busca la `ClaveIdempotencia`, limitada al mismo usuario, la misma caja y la misma empresa. Un reintento con la misma clave devuelve el ticket ya emitido aunque el token ya se usó o venció. Una clave nueva con un token usado responde 409.
> 5. **La emisión exige las mismas líneas que la cotización.** Las líneas de `EmitirConsumoRequest` deben coincidir con la huella de líneas del `CotizacionToken` (artículo, unidad, cantidad y orden). Si no coinciden, 409 `REPARTO_CAMBIO` con `motivo = LINEAS` y la cotización nueva. Nunca se aplica la `ValidadaEn` de una línea a otra.
> 6. **`ValidadaEn` nunca se renueva desde un token (SW-06 precisado).** La gracia de 3 minutos se mide desde la **primera** validación de la línea. Recotizar con `CotizacionAnterior` conserva la `ValidadaEn` original, no la reinicia.
> 7. **Contador de lecturas de la foto** (máximo 3 por `LecturaToken`): en la memoria del sitio, por el `Id` del token. Se pierde al reiniciar la API, lo que es aceptable con 2 minutos de vida. No se escribe en la base.
> 8. **Prueba:** un token de lectura presentado como identificación, un token de identificación usado dos veces con dos claves distintas, unas líneas cambiadas entre la cotización y la emisión, y una recotización que intenta extender la gracia. Cada caso responde con su código.

**Recomendación: (a), con la gracia de 3 minutos de SW-06.** **Costo:** 0,1 sp (inferido). **Alternativa de SW-06 descartada:** revalidar siempre al emitir, que rechaza en la caja un plato ya servido por un cobro con tarjeta de 30 segundos.

- [x] (a) SW-02 v2 y SW-06 precisado · [ ] (b) SW-02 original · [ ] (c) Tabla de identificaciones

> **Precisión del propietario a D-02 (2026-10-15, sesión de A), literal:** «No. Mas simple. Obligar a ingresar el carnet cada vez que haya de realizar un consumo. La empresa exige que se debe utilizar el carnet por cada consumo nuevo por tanto no se debe acomodar al cajero pero si aplicar el mandato de la empresa en todo momento.»
>
> **Efecto en SW-02 v2:**
> - **Un carné por cada consumo nuevo,** siempre. No existe «agregar al último consumo» ni ninguna reutilización de una lectura anterior, aunque sea del mismo empleado y en la misma caja.
> - **La lectura vale para todo el consumo abierto.** El empleado agrega o quita artículos libremente hasta emitir. La identificación no vence a mitad de un consumo en curso: la vida de 10 minutos del punto 2 se sustituye por «mientras el consumo esté abierto».
> - **Consumo abandonado:** un consumo sin emitir que quede inactivo se cancela solo, y continuar exige pasar el carné de nuevo. El plazo de inactividad lo propone el diseño; es un detalle técnico, no una comodidad para el cajero.
> - **Al emitir, la identificación queda usada** (punto 3, índice único): el siguiente consumo exige el carné.
> - **No hay límite de consumos por día.** Solo aplican los topes firmados: la bolsa, las franjas, el almuerzo y la cena una vez por franja, y el cupo de nómina.
> - **Sin cambio:** el auditor aceptó «un solo uso por ticket». La precisión lo hace más estricto, no más débil.

---

#### D-03 · Identificación sin carné: tope, autorización registrada y vía sin foto (SW-17, UQ-2) — seguridad

**Qué se decide:** qué pasa al llegar al tope de 3 identificaciones sin carné por mes, cómo queda registrada la autorización y cómo se busca al comensal.

| Opción | Consecuencia |
|---|---|
| **(a) Tope duro de 3; la autorización se guarda como `doc.Autorizacion` de tipo `SIN_CARNE`; el estado «sin foto por decisión del titular» no cuenta para el tope; búsqueda acotada** | El tope limita de verdad y queda rastro de quién autorizó. Quien no da su foto no pierde el beneficio (D-05) |
| (b) Permitir pasar el tope con otra autorización ([POS] F-08) | El tope deja de limitar: ya hay una autorización en cada caso |
| (c) Tope duro sin excepción para quien no tiene foto | El que no consiente pierde el beneficio desde el cuarto consumo, y entonces el consentimiento no es libre ([SEG] SEG-CORP-03) |

**Detalle de (a):**
1. **Tope duro de 3 por comensal y mes (SW-17 = UQ-2).** Al llegar al tope, se atiende como visitante (EC-16).
2. **`doc.Autorizacion` de tipo `SIN_CARNE`** (amplía `CK_Autorizacion_Tipo` en M3, junto a `REVERSO_CONSUMO`). Se escribe al emitir el ticket, enlazada al documento. Un disparador exige que el autorizante sea distinto de `IdentidadConfirmadaPor` y del creador (regla nueva en el rango 51800 a 51849). Hoy `corp.Consumo` solo guarda quién confirmó la identidad ([SEG] SEG-CORP-08).
3. **Estado «sin foto por decisión del titular»** (columna en `com.Comensal`, en M1): exige la autorización de otra persona en **cada** consumo, **no cuenta** para el tope de 3 y sale aparte en RC-05. En la fase 2 lo sustituye el PIN.
4. **Búsqueda (C-6):**
   - mínimo de 3 caracteres y como mucho 10 resultados;
   - la consulta de consumos del cajero (C-10), limitada a su jornada y a su caja;
   - la búsqueda por nombre en los consumos, solo para la empresa (SEG-CORP-17).
5. **RC-05** marca las autorizaciones de un supervisor sin sesión ni jornada abierta en esa sede a esa hora: es la señal de una contraseña aprendida.

**Recomendación: (a).** **Costo:** 0,05 sp el tipo `SIN_CARNE` y su disparador (dentro de los 0,05 de D-01, punto 4). El estado sin foto va en D-05. La búsqueda acotada cuesta 0.

- [x] (a) · [ ] (b) · [ ] (c)

---

#### D-04 · Custodia criptográfica de la foto (FD-03, SW-08) — seguridad, Media

**Qué se decide:** dónde vive la foto, cómo se cifra y cómo se sirve.

| Opción | Consecuencia |
|---|---|
| **(a) En la base de la empresa, tabla aparte `com.ComensalFoto`, AES-256-GCM en la aplicación con la construcción de ADR-67, con AAD fija y una DEK por escritura; servida solo tras una lectura; sin caché en disco** | Atómica con el padrón y viaja con el respaldo. 90 MB para 2.000 comensales (0,9 % del tope de Express). La AAD impide cambiar la foto de una fila por la de otra |
| (b) Almacén de adjuntos de ADR-67, fuera de la base | ADR-67, punto 2, ancla todo adjunto a un documento emitido. Habría que precisarlo, y servir en menos de 1 s es más difícil |
| (c) TDE o `ENCRYPTBYKEY` | TDE no existe en Express, y con `ENCRYPTBYKEY` el DBA descifra |

**Precisiones incorporadas en (a) ([SEG] SEG-CORP-05, §6.1, prioridad 8):**
- **AAD** = identificador inmutable de la empresa + `ComensalId` + `VersionFoto` + la etiqueta `com.foto.v1`;
- **una DEK nueva en cada escritura**: cambiar la foto nunca reutiliza la DEK con otro nonce;
- **al servir** (C-3), se comprueba que la `VersionFoto` descifrada coincide con la del `LecturaToken`. Si no coincide, no se muestra nada y queda una línea en la bitácora;
- **depende de DB-8** (el núcleo criptográfico de ADR-67 construido) o de construirlo dentro de T1 **con el mismo diseño, sin una variante propia** (sección 6);
- **SW-08 sin cambios:**
  - la foto solo se sirve tras una lectura, con `no-store`;
  - no hay URL por el `Id` del comensal;
  - en la Web llega como `data:`, y en MAUI vive solo en memoria (50 fotos como máximo por sesión);
  - no tiene metadatos (EXIF);
  - cada vista administrativa va a la bitácora;
- **minimización (EC-03):** la foto de un comensal **de baja o inhabilitado** no se muestra en la caja (se trata como el carné bloqueado, PV-5). Solo se muestra si el comensal está suspendido.

**Recomendación: (a).** **Costo:** 0 sp, porque es especificación. Si T1 tiene que adelantar el núcleo de ADR-67, son unas +0,3 sp que salen de la ola 3b (inferido).

- [x] (a) · [ ] (b) · [ ] (c)

---

#### D-05 · UQ-7: consentimiento de la foto — seguridad y legal, Media

**Qué se decide:** si el consentimiento del comensal para usar su foto es obligatorio y cómo se registra.

**Conclusión técnica del auditor ([SEG] SEG-CORP-03), sujeta a la confirmación de un abogado:**
- según la definición de la Ley 172-13, la foto **no es un dato sensible por sí misma**, pero sí es un **dato personal**;
- la Constitución protege la **propia imagen** (art. 44);
- la excepción laboral puede cubrir a los empleados, pero **no al personal de servicio**, que no es empleado de la empresa;
- y el consentimiento de un empleado difícilmente es «libre» si negarlo lo deja sin el beneficio.

| Opción | Consecuencia |
|---|---|
| **(a) Consentimiento obligatorio con registro + aviso informativo versionado + vía sin foto + cláusulas de encargado + derecho de acceso** | Resiste las dos lecturas de la ley (con o sin la excepción laboral). Es barata |
| (b) La casilla de AC-05 sola, obligatoria | Una casilla sin fecha, sin autor y sin la versión del texto no prueba nada |
| (c) Sin consentimiento, amparado en la relación laboral | No cubre al personal de servicio. Riesgo legal para el cliente |

**Detalle de (a):**
1. **Obligatorio.** Sin el registro del consentimiento, la API no admite cargar la foto (`PUT /api/comensales/{id}/foto` responde 422 `CONSENTIMIENTO_FOTO_FALTA`).
2. **Registro** en `com.Comensal` (M1): `ConsentimientoFotoEn datetime2(3)`, `ConsentimientoFotoRegistradoPor` y `VersionAviso`. El documento firmado (en papel o en un formulario) lo guarda RR. HH.; el sistema guarda la prueba de que existe. Cada cambio va a la bitácora.
3. **Aviso informativo versionado:**
   - la finalidad: identificar al comensal en la cafetería y controlar el beneficio;
   - el responsable: la empresa;
   - los encargados: el tercero, que ve la foto en la caja, y GSF, con acceso de soporte;
   - la conservación: hasta 90 días después de la baja o del cese, y en los respaldos hasta su plazo máximo (D-06);
   - los derechos de acceso, rectificación, supresión y oposición, y dónde se ejercen (RR. HH.).

   La pantalla AC-05 muestra la versión vigente del aviso.
4. **Vía sin foto:** el estado «sin foto por decisión del titular» de D-03, punto 3. **La retirada del consentimiento borra la foto en el acto**, sin esperar los 90 días, y la apunta en la lista de supresiones (D-06).
5. **Derecho de acceso:** en AC-02, una impresión «Datos del comensal» con sus datos, consumos, saldos y si tiene foto. La foto se muestra en pantalla, sin exportarla. Sirve también como estado de cuenta a pedido (D-07, detección).
6. **Contratos:**
   - una cláusula de encargado del tratamiento en el contrato con el tercero (confidencialidad, uso solo para la finalidad, sin copias ni fotos de la pantalla);
   - otra en el contrato de GSF con el cliente.

**Nota legal obligatoria:** el auditor citó la Ley 172-13 **de memoria, sin releerla** ([SEG] 4.3). **El asesor legal del cliente debe confirmar dos cosas:**
- los artículos y el alcance de la excepción laboral;
- **si la Ley 172-13 sigue vigente en 2026** o si la sustituyó una ley nueva de protección de datos.

Las medidas de (a) se eligieron para que sirvan con cualquiera de las dos respuestas. Aun así, la confirmación es la condición PM-05.

**Si algún día se agrega el reconocimiento facial automático,** la foto pasa a usarse como dato biométrico y hay que repetir esta revisión.

**Recomendación: (a).** **Costo:** 0,15 sp en el sistema (columnas en M1, vía sin foto, impresión de AC-02; inferido). El aviso y las cláusulas los redacta el abogado del cliente: es un costo legal del cliente, que no estimo.

- [x] (a) Consentimiento obligatorio con registro, aviso, vía sin foto y cláusulas · [ ] (b) Solo la casilla · [ ] (c) Sin consentimiento

---

#### D-06 · Retención de la foto y lista de supresiones fuera de la base de la empresa (FD-03, retención) — seguridad, Media

**Qué se decide:** cuándo se borra la foto, cómo llega el borrado al nodo y cómo se evita que una restauración la devuelva.

| Opción | Consecuencia |
|---|---|
| **(a) Borrado por baja, por cese sin baja y por retiro del consentimiento; borrado en el nodo por la clase de seguridad; lista de supresiones en `GPOS_SYSDATA` que se vuelve a aplicar tras restaurar; plazo máximo de los respaldos** | Cierra los cuatro huecos de [SEG] SEG-CORP-04 sin destruir llaves |
| (b) FD-03 original: solo a los 90 días de `FechaBaja` | El personal de servicio que cesa sin baja conserva la foto sin límite, y una restauración devuelve las fotos borradas |
| (c) Borrado criptográfico (una KEK de fotos por período que se destruye) | Choca con ADR-67, punto 3 («ninguna versión se destruye») y cuesta más |

**Detalle de (a):**
1. El trabajo de retención borra la foto:
   - a los 90 días de la baja;
   - cuando el carné está vencido o no hay ningún carné activo y no hubo consumo en `DiasBorradoFoto` días (90 por omisión);
   - en el acto, al retirar el consentimiento.

   Corre también al arrancar la API y es idempotente.
2. El borrado viaja al nodo en la **clase de seguridad**, igual que los bloqueos (5 minutos p95 con conexión). El nodo lo aplica con un `DELETE` físico.
3. **Lista de supresiones en `GPOS_SYSDATA`**, no en la base de la empresa. Guarda el comensal, la versión de la foto, la fecha y el motivo, sin la imagen. La reconciliación posterior a una restauración (guarda 51330, MD-59) la vuelve a aplicar **antes de habilitar la emisión**.
4. **Plazo máximo de los respaldos con fotos:** lo fija devops (por ejemplo, 35 días en los rutinarios) y se informa en el aviso (D-05). Si hay respaldos de largo plazo, también se informan.

**Recomendación: (a).** **Costo:** 0,15 sp y 0 USD (inferido).

- [x] (a) · [ ] (b) · [ ] (c)

---

#### D-07 · Carné: HMAC con custodia, rotación solo por compromiso, captura del lector y detección (FD-04, SW-07) — seguridad, Media

**Qué se decide:** cómo se guarda y se protege el identificador del carné, cómo se captura la lectura y qué controles detectan un carné tecleado o clonado.

| Opción | Consecuencia |
|---|---|
| **(a) HMAC-SHA-256 por empresa, con la llave en `GPOS_SYSDATA` y la custodia de ADR-67; rotación solo por compromiso, hecha por un proceso de la central; captura de SW-07; detección en RC-05 con umbrales** | Un respaldo robado de la base de la empresa no trae la llave al lado. Perder el anillo no obliga a volver a registrar todos los carnés. La rotación no choca con `TR_Carne_Estado` |
| (b) FD-04 y SW-07 originales: llave envuelta solo con el anillo, en la base de la empresa; migración perezosa en la lectura | Si se pierde el anillo, ningún carné se resuelve y la cafetería se detiene en la hora pico. La lectura (una ruta `SoloConsulta`) escribiría, y el nodo no es dueño de `com.Carne` |
| (c) Identificador en claro | Con una copia de la base, se clonan todos los carnés |

**Detalle de (a):**
1. **Custodia de la llave HMAC (SEG-CORP-06):**
   - doble envoltura (anillo + certificado de recuperación de H-17 v2), valor de control y la regla «sin custodia, no se activa», como la KEK de ADR-67;
   - la llave vive en **`GPOS_SYSDATA`**, con su versión.

   Motivo: un UID EM4100 tiene unos 40 bits (inferido). Con la llave, recorrer ese espacio es trivial.
2. **Rotación (SEG-CORP-16):**
   - solo cuando la llave se compromete, no de forma periódica;
   - la reescribe un proceso de la central a partir de los carnés acertados con la versión vieja, nunca la ruta de lectura;
   - `TR_Carne_Estado` admite cambiar el par (`IdentificadorHmac`, `HmacVersion`) solo hacia una versión mayor;
   - pasados 90 días, los carnés sin migrar se vuelven a registrar.

   Sigue haciendo falta `com.Carne.HmacVersion` ([BP] 12).
3. **Captura (SW-07, sin cambio):**
   - la ráfaga va del prefijo al sufijo y se descarta toda tecla, incluido `Enter`;
   - `Enter` confirma solo después de la ráfaga y 500 ms después de pintar la foto;
   - el formato es estricto por tecnología, sin coincidencia parcial;
   - el QR lleva 128 bits y se entrega una sola vez;
   - el prefijo enruta, no autentica, y se recomienda `F13` a `F24`.
4. **Detección (SEG-CORP-12).** El riesgo residual sigue Medio y es inevitable en la fase 1. RC-05 marca:
   - los consumos en un día en que RR. HH. registra al comensal como ausente (manual en la fase 1);
   - la proporción de lecturas sin prefijo por caja;
   - más de 5 carnés desconocidos seguidos;
   - el mismo carné en dos cajas o en dos sedes en pocos minutos.

   El comensal ve su saldo en cada ticket (F-5) y puede pedir su estado de cuenta (D-05, punto 5).
5. **Criterio de salida a la fase 2:** DESFire **solo** cierra el riesgo con un lector que haga la autenticación mutua y entregue un valor que cambie en cada lectura y que el servidor pueda verificar (por ejemplo, OSDP o USB HID sin emulación de teclado). Un DESFire leído por UID como teclado se clona igual. Costo de referencia (inferido): USD 2 a 4 por carné y USD 100 a 250 por lector.

**Recomendación: (a).** **Costo:** 0,1 sp la custodia y 0,05 sp los umbrales de RC-05 (inferido). La rotación por compromiso cuesta 0, porque es más simple que la migración perezosa.

- [x] (a) · [ ] (b) · [ ] (c)

---

#### D-08 · Contención RG-14 sobre `corp.Consumo`, `corp.Reverso` y `com.Saldo` — seguridad, Media

**Qué se decide:** si la credencial de la aplicación (`gpos_app`) puede reescribir un ticket ya emitido o un saldo fuera de la transacción del ticket.

| Opción | Consecuencia |
|---|---|
| **(a) `DENY UPDATE, DELETE` a `gpos_app` sobre `corp.Consumo` y `corp.Reverso`; cuadre diario de `com.Saldo` contra su libro** | Con la credencial comprometida, no se pueden reescribir los importes, la instantánea F-5, el modo fiscal ni la identidad confirmada. Un `Usado` alterado se detecta en el día |
| (b) [DAT] 9 original: `DENY` solo en las líneas, los pagos y el libro | `TR_Documento_Inmutable` protege `doc.Documento`, pero no su extensión |

**Detalle de (a):**
- `corp.Consumo` y `corp.Reverso` se insertan **completos** dentro de la transacción. La instantánea F-5 sale del `OUTPUT` del `UPDATE` condicional **antes** del `INSERT` del encabezado ([DAT] 4.3).
- Si alguna columna necesitara una escritura posterior, va con un disparador de inmutabilidad como el del documento y un `GRANT UPDATE` por columna, como el de `com.UsoBeneficio.ReversoDocumentoId`.
- **Cuadre diario** (no solo tras restaurar): `com.Saldo.Usado = SUM(com.SaldoMovimiento.Monto)` por saldo. Si no cuadra, deja un aviso y una línea en la bitácora. Lo corre el sitio dueño del saldo (D-15).
- `com.Saldo` mantiene `UPDATE` (el `UPDATE` condicional lo necesita) y `DENY DELETE`.

**Recomendación: (a).** **Costo:** 0,05 sp (inferido).

- [x] (a) · [ ] (b)

---

#### D-09 · Reglas del reverso: servido y posterior al Z (C-11) — seguridad, Media

**Qué se decide:** qué libera un reverso y quién autoriza un reverso tardío.

| Opción | Consecuencia |
|---|---|
| **(a) Solo un reverso de líneas no servidas libera el uso del 100 %; un reverso de otro día o posterior al Z lo autoriza un usuario de la empresa** | Cierra el segundo almuerzo subsidiado (SEG-CORP-10) y el fraude clásico de la devolución de efectivo después del Z (SEG-CORP-11) |
| (b) [BP] y [DAT] originales: todo reverso libera el día y lo autoriza el supervisor del tercero | Cajero y supervisor, de acuerdo, pueden dar dos almuerzos por persona o sacar efectivo de un consumo legítimo |

**Detalle de (a):**
- **Servido = 1:**
  - se revierte el importe (dinero, bolsa) y el kárdex va al borrador de merma, que confirma la empresa (D-01, punto 3);
  - `com.UsoBeneficio.ReversoDocumentoId` **no se llena**: el 100 % del día queda consumido;
  - lo comprueba el disparador del reverso.
- **Reverso de otro día o posterior al Z** de la jornada del ticket: el autorizante debe ser un usuario de la empresa (no externo, D-01). `ConsumoReversableDto.DespuesDelZ` ya existe para que la pantalla lo pida.
- **Reverso con devolución en efectivo dentro de la jornada:** sigue con el supervisor y sale en RC-05 por cajero.

**Recomendación: (a).** **Costo:** 0 sp la regla del servido (dentro de T6) y 0,05 sp el control posterior al Z (inferido, compartido con D-10).

- [x] (a) · [ ] (b)

---

#### D-10 · Contingencia en papel: talonario, quién digita y control del lote (SW-18, UQ-6) — seguridad, Media

**Qué se decide:** cómo se reservan los vales, quién digita el lote y cómo se detecta un vale inventado.

| Opción | Consecuencia |
|---|---|
| **(a) Talonario con rangos reservados por sede (SW-18); el lote lo digita la empresa por omisión (UQ-6); el vale lleva la firma del comensal; se marca como excepción todo vale cuya hora cae en un período en que la sede emitió en línea** | El tercero no puede llenar vales de ausentes durante una caída que no existió |
| (b) El supervisor del tercero digita el lote | Puede inflar su liquidación (RO-3) |
| (c) Vales con cualquier número | Un vale inventado entra como excepción y nada lo detecta |

**Detalle de (a):**
- **SW-18:** el lote solo acepta números de un rango reservado y no usado, una sola vez (`UX_Consumo_Vale`).
- **UQ-6:** `corp-contingencia` es del administrador del beneficio por omisión. Si la empresa se lo da al supervisor del tercero, entra en la lista de permitidos de D-01, pero el lote se marca en RC-05 y la autorización la da un usuario de la empresa.
- **El cruce de horas** usa los tickets en línea de la misma sede y franja. El vale cruzado no se rechaza (R-O5: la venta siempre gana), pero entra con `Excepcion = 1` y sale en RC-05.

**Recomendación: (a).** **Costo:** 0,05 sp el talonario (ya en T10) y el cruce de horas dentro de los 0,05 de D-09. Para la empresa cliente: más trabajo de RR. HH. en los días de corte.

- [x] (a) · [ ] (b) · [ ] (c)

---

#### D-11 · El ticket como vale de comida: copias y reintentos (SW-11, UQ-3) — seguridad, Media

**Qué se decide:** si el ticket sirve para retirar la comida y cómo se cuentan sus copias.

| Opción | Consecuencia |
|---|---|
| **(a) `TicketEsValeRetiro` sí por omisión (UQ-3); la leyenda la pone el motor de impresión; toda impresión del `TCI` y del `RCI` se cuenta en `doc.Impresion`; la copia dice «COPIA n · NO VÁLIDA PARA RETIRAR ALIMENTOS»; un solo reintento como original, y solo si el agente de impresión informó la falla** | Cierra los 3 vales por ticket (SEG-CORP-09) sin frenar la fila |
| (b) SW-11 original: hasta 2 reintentos como original en 10 minutos | El servidor no sabe si la impresora falló (`[NG] ReglasReimpresion.cs:17-21`): hasta 3 vales válidos por ticket |
| (c) Autorización en cada copia (VE-01) | Frena la fila en la hora pico y no cierra el reintento |

**Detalle de (a):**
- El agente de impresión informa el estado ESC/POS (sin papel, tapa abierta, error). Si informó que imprimió, el pedido de reintento sale como «COPIA».
- RC-05 muestra la proporción de reintentos por cajero, con alerta por encima del 2 % de los tickets en una semana.
- En la fase 2, el KDS «quema» el ticket en las sedes grandes.
- Sin el parámetro, la copia dice solo «COPIA n».

**Recomendación: (a).** **Costo:** 0,1 sp (inferido). Puede necesitar un cambio pequeño en `GPOS.AgenteImpresion` para devolver el estado; [BP] 2.3 decía «sin cambios». Lo confirma el arquitecto-software.

- [x] (a) · [ ] (b) · [ ] (c)

---

#### D-12 · Costura fiscal sin opción elegida (SW-03, SW-16, FD-09, FD-10, UQ-9) — diseño

**Qué se decide:** cómo queda lista la costura para cualquier valor de H-04 **sin elegirlo**. Esta hoja **no** decide H-04.

| Opción | Consecuencia |
|---|---|
| **(a) Una estrategia por modo (P0, S1, S2, S6, sin definir); `NULL` = falla cerrada (FD-09); S-1 por la ruta única con el ticket como documento acompañante, con dos caminos y un registrador (SW-03); la marca genérica `ventas.Venta.InventarioDescargadoPorId`, diseñada con B y compartida con el Restaurante (FD-10); con S-1, dos piezas impresas (SW-16, sujeto al contable); no se ofrece «Atender como visitante» de forma automática (UQ-9); el cambio de modo exige la referencia del documento firmado por el cliente (SEG-CORP-20)** | La ventana no cambia con el modo. Nadie cobra dinero del empleado hasta firmar H-04. El cajero nunca elige la ruta fiscal |
| (b) `P0` por omisión | Equivale a elegir P-0, cuyo riesgo es Alto ([HF] 5) |
| (c) E32 en otra transacción, por la bandeja | Deja dinero cobrado sin comprobante si falla ([CONT] 6.6) |
| (d) La vertical arma el E32 por su cuenta | Es la ruta de facturación propia que descarta ADR-112 |

**Precisión de SEG-CORP-20:**
- el motivo del `PUT /api/corporativa/modo-fiscal` exige la **referencia del documento firmado por el cliente** (la firma de H-04 y, con P-0, la aceptación escrita del riesgo de ADR-87);
- en las instalaciones de demostración, el valor se marca «de prueba»;
- la lista de puesta en marcha compara el valor con la firma (PM-03).

**Pendiente si se firma S-2:** la marca de FD-10 es 1:1 y no sirve para un E32 que ampara N tickets. Se resuelve con Datos y B solo si se firma S-2 ([BP] 7.2).

**Recomendación: (a).** **Costo:**
- dentro de T5 (1,2 sp);
- T12 (camino B), +0,5 sp, solo si H-04 = S-1;
- S-2 suma su propio diseño de la marca N:1, sin estimar.

- [x] (a) · [ ] (b) · [ ] (c) · [ ] (d)

---

#### D-13 · Módulos, esquemas, padrón y documentos (SW-01, FD-01, FD-02, FD-08) — diseño

**Qué se decide:** la estructura de código y de datos.

| Opción | Consecuencia |
|---|---|
| **(a)** El módulo `Comensales` en el nivel 5 y `Corporativa` en el nivel 6, con la regla «ninguna vertical depende de otra» (SW-01). Los esquemas `com` (común, sin depender de `corp` ni de `res`) y `corp` (FD-01). Un padrón propio `com.Comensal` con un enlace opcional y único a `rrhh.Empleado`, sin cédula (FD-02). La familia `CIN` con los tipos `TCI` (40) y `RCI` (41), series por sede con los prefijos `CI` y `RC` (FD-08) | Cumple H-02 (a) y ADR-112, punto 6. `rrhh.Empleado` no se inunda ni guarda la cédula del comensal |
| (b) `Comensales` dentro de `Corporativa`; todo en `corp` | Obliga al Restaurante (`CARGO_EMPRESA`) a depender de otra vertical |
| (c) El padrón en `rrhh.Empleado`, o en `res.ClienteEmpleado` | Guarda la cédula y mezcla vendedores con comensales; la Estándar no puede depender de `res` |
| (d) Familia `INV` | Más barata, pero mezcla los tickets con los documentos de inventario |

**Nota:** `com.UsoBeneficio.FranjaId` no lleva una FK a `corp.Franja` (la regla «`com` no referencia a `corp`», [DAT] 10.2). La valida el disparador de emisión de `corp`. Los ids 40 y 41 y el rango 51800 a 51849 se confirman con B (DB-4).

**Recomendación: (a).** **Costo:** dentro de T1 y T2 (2,0 sp).

- [x] (a) · [ ] (b) · [ ] (c) · [ ] (d)

---

#### D-14 · Orden de bloqueos del ticket (SW-04, FD-11) — diseño

**Qué se decide:** el orden de los recursos que toma la emisión, como precisión de ADR-45:
1. jornada;
2. documentos;
3. configuración;
4. series (`TCI`; en el camino B, `FPOS` y después `TCI`);
5. NCF (solo en el camino B);
6. caja;
7. saldos: `com.UsoBeneficio` → `com.Saldo` BM → `com.Saldo` CN;
8. filas de inventario.

| Opción | Consecuencia |
|---|---|
| **(a) El orden de [BP] 7.3, igual en los dos caminos, con una prueba que compara las secuencias con las de la venta** | Sin interbloqueos entre el ticket, la venta del visitante y el E32. Unos 6 ms por emisión con la serie tomada, menos del 1 % del pico de 35 tickets por minuto (inferido) |
| (b) Un orden propio de la vertical | Riesgo de interbloqueo con la venta |

**Recomendación: (a).** **Costo:** 0,2 sp, dentro de T5.

- [x] (a) · [ ] (b)

---

#### D-15 · Nodo de la sede: dueño del saldo, traspaso, custodia del nodo y entrega de llaves (SW-15) — seguridad

**Qué se decide:** cómo funciona la vertical con un nodo de sede y cómo llegan las llaves al nodo.

| Opción | Consecuencia |
|---|---|
| **(a)** La bolsa y la nómina solo en el sitio dueño del saldo; fuera de su sede, solo el 100 % (SW-15). **El traspaso del dueño rige desde el período siguiente**, o cuando la sede vieja confirme su bandeja hasta la fecha del cambio (SEG-CORP-14). **El nodo es un equipo de TI de la empresa:** cuarto cerrado o candado, BitLocker, sin cuentas del tercero y con las carpetas de ADR-77 (SEG-CORP-13). **La entrega de llaves al nodo** (KEK de fotos y llave HMAC) se diseña como **precisión firmada de ADR-67, punto 9**, antes de T11 | Cierra el doble gasto en el cambio de sede y la extracción de llaves en el área del tercero |
| (b) SW-15 original, sin protocolo de traspaso | Durante el cambio de sede hay dos escritores del mismo saldo |
| (c) Consultar el saldo remoto en línea | Depende de la conexión, que es justo lo que falta en la contingencia |

**Por qué hace falta la precisión de ADR-67, punto 9:** [DAT] 5 dice que la DEK de la foto «se envuelve de nuevo para la KEK del nodo». Pero el punto 9 dice que la KEK del nodo **nunca sale del nodo**, así que la central no puede envolver para ella sin otra pieza (una llave de transporte). Esa pieza no está diseñada.

**Recomendación: (a).** **Costo:**
- 0,1 sp el traspaso del dueño, en T11;
- 0,05 sp el diseño de la precisión (inferido);
- 0 USD para el cliente si ya tiene Windows Pro (BitLocker).

La sincronización entera (T11) son 0,4 sp, que ya estaban en [BP].

- [x] (a) · [ ] (b) · [ ] (c)

---

### Bloque B · Lo operativo

#### D-16 · Reparto del almuerzo y la cena (SW-05, FD-06, FD-15)

**Qué se decide:**
- el 100 % exige al menos una línea del **grupo principal** y se asigna de mayor a menor importe (SW-05);
- un artículo está en un solo grupo por franja, y una línea entra completa o no entra; el servidor parte 2 jugos en 1 + 1 (FD-06);
- el reparto se hace sobre el **total con ITBIS** de la línea, y el ITBIS del ticket es informativo y sirve a la costura (FD-15).

| Opción | Consecuencia |
|---|---|
| **(a) Lo de arriba** | Un jugo solo no consume el almuerzo (R-7). El reparto es determinista y se prueba con E-1 a E-7 ([HF] 3.6) |
| (b) Cualquier línea de la composición, en el orden de captura | El cajero decide qué queda al 100 % |

**Recomendación: (a).** **Costo:** dentro del motor (T3, 1,05 sp), con +0,05 sp por el grupo principal.

- [x] (a) · [ ] (b)

#### D-17 · Cobertura y franjas (FD-05, FD-07)

**Qué se decide:**
- la cobertura de la bolsa es 0, 50 o 100 %, y sin fila vale 100 (FD-05);
- un artículo sin franja en la sede no tiene restricción en esa sede, y una franja que cruza la medianoche se asigna a la fecha de inicio (FD-07).

| Opción | Consecuencia |
|---|---|
| **(a) Lo de arriba** | Es la lista firmada en F-2. Ampliarla a 0..100 es una migración trivial |
| (b) Cobertura libre de 0 a 100 desde ya | Nadie la pidió |

**Recomendación: (a).** **Costo:** 0.

- [x] (a) · [ ] (b)

#### D-18 · Bolsa sin proceso de cierre (FD-13)

**Qué se decide:** el mes pasado se cierra por la regla del período vigente, sin escribir nada el día 1, y un proceso idempotente «Asegurar bolsas del mes» corre al arrancar y a las 00:05.

| Opción | Consecuencia |
|---|---|
| **(a) Sin cierre, con «Asegurar bolsas»** | Si el nodo estaba apagado el día 1, no hay nada que recuperar. CA-10 se cumple por construcción |
| (b) Un cierre que escribe el día 1 | Hay que recuperarlo si falla |

**Recomendación: (a).** **Costo:** dentro de T3.

- [x] (a) · [ ] (b)

#### D-19 · El Z: «cada peso cuenta una vez» (SW-12)

**Qué se decide:** un contrato nuevo en el núcleo de caja, `IAporteCierreCaja`, que separa el dinero esperado (entra en el arqueo) de los bloques informativos (no entran). Si un E32 ampara el dinero, lo cuenta `ventas.VentaPago`; si no, `corp.ConsumoPago`. La nómina nunca entra en el arqueo.

| Opción | Consecuencia |
|---|---|
| **(a) `IAporteCierreCaja`** | Sin doble conteo en ninguno de los cuatro modos (CA-08, CA-11) |
| (b) Escribir el dinero del ticket en `caja.Movimiento` | Mezcla el ticket con los movimientos manuales |

**Recomendación: (a).** **Costo:** 0,15 sp en T8. Precisa ADR-112 (sección 8).

- [x] (a) · [ ] (b)

#### D-20 · Corte de nómina (SW-14)

**Qué se decide:**
- el corte se cierra y se exporta en una sola operación idempotente, con la ruta `Esencial`, solo en la central y solo con la sincronización al día;
- **el archivo neutraliza las fórmulas**: se antepone `'` a las celdas que empiezan con `=`, `+`, `-`, `@`, tabulación o retorno;
- la pantalla muestra la huella guardada para que RR. HH. la compare (SEG-CORP-18).

| Opción | Consecuencia |
|---|---|
| **(a) Lo de arriba** | RR. HH. puede cerrar con la licencia vencida. Un nombre importado no se ejecuta como fórmula |
| (b) Ruta `Operativa` | RR. HH. no puede cerrar con la licencia vencida |

**Recomendación: (a).** **Costo:** dentro de T7; la neutralización cuesta menos de 0,05 sp.

- [x] (a) · [ ] (b)

#### D-21 · «No es la persona» desde la caja (UQ-1)

**Qué se decide:** si el cajero bloquea el carné o solo registra la excepción.

| Opción | Consecuencia |
|---|---|
| **(a) Bloqueo preventivo**, con confirmación: solo la transición Activo → Bloqueado con el motivo fijo, por la ruta C-5 `Esencial`. El desbloqueo es de la empresa | Detiene enseguida un carné prestado o clonado. Un bloqueo por error se corrige en AC-04 |
| (b) Solo registrar en RC-05 | El carné prestado sigue funcionando hasta que RR. HH. lo vea |

**Recomendación: (a).** El contrato no cambia con (b). **Costo:** 0.

- [x] (a) · [ ] (b)

#### D-22 · Back-office solo en la Web en la fase 1 (SW-13)

**Qué se decide:** MAUI lleva solo la ventana, el reverso, la reimpresión y el Z. La administración del padrón, las fotos y los beneficios va solo en la Web. Es una diferencia con [UX] 8.3, punto 9.

| Opción | Consecuencia |
|---|---|
| **(a) Solo en la Web.** La foto se carga como archivo, y la cámara de AC-05 queda para la fase 2 | Ahorra unas 0,5 sp (inferido) |
| (b) El back-office también en MAUI, con la cámara | +0,5 sp |

**Recomendación: (a).** **Costo:** −0,5 sp frente a (b).

- [x] (a) · [ ] (b)

#### D-23 · Reportes y minimización (FD-14)

**Qué se decide:**
- las vistas con personas van en `rptc` y la liquidación al administrador (sin personas) va en `rpt` (FD-14);
- RC-01 agrupa **por día y franja por omisión**, con el detalle por línea a pedido y con el mismo privilegio, porque el detalle por línea puede revelar una dieta;
- la pantalla de los motivos libres dice «No escriba datos personales en el motivo»;
- una **prueba automática de CA-13** comprueba que ninguna vista de `rpt` ni de `rptc` depende de `com.ComensalFoto` (consulta a `sys.sql_expression_dependencies`).

| Opción | Consecuencia |
|---|---|
| **(a) Lo de arriba** | El tercero no ve personas. CA-13 deja de depender de una revisión manual |
| (b) Excluir los tipos de la Corporativa de `rpt.Autorizaciones`, en lugar de poner el aviso | Más protector, pero quita esas autorizaciones del reporte común |

**Recomendación: (a).** **Costo:** menos de 0,05 sp, dentro de T9.

- [x] (a) · [ ] (b)

---

### Bloque C · Lo menor

#### D-24 · Cupo de nómina en el ticket (FD-12)

**Contradicción entre agentes:**
- [DAT] propone imprimirlo **sí por omisión**, para que el comensal no pase el cupo sin saberlo;
- [SEG] SEG-CORP-17 propone **no por omisión**, porque expone una deuda del empleado en un papel que puede quedar en la bandeja.

F-5 deja el cupo como opción configurable. **Criterio:** minimización de datos con un costo nulo. El cajero y el comensal lo ven en pantalla al elegir la nómina.

| Opción | Consecuencia |
|---|---|
| **(a) No se imprime por omisión.** Se muestra en pantalla al elegir la nómina, y la empresa lo puede encender | Menos exposición, sin perder la información en el momento del pago |
| (b) Se imprime por omisión (FD-12 original) | Más información en el papel |

**Recomendación: (a).** El dato se guarda siempre. **Costo:** 0.

- [x] (a) · [ ] (b)

#### D-25 · Precios sin flujo de propuestas del tercero (SW-10)

| Opción | Consecuencia |
|---|---|
| **(a) Fase 1 sin flujo:** la empresa registra en las listas del núcleo los precios que propone el tercero, con la bitácora vigente | Cumple la sub-decisión de H-01 sin construir nada |
| (b) Flujo de propuesta y aprobación | +0,4 sp (inferido) |

**Recomendación: (a).** Se agrega si un cliente lo pide. **Costo:** 0.

- [x] (a) · [ ] (b)

#### D-26 · Firma de nómina en el ticket y orden de los medios (UQ-4, UQ-5)

| Opción | Consecuencia |
|---|---|
| **(a)** Una línea de firma por empresa (`FirmaNomina`), **apagada** hasta que el contador responda sobre el art. 201 del Código de Trabajo (UQ-4). El orden de los medios lo fija cada empresa, con **efectivo primero** por omisión (UQ-5) | Nada se decide sin el contador |
| (b) Firma siempre encendida | Más papel y más tiempo en la fila, sin una base legal confirmada |

**Recomendación: (a).** **Costo:** 0.

- [x] (a) · [ ] (b)

#### D-27 · «No usar mi bolsa» (UQ-8)

| Opción | Consecuencia |
|---|---|
| **(a) No en la fase 1** | Una tecla y un caso menos en el reparto, sin que el propietario lo haya pedido |
| (b) Incluirla | ≈ 0,1 sp (inferido) |

**Recomendación: (a).** **Costo:** 0.

- [x] (a) · [ ] (b)

#### D-28 · Carga de la foto: tope de píxeles y biblioteca (SEG-CORP-19)

| Opción | Consecuencia |
|---|---|
| **(a)** Leer el encabezado y rechazar las imágenes de más de 4.000 × 4.000 px antes de decodificar; una carga concurrente por usuario; **SkiaSharp** (licencia MIT, 0 USD), que se actualiza según la política de paquetes | Evita la bomba de descompresión en la API que atiende las cajas |
| (b) ImageSharp | Puede exigir una licencia comercial por encima de cierto ingreso (inferido, sin verificar). Habría que verificarla antes |

**Recomendación: (a).** **Costo:** menos de 0,05 sp y 0 USD.

- [x] (a) · [ ] (b)

---

## 4. Matriz de incorporación de la §6.1 del auditor (para su confirmación)

| Prioridad en [SEG] 6.1 | Hallazgo | Qué pedía | Dónde queda |
|---|---|---|---|
| 1 | SEG-CORP-02 | Externo nunca ADMIN; lista de permitidos en `PermisosService.EfectivosAsync`; inventario de la empresa; CA-09 ampliado | D-01, puntos 1, 2, 3 y 6 |
| 2 | SEG-CORP-07 | Un propósito por tipo; `IdentificacionUid` único; líneas idénticas; `ValidadaEn` sin renovar | D-02, puntos 1, 3, 5 y 6 (y 2, 4 y 7) |
| 3 | SEG-CORP-08 | Autorizante distinto del usuario, por comparación; `doc.Autorizacion` de tipo `SIN_CARNE` | D-01, punto 4; D-03, punto 2 |
| 4 | SEG-CORP-10 | Un reverso servido no libera el 100 % | D-09 |
| 5 | SEG-CORP-15 | `DENY UPDATE, DELETE` en `corp.Consumo` y `corp.Reverso`; cuadre diario del saldo | D-08 |
| 6 | SEG-CORP-09 | Un reintento como original, solo con la falla informada por el agente | D-11 |
| 7 | SEG-CORP-11 | Reverso posterior al Z autorizado por la empresa; cruce de horas del lote | D-09 y D-10 |
| 8 | SEG-CORP-05, 16, 20 | AAD y DEK por escritura; rotación del HMAC solo por compromiso; referencia escrita en el motivo del modo fiscal | D-04, D-07 (punto 2) y D-12 |
| §6.2 | SEG-CORP-05, 06, 03 | DB-8; custodia de la llave HMAC en `GPOS_SYSDATA`; columnas del consentimiento en M1 | Sección 5 (C-T1); D-07, punto 1; D-05 |
| §6.3 | SEG-CORP-13, 14, 04 | Precisión de ADR-67, punto 9; traspaso del dueño; borrado en el nodo | D-15 y D-06, punto 2; sección 5 (C-T11) |
| §6.4 | SEG-CORP-01, 03, 04, 12, 13, 02, 20 | Las siete condiciones del primer cliente | Sección 5, PM-01 a PM-10 |
| Bajas no listadas en 6.1 | SEG-CORP-17, 18, 19 | Minimización, CSV, píxeles | D-03, D-04, D-23, D-24, D-20 y D-28 |

**Costo agregado de las remediaciones:** 1,0 sp, más 0,3 sp si T1 tiene que adelantar el núcleo de ADR-67 (DB-8). Es decir, **1,0 a 1,3 sp**, como estimó el auditor ([SEG] 6.4). Desglose:
- §6.1: 0,4 sp;
- custodia HMAC: 0,1 sp;
- consentimiento: 0,15 sp;
- retención y supresiones: 0,15 sp;
- umbrales de RC-05: 0,05 sp;
- custodia del nodo: 0,05 sp;
- traspaso del dueño: 0,1 sp.

---

## 5. Condiciones comprobables

### 5.1 Antes de construir (puertas de tramo)

| # | Condición | Cómo se comprueba | Responsable |
|---|---|---|---|
| C-T1 | **DB-8:** el núcleo criptográfico de ADR-67 (KEK por empresa, sitio y versión, custodia y valor de control) construido, o construido dentro de T1 con el mismo diseño | La tabla de KEK y su prueba de custodia existen en la rama base de T1; ninguna clase de cifrado propia de `com` | B (ola 3b, bloque 3b-A) o T1 |
| C-T1b | La llave HMAC con la custodia de ADR-67, en `GPOS_SYSDATA` (D-07) | Prueba: sin custodia, el módulo no se activa | T1 |
| C-T11 | **La precisión de ADR-67, punto 9 (llaves al nodo), firmada** (D-15) | Firma del propietario registrada | Maestro → propietario |

### 5.2 Antes del primer cliente (lista de puesta en marcha)

Ninguna se da por cumplida con una declaración: cada una tiene su evidencia.

| # | Condición | Evidencia que la cumple | Responsable |
|---|---|---|---|
| **PM-01** | **DB-7:** el acceso multiempresa v1 (membresía validada en cada petición, ADR-36) **o** una instalación con **una sola empresa habilitada** y sin empresas de prueba ni de demostración (SEG-CORP-01, Alta) | O la prueba de membresía de la v1 aprobada por QA, o la consulta a `GPOS_SYSDATA` que devuelve **1** empresa habilitada, anexada al acta de puesta en marcha. Si después se agrega una empresa sin la v1, la condición se pierde y hay que volver a comprobarla | A (v1) o devops (instalación dedicada) |
| **PM-02** | **DB-8: ADR-67 implementado** (no solo decidido): el estado de implementación de ADR-67 en `master` dice «implementado» en el bloque 3b-A, **o** el núcleo construido en T1 (C-T1) con su prueba de custodia en verde (observación O-1 del auditor) | El ADR-67 de `master`, con su estado; la prueba de custodia en verde | B |
| **PM-03** | **H-04 decidida** por el propietario, y el modo fiscal de la empresa (`corp.Parametros.ModoFiscalPorcion`) **coincide con la firma**, con su referencia en el motivo. Con P-0, el riesgo Alto aceptado por escrito en ADR-87 | La firma de H-04; la consulta del valor y su historia temporal; el motivo con la referencia | Propietario; SUPER |
| **PM-04** | **La respuesta del contador** a CF-1 (y a CC-06, CC-07, CC-10 a CC-13 y UQ-4), recibida y archivada | El documento del contador, citado en la decisión de H-04 | Especialista-contable → propietario |
| **PM-05** | **La revisión legal:** el asesor del cliente confirma la Ley 172-13 (artículos, excepción laboral y **vigencia en 2026**); el aviso informativo, versionado y publicado; las cláusulas de encargado firmadas con el tercero y con GSF; los consentimientos firmados de quienes tienen foto | El dictamen legal; el aviso con su versión en AC-05; los contratos; un muestreo de los consentimientos contra `ConsentimientoFotoEn` | Asesor legal del cliente; empresa cliente |
| **PM-06** | **El simulacro de restauración:** restaurar un respaldo con fotos ya suprimidas demuestra que la lista de supresiones se vuelve a aplicar antes de habilitar la emisión, que la guarda 51330 bloquea hasta reconciliar y que `com.Saldo` cuadra con su libro | Acta del simulacro con los resultados; el plazo máximo de los respaldos con fotos definido y escrito en el aviso | Devops; qa-automatizado |
| PM-07 | CA-09 ampliado (D-01, punto 6) aprobado por QA, y los perfiles del tercero revisados contra la lista de permitidos | Informe de QA; la lista de perfiles exportada | QA; empresa cliente |
| PM-08 | Los umbrales de RC-05 activos, el estado de cuenta del comensal disponible y la revisión mensual de RC-05 por la empresa. **Si el honorario del tercero depende de las comidas servidas** (contrato, H-01), el riesgo del carné pasa a Alto y estos controles son obligatorios | El reporte con los umbrales; el procedimiento firmado por la empresa | Empresa cliente |
| PM-09 | Si hay nodo: bajo la custodia de TI de la empresa, con BitLocker, sin cuentas del tercero y con la entrega de llaves de C-T11 construida | Lista de verificación del nodo firmada por TI del cliente | Devops; TI del cliente |
| PM-10 | El conteo físico periódico de la empresa (D-01, punto 3) programado | El procedimiento del cliente | Empresa cliente |

**PM-01 a PM-06 son las que pidió el propietario. Sin cualquiera de ellas, la recomendación es no poner en marcha.** PM-07 a PM-10 vienen de [SEG] 6.4.

---

## 6. Dependencias con B y estimación actualizada

### 6.1 Dependencias (DB-1 a DB-8)

| # | Dependencia | Dueño | Bloquea | Efecto si no está |
|---|---|---|---|---|
| DB-1 | Mecanismo de verticales, **tramo 3c** (módulo, activación por el SUPER, modo de caja, guarda, `IExtensionVenta`, regla de arquitectura) | B | T4 y T5 | No se puede construir la ventana ni la emisión |
| DB-2 | `GPOS.Componentes` y el `PanelCobro` de Duty Free, con el medio «Nómina» como parámetro aditivo | B (Duty Free) | T4 (parcial) | T4 escribe su propio panel: +0,3 sp |
| DB-3 | FD-10 (`InventarioDescargadoPorId`, compartida con el Restaurante) y los métodos aditivos de `IExtensionVenta` (`SeriesAdicionales`, `RegistrarSaldosAsync`, movimientos del documento acompañante); nota de crédito «reembolsada por un documento acompañante» | B con A | T12 (solo S-1) | El camino A no lo necesita |
| DB-4 | Ids de tipo 40 y 41, rango de errores 51800 a 51849 y los saldos `TD`/`TP` de `CARGO_EMPRESA` | B | Unión | Choques al unir |
| DB-5 | Módulos activos en la introspección de la API de reportes | B | No bloquea T9 | Los reportes RC se verían sin el módulo activo |
| DB-6 | Sincronizador de la entrega 2 (ADR-53) | Quien construya la entrega 2 | T11 | T11 no tiene sobre qué registrarse |
| DB-7 | **Acceso multiempresa v1** | A (según [BP] 13.1; que B lo planifique) | **El primer cliente** (PM-01), no la construcción | Riesgo Alto, salvo la instalación con una sola empresa |
| DB-8 | **Núcleo criptográfico de ADR-67** (ola 3b, bloque 3b-A) | B, o T1 con el mismo diseño | **T1** (C-T1) y el primer cliente (PM-02) | T1 adelanta el núcleo: +0,3 sp que salen de la ola 3b |

### 6.2 Estimación (inferida, ±40 %)

| Concepto | sp |
|---|---|
| Base del blueprint, sin el camino B (T1 a T11) | 8,8 |
| + remediaciones de seguridad (sección 4) | +1,0 |
| **Total sin el camino B** | **9,8** (de 5,9 a 13,7) |
| + DB-8 dentro de T1, si B no lo trae | +0,3 → 10,1 |
| + T12, si H-04 = S-1 | +0,5 |
| **Total con S-1** | **10,3** (de 6,2 a 14,4); **10,6** con DB-8 en T1 |
| Semanas-persona a 1,2 sp por semana | **8,2** sin el camino B; **8,6 a 8,8** con S-1 |
| Con la capacidad común ya construida por [CE] (H-02 (a)) | −1,2 sp en T1 |

**Por qué creció frente a [HF] 8.1 (8,0 sp con S-1):**
- +1,1 sp por lo que encontró el blueprint: la sincronización, los enganches del núcleo, SW-09, el grupo principal, la guarda de los reportes, el talonario y la E34 con reembolso;
- +1,0 a 1,3 sp por la seguridad.

**Licencias e infraestructura de GSF:** 0 adicional; SkiaSharp tiene licencia MIT.

**Para el cliente:**
- un lector de USD 20 a 150 por caja;
- una impresora térmica de USD 150 a 300, si no la tiene;
- un nodo de USD 500 a 1.000 por sede grande;
- un filtro de privacidad opcional de USD 30 a 60 por pantalla;
- el trabajo legal del aviso y de los contratos.

El precio por e-CF de S-1 sigue sin verificar (pedirlo a IQ).

**Opción más barata, si hay que recortar:**
- T11 se aplaza hasta que exista un cliente con nodo: −0,4 sp, junto con su traspaso (−0,1);
- la cámara ya está fuera (D-22).

No recomiendo recortar D-01: el auditor lo rechaza como control procedimental.

### 6.3 Tramo en la entrega 3

- **Ubicación:** un tramo propio **después de 3c**, el mecanismo de verticales (ADR-112 movió el mecanismo de 3a a 3c, `[NG] docs/adr/ADR-112.md:33`). Conviene hacerlo junto a 3d de [CE], porque comparten la capacidad común.
- **T1 puede empezar antes de 3c** si DB-8 está listo.
- **Nada en la entrega 1** (H-11).
- **Efecto en la entrega 3 (inferido):** [HF] la dejaba en unas 45,3 a 47,5 sp. Con esta estimación pasa a unas **47,6 a 50,1 sp**:
  - 38,5 + (10,3 − 1,2) = 47,6 sp, aprovechando la capacidad común;
  - 39,5 + 10,6 = 50,1 sp, sin ella, con S-1 y DB-8 en T1.
- **Lo planifica el orquestador con B** cuando no reste capacidad a la ruta crítica de diciembre.

---

## 7. Nota aparte para B: hallazgo del núcleo actual (SEG-CORP-08)

**No es de la vertical.** Es del núcleo vigente en `feature/modelo-ng` (`ce33b2a8`) y afecta a toda autorización de ADR-68. Lo registro para que B, como coordinador, decida su tratamiento. La vertical ya se protege por su cuenta con D-01, punto 4.

- **Qué pasa (verificado):**
  - `[NG] src/GPOS.Core/Servicios/Nucleo/AutorizacionesSupervisor.cs:73` decide la forma B («propio») solo si no hay usuario o si no hay contraseña y el usuario es el de la sesión;
  - si el cajero escribe **su propio código y su propia contraseña**, el flujo sigue como forma A, valida la credencial y en `:109` devuelve `AutorizacionValidada(…, PorCredencial: true)` con él mismo como autorizante;
  - en `:137` la bitácora lo anota como «(supervisor presente)».
- **Efecto:**
  - un usuario con la acción Autorizar en su perfil queda registrado como si otra persona hubiera estado presente;
  - toda regla que use `PorCredencial` para exigir «otra persona» queda abierta;
  - ningún consumidor de la rama compara al autorizante con la sesión (`git grep` de `Autorizante`, `PorCredencial` y `MISMO_USUARIO` en `src`).
- **Severidad del auditor:** Media.
- **Remediación sugerida, a decidir por B:**
  - en el validador común, si el usuario normalizado es el de la sesión, se trata como forma B (exige el privilegio propio y devuelve `PorCredencial = false`), aunque traiga contraseña;
  - las rutas que exigen otra persona rechazan la forma B, como hará la Corporativa;
  - prueba: la autorización con la propia credencial queda como «privilegio propio» en la bitácora.
- **Costo:** unas 0,05 sp (inferido).
- **ADR:** es una precisión de ADR-68 (sección 8).

---

## 8. ADR y precisiones candidatas (estado: Propuesto)

Los textos completos se redactan para `master` al firmar. Los registra B con el Documentador. Ninguno contradice un ADR vigente.

| ADR | Tipo | Contenido | Puntos |
|---|---|---|---|
| **ADR-45** | Precisión | Orden de bloqueos del ticket interno en los dos caminos; nivel «saldos»: `com.UsoBeneficio` → `com.Saldo` BM → CN | D-14 |
| **ADR-67, punto 9** | Precisión | Entrega de llaves de la central al nodo (KEK de fotos y llave HMAC): quién envuelve, con qué llave de transporte y cómo se rota, sin sacar la KEK del nodo. También: la custodia de la llave HMAC con la doble envoltura y el valor de control | D-15, D-07 |
| **ADR-68** | Precisión | «Otra persona» se comprueba **comparando** al autorizante con el usuario de la sesión, no por `PorCredencial`. Tipos nuevos `REVERSO_CONSUMO` y `SIN_CARNE` en `doc.Autorizacion`. Corrección del núcleo de la sección 7. Conteo de copias del ticket que sirve de vale (precisa VE-01) | D-01, D-03, D-11; sección 7 |
| **ADR-85** (Aceptado) | Precisión | SW-02 v2 (tokens), SW-07 (captura del lector), SW-09 v2 (invariante del externo y lista de permitidos), SW-11 (leyenda y copias), SW-13 (back-office en la Web), reverso posterior al Z autorizado por la empresa | D-01, D-02, D-07, D-09, D-11, D-22 |
| **ADR-87** (Propuesto) | Diseño de la costura | Estrategias por modo, falla cerrada en `NULL`, dos caminos y un registrador, la referencia escrita en el motivo del cambio. **La opción sigue en H-04** | D-12 |
| **ADR-88** (Aceptado) | Precisión | `com` y `corp` (FD-01, FD-02), la foto con su AAD y una DEK por escritura, el consentimiento y la vía sin foto, la retención y la lista de supresiones en `GPOS_SYSDATA`, la llave HMAC en `GPOS_SYSDATA` con su versión y la rotación solo por compromiso | D-04 a D-07, D-13 |
| **ADR-112** | Precisión | Métodos aditivos de `IExtensionVenta` (`SeriesAdicionales`, `RegistrarSaldosAsync`, movimientos del documento acompañante), la extensión interna del documento acompañante (fuera del contrato HTTP) y `IAporteCierreCaja` en `Caja` | D-12, D-19 |

---

## 9. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación o aceptación |
|---|---|---|---|
| R-1 | Un usuario del tercero entra a otra empresa de la instalación | **Alta** | PM-01 |
| R-2 | El tercero recibe poderes de la empresa por un perfil mal hecho | **Alta** sin D-01 | D-01 (invariante y lista de permitidos), PM-07 |
| R-3 | Una identidad reutilizada vacía la bolsa | Media | D-02 |
| R-4 | Carné tecleado o clonado por el cajero | **Media residual, aceptado en la fase 1** (Alta si el honorario depende de las comidas) | D-07 (detección), PM-08; DESFire con lector seguro en la fase 2 |
| R-5 | Fotos: consentimiento, retención y restauración (Ley 172-13) | Media | D-05, D-06, PM-05, PM-06 |
| R-6 | Pérdida de la llave HMAC por perder el anillo | Media (disponibilidad) | D-07, punto 1 |
| R-7 | Reescritura de tickets o saldos con la credencial de la aplicación | Media | D-08 |
| R-8 | 3 vales por ticket; segundo almuerzo por reverso; efectivo sacado tras el Z; vales inventados | Media | D-09, D-10, D-11 |
| R-9 | Doble gasto al cambiar la sede de referencia | Media | D-15 |
| R-10 | La porción pagada sin NCF (si se firma P-0) | **Alta** | H-04 antes del primer cliente (PM-03, PM-04); la costura queda lista |
| R-11 | La entrega 3 crece unas 10 sp | Media | Capacidad común con [CE]; T11 aplazable |
| R-12 | DB-8 llega tarde y T1 adelanta el núcleo de ADR-67 | Media | +0,3 sp con el mismo diseño, nunca una variante (C-T1) |
| R-13 | La Ley 172-13 ya no rige o la excepción laboral se lee distinto | Media | Las medidas de D-05 sirven en las dos lecturas; PM-05 |

**Riesgo residual aceptado explícitamente si se firma:** R-4 en Medio durante la fase 1. Ningún otro se acepta sin su mitigación.

---

## 10. Recomendación y firma

**Recomendación: Aprobar con observaciones.**
- Se firma el diseño con D-01 a D-28 en la opción (a).
- Observación 1: el auditor confirma solo las diferencias de la sección 4.
- Observación 2: PM-01 a PM-06 son requisitos de la puesta en marcha, no del diseño.

H-04 no se toca.

| Casilla | Contenido |
|---|---|
| [ ] **Todo según recomendación** | D-01 a D-28 en (a); condiciones de la sección 5 como requisitos; ADR y precisiones de la sección 8 como propuestos |
| [ ] Firma punto por punto | Según las casillas marcadas en la sección 3 |

Firma: ________________ (propietario) · Fecha: ________

**Si el propietario firma:**
1. El auditor-seguridad confirma la sección 4 (solo las diferencias) y su informe pasa a «Aprobado con observaciones».
2. El arquitecto-datos actualiza [DAT]:
   - `IdentificacionUid`;
   - las columnas del consentimiento y el estado sin foto;
   - el tipo `SIN_CARNE`;
   - el `DENY` en `corp.Consumo` y `corp.Reverso`;
   - el disparador de `HmacVersion`;
   - la lista de supresiones en `GPOS_SYSDATA`;
   - la llave HMAC en `GPOS_SYSDATA`;
   - FD-12 apagado por omisión.
3. El arquitecto-software actualiza [BP]:
   - SW-02 v2 y SW-09 v2;
   - SW-11 con la falla informada por el agente;
   - el reverso servido y el posterior al Z;
   - el traspaso del dueño;
   - el borrador de la precisión de ADR-67, punto 9.
4. B registra las precisiones de la sección 8, recibe la nota de la sección 7 y confirma DB-1, DB-3, DB-4 y DB-8.
5. El orquestador agrega el tramo a la entrega 3, después de 3c.

**Si el propietario rechaza:**
- **D-01 (b) o (c):** el informe de seguridad queda en Rechazado y no se recomienda construir T8. La alternativa mínima aceptable es D-01 sin el punto 3 (inventario), con PM-10 reforzada.
- **D-02 (b):** queda abierta la reutilización de la identidad. Se necesita al menos el punto 3 (`IdentificacionUid`) o la tabla de identificaciones (c).
- **D-05 (b) o (c):** PM-05 lo debe resolver el abogado antes del primer cliente, con el riesgo legal para el cliente.
- **Otros puntos del bloque A:** el agente dueño los reescribe con la opción elegida, sin otra ronda de seguridad salvo D-04, D-06 y D-07.

---

## Resumen: lo que más importa para el propietario

1. **Seguridad: dos textos reescritos que el auditor rechazaba.**
   - **SW-09 (D-01):** el personal del tercero nunca es ADMIN, y su poder sale de una lista cerrada de permitidos, no de una lista de excluidos. Las mermas y los conteos los confirma la empresa, y quien autoriza nunca puede ser el mismo usuario.
   - **SW-02 (D-02):** cada token tiene un solo uso y un solo tipo, y la emisión exige las mismas líneas que se cotizaron.
   - Con esto y con las condiciones de la sección 5, el informe pasa a «Aprobado con observaciones».
2. **La foto (D-05, UQ-7):** el consentimiento es obligatorio y queda registrado con fecha, autor y versión del aviso. Hay una vía sin foto que no quita el beneficio, y el retiro del consentimiento borra la foto en el acto. **Un abogado debe confirmar la Ley 172-13 y si sigue vigente en 2026.**
3. **No se pone en marcha con un cliente sin seis comprobaciones** (PM-01 a PM-06):
   - el acceso multiempresa v1 o una sola empresa habilitada;
   - ADR-67 implementado;
   - H-04 decidida;
   - la respuesta del contador;
   - la revisión legal;
   - un simulacro de restauración.
4. **Costo:** la seguridad suma 1,0 a 1,3 sp. La vertical queda en **9,8 sp sin S-1 y 10,3 a 10,6 sp con S-1** (unas 8,2 a 8,8 semanas-persona). La entrega 3 queda en unas 47,6 a 50,1 sp. Nada en la entrega 1, y 0 USD en licencias para GSF.
5. **Para B (sección 7):** en el núcleo actual, un usuario que escribe su propia contraseña queda registrado como «supervisor presente». No es de la vertical, pero conviene corregirlo en el validador común como precisión de ADR-68.

### Cierre
- Estado: Completado (hoja preparada; D-01 a D-28 **Pendientes de firma**; H-04 sigue abierta y no se decide aquí)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\hoja-firma-diseno-corporativa-2026-10-15.md` (sin commit)
- Supuestos:
  - sp y costos inferidos (±40 %);
  - las normas legales vienen de [SEG], citadas de memoria y sin releer;
  - DB-7 como responsabilidad de A, según [BP] 13.1;
  - DB-8 de B, por la ola 3b;
  - la cifra de la entrega 3 parte de las de [HF] 8.1;
  - D-11 puede necesitar un cambio pequeño en `GPOS.AgenteImpresion` (lo confirma el arquitecto-software).
- Decisiones candidatas a ADR: precisiones de ADR-45, ADR-67 punto 9, ADR-68, ADR-85, ADR-88 y ADR-112; diseño de la costura en ADR-87 (sección 8)
- Entregas a otros agentes:
  - auditor-seguridad → confirmar la sección 4;
  - arquitecto-datos y arquitecto-software → los cambios de la sección 10 tras la firma;
  - devops → el plazo de los respaldos con fotos y la custodia del nodo;
  - especialista-contable → UQ-4 con CF-1;
  - asesor legal del cliente → PM-05;
  - B → la sección 7, DB-1 a DB-8 y el registro de la sección 8;
  - orquestador → el tramo en la entrega 3, después de 3c.
- Próximo paso recomendado: que el propietario firme D-01 a D-28 y que el auditor confirme solo la sección 4.

---

## Confirmación del auditor (2026-10-15)
**Aprobado con observaciones.** Las 12 filas de la matriz de la §4 están conformes y no falta ninguna remediación.
- **O-1, aplicada:** PM-02 acepta también el núcleo de ADR-67 construido en T1, con su prueba de custodia en verde.
- **O-2, condicional:** solo aplica si en D-01 se elige la alternativa mínima, sin el punto 3. En ese caso el procedimiento nombra a la persona de la empresa que confirma el borrador de merma del reverso «servido». Con la recomendación (a) no aplica.

---

## Registro de firma (2026-10-15, sesión de A)

**Respuesta literal del propietario:** «Firmo D-01 a D-28 de la hoja del diseño de la vertical Corporativa según la recomendación (todo en (a)), con D-02 precisado: carné obligatorio en cada consumo nuevo. H-04 sigue abierta.»

- **Firmadas en (a):** D-01 a D-28, incluidas SW-02 v2 y SW-09 v2. D-02 lleva la precisión del propietario: carné en cada consumo nuevo, la lectura vale mientras el consumo está abierto y no hay límite de consumos por día.
- **Seguridad:** el auditor la aprobó con observaciones. O-1 está aplicada en PM-02; O-2 no aplica con D-01 (a).
- **Siguen abiertas:**
  - H-04;
  - las condiciones PM-01 a PM-10, antes del primer cliente;
  - las dependencias DB-1 a DB-8, con B.
- **Precisiones de ADR que salen de esta firma,** para que B las registre: ADR-45, ADR-67 punto 9, ADR-68, ADR-85, ADR-87 (diseño de la costura, sin la opción), ADR-88 y ADR-112.
- **Construcción:** en la entrega 3, en el tramo siguiente a 3c.

---

## Precisión del propietario posterior a la firma (2026-10-15): F-6, cobertura en porcentaje o en monto

**Literal:** «el monto del 50% del subsidio puede no ser también un monto directo aplicado como subsidio no siempre será un valor porcentual.»

**Efecto en D-17 (cobertura y franjas) y en FD-05:**
- **Dos tipos de cobertura.** La cobertura de la bolsa por artículo puede ser un **porcentaje** (0 %, 50 %, 100 % u otro) o un **monto fijo** en pesos. Por ejemplo, la empresa cubre RD$50 de un artículo de RD$120 y el empleado paga RD$70.
- **Tope del monto:** un monto fijo nunca cubre más que el precio de la línea. Si el precio baja por debajo del monto, la cobertura se limita al precio.
- **El monto se aplica por unidad,** multiplicado por la cantidad. El monto de la cobertura y el precio quedan congelados en la línea del ticket.
- **Con la bolsa:** igual que el porcentaje, el monto fijo se descuenta de la bolsa (F-2). Si la bolsa no alcanza, la diferencia la paga el empleado.
- **Modelo:** `corp.Cobertura` lleva un tipo (`PCT` o `MONTO`) y un valor, con restricciones `PCT` entre 0 y 100 y `MONTO` ≥ 0. El reparto de la línea sigue sumando el total (FD-06).
- **Costo:** unas 0,1 sp (inferido). No cambia la seguridad ni las condiciones de puesta en marcha.
