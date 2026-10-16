# [Informe de Seguridad] Revisión del diseño de la vertical Corporativa (entrega 3)

- **Fecha:** 2026-10-15. **Autor:** auditor-seguridad (equipo A). **Tipo:** revisión de diseño. No hay código nuevo.
- **Documentos revisados:**
  - `traspasos/A/hoja-firma-vertical-corporativa-2026-10-15.md` (**[HF]**), firmada salvo H-04;
  - `traspasos/A/datos-vertical-corporativa-2026-10-15.md` (**[DAT]**), FD-01 a FD-15;
  - `traspasos/A/blueprint-vertical-corporativa-2026-10-15.md` (**[BP]**), SW-01 a SW-18 y sección 8;
  - `traspasos/A/ux-vertical-corporativa-2026-10-15.md` (**[UX]**), PV-1 a PV-7 y UQ-7.
- **Código contrastado (solo lectura):** repositorio `GPOS NG`, rama `origin/feature/modelo-ng` en `ce33b2a8` (2026-10-15 18:52), leído con `git show` y `git grep`. Lo cito como `[NG] ruta:línea`. No modifiqué código, bases, configuración ni los documentos revisados. No compilé ni ejecuté pruebas.
- **Etiquetas:** **[V]** verificado en esta sesión, en el código o en el documento citado; **[I]** inferido; **[M]** norma citada de memoria. En esta sesión no tengo acceso a la web, así que **no releí** la Ley 172-13 ni la Constitución (ver 4.3).
- **Estado de la recomendación:** técnica. La decisión es del propietario (C2). SW-01 a SW-18 y FD-01 a FD-15 siguen **Pendientes de firma**.

---

## 1. Alcance y superficie revisada

| Superficie | Dónde | Qué se revisó |
|---|---|---|
| Caja (cajero y supervisor del tercero) | [BP] 6.3 (C-1 a C-14), 8.1, 8.2, 8.4 | Tokens SW-02, lector, foto, sin carné, cotización y emisión, reverso, 409, reimpresión |
| Administración de la empresa | [BP] 6.7, 6.5; [UX] 7 | Padrón, carnés, foto, montos, modo fiscal (solo el SUPER), corte de nómina |
| Reportes | [DAT] 7 y 11; [BP] 6.8 | Vistas `rpt`/`rptc`, datos personales, foto (CA-13) |
| Datos y privilegios | [DAT] 2.5, 2.6, 3, 4, 8, 9 y 10 | Cifrado de la foto, HMAC del carné, concurrencia de saldos, contención RG-14 |
| Nodo y sincronización | [DAT] 5; [BP] 9 | Dueño del saldo, bloqueos prioritarios, uso duplicado, llaves en el nodo |
| Tareas en segundo plano | [DAT] 2.8 y 2.6; [BP] 9.2 | «Asegurar bolsas», borrado de fotos a los 90 días, retención |
| Marco firmado | ADR-32, ADR-36, ADR-43, ADR-44, ADR-67, ADR-68, perfil FIPS, RG-14 | Coherencia del diseño con lo firmado |

**Superficie anónima nueva:** ninguna. Todas las rutas exigen sesión. **Amenaza principal del dominio:** el fraude interno del tercero. Su cajero y su supervisor son a la vez quien despacha, quien confirma la identidad y quien se beneficia de una liquidación inflada ([HF] R-4; [POS] RO-3). Casi todos los hallazgos de integridad parten de ese hecho.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Qué bloquea |
|---|---|---|---|
| **SEG-CORP-01** | **Alta** | DB-7: sin el acceso multiempresa v1, un usuario del tercero entra a las demás empresas de la instalación con sus mismos permisos | El **primer cliente**, no la construcción |
| **SEG-CORP-02** | **Alta** | SW-09 se apoya en una lista de exclusión y en un recorte sin un punto único. El ADMIN tiene cortocircuitos en al menos seis sitios y el inventario (ajustes, mermas, entradas) queda fuera del recorte | La **firma de SW-09** tal como está redactada |
| SEG-CORP-03 | Media | Foto y Ley 172-13: falta el consentimiento documentado, el aviso informativo y una vía sin foto. La casilla de UQ-7 sola no basta | El primer cliente; FD-03 con una condición |
| SEG-CORP-04 | Media | Retención de la foto incompleta: no cubre al personal de servicio sin baja, el borrado en los nodos ni la reaparición tras una restauración. La retención de los respaldos no está definida | El primer cliente |
| SEG-CORP-05 | Media | La construcción de la foto no fija los datos asociados (AAD) al comensal ni a la versión, y depende de ADR-67, que no está implementado | Antes de construir T1 |
| SEG-CORP-06 | Media | La llave HMAC del carné no tiene custodia de recuperación. Si se pierde el anillo, se pierden todos los carnés | Antes de construir T1 |
| SEG-CORP-07 | Media | SW-02: un solo propósito para los tres tokens (confusión de tipo). El token de identificación se puede reutilizar durante 10 minutos y no se exige que las líneas coincidan | La firma de SW-02 |
| SEG-CORP-08 | Media | «Otra persona» no queda garantizada: el validador del núcleo acepta como forma A la credencial del propio usuario, y la autorización sin carné no se guarda | La firma de SW-09 y de FD (columna) |
| SEG-CORP-09 | Media | El ticket como vale: los dos reintentos «por falla de la impresora» salen como original sin que el servidor lo pueda comprobar. Son hasta 3 vales por ticket | La firma de SW-11 |
| SEG-CORP-10 | Media | Un reverso «servido» del almuerzo libera el 100 % del día: permite un segundo almuerzo subsidiado | La firma de FD/SW (regla) |
| SEG-CORP-11 | Media | Reverso de efectivo y lote de contingencia: los cierra solo el tercero, sin un control de la empresa | La firma de SW-18 y de C-11 |
| SEG-CORP-12 | Media | Carné tecleado o clonado por el propio cajero: el residual Medio se confirma, pero faltan los controles de detección y el criterio de salida (DESFire) | Ninguna firma; condiciones del primer cliente |
| SEG-CORP-13 | Media | Nodo en la sede: guarda las fotos, la KEK y la llave HMAC en un equipo que puede estar en el área del tercero. La distribución de llaves al nodo no está diseñada | Antes de T11 |
| SEG-CORP-14 | Media | SW-15: el cambio de sede de referencia traspasa el dueño del saldo sin protocolo y abre una ventana de doble gasto | Antes de T11 |
| SEG-CORP-15 | Media | Contención RG-14: `gpos_app` puede reescribir `corp.Consumo`, `corp.Reverso` y `com.Saldo` después de emitir | La firma de FD (permisos) |
| SEG-CORP-16 | Baja | La rotación de la llave HMAC contradice el disparador `TR_Carne_Estado`, escribe desde una ruta de solo consulta y no puede correr en el nodo | La firma de SW-07/FD-04 (texto) |
| SEG-CORP-17 | Baja | Minimización: foto del comensal de baja (EC-03), búsqueda por nombre del cajero (C-6, C-10), detalle por línea en RC-01, motivo libre en `rpt.Autorizaciones` y cupo de nómina impreso por omisión | No |
| SEG-CORP-18 | Baja | Archivo del corte de nómina sin neutralizar fórmulas (inyección CSV) y verificación de la huella | No |
| SEG-CORP-19 | Baja | Carga de la foto: falta un tope de píxeles antes de decodificar (bomba de descompresión) y la biblioteca de imágenes no está elegida (licencia) | No |
| SEG-CORP-20 | Baja | Modo fiscal: el SUPER (GSF) fija la postura fiscal del cliente sin una referencia obligatoria a la decisión escrita del cliente | No |

**Cuenta:** 2 Altas, 13 Medias, 5 Bajas. Ninguna Crítica.

---

## 3. Checklist OWASP Top 10 (2021)

| Categoría | Resultado | Hallazgos o evidencia |
|---|---|---|
| A01 Control de acceso roto | **Falla** en dos puntos: multiempresa y recorte del ADMIN | SEG-CORP-01, 02, 08, 11; bien: la empresa sale del token ([BP] 6.1), módulo antes que permiso ([BP] 6.1), el modo fiscal solo para el SUPER ([BP] 6.7) |
| A02 Fallas criptográficas | Bien en los algoritmos (AES-256-GCM, HMAC-SHA-256 y Data Protection por omisión, todos aprobados por FIPS); observaciones en la AAD y en la custodia | SEG-CORP-05, 06, 13, 16 |
| A03 Inyección | Bien: formato estricto por tecnología, sin coincidencia parcial, parámetros tipados ([BP] 8.4). Observación: CSV del corte | SEG-CORP-18 |
| A04 Diseño inseguro | Observaciones de fraude interno: vale, reverso, contingencia y carné tecleado | SEG-CORP-09, 10, 11, 12, 14 |
| A05 Configuración de seguridad | Observaciones: la segregación depende de que los perfiles estén bien hechos; el prefijo del lector no es un secreto (correcto, [BP] 8.4) | SEG-CORP-02 |
| A06 Componentes vulnerables | Por decidir: la biblioteca de imágenes | SEG-CORP-19 |
| A07 Identificación y autenticación | Bien: sin credenciales nuevas, tokens atados a usuario, caja, empresa y comensal. Observación: tokens | SEG-CORP-07, 08 |
| A08 Integridad de software y datos | Bien: huella del corte, inmutabilidad del documento, instantánea F-5. Observaciones: contención de `gpos_app` | SEG-CORP-15, 18 |
| A09 Registro y monitoreo | Bien: bitácora de cada vista de la foto, RC-05, la lectura no va a los registros ([BP] 8.4). Faltan umbrales de alerta concretos | SEG-CORP-11, 12 |
| A10 SSRF | **No aplica**: el diseño no hace peticiones salientes con destinos que dé el usuario (el e-CF sale por la ruta única existente) | — |

---

## 4. Hallazgos

### SEG-CORP-01 · Alta · Acceso multiempresa v1 sin construir (DB-7)

- **Riesgo (validado).** Hoy cualquier usuario autenticado puede entrar a cualquier empresa de la instalación, y los usuarios, el nivel ADMIN y los perfiles son globales. Un cajero del tercero, con su perfil de cajero (que incluye `pos` y la apertura de caja, [BP] 8.2), podría operar en otra empresa del mismo dueño: vender, consultar documentos y clientes o abrir su caja. ADR-43 limita la instalación a un solo dueño, así que el alcance son las demás empresas de ese dueño **y las empresas de prueba o demostración** que se creen en la misma instalación.
- **Evidencia:** [NG] `CLAUDE.md:47` (un dueño por instalación), `CLAUDE.md:54` («acceso de cualquier usuario autenticado a cualquier empresa»); [NG] `docs/adr/ADR-036.md:14` (la validación de la membresía en cada petición está decidida, no construida); [BP] 8.3 (línea 488) y 13.1 DB-7 (línea 632).
- **Condición previa (de acuerdo con el arquitecto, con dos precisiones):**
  1. Antes del primer cliente: **o** la versión 1 del acceso multiempresa (membresía por empresa validada en cada petición, ADR-36), **o** una instalación dedicada **con una sola empresa** y sin empresas de prueba ni de demostración.
  2. La segunda vía se verifica en la lista de puesta en marcha con un dato, no con una declaración: el número de empresas habilitadas en `GPOS_SYSDATA` debe ser 1. Si después se agrega una empresa sin la v1, el riesgo vuelve.
- **No bloquea la construcción** (todo es desarrollo). **Costo:** la v1 ya está estimada en su propio tramo; la vía de la instalación dedicada cuesta 0 sp.

### SEG-CORP-02 · Alta · El recorte del personal externo (SW-09) no es un control cerrado

- **Riesgo.** SW-09 propone recortar, para las cuentas marcadas como externas, el nivel ADMIN y una lista de privilegios (`com-*`, `corp-beneficios`, `corp-nomina`, precios y listas) «aunque un perfil se los dé». Tiene tres huecos:
  1. **El ADMIN entra por muchas puertas.** El servidor no calcula el nivel en un solo punto. Si el recorte se pone en uno y se olvida otro, el externo con ADMIN conserva sus poderes. Además, un externo con ADMIN puede **autorizar** cualquier operación de otro cajero, porque el autorizador da el privilegio por el nivel.
  2. **Es una lista de exclusión.** No cubre los privilegios del núcleo que más importan en una cafetería: ajustes y mermas de inventario, entradas, conteo, conduces, maestros de artículos, usuarios y perfiles, formatos y numeración. Un perfil mal hecho que le dé al tercero «ajustes» le permite justificar como merma lo que falta. También le dejaría sin cubrir cualquier privilegio que se agregue en el futuro.
  3. **La segregación del inventario no está definida.** [DAT] 2.13 crea un borrador de merma en el reverso «servido» que «confirma el encargado», pero no dice quién es el encargado. Si el tercero registra las entradas, confirma las mermas y vende, el costo de la comida solo lo controla un conteo físico de la empresa, y ese conteo no está previsto.
- **Evidencia [V]:** [NG] `src/GPOS.Contracts/Seguridad/Permisos.cs:45`; cortocircuitos del ADMIN en `src/GPOS.Api/Seguridad/Seguridad.cs:111`, `:158`, `:176-188`, `src/GPOS.Api/Seguridad/PermisosServidor.cs:45` y `:65`, `src/GPOS.Api/Seguridad/FiltroCostos.cs:26`, y `src/GPOS.Core/Sistema/AutorizadorSupervisor.cs:39-40` (`mapa.EsAdmin || …`); [BP] 8.2 (línea 479); [DAT] 2.13.
- **Remediación (para el texto de SW-09):**
  1. **Invariante en la cuenta:** una cuenta (y, cuando exista, una membresía) marcada «Personal del administrador externo» **nunca** tiene nivel ADMIN ni SUPER. La regla vale en el alta, en la edición y en la emisión del token, y la `RevocacionSesiones` vigente invalida un token con un nivel mayor. Si el almacén lo permite, también como `CHECK` en la tabla de usuarios. Así el nivel del token es USER, y los cortocircuitos de la lista anterior nunca se activan para un externo.
  2. **Lista de permitidos, no de excluidos,** aplicada en `PermisosService.EfectivosAsync`, que es la fuente común del mapa de la sesión y del autorizador. Lo único permitido: `corp-consumo`, `corp-reverso`, `pos`, apertura y cuadre de su caja, `rep-corporativa` y, si la empresa lo decide, `corp-contingencia`. Todo lo demás se descarta aunque un perfil lo dé (falla cerrada), y deja una línea en la bitácora y en RC-05.
  3. **El inventario, de la empresa:** las mermas, los ajustes y el cierre del conteo los confirma un usuario de la empresa. El tercero solo puede registrar borradores. Se agrega a H-09 un conteo físico periódico de la empresa (por ejemplo, semanal en los artículos de mayor costo). Cuesta 0 sp en el sistema: ya existen el conteo ciego y los borradores.
  4. **Prueba:** CA-09 se amplía con un perfil que concede de más (incluidos ADMIN y «ajustes») y con un externo que intenta autorizar.
- **Costo:** unas 0,25 sp en lugar de 0,2 (inferido). **Alternativa descartada:** el control solo procedimental, porque depende de que nadie se equivoque al armar un perfil, y el error no se ve hasta la auditoría.

### SEG-CORP-03 · Media · Foto, Ley 172-13 y UQ-7: consentimiento documentado, aviso y vía sin foto

**Conclusión técnica (sujeta a la confirmación de un abogado, ver 4.3).**
1. **¿Es la foto un dato sensible?** Según la definición de la Ley 172-13 [M], **no lo es por sí misma**. Esa definición enumera el origen racial o étnico, las opiniones políticas, las convicciones religiosas, filosóficas o morales, la afiliación sindical y la información sobre la salud o la vida sexual. La foto es un **dato personal** (la imagen identifica a la persona) y la Constitución protege la **propia imagen** (art. 44 [M]). Dos matices:
   - una foto puede revelar de forma incidental un dato sensible (el origen étnico o un atuendo religioso), así que se trata con cuidados equivalentes a los de un dato sensible, que es lo que el diseño ya hace;
   - el diseño solo prevé la **comparación visual por una persona**. Si algún día se agrega el reconocimiento facial automático, la foto pasa a usarse como dato biométrico y hay que repetir esta revisión.
2. **¿Hace falta un consentimiento?** La regla general de la ley es el consentimiento libre, expreso e informado, por escrito o por un medio equivalente. La ley prevé excepciones para los datos necesarios en una relación contractual o laboral [M]. Esa excepción **puede** cubrir a los empleados, pero **no cubre al personal de servicio**, que no es empleado de la empresa ([DAT] 2.3, punto 4). Además, en una relación laboral el consentimiento difícilmente es «libre» si negarlo deja sin el beneficio.
3. **Respuesta a UQ-7:** **sí, la casilla debe ser obligatoria**, pero sola no basta. La opción que resiste las dos lecturas de la ley, y es barata, tiene cuatro partes:
   - **Consentimiento informado por escrito**, firmado en papel o en un formulario que guarda RR. HH. En el sistema se registran `ConsentimientoFotoEn`, `ConsentimientoFotoRegistradoPor` y `VersionAviso`, y sin ese registro no se puede cargar la foto. Una casilla sin la fecha, sin quién la marcó y sin la versión del texto no prueba nada.
   - **Aviso informativo** (versión numerada) con:
     - la finalidad (identificar al comensal en la cafetería y controlar el beneficio);
     - el responsable (la empresa);
     - los encargados (el tercero, que ve la foto en la caja, y GSF como proveedor con acceso de soporte);
     - la conservación (hasta 90 días después de la baja, y en los respaldos hasta que vencen, ver SEG-CORP-04);
     - los derechos de acceso, rectificación, supresión y oposición, y dónde se ejercen (RR. HH.).
   - **Vía sin foto** para quien no consiente o retira el consentimiento. La retirada **borra la foto en el acto**, sin esperar los 90 días. Hoy, sin foto, cada consumo exige la autorización de otra persona (EC-04, [UX] 528). Si esa identificación cuenta para el tope duro de 3 por mes (SW-17), quien no da su foto pierde el beneficio desde el cuarto consumo, y entonces el consentimiento no es libre. Propuesta: un estado «sin foto por decisión del titular» que exige la autorización de otra persona en cada consumo, **no cuenta para el tope de 3** y sale aparte en RC-05. En la fase 2 lo sustituye el PIN.
   - **Contratos:** una cláusula de encargado del tratamiento en el contrato con el tercero (confidencialidad, uso solo para la finalidad, sin copias, sin fotos de la pantalla) y otra en el contrato de GSF con el cliente.
4. **Derecho de acceso:** se agrega en AC-02 una impresión «Datos del comensal», que entrega al titular sus datos, sus consumos, sus saldos y si tiene foto (y se la muestra en pantalla, sin exportarla). La rectificación (cambiar la foto o el nombre) y la supresión de la foto ya existen. Los tickets no se suprimen porque los ampara la obligación de conservación (MD-61), pero no contienen la foto.
- **Evidencia:** [HF] H-08 (líneas 368 y 625, R-5); [UX] AC-05 (línea 714) y UQ-7 (línea 940); [UX] EC-04 (línea 528); [BP] SW-17 (línea 693); [DAT] 2.3.
- **Costo:** unas 0,15 sp (las columnas en M1, la vía sin foto y la impresión de AC-02, inferido). El aviso y las cláusulas los redacta el abogado del cliente, con un costo legal que no estimo.

### SEG-CORP-04 · Media · Retención de la foto: disparadores, nodos, restauración y respaldos

- **Riesgo:**
  1. El borrado depende de `FechaBaja`. El personal de servicio cuyo contrato termina suele quedar con el carné **vencido** pero sin baja, y su foto se conservaría sin límite.
  2. [BP] 9.2 no dice cómo llega el borrado al nodo: el nodo conservaría la foto.
  3. **Una restauración devuelve las fotos ya borradas**, y también las suprimidas a pedido del titular, porque la bitácora del borrado vive en la misma base restaurada.
  4. La retención de los respaldos no está definida: la política sembrada es de 7 días y se iba a corregir. Sin un plazo, «hasta que vencen» no se le puede informar al titular.
- **Evidencia:** [DAT] 2.6 (línea 112) y 8 (línea 321); [BP] 8.5 (línea 504) y 9.2 (líneas 526-540); [NG] `docs/operaciones/2026-10-04-prepiloto-respaldos.md:12` y `:64`.
- **Remediación:**
  1. El trabajo de retención también borra la foto cuando el carné está vencido o no hay ningún carné activo y no hubo consumo en `DiasBorradoFoto` días.
  2. El borrado viaja al nodo en la **clase de seguridad**, igual que los bloqueos (5 minutos p95), y el nodo lo aplica con un `DELETE` físico.
  3. **Lista de supresiones fuera de la base de la empresa.** Se guarda en `GPOS_SYSDATA`, con el comensal, la versión de la foto, la fecha y el motivo, sin la imagen. La reconciliación posterior a una restauración (guarda 51330, MD-59) vuelve a aplicarla antes de habilitar la emisión. El trabajo de retención también corre al arrancar y es idempotente.
  4. **Plazo máximo de los respaldos** con fotos: lo fija devops, por ejemplo 35 días en los rutinarios. Ese plazo va en el aviso. Si se guardan respaldos de largo plazo, también se informa.
- **Alternativa descartada:** el borrado criptográfico (una KEK de fotos por período que se destruye). Choca con ADR-67, punto 3 («ninguna versión se destruye»), obliga a volver a envolver las fotos vigentes y cuesta más que la lista de supresiones.
- **Costo:** unas 0,15 sp (inferido) y 0 USD.

### SEG-CORP-05 · Media · Construcción criptográfica de la foto: AAD y dependencia de ADR-67

- **Riesgo:**
  1. [DAT] 2.6 dice «la construcción de ADR-67, punto 3», pero no fija qué datos asociados autentica el cifrado. Si la AAD no incluye el comensal y la versión, alguien con escritura en la base (un DBA o la credencial de la aplicación comprometida) puede **cambiar el texto cifrado de una fila por el de otra**. Como el contenido es válido, se descifra sin error y la caja muestra la cara de otra persona.
  2. «Cambiarla sobrescribe el contenido»: hay que exigir una DEK nueva en cada escritura. Si se reutiliza la DEK con otro nonce o, peor, con el mismo, se pierde la garantía de GCM.
  3. ADR-67 está **decidido, no implementado** (ola 3b, bloque 3b-A). T1 no puede cifrar la foto sin la tabla de KEK, la custodia y el valor de control.
- **Evidencia:** [DAT] 2.6 (líneas 108-112) y DDL (líneas 435-445); [NG] `docs/adr/ADR-067.md:5` (estado de implementación) y `:12` (punto 3).
- **Remediación:**
  - AAD = identificador inmutable de la empresa + `ComensalId` + `VersionFoto` + la etiqueta `com.foto.v1`;
  - una DEK nueva por escritura;
  - al servir la foto, comprobar que la `VersionFoto` descifrada coincide con la del `LecturaToken`;
  - nueva dependencia **DB-8**: el núcleo criptográfico de ADR-67 (KEK por empresa, sitio y versión, con custodia) construido antes de T1, o construido en T1 con el mismo diseño, sin una variante propia.
- **Costo:** 0 sp, porque es especificación. Si T1 tiene que adelantar el núcleo de ADR-67, son unas 0,3 sp que salen de la ola 3b (inferido).

### SEG-CORP-06 · Media · Llave HMAC del carné sin custodia de recuperación

- **Riesgo.** La llave se genera al activar el módulo y se guarda envuelta solo con el anillo del sitio ([BP] 8.6). Si el anillo se pierde (por ejemplo, al restaurar en otro equipo), **ningún carné vuelve a resolverse**. Los QR se reimprimen. Los carnés de proximidad hay que volver a registrarlos uno por uno, y la cafetería se detiene en la hora pico. Es un riesgo de disponibilidad, no de confidencialidad.
- **Evidencia:** [BP] 8.6 (línea 510); [NG] `docs/adr/ADR-067.md:12` (la KEK de los adjuntos sí tiene la doble envoltura).
- **Remediación:** la misma custodia que la KEK de ADR-67, es decir, la doble envoltura (anillo y certificado de recuperación de H-17 v2), el valor de control y «sin custodia, no se activa». La llave vive en `GPOS_SYSDATA` con la versión, no en la base de la empresa, para que un respaldo robado de la base de la empresa no traiga la llave al lado.
- **Por qué importa la ubicación:** el HMAC solo protege si la llave no se filtra junto con la base. El identificador de un carné de 125 kHz tipo EM4100 tiene unos 40 bits [I]. Con la llave, recorrer ese espacio es trivial, y se recuperarían todos los identificadores para clonarlos.
- **Costo:** unas 0,1 sp (inferido).

### SEG-CORP-07 · Media · SW-02: tipo, reutilización y contenido de los tokens

**Lo que está bien [V]:**
- Data Protection usa sus algoritmos por omisión, porque no hay ninguna configuración de algoritmos: AES-256-CBC con HMAC-SHA-256, cifrado autenticado y aprobado en el perfil FIPS (documentación de Microsoft).
- El anillo es del sitio ([NG] `src/GPOS.Core/Infraestructura/Anillo/AnilloDataProtection.cs:277`).
- La caja no puede leer ni alterar el contenido (el saldo visto viaja dentro del token).
- Las vidas son cortas (2, 10 y 3 minutos).

**Riesgos:**
1. **Un solo propósito** (`GPOS.Corporativa.Caja.v1` + la empresa) para los tres tokens. Si los contenidos se parecen y la deserialización es tolerante, un token de lectura podría aceptarse como token de identificación. Eso salta «Confirmar identidad» (CA-01) y deja un `IdentidadConfirmadaPor` que no corresponde a ningún acto.
2. **El token de identificación se puede reutilizar** durante 10 minutos: con una sola lectura del carné se pueden emitir varios tickets del mismo comensal y vaciar su bolsa sin que la persona vuelva a presentarse. El índice de `UsoBeneficio` solo protege el almuerzo, no la bolsa.
3. «Máximo 3 lecturas por token» de la foto exige un estado, y el diseño dice que los tokens «no se guardan». Falta decir dónde vive ese contador.
4. La emisión recibe otra vez las líneas además del `CotizacionToken`. Falta la regla de que deben coincidir con la huella del token; si no, la `ValidadaEn` de una línea podría aplicarse a otra.
5. La gracia de 3 minutos de SW-06 debe medirse desde la primera validación de la línea, sin renovarla al recotizar con `CotizacionAnterior`.

**Evidencia:** [BP] 8.1 (línea 469), DTO de C-2, C-4, C-8 y C-9 (líneas 244-296), 5.4 (línea 189) y 8.5 (línea 501).

**Remediación:**
- un propósito por tipo (`…Caja.Lectura.v1`, `…Identificacion.v1`, `…Cotizacion.v1`) y un campo `tipo` obligatorio;
- un `Id` aleatorio en cada token;
- **identificación de un solo uso en la emisión**: columna `corp.Consumo.IdentificacionUid` con un índice único, de modo que un segundo ticket con el mismo token responde 409 y la caja vuelve a leer el carné. Es persistente, no necesita una tabla nueva y viaja con el ticket;
- el contador de lecturas de la foto en memoria del sitio, por el `Id` del token (se pierde al reiniciar, lo que es aceptable con 2 minutos de vida);
- emisión con las líneas idénticas a las del token: si no, 409 `REPARTO_CAMBIO`;
- `ValidadaEn` nunca se renueva desde un token;
- los tokens atados también a la sesión (`sid`) y, el de cotización, a la jornada;
- la búsqueda por la clave de idempotencia, limitada al mismo usuario, la misma caja y la misma empresa.

**Costo:** unas 0,1 sp (inferido).

### SEG-CORP-08 · Media · La regla «otra persona» y la autorización sin carné

- **Riesgo [V].** El validador del núcleo trata como forma B («privilegio propio») solo el caso sin contraseña. Si el usuario escribe **su propio código y su propia contraseña**, el validador lo trata como forma A y devuelve `PorCredencial = true` con él mismo como autorizante. Un supervisor que cobra en la caja podría autorizar su propio reverso o su propia identificación sin carné. Además:
  - la identificación sin carné (C-7) no es un documento, y [DAT] no tiene ninguna columna que guarde **quién la autorizó**: `corp.Consumo` solo guarda quién confirmó la identidad, y el disparador 51820 cubre el reverso, no esto;
  - la contraseña del supervisor se escribe en el equipo del cajero, que puede verla.
- **Evidencia:** [NG] `src/GPOS.Core/Servicios/Nucleo/AutorizacionesSupervisor.cs:73` y `:109`; [BP] 8.2 (línea 480); [DAT] DDL de `corp.Consumo` (líneas 609-653) y 3 (regla 51820).
- **Remediación:**
  1. La regla de la Corporativa compara `AutorizacionValidada.Autorizante` con el usuario de la sesión (normalizados) y rechaza si coinciden: 422 `AUTORIZANTE_MISMO_USUARIO`. Mirar `PorCredencial` no basta.
  2. La autorización sin carné se guarda al emitir como `doc.Autorizacion` de un tipo nuevo `SIN_CARNE` (amplía `CK_Autorizacion_Tipo`), y el disparador exige que el autorizante sea distinto de `IdentidadConfirmadaPor`.
  3. RC-05 marca las autorizaciones de un supervisor que no tenía sesión ni jornada abierta en esa sede a esa hora: es la señal de una contraseña aprendida.
- **Costo:** unas 0,05 sp (inferido).

### SEG-CORP-09 · Media · El ticket como vale de comida y los reintentos de impresión

- **Riesgo [V].** Con `TicketEsValeRetiro`, el ticket impreso es lo que se cambia por la comida. SW-11 marca las copias como «NO VÁLIDA PARA RETIRAR ALIMENTOS», pero el reintento por falla de la impresora sale **como original** hasta 2 veces en 10 minutos, y el servidor no sabe si la impresora falló. Un cajero puede obtener hasta 3 vales válidos por ticket. El inventario baja una sola vez: las dos comidas de más aparecen como faltante y vuelven a SEG-CORP-02, punto 3. Además, el despachador de la línea no puede distinguir un vale verdadero de uno impreso aparte.
- **Evidencia:** [NG] `src/GPOS.Core/Servicios/Nucleo/ReglasReimpresion.cs:17-21` («El servidor no sabe si la impresora falló»); [BP] 10.2 (líneas 557-561).
- **Remediación:**
  - para el `TCI` con `TicketEsValeRetiro`, un solo reintento como original, y solo si el agente de impresión informó la falla (el estado de la impresora ESC/POS: sin papel, tapa abierta o error). Si el agente informó que imprimió, el pedido de reintento sale como «COPIA»;
  - RC-05 con la proporción de reintentos por cajero y un umbral de alerta, por ejemplo más del 2 % de los tickets en una semana;
  - para las sedes grandes, la fase 2 despacha contra la pantalla (KDS), que «quema» el ticket.
- **Alternativa descartada:** pedir una autorización en cada copia. Frena la fila y no cierra el reintento.
- **Costo:** unas 0,1 sp (inferido).

### SEG-CORP-10 · Media · El reverso «servido» del almuerzo libera el 100 % del día

- **Riesgo.** El reverso escribe `com.UsoBeneficio.ReversoDocumentoId`, y el índice único filtrado deja de contar ese uso, así que el comensal puede tomar otro almuerzo al 100 % el mismo día. Si la comida **sí se sirvió** (`Servido = 1`), cajero y supervisor pueden, de acuerdo, dar dos almuerzos subsidiados por persona. Queda en RC-05, pero nada lo impide.
- **Evidencia:** [DAT] DDL de `com.UsoBeneficio` (líneas 499-509), `corp.ReversoLinea.Servido` (línea 740) y 2.13; [HF] H-06 (a).
- **Remediación:** solo un reverso de líneas **no servidas** libera el uso del beneficio. Con `Servido = 1`, el uso queda consumido: se revierte el importe y el kárdex va a la merma, pero no se libera el 100 % del día. Se comprueba en el disparador del reverso.
- **Costo:** 0 sp (es una regla dentro de T6).

### SEG-CORP-11 · Media · Reverso de efectivo y lote de contingencia sin control de la empresa

- **Riesgo:**
  1. El reverso de un consumo pagado en efectivo devuelve dinero de la caja con la autorización de otra persona, pero las dos personas son del tercero. Es el fraude clásico de la devolución: se reversa un consumo legítimo y el efectivo sale de la caja.
  2. El lote de contingencia se digita con vales de un talonario reservado (SW-18). Si la empresa le da `corp-contingencia` al supervisor del tercero (UQ-6), este puede llenar vales de comensales ausentes durante una caída que no existió.
- **Evidencia:** [BP] 6.3 (C-11 y C-12, líneas 232-233), 6.4 y 6.2 (línea 208); [DAT] 5 (línea 273).
- **Remediación:**
  - un reverso **de otro día o posterior al Z** de la jornada lo autoriza un usuario de la empresa, no uno externo;
  - el reverso con devolución en efectivo dentro de la jornada sigue con el supervisor y sale en RC-05 por cajero;
  - el lote marca como excepción todo vale cuya hora cae en un período en que esa sede emitió tickets en línea, porque es la prueba de que el sistema funcionaba;
  - se mantiene la recomendación de que el lote lo digite la empresa (UQ-6) y se pide que el vale lleve la firma del comensal.
- **Costo:** unas 0,05 sp (inferido).

### SEG-CORP-12 · Media · Carné de proximidad o QR tecleado o clonado por el cajero

**Validación de 8.4 (lector como teclado):**
- **Inyección de teclas: cerrada.** La captura descarta toda tecla entre el prefijo y el sufijo, incluido `Enter`. Además, `Enter` solo confirma si llega después de la ráfaga y 500 ms después de pintar la foto. Lo doy por correcto.
- **Formato estricto y sin coincidencia parcial: correcto.** Las expresiones de [BP] 8.4 están acotadas y el servidor no busca nada si el formato falla.
- **El prefijo como enrutamiento, no como autenticidad: correcto.** Coincido con la recomendación de usar `F13` a `F24` o un carácter de control.
- **Riesgo residual Medio: lo confirmo.** El atacante relevante **no es** un extraño, sino el **propio cajero**. Para la API, una lectura y un tecleo son iguales. El cajero puede presentar el identificador de un empleado ausente y luego confirmar él mismo la foto. Los tres tipos de carné tienen este problema:
  - el de 125 kHz y el Mifare por UID se clonan con equipo barato, y los carnés de control de acceso que la empresa ya tiene suelen llevar **el número impreso y en rangos seguidos** [I];
  - el QR de 128 bits impide adivinarlo, pero **no impide copiarlo**: basta una foto del plástico, que además está a la vista de la fila.

**Riesgo concreto:** almuerzos al 100 % y consumos de la bolsa de empleados ausentes. La empresa paga la comida y la liquidación del tercero se infla.

**Remediación (detección, porque en la fase 1 no se puede prevenir):**
1. RC-05 con umbrales concretos:
   - consumos de un comensal en un día en que RR. HH. lo registra ausente (manual en la fase 1; conciliación con la asistencia en la fase 2);
   - proporción de lecturas «sin prefijo» por caja, cuando la caja usa el tiempo entre teclas;
   - más de 5 carnés desconocidos seguidos (ya está).
2. El comensal ve su saldo en cada ticket (F-5). Se suma la impresión «Datos del comensal» (SEG-CORP-03, punto 4) como estado de cuenta a pedido, para que el empleado detecte consumos que no hizo.
3. **Criterio de salida a la fase 2:** DESFire solo cierra el riesgo si el lector **no** entrega un valor fijo como teclado. Hace falta un lector que haga la autenticación mutua con el carné y entregue al servidor un valor que cambie en cada lectura y que el servidor pueda verificar (por ejemplo, por OSDP o por USB HID sin emulación de teclado). Un DESFire leído por UID como teclado se clona igual que un Mifare. Costo de referencia (inferido): carné DESFire EV3 de USD 2 a 4 frente a USD 0,3 a 0,5 del EM4100, y lector con salida segura de USD 100 a 250.
4. **Condición:** si el honorario del tercero depende del número de comidas servidas (lo dice el contrato, H-01), este riesgo pasa a **Alto** para ese cliente. Antes de la puesta en marcha hay que exigir los puntos 1 y 2 operando y la revisión mensual de RC-05 por la empresa.

**Evidencia:** [BP] 8.4 (líneas 490-497); [UX] 6.3 (líneas 620-627); [HF] R-4 (línea 623).

**Costo:** unas 0,05 sp de umbrales dentro de RC-05 (inferido).

### SEG-CORP-13 · Media · Custodia del nodo de la sede y distribución de llaves

- **Riesgo:**
  1. Un nodo guarda las fotos de su sede, la KEK, la llave HMAC y su anillo. Si el equipo está físicamente en el área del tercero o con una cuenta de administrador del tercero, quien lo controla puede extraer el anillo y descifrar las fotos, y con la llave HMAC puede recuperar los identificadores de 125 kHz (SEG-CORP-06).
  2. [DAT] 5 dice que la DEK de la foto «se envuelve de nuevo para la KEK del nodo, como ADR-67, punto 9, en sentido inverso». Pero ADR-67, punto 9, dice que **la KEK del nodo nunca sale del nodo**. Entonces la central no puede envolver para esa KEK sin otra pieza. Ni esa pieza ni el envío de la llave HMAC «envuelta para el nodo» están diseñados.
- **Evidencia:** [DAT] 5 (líneas 266-267); [BP] 9.2 (líneas 531-532); [NG] `docs/adr/ADR-067.md:25`.
- **Remediación:**
  - el nodo es un equipo de TI de la empresa: en un cuarto cerrado o con un candado físico, con BitLocker y sin cuentas del tercero, con las carpetas protegidas de ADR-77;
  - la entrega de llaves al nodo (KEK de fotos e HMAC) se diseña como **precisión firmada de ADR-67, punto 9** (quién envuelve, con qué llave de transporte y cómo se rota), antes de T11 y sin una construcción nueva sin revisar.
- **Costo:** 0 USD para el cliente si ya tiene Windows Pro (BitLocker); unas 0,05 sp de diseño (inferido).

### SEG-CORP-14 · Media · SW-15: cambio de la sede de referencia y doble gasto

- **Lo que está bien.** Que el saldo lo escriba **solo el sitio de la sede de referencia** es el control correcto contra el doble gasto entre sitios. También son correctos el 100 % fuera de la sede con la marca local, el uso duplicado como `Excepcion = 1` en RC-05 sin revertir lo servido (ADR-53, cláusula 5) y los bloqueos en la clase de seguridad.
- **Riesgo.** El cambio de `SedeReferenciaId` en `com.ComensalAsignacion` (maestro de la central) mueve el dueño del saldo. Si la sede vieja no subió su bandeja, durante un tiempo hay **dos escritores** del mismo saldo: un nodo aislado sigue consumiendo una bolsa que la central ya entregó a otro sitio.
- **Evidencia:** [DAT] 2.4 y 5 (línea 269); [BP] 9.2 (línea 533).
- **Remediación:** el traspaso de dueño rige desde el **período siguiente** (el día 1 o el siguiente período de nómina), o cuando la sede vieja confirme su bandeja hasta la fecha del cambio. Mientras tanto, la sede nueva atiende como «fuera de su sede» (100 % sí, bolsa no). La regla se prueba con un nodo aislado.
- **Costo:** unas 0,1 sp en T11 (inferido).

### SEG-CORP-15 · Media · Contención RG-14: escritura de `gpos_app` después de emitir

- **Riesgo.** [DAT] 9 niega `UPDATE` y `DELETE` en las líneas, los pagos y el libro, pero **no** en `corp.Consumo` ni en `corp.Reverso` (los importes, la instantánea F-5, el modo fiscal y la identidad confirmada). Tampoco limita las escrituras en `com.Saldo` fuera de la transacción del ticket. Con la credencial de la aplicación comprometida, se pueden reescribir los importes de un ticket ya emitido o el `Usado` de una bolsa sin dejar un movimiento. `TR_Documento_Inmutable` protege `doc.Documento`, pero no su extensión.
- **Evidencia:** [DAT] 9 (líneas 330-334) y 8 (línea 320).
- **Remediación:**
  - `DENY UPDATE, DELETE` sobre `corp.Consumo` y `corp.Reverso`: se insertan completos dentro de la transacción y la instantánea sale del `OUTPUT` antes del `INSERT`; si alguna columna necesitara una escritura posterior, un disparador de inmutabilidad como el del documento;
  - una comprobación **diaria**, no solo tras restaurar, de `com.Saldo.Usado = SUM(com.SaldoMovimiento.Monto)`, con un aviso y una línea en la bitácora si no cuadra.
- **Costo:** unas 0,05 sp (inferido).

### SEG-CORP-16 · Baja · Rotación de la llave HMAC

- **Riesgo.** La migración perezosa de [BP] 8.4 reescribe `IdentificadorHmac` en la lectura. Eso choca con tres cosas:
  - el disparador `TR_Carne_Estado` de [DAT], que prohíbe cambiar el identificador;
  - C-2, que es una ruta `Consulta` + `SoloConsulta` y no debería escribir (por ejemplo, con el candado de restauración);
  - el nodo, que no es dueño de `com.Carne`.
- **Evidencia:** [BP] 8.4 (línea 497); [DAT] DDL (línea 433); [BP] 6.3 C-2 (línea 223).
- **Remediación:**
  - la rotación solo se hace **cuando la llave se compromete**, no de forma periódica: una llave de seudonimización bien custodiada no necesita rotar;
  - la reescritura la hace un proceso de la central, no la ruta de lectura, a partir de la lista de carnés acertados con la versión vieja;
  - el disparador admite cambiar el par (`IdentificadorHmac`, `HmacVersion`) solo hacia una versión mayor;
  - pasado un plazo (por ejemplo, 90 días), los carnés sin migrar se vuelven a registrar.

### SEG-CORP-17 · Baja · Minimización de datos ante el tercero y en los reportes

- **EC-03:** muestra la foto de un comensal **de baja** o inhabilitado. Sin beneficio no hay finalidad que lo justifique. Se propone mostrar la foto solo si está suspendido, y para B e I tratarlo como el carné bloqueado (PV-5). ([UX] línea 527.)
- **C-6 y C-10:** la búsqueda por nombre del cajero permite recorrer el padrón y los consumos por persona. Se propone un mínimo de 3 caracteres, como mucho 10 resultados, la consulta del cajero limitada a su jornada y a su caja, y la búsqueda por nombre en los consumos solo para la empresa. ([BP] líneas 227 y 231.)
- **RC-01:** el grano por línea muestra **qué come** cada persona, y eso puede dejar ver datos de salud (una dieta). Se propone que por omisión agrupe por día y franja, con el detalle por línea a pedido y con el mismo privilegio. ([DAT] línea 805.)
- **`rpt.Autorizaciones`:** la lee el rol del diseñador SQL e incluye el **motivo libre**, que en un reverso o en una identificación sin carné puede traer el nombre o un dato de salud. Se propone una indicación en la pantalla («No escriba datos personales en el motivo») o excluir los tipos de la Corporativa de esa vista. ([NG] `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesOla3.cs:585-587`; `PermisosLecturaReportes.cs:8-15`.)
- **FD-12:** el cupo de nómina impreso **por omisión** expone una deuda del empleado en un papel que puede quedar en la bandeja. Se propone que por omisión no se imprima y que se muestre en pantalla solo al elegir nómina.
- **CA-13:** se agrega una prueba automática: ninguna vista de `rpt` ni de `rptc` depende de `com.ComensalFoto` (se consulta `sys.sql_expression_dependencies`).

### SEG-CORP-18 · Baja · Archivo del corte de nómina

- **Riesgo.** El CSV o Excel lleva nombres que vienen de la importación. Una celda que empieza con `=`, `+`, `-`, `@`, tabulación o retorno se interpreta como fórmula al abrir el archivo (inyección CSV). Además, la huella SHA-256 sirve solo si RR. HH. la compara con el valor del servidor, no con uno que viaje junto al archivo.
- **Evidencia:** [BP] 6.5 (línea 363); [DAT] 8 (línea 322).
- **Remediación:** anteponer `'` a esas celdas al exportar, y que la pantalla de AC del corte muestre la huella guardada para compararla.

### SEG-CORP-19 · Baja · Procesamiento de la imagen al cargar la foto

- **Riesgo.** El tope de 2 MB no limita los **píxeles**: un PNG pequeño puede declarar dimensiones enormes y agotar la memoria de la API al decodificarlo, y la API es la misma que atiende las cajas. Además, los decodificadores de imágenes tienen historial de vulnerabilidades.
- **Evidencia:** [BP] 6.7 (línea 385).
- **Remediación:**
  - leer el encabezado y rechazar más de 4.000 × 4.000 px antes de decodificar;
  - limitar la ruta a una carga concurrente por usuario;
  - elegir una biblioteca mantenida, que se actualiza según la política de paquetes del proyecto. Costo: SkiaSharp tiene licencia MIT (0 USD); ImageSharp exige una licencia comercial por encima de cierto ingreso del licenciatario [I], así que habría que verificarla antes de elegirla.

### SEG-CORP-20 · Baja · Quién fija el modo fiscal

- **Riesgo.** La falla cerrada FD-09 es correcta: con `NULL` no se cobra dinero del empleado, y el disparador 51815 lo vuelve a comprobar. Pero el valor lo pone el **SUPER, que es de GSF**, y eso es decidir la postura fiscal del cliente. Con P-0, además, es aceptar un riesgo Alto ([HF] 5.4).
- **Evidencia:** [DAT] 2.12 (líneas 169-175); [BP] 7.1 y 6.7 (línea 392).
- **Remediación:**
  - el motivo del cambio exige la referencia del documento firmado por el cliente (la decisión de H-04, y con P-0 la aceptación escrita del riesgo de ADR-87);
  - la lista de puesta en marcha compara el valor con esa firma;
  - en las instalaciones de demostración, el valor se marca como de prueba para que no pase a producción por arrastre.

### 4.3 Fuentes legales y su limitación (C6)

| Fuente | Lo que se usa | Estado |
|---|---|---|
| Constitución de la República Dominicana (2015), **art. 44** | Intimidad, honor y **propia imagen**. Num. 2: acceso a los datos propios en registros públicos y privados, principios de calidad, licitud, lealtad, seguridad y finalidad, y la actualización, rectificación o destrucción de los datos que afecten derechos | [M] De memoria, con confianza alta en el contenido |
| Constitución, **art. 70** | Hábeas data | [M] Confianza alta |
| **Ley 172-13**, Orgánica sobre Protección de Datos de Carácter Personal (diciembre de 2013) | La definición de **datos sensibles** (sin la imagen ni la biometría en la lista), el consentimiento **libre, expreso e informado, por escrito o por un medio equivalente** como regla, las excepciones por relación contractual o laboral, los derechos de acceso, rectificación, supresión y oposición, y el deber de seguridad y de secreto | [M] **No releída en esta sesión** (sin acceso a la web). No cito números de artículo para no inventarlos |

**Pendiente:**
- que un abogado del cliente confirme los artículos y la excepción laboral;
- **verificar si en 2026 rige todavía la Ley 172-13** o si la sustituyó otra ley: hubo proyectos de una ley nueva de protección de datos y no sé si se aprobaron.

Las remediaciones de SEG-CORP-03 se eligieron para que sirvan con cualquiera de las dos lecturas (con o sin la excepción laboral), y no dependen de la respuesta.

---

## 5. Controles que están bien implementados en el diseño

1. **El servidor decide todo** el reparto, la franja (con `IRelojProtegido`), la identidad confirmada y el modo fiscal. El precio sale del maestro, nunca de la pantalla ([BP] 1.3 y 5.1).
2. **Concurrencia del saldo:** `UPDATE` condicional con el `Usado` visto, que viaja **dentro** del token y no por la pantalla, más el `CHECK` que impide un saldo negativo y la transacción entera que se deshace si algo falla. El 409 trae la cotización nueva y **no reintenta solo**. Esto cierra CA-03, CA-04 y CA-07 ([DAT] 4.2 y 4.3; [BP] 6.3).
3. **Un almuerzo por franja y día** garantizado por un índice único, sin una lectura previa que compita con otra caja ([DAT] 4.2).
4. **Carné con identificador opaco y HMAC con llave por empresa:** el mismo UID da valores distintos en dos empresas, la respuesta tarda lo mismo con un carné que existe y con uno que no, y hay un límite de 30 lecturas por minuto ([DAT] 2.5; [BP] 8.3 y 8.4).
5. **QR de 128 bits** generado por el sistema y entregado una sola vez. **Un carné reemplazado nunca vuelve a activarse** ([BP] 6.7; [DAT] 2.5).
6. **Lector:** la ráfaga descarta `Enter`, el formato es estricto por tecnología y el prefijo se valida como enrutamiento, no como prueba ([BP] 8.4).
7. **Foto:**
   - una sola versión, reducida y **sin metadatos (EXIF)**, cifrada en la aplicación con un algoritmo aprobado;
   - servida solo después de una lectura vigente, con `no-store`, sin URL por el `Id` del comensal, sin galería y sin caché en disco en MAUI;
   - cada vista administrativa va a la bitácora ([DAT] 2.6; [BP] 8.5; [UX] PV-1 a PV-7). PV-1, PV-3, PV-5 y PV-6 los doy por buenos tal cual. PV-4 y PV-7 están bien descritos como medidas contra la copia accidental, no como protección (ADR-32).
8. **Sin cédula** en el padrón, y ninguna vista une el enlace con `rrhh.Empleado` ([DAT] 2.3).
9. **Reportes:** las personas van en `rptc`, que el rol del diseñador SQL no lee; RC-06 va sin personas en `rpt`; `DENY` sobre `com` y `corp` generado desde `sys.schemas` y reaplicado ([DAT] 7 y 9; [NG] `PermisosLecturaReportes.cs:8-15`).
10. **Falla cerrada fiscal FD-09:** `NULL` no elige ninguna opción y bloquea el dinero del empleado en la cotización (antes de cobrar la tarjeta) y en la base. El mensaje no sugiere ninguna salida. El cambio es solo del SUPER, con historia temporal ([DAT] 2.12; [BP] 7.1).
11. **Corte de nómina:** se cierra y se exporta en una sola operación idempotente, el cierre es inmutable y no se cierra con la sincronización atrasada ([BP] 6.5).
12. **El reverso** no puede devolver más de lo consumido (`doc.LineaSaldo`), la bolsa de un mes cerrado no se reabre y otra persona debe autorizarlo, además del disparador 51820 ([DAT] 3).
13. **La lectura del carné va por `POST`**, así que el identificador no queda en las URL ni en los registros de acceso ([BP] 6.3).
14. **Sin secretos** en `appsettings` ni en texto plano (ADR-44), con algoritmos dentro del perfil FIPS ([BP] 8.6).

---

## 6. Remediaciones priorizadas y condiciones previas

### 6.1 Para el texto de la hoja SW y FD (antes de firmar)

| Prioridad | Hallazgo | Qué se escribe | Costo (inferido) |
|---|---|---|---|
| 1 | SEG-CORP-02 | SW-09: invariante «el externo nunca es ADMIN», lista de permitidos en `PermisosService.EfectivosAsync`, inventario de la empresa, CA-09 ampliado | +0,05 sp sobre las 0,2 de SW-09 |
| 2 | SEG-CORP-07 | SW-02: un propósito por tipo, identificación de un solo uso (`IdentificacionUid` único), líneas idénticas, `ValidadaEn` sin renovar | 0,1 sp |
| 3 | SEG-CORP-08 | Autorizante distinto del usuario por comparación; `doc.Autorizacion` de tipo `SIN_CARNE` | 0,05 sp |
| 4 | SEG-CORP-10 | Un reverso servido no libera el 100 % | 0 |
| 5 | SEG-CORP-15 | `DENY UPDATE, DELETE` en `corp.Consumo` y `corp.Reverso`; cuadre diario del saldo | 0,05 sp |
| 6 | SEG-CORP-09 | SW-11: un reintento como original solo con la falla informada por el agente | 0,1 sp |
| 7 | SEG-CORP-11 | Reverso posterior al Z autorizado por la empresa; lote con el cruce de las horas en línea | 0,05 sp |
| 8 | SEG-CORP-05, 16, 20 | AAD y DEK por escritura; rotación del HMAC solo por compromiso; referencia escrita en el motivo del modo fiscal | 0 |

### 6.2 Antes de construir T1

- **DB-8 (nueva):** el núcleo criptográfico de ADR-67 (KEK por empresa, sitio y versión, con custodia y valor de control) disponible (SEG-CORP-05).
- La llave HMAC con la custodia de ADR-67, guardada en `GPOS_SYSDATA` (SEG-CORP-06): 0,1 sp.
- Las columnas del consentimiento y el estado «sin foto por decisión del titular» en M1 (SEG-CORP-03): 0,15 sp.

### 6.3 Antes de T11 (sincronización)

- La precisión firmada de ADR-67, punto 9, para la entrega de llaves al nodo (SEG-CORP-13).
- El traspaso del dueño del saldo (SEG-CORP-14), con 0,1 sp, y el borrado de fotos en la clase de seguridad (SEG-CORP-04).

### 6.4 Antes del primer cliente (lista de puesta en marcha)

1. **SEG-CORP-01:** la v1 del acceso multiempresa, o una instalación con **una sola** empresa habilitada (comprobado en `GPOS_SYSDATA`).
2. **SEG-CORP-03:**
   - el aviso informativo versionado;
   - los consentimientos firmados de quienes tienen foto;
   - las cláusulas de encargado con el tercero y con GSF;
   - la confirmación legal de la vigencia de la Ley 172-13.
3. **SEG-CORP-04:** el plazo máximo de los respaldos con fotos definido e informado, y un **simulacro de restauración** que demuestre que las supresiones se vuelven a aplicar.
4. **SEG-CORP-12:** los umbrales de RC-05 activos, el estado de cuenta del comensal disponible y la revisión mensual por la empresa. Si el honorario del tercero depende de las comidas servidas, el riesgo pasa a Alto y estos controles son obligatorios.
5. **SEG-CORP-13:** el nodo (si lo hay) bajo la custodia de TI de la empresa, con BitLocker y sin cuentas del tercero.
6. **SEG-CORP-02:** CA-09 ampliado aprobado por QA, y los perfiles del tercero revisados contra la lista de permitidos.
7. **SEG-CORP-20:** el modo fiscal coincide con la firma de H-04.

**Costo total de las remediaciones:** unas **1,0 a 1,3 sp** (inferido, ±40 %), algo menos de una semana-persona a 1,2 sp por semana, con 0 USD en licencias. Para el cliente, el costo es el que ya estaba (un filtro de privacidad opcional de USD 30 a 60 por pantalla, [UX] PV-2) más el trabajo legal del aviso y de los contratos.

---

## 7. Recomendación

**Rechazado en el texto actual** de SW-09 y SW-02, por SEG-CORP-02 (Alta) y por la condición de SEG-CORP-01 (Alta), que solo es aceptable como requisito obligatorio y comprobable. Las demás Medias no bloquean por sí solas.

**Pasa a «Aprobado con observaciones», sin una ronda completa nueva,** si se cumplen dos cosas:
1. la hoja de firma de SW-01 a SW-18 y FD-01 a FD-15 incorpora las remediaciones de 6.1;
2. la condición 1 de 6.4 (DB-7) queda escrita como **requisito obligatorio de la puesta en marcha** con su comprobación, junto con las demás condiciones de 6.2 a 6.4.

La revisión de esa versión solo tiene que comprobar que se incorporó lo de la sección 6.1.

Sobre el punto que dejó abierto la hoja (H-08 y la Ley 172-13): **la foto no es un dato sensible por definición, pero es un dato personal protegido por la Constitución (propia imagen)**. La casilla de UQ-7 debe ser obligatoria y debe ir acompañada de lo siguiente:
- un registro del consentimiento con fecha, autor y versión del aviso;
- una vía sin foto que no castigue a quien no consiente;
- la confirmación legal (4.3).

---

## Resumen breve

- **2 Altas:**
  - DB-7 (multiempresa v1). Validada, y bloquea el primer cliente, no la construcción.
  - SW-09. El recorte del ADMIN como lista de exclusión no cierra la segregación: el ADMIN tiene cortocircuitos en seis o más sitios del código y el tercero podría recibir ajustes y mermas de inventario. Se cierra con una invariante en la cuenta y una lista de permitidos.
- **13 Medias**, casi todas de fraude interno del tercero y de privacidad:
  - tokens con un solo propósito y la identificación reutilizable;
  - «otra persona» que el núcleo no garantiza;
  - 3 vales por ticket;
  - el reverso servido que libera el almuerzo;
  - el reverso y la contingencia sin la empresa;
  - el carné tecleado (residual Medio confirmado, con criterio para DESFire);
  - en la foto: la AAD, la custodia de la llave HMAC, la retención con restauraciones y nodos, y el consentimiento;
  - la custodia del nodo;
  - el traspaso del dueño del saldo;
  - la contención de `gpos_app`.
- **La foto y la Ley 172-13:** no es un dato sensible por definición, pero es un dato personal (propia imagen). UQ-7 debe ser obligatoria con un registro del consentimiento, un aviso, una vía sin foto y cláusulas de encargado. La ley no se releyó en esta sesión y la debe confirmar un abogado, incluida su vigencia en 2026.
- **Lo que está bien:** el servidor decide, el saldo se controla con un `UPDATE` condicional y el 409 trae la cotización nueva, el índice único del almuerzo, el HMAC por empresa, el QR de 128 bits, la ráfaga del lector que descarta `Enter`, la foto sin metadatos ni caché, las vistas `rptc` y la falla cerrada FD-09.
- **Costo de las remediaciones:** unas 1,0 a 1,3 sp y 0 USD en licencias.
- **Recomendación:** Rechazado en el texto actual. Pasa a «Aprobado con observaciones» al incorporar 6.1 y las condiciones de 6.4.

### Cierre
- Estado: Rechazado (recomendación técnica sobre el texto actual de SW-02 y SW-09). Pasa a «Aprobado con observaciones» si la hoja incorpora la sección 6.1 y las condiciones de 6.2 a 6.4. SW-01 a SW-18 y FD-01 a FD-15 siguen Pendientes de firma.
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-diseno-corporativa-2026-10-15.md` (sin commit).
- Supuestos:
  - normas legales citadas de memoria, sin releerlas (no hay acceso a la web);
  - los costos en sp y en USD son inferidos (±40 %);
  - el UID de 125 kHz tiene unos 40 bits;
  - los carnés de acceso existentes suelen llevar el número impreso;
  - la licencia de ImageSharp está sin verificar;
  - los algoritmos de Data Protection son los de omisión, porque no hay ninguna configuración en el código.
- Decisiones candidatas a ADR:
  - precisión de ADR-67, punto 9 (llaves hacia el nodo);
  - precisión de ADR-88 (AAD de la foto, custodia y ubicación de la llave HMAC, consentimiento y vía sin foto, lista de supresiones fuera de la base de la empresa);
  - precisión de ADR-68 («otra persona» por comparación del autorizante, tipo `SIN_CARNE`);
  - precisión de ADR-85 (invariante del personal externo y lista de permitidos).
- Entregas a otros agentes:
  - Arquitecto Maestro → incorporar 6.1 a la hoja de SW y FD, y 6.4 a la lista de puesta en marcha;
  - arquitecto-datos → `IdentificacionUid` único, columnas del consentimiento, `doc.Autorizacion` de tipo `SIN_CARNE`, `DENY` en `corp.Consumo` y `corp.Reverso`, disparador del HMAC por versión, lista de supresiones en `GPOS_SYSDATA`;
  - arquitecto-software → SW-02, SW-09, SW-11, reverso servido, traspaso del dueño del saldo y diseño de las llaves del nodo;
  - devops → plazo máximo de los respaldos con fotos y custodia del nodo;
  - especialista-contable o asesor legal del cliente → confirmar la Ley 172-13 (artículos, excepción laboral y vigencia en 2026), el aviso y las cláusulas de encargado;
  - qa-automatizado → CA-09 ampliado, prueba de dependencias de CA-13 y simulacro de restauración con supresiones.
- Próximo paso recomendado: que el Maestro incorpore la sección 6.1 a la hoja de firma de SW-01 a SW-18 y FD-01 a FD-15, y que este auditor confirme solo esas diferencias.
