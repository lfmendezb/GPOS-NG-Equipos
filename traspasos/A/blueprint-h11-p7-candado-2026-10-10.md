# [Blueprint Técnico] H-11, segunda parte: marca P-7, respaldo posterior, candado de restauración CR-01 y chequeras P-3 (versión 2)

- **Autor:** arquitecto-software, equipo A · **Fecha:** 2026-10-10
- **Árbol leído:** `GPOS-NG-h11b`, rama `a/h11-p7-candado`, desde `feature/modelo-ng` `e7f1f96` (ya trae H-11, `Ola4AplicacionEmision`, A-3 y A-4). No cambié el árbol. Ramas leídas con `git show`: `origin/c/adr81-fase-a-diseno` (`929f44e` y `bd65f73`) y `origin/master`.
- **Encargo (firmado por el propietario el 2026-10-10):** `GPOS-NG-Equipos/avisos/B-a-A/2026-10-10-h11-p7-y-candado.md`, `…-h11-firmado.md`, `…-acuse-a3-y-registro.md` y `…-uniones-h11-a2-c6-rendimiento.md`.
- **Firmas que se aplican:** ADR-53, cláusula 9: primera precisión (P-1 a P-6 y H-13), segunda (P-7 y CR-01) y tercera (P-81A-11 y P-81A-12), en `origin/master:docs/adr/ADR-053.md:151-170`. También ADR-81 (`:82-86`) y P-81A-13 (ADR-121).
- **Documentos base:** `blueprint-h11-desbloqueo-restauracion-2026-10-10.md` (en adelante **[H11]**), `datos-h11-desbloqueo-restauracion-2026-10-10.md` (**[D11]**) y el blueprint v2 de la fase A de ADR-81 de C (**[C81]**: §6.6, §7.2 bloque B, §8.8 y P-81A-11 a 13).
- **Marcas:** **[V]** verificado hoy en el código o en un documento firmado, con su cita · **[I]** inferido, sin verificar.
- **Estado:** **versión 2** (dictamen C-2, sección V2). Lista para el arquitecto-datos, con 10 preguntas: PC-1 a PC-6 (§12; PC-2 cambia de recomendación) y PC-7 a PC-10 (V2.6). PC-7 a PC-10 requieren la firma del propietario. Ninguna bloquea el inicio del diseño de datos; **C2-01 sí impide publicar**.

---


## V2. Cambios de la versión 2 (dictamen C-2 de C, 2026-10-10)

**Fuente:** `GPOS-NG-Equipos/avisos/C-a-B/2026-10-10-c2-dictamen-h11.md`. C declaró H-11 «Rechazado como publicable» por C2-01 (Alta). Esta versión cubre C2-01 a C2-07, R-12 y el número de error que corrigió el arquitecto-datos: **51391 está reservado por ADR-78 (51387-51393); se usa 51403**. En el resto del documento, los cambios se marcan con **[v2]**.

| Hallazgo | Qué cambia | Sección |
|---|---|---|
| **C2-01 (Alta)** | Declaración del último NCF **por prefijo**, que puede pasar del `Hasta`; **piso por prefijo** en la base de empresa, aplicado en el servicio **y** en un disparador de `fiscal.SecuenciaNcf` (51404); los bloques `C` con capacidad entran en R1 y R3; zona incierta sin bloque | V2.1 |
| C2-02 | Sin cambios: P-3 con C9 ya estaba (D-12) | §6.1, §10.1 |
| **C2-03** | Se **congela** el último momento conocido en la primera detección | V2.2 |
| **C2-04** | R-10 pasa a **verificado**; detección por **regresión** al arrancar, contra el piso y la marca (y, si se firma, contra un latido de numeración); guía de devops | V2.3 |
| **R-12** | Las escrituras leen el candado de empresa **sin caché**; la vigilancia y el manejador de 51330 y 51403 invalidan la caché | V2.4 |
| C2-05, C2-06, C2-07 | El 429 solo en las rutas con `EnableRateLimiting`; PD11 con rasgo de carga; `@hasta` como `DbType.Date` | V2.5 |

### V2.1 C2-01: NCF repetido al reabrir o ampliar un rango después del respaldo

**Causa (verificada en el código y en la sonda de C):**
- R1 y R3 solo leen los bloques `A` y `R` (`ConsultasRestauracion.cs:52,66`) [V].
- R2 rechaza un último probado por encima del `Hasta` (`PlanDesbloqueo.cs:144-145`) [V].
- `GuardarSecuenciaAsync` deja reabrir un bloque `C` y ampliar el `Hasta` sin conocer la restauración. Solo compara contra lo emitido **en la base** y contra los rangos cerrados por un desbloqueo (`AdministracionService.cs:310-334,350`) [V].
- El disparador `TR_SecuenciaNcf_Bloque` impide los solapes y la reapertura de un `X`, pero no conoce ningún piso (`SqlMigracionesOla3.cs:385-400`) [V].

**Diseño:**

1. **La declaración pasa a ser por prefijo.**
   - `DesbloqueoRestauracionRequest` cambia `Secuencias: UltimoProbadoDto[]` por **`Prefijos: UltimoProbadoPrefijoDto(string Prefijo, string? UltimoNcfProbado, string Fuente, string Referencia)[]`**.
   - La lista cubre exactamente los prefijos que tienen algún bloque `A`, `R` o `C` con capacidad en la base, **o** una marca o un piso.
   - Las reglas de fuente y referencia no cambian. En los prefijos `E…`, solo `PROVEEDOR` (P-5).
   - **El último probado puede pasar del `Hasta`** de todos los bloques de la base (el caso del rango ampliado). Hay un solo tope: que quepa en los dígitos.
   - El contrato de R2 y R3 cambia. La tarjeta pide una fila por prefijo en vez de una por secuencia, así que hay menos campos.
2. **Plan por prefijo** (`PlanDesbloqueo`, sigue siendo una función pura). Con `corte = último probado` del prefijo, para cada bloque `A`, `R` o `C` con `Siguiente ≤ Hasta`:

   | Caso | Acción |
   |---|---|
   | `Siguiente − 1 ≥ corte` | `SIN_CAMBIO` |
   | `Desde ≤ corte < Hasta` | `CERRAR_Y_CONTINUAR`: `X` hasta el corte; el resto pasa a un bloque nuevo **con el mismo estado** (`A`, `R` o **`C`**: un bloque cerrado a mano sigue cerrado) |
   | `corte ≥ Hasta` | `CERRAR_AGOTADA`: todo en `X` |

   - **Zona incierta:** se registra **por bloque**, desde `Siguiente` hasta `MIN(corte, Hasta)`.
   - **La porción que pasa del mayor `Hasta` del prefijo** (`MAX(Hasta) + 1 … corte`) se registra como **zona incierta sin bloque**: son los números que se emitieron de una ampliación que el respaldo no tiene.
3. **Piso por prefijo en la base de empresa** (nuevo; lo diseña el arquitecto-datos):
   - **Tabla `fiscal.PisoNcf`** (`Prefijo` como llave, `Piso bigint`, `Origen`, `ReconciliacionId`, `ActualizadoEn`).
     - `Piso = MAX(cortes confirmados del prefijo, marca P-7 vigente)`.
     - **Solo sube.** La aplicación no la escribe: `DENY INSERT, UPDATE, DELETE` y un disparador que rechaza las bajadas.
   - **Cómo llega la marca:** el servicio inserta en R3, dentro de su transacción, las filas `sync.ReconciliacionPiso(ReconciliacionId, Prefijo, Piso, Origen)`: el corte de cada prefijo y la marca de `GPOS_SYSDATA` cuando es mayor. Estas filas siguen la regla «solo con la reconciliación abierta» (51389).
   - **`usp_ConfirmarReconciliacionLocal` aplica el `MAX` a `fiscal.PisoNcf`** y comprueba la regla **C10**:
     - cada prefijo de la reconciliación tiene su fila de piso;
     - ningún bloque `A`, `R` o `C` del prefijo tiene `Siguiente ≤ piso` con `Siguiente ≤ Hasta`.
   - Así, **la marca de `GPOS_SYSDATA` queda copiada dentro de la base de empresa**, donde un disparador la puede leer (un disparador no lee otra base).
4. **Disparador nuevo `fiscal.TR_SecuenciaNcf_Piso`** (`AFTER INSERT, UPDATE`; **51404**, libre según la búsqueda en `Migraciones/*.cs`):
   - **Rechaza** toda fila con `Estado IN ('A','R')`, `Siguiente ≤ Hasta` y `Siguiente ≤ Piso` de su prefijo, cuando:
     - es un **alta**;
     - es una **reapertura** (`Estado` pasa de `C` a `A` o `R`);
     - es una **ampliación** (`Hasta` sube);
     - o el `Siguiente` **baja**.
   - Texto: «Los números hasta {piso} de {prefijo} ya se usaron antes de una restauración: el siguiente debe ser mayor (CR-01).»
   - **Coste:** la emisión hace `UPDATE Siguiente` (sube), así que el disparador sale en la primera comparación con `deleted`. Se mide con 8.2 (5).
   - El arquitecto-datos decide si lo funde con `TR_SecuenciaNcf_Bloque`.
5. **Servicio** (`GuardarSecuenciaAsync`):
   - la misma regla, con el mensaje para el usuario: «El siguiente número de {prefijo} debe ser mayor que {piso}…»;
   - además lee la **marca de `GPOS_SYSDATA`**, porque cubre el caso en que la propia base perdió su piso al restaurarse.
   - **Si la marca no se puede leer, no rechaza:** el disparador sigue protegiendo con el piso local. Así no se bloquea la operación diaria por una caída de `GPOS_SYSDATA`.
   - Con el candado de empresa activo, sigue la regla de PC-2.
6. **Lectura de R1:**
   - `SecuenciasVigentes` pasa a `Estado IN ('A','R') OR (Estado = 'C' AND Siguiente <= Hasta)`;
   - se agregan el piso local y la marca por prefijo (`MarcaP7Dto` gana `PisoLocal`);
   - la tarjeta agrupa por prefijo y muestra los bloques de cada uno.
7. **Reglas de la confirmación que cambian:**
   - C3 (completitud) incluye los bloques `C` con capacidad;
   - C4 admite la continuación en `C`;
   - C5 no cambia;
   - **C10** es nueva (punto 3).
   - **La zona incierta sin bloque** necesita que `fiscal.NcfZonaIncierta.SecuenciaId` admita nulos, más una columna `Prefijo varchar(3)` (o una tabla hermana). Lo decide el arquitecto-datos. **Una zona sin bloque no se vuelve a registrar nunca:** la cubre el piso.
8. **Lo que reemplaza:**
   - I-10 e I-11 de §4.2 quedan **absorbidas**: el último probado por prefijo debe ser `≥ MAX(piso local, marca, último emitido en la base)`;
   - I-11 deja de pedir que se registre la secuencia antes de desbloquear (PC-2 pierde su motivo principal; ver V2.6).

**Pruebas nuevas:**

| Id | Caso | Esperado |
|---|---|---|
| **CA-H11-19** | B02 `C` al respaldar → reabierto → emite 02 y 03 → restaurar | R1 lista el bloque `C`. Con el corte 03 y la evidencia, R3 lo deja en `X` hasta 03 (o continúa en `C`). Reabrir después con `Siguiente ≤ 3` → **51404** desde el servicio y desde un `UPDATE` directo. La venta siguiente nunca toma 02 ni 03 |
| **CA-H11-20** | B02 con `Hasta = 1` → ampliado → emite 02 y 03 → restaurar | R2 **acepta** el corte 03 (por encima del `Hasta`); zona sin bloque 02-03; piso 3. Ampliar o dar de alta B02 desde 2 → 422 desde el servicio y 51404 directo. Desde 4 → pasa |
| CA-H11-21 | Piso que llega de la marca | `GPOS_SYSDATA` con la marca 150 y la empresa restaurada a un punto anterior al desbloqueo (sin piso) → R3 copia el piso 150 → el alta de B02 desde 120 → 51404 |
| CA-H11-22 | El piso no baja | `UPDATE` o `DELETE` directo de `fiscal.PisoNcf` → rechazado; como `gpos_app` → 229 |

### V2.2 C2-03: congelar el último momento conocido

- **Problema (verificado):** `ConsultasRestauracion.Reloj` calcula el último momento con el `MAX` de `audit.Bitacora.FechaHora` y de los momentos de `doc.Documento` (`ConsultasRestauracion.cs:25-32`) [V]. Con el candado sigue habiendo escrituras en la bitácora: la reimpresión (PC-4), el respaldo, el alta de secuencias de PC-2 y las líneas de R2. Entonces el último momento avanza y el margen de RN-12 se queda corto.
- **Decisión D-13 (técnica, dentro de RN-12 firmada):** se congela en la **primera detección** de cada fork.
  - **Tabla `sync.DeteccionRestauracion`:** `ForkActual` como llave, `DetectadaEn` y `UltimoMomento`, que se calcula con la consulta actual **en el momento de detectar**.
  - **Procedimiento `sync.usp_RegistrarDeteccion`** (`EXECUTE AS OWNER`; es idempotente: si el fork ya tiene fila, no hace nada).
  - **Quién lo llama:**
    - `ComprobarAlArrancarAsync`, antes de atender peticiones;
    - el comprobador, al ver por primera vez `Restaurada = 1` (V2.4);
    - y R1.
  - **El servicio de R1 a R3 lee el valor congelado.** La consulta en vivo queda solo como respaldo si no hay fila, y en ese caso se informa como aviso.
  - **Cubre también la regresión de V2.3**, con el fork actual como clave y la causa `REGRESION`.
- *Alternativa descartada:* calcularlo sin contar las acciones permitidas con el candado. Exige filtrar la bitácora por acción, y cada ruta nueva en la lista blanca abriría el mismo agujero.
- **Prueba (amplía CA-CR-01):** restaurar → reimprimir, entrar y respaldar → R1 → `UltimoMomentoConocidoUtc` y `DiasInciertos` iguales a los de la detección.

### V2.3 C2-04: copia anterior adjuntada (fork conservado) y detección por regresión

- **R-10 pasa a [V]:** C verificó que adjuntar una copia anterior de los `.mdf` y `.ldf` conserva el fork, así que la base no se detecta y emite. También verificó que revertir una instantánea **de la base** cambia el fork. Una máquina virtual revertida entera no la cubre ningún mecanismo de este diseño.
- **Detección por regresión** (al arrancar, en `ComprobarAlArrancarAsync`, y cada 5 min en la vigilancia):
  - para cada empresa y prefijo, se calcula `actual = MAX(Siguiente − 1)` sobre **todos** los bloques del prefijo, incluidos `C` y `X`;
  - **hay regresión** si `actual < MAX(piso local, marca P-7)`;
  - un NCF nunca retrocede de forma legítima: 51326 y el servicio lo impiden.
- **Efecto de la regresión:** `EXEC sync.usp_BloquearPorRegresion` (`EXECUTE AS OWNER`) pone `EmisionBloqueada = 1` y `MotivoBloqueo = 'RESTAURACION'`, y registra la detección.
  - Con eso, `Clasificar` da `RESTAURADA`, rige el candado y se libera con **el mismo R3**: `usp_AbrirReconciliacionLocal` ya acepta `@bloq = 1` con ese motivo (`SqlMigracionesH11.cs:55-58`) [V].
  - En `GPOS_SYSDATA` queda el evento `REGRESION_NUMERACION` (A).
- **Límite:** solo detecta una copia anterior al **último desbloqueo**. **PC-10** propone ampliarla con un **latido de numeración**: cada 5 min, la vigilancia guarda en `GPOS_SYSDATA` el `MAX(Siguiente − 1)` por empresa, nodo y prefijo (solo sube). Así se detecta cualquier copia más vieja que unos 5 minutos de emisión. **No sirve** si `GPOS_SYSDATA` también se revirtió (máquina virtual entera).
- **Guía de devops** (entrega): solo `RESTORE` desde respaldos. Prohibido:
  - adjuntar copias de `.mdf` o `.ldf`;
  - revertir instantáneas de la máquina virtual con las bases en uso.

  Si es inevitable, ejecutar después `GPOS.Migracion verificar` y revisar la tarjeta.

### V2.4 R-12: cerrar la ventana de 15 s de la caché

- **En las escrituras** (`POST`, `PUT`, `PATCH` y `DELETE` de una sesión con empresa), el middleware lee el candado de empresa **sin caché**: una consulta de una fila a `sync.EstadoEmision`, ≈ 0,2 ms por escritura [I]. Los `GET` siguen con la caché de 15 s.
- **La vigilancia** recorre las empresas cada 15 s e **invalida** la caché de la que cambió. Además llama a `usp_RegistrarDeteccion` (V2.2).
- **El manejador de errores** invalida la caché de la empresa cuando el motor responde 51330 o 51403.
- **Efecto:** ninguna escritura HTTP pasa con la base ya restaurada. Las lecturas pueden tardar hasta 15 s en ver la franja.
- **Prueba (amplía CA-CR-04):** restaurar sin detener la API → la primera escritura de un maestro → 503 `BASE_RESTAURADA`.

### V2.5 C2-05, C2-06 y C2-07

- **C2-05:** se confirma el dictamen de §13.4. Sin el ajuste, `SeparacionTokensTests` da 32/32 sin ningún 429 (C), y el 429 viene de `DispositivosK1Tests`, que tiene los límites habilitados (`:85`, `:1116-1119`) [V].
  - **Corrección:** aceptar el 429 solo en las rutas con `EnableRateLimitingAttribute`, más una prueba con una partición limpia que exija 401 o 403.
- **C2-06:** `PD11_las_consultas_de_RN12…` (`DesbloqueoRestauracionMigracionTests.cs:183`) lleva `[Trait("Categoria", "Carga")]` y sale del filtro oficial (`&Categoria!=Carga`). Se ejecuta sola en la tanda de carga y conserva el tope de 2 s. Cambiar el filtro oficial es decisión de B (entrega).
- **C2-07:** `@hasta` se pasa como `DbType.Date` (`RestauracionSitioService.cs:206`), igual que la consulta registrada.

### V2.6 Preguntas nuevas y cambios en las anteriores

| # | Pregunta | Por qué exige firma | Opciones | Recomendación y costo [I] |
|---|---|---|---|---|
| **PC-7** (propietario; precisión de la cláusula 9 de ADR-53 y extensión de P-7) | **Piso de NCF por prefijo.** ¿El último NCF probado se declara por prefijo (puede pasar del `Hasta`) y, desde el desbloqueo, ningún bloque de ese prefijo puede emitir números iguales o menores que el piso (`MAX` de los cortes confirmados y la marca P-7), tampoco en un alta, una ampliación o una reapertura hechas por el ADMIN? | Restringe para siempre lo que el ADMIN puede hacer con los rangos que autoriza la DGII. La primera precisión decía «cada secuencia vigente se cierra en el último NCF probado», por secuencia y sin pasar del `Hasta` | (a) **Sí, en el servicio y en el disparador** (51404). (b) Solo en el servicio (el motor no lo garantiza). (c) No (C2-01 sigue abierto: NCF repetido) | **(a).** Es lo único que cierra C2-01 en la base. +0,35 sp |
| **PC-8** (propietario; R-D4 de [D11], construida con el «no» por omisión, fuera de la hoja) | **Bloques cerrados a mano (`C`) con números sin usar.** ¿Entran en el desbloqueo? | Hoy un bloque `C` reabierto después del respaldo repite NCF (C2-01 a) | (a) **Entran en R1 y R3** con el corte del prefijo: lo que llega al corte pasa a `X` y el resto sigue en `C`. (b) Al desbloquear, todo bloque `C` con capacidad se cierra completo en `X` (se pierde el resto del rango). (c) No entran | **(a).** No pierde rango y, con el piso de PC-7, no se repiten. +0,05 sp (sobre PC-7). (b): +0,03 sp |
| **PC-9** (propietario) | **Zona incierta sin bloque** (números de una ampliación que el respaldo no tiene). ¿Se registra como zona incierta para el contador, igual que la de un bloque? | Cambia el registro fiscal de P-6 (la zona se registra y se entrega una guía al contador) | (a) **Sí**, con `Prefijo` y sin `SecuenciaId`. (b) Solo en el piso, sin zona | **(a).** El contador necesita saber que esos números existen. +0,05 sp |
| **PC-10** (propietario; extensión de P-7) | **Latido de numeración** para detectar una copia anterior adjuntada (C2-04) | Es otra marca externa en `GPOS_SYSDATA` y bloquea una base sin que cambie su fork | (a) **Sí**, cada 5 min por empresa, nodo y prefijo. (b) Solo la regresión contra el piso y la marca (lo pedido por C) | **(a).** Cubre cualquier copia, no solo las anteriores a un desbloqueo. +0,1 sp |

**Sin firma** (son técnicas, dentro de lo firmado):
- **D-13**, congelar el último momento conocido: aplica RN-12 tal como está firmado;
- **V2.4**, la lectura sin caché;
- **C2-05 a C2-07**, las correcciones de pruebas y de tipos;
- la regresión contra el piso y la marca (V2.3): solo usa datos que P-7 ya firmó.

**Cambio en PC-2:** con PC-7 (a), I-11 desaparece. Ya no hace falta registrar la secuencia antes de desbloquear, porque el corte puede pasar del `Hasta`. PC-2 queda solo para el caso en que el SUPER quiera registrar con el candado un rango **nuevo** autorizado después del respaldo. **Recomendación nueva: (c) No**: se registra después de desbloquear y el piso lo protege. Ahorra 0,05 sp y quita una ruta de la lista blanca.

**Cambio en PC-5:** C2-01 es Alta y C recomienda no publicar sin ella, así que **va en PR-2a**.

### V2.7 Esfuerzo y fecha [I], ±40 %

| Parte | sp |
|---|---|
| Versión 1 (con D-11) | 2,40 |
| − PC-2 (c) | −0,05 |
| C2-01: declaración por prefijo y plan con bloques `C` (PC-8 a) | +0,20 |
| C2-01: piso (tabla, `ReconciliacionPiso`, C10), disparador 51404, servicio y marca en `GuardarSecuenciaAsync` (PC-7 a) | +0,20 |
| C2-01: zona sin bloque (PC-9 a) | +0,05 |
| C2-01: pruebas CA-H11-19 a 22 | +0,10 |
| C2-03: detección congelada | +0,10 |
| C2-04: regresión contra el piso y la marca, y la guía | +0,10 |
| PC-10 (a): latido de numeración | +0,10 |
| R-12: lectura sin caché en las escrituras e invalidación | +0,05 |
| C2-05 a C2-07 | +0,05 |
| **Total de la versión 2** | **3,30 (de 2,0 a 4,6)**; sin D-11, 2,75 |

- **Fecha:**
  - a unos 0,9 sp por día, son **unos 3,5 a 4 días hábiles** de un desarrollador: **+1 día** respecto de la versión 1 y **≈ +3 días** respecto de un PR solo con P-7;
  - con PC-5 (a): **PR-2a ≈ 2,75 sp** (con C2-01, unos 3 días) y **PR-2b ≈ 0,55 sp** (alrededor de 1 día después).
- **Costo:** unos USD 5.000 a 6.600; infraestructura USD 0.
- **Lo que no se puede recortar sin firma:** C2-01, porque deja abierto un NCF repetido.

---

## 0. Resumen de las decisiones

| # | Decisión | Por qué, en una línea |
|---|---|---|
| D-6 | **El candado se aplica en tres capas.** (1) **Un solo middleware** `ModoCandadoRestauracion` para los dos candados, que rechaza toda escritura HTTP no marcada. (2) Los **trabajos en segundo plano** consultan el mismo estado. (3) En la base de empresa, los **disparadores**: los 51330 de emisión y caja que ya existen y uno nuevo sobre `doc.Documento` | El middleware cubre las 125 rutas de escritura y también `GPOS_SYSDATA`. Los disparadores cubren lo que tiene efecto fiscal o de dinero aunque falle la capa HTTP |
| D-7 | **El candado de la base de empresa es el estado `RESTAURADA` de H-11.** No hay estado nuevo: lo libera **R3** | R3 ya exige el SUPER, el motivo y la bitácora en una transacción (CR-01) |
| D-8 | **La marca P-7 es una tabla de solo inserción en `GPOS_SYSDATA`.** La marca vigente es el `MAX` por empresa, nodo y prefijo. Se escribe **después** de confirmar R3 y se recompone desde `sync.Reconciliacion` de las bases de empresa | Solo puede subir y deja su historia. La recomposición cubre el fallo entre las dos bases y P-81A-12 |
| D-9 | **El respaldo posterior lo ejecuta la API**: `COPY_ONLY` de la base de la empresa **y** de `GPOS_SYSDATA`, en segundo plano, con estado en `GPOS_SYSDATA`. Devops se encarga del permiso, la retención, la copia fuera del equipo y la alerta | Sigue el patrón de `RespaldoService` (`src/GPOS.Core/Servicios/RespaldoService.cs:13-37`) [V]: sin secretos nuevos, sin depender de Backup Tool y USD 0 |
| D-10 | **Orden de liberación:** mientras `GPOS_SYSDATA` tiene candado, R3 queda rechazado en el middleware (503) y en el servicio (409) | P-81A-12 y [C81] §8.8.5: la marca tiene que estar recompuesta antes de usarla |
| D-11 | **Recomendación: A construye en este PR el núcleo del candado de `GPOS_SYSDATA` sin el factor.** Incluye la detección, la reconciliación sin los pasos del factor, la liberación, la regla de P-81A-11 en el inicio de sesión y `BitacoraSeguridad`. C agrega después lo que depende del factor | Cierra R-16 de [C81] (`GPOS_SYSDATA` sin candado entre las dos uniones). P-81A-12 lo necesita para recomponer la marca. Es la pregunta **PC-1** |
| D-12 | **P-3:** R3 confirma el siguiente cheque de cada cuenta con chequera. Se agrega la regla C9 al procedimiento de confirmación | Firmado (+0,1 sp); el punto de extensión ya existe [V] |

**[v2] Esfuerzo: 3,3 sp (V2.7).** Versión 1: **Esfuerzo [I], ±40 %:** **2,4 sp** con D-11, o 1,85 sp sin ella. El primer PR de H-11 era de 0,9 sp. **La fecha del PR se mueve unos 2 días hábiles** respecto de un PR que solo tuviera P-7. Se puede partir en dos (PC-5). Detalle en §14.

---

## 1. Contexto y alcance

### 1.1 Lo que ya existe (verificado)

| Pieza | Evidencia | Uso aquí |
|---|---|---|
| Detección del fork de la base de empresa | Vista `sync.EstadoEmision.Restaurada`: falla cerrada si el fork es nulo o distinto (`src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesH11.cs:21-37`) | Es la fuente del candado de empresa |
| Guarda de emisión 51330 | `doc.TR_Documento_Emision` en la transición 0 → 1 (`SqlMigracionesOla3EmisionLigera.cs:49-55`) y `caja.TR_Movimiento_Nodo` (`SqlMigracionesOla3.cs:334-342`) | Se conservan |
| R1, R2 y R3 | `src/GPOS.Api/Endpoints/RestauracionEndpoints.cs:16-32`: R1 con `RequiereAdmin`; R2 y R3 con `RequiereSuper` y el límite `Desbloqueo`. Servicio en `RestauracionSitioService.cs` | Se amplían con P-7, P-3 y el respaldo |
| Precedente del middleware | `ModoEsquemaPendiente` con la marca `PermitidaConEsquemaPendiente` (`src/GPOS.Api/Seguridad/ModoEsquemaPendiente.cs:34-75`) y `CambioClaveObligatorio` (`CambioClaveObligatorio.cs:28-48`) | Mismo patrón: rechazo por omisión |
| Canalización HTTP | Orden: `UseAuthentication` → `UseRateLimiter` → `UseAuthorization` → `UseCambioClaveObligatorio` → `UseModoEsquemaPendiente` → `UseVersionEsquemaEmpresa` → `UseGuardaSitio` (`src/GPOS.Api/Program.cs:238-250`) | El candado va entre `VersionEsquemaEmpresa` y `GuardaSitio` |
| Lectura por empresa con caché | `ComprobadorEsquemaEmpresas` lee la base de la empresa de la sesión, con 1 min de caché si está correcta y 10 s si no, y la invalida por empresa (`src/GPOS.Core/Infraestructura/EsquemaEmpresasNg.cs:22-59`); consulta en `VersionEsquema.cs:21-28` | Se amplía con el estado del candado |
| Punto de extensión de P-3 | `sync.ReconciliacionChequera` (`SiguienteLocal`, `UltimoEmitido`, `SiguienteConfirmado`; `src/GPOS.Core/Dominio/Configuracion/Bandeja.cs:117-124`), su disparador «solo abierta» y `DENY UPDATE, DELETE` (`SqlMigracionesH11.cs:222-235`). Contador en `banco.Chequera.Siguiente` (`Bancos.cs:10-15`). Bloqueo `GPOS.Chequera:{cuenta}` en el nivel de documentos (`src/GPOS.Core/Negocio/Comun.cs:239-255`) | C9 y bloqueo ordinal |
| Respaldo dentro de la API | `POST /api/admin/respaldos` hace `BACKUP … COPY_ONLY, INIT, CHECKSUM` en `InstanceDefaultBackupPath` (`RespaldoService.cs:13-37`; `AdminEndpoints.cs:117-118`) | Patrón de D-9 |
| Trabajos que escriben | `TrabajoNotificaciones` (empresas, cada 30 s; `TrabajoNotificaciones.cs:74-118`), `TrabajoRncDgii` (padrón en `GPOS_SYSDATA`) y `TrabajoReloj` (ancla del reloj) (`Program.cs:178-190`) | Capa 2 |
| `GPOS_SYSDATA` | `EnsureCreated` más el SQL idempotente de `EsquemaSistema.ActualizarAsync` al arrancar (`Inicializacion.cs:17-19`; `EsquemaSistema.cs:45`). **No hay bitácora general** del sistema; solo `DispositivosBitacora` | Bloques A (en parte) y B de [C81] |
| Nivel del SUPER | `NivelesUsuario.Super = "SUPER"` (`src/GPOS.Contracts/Seguridad/Cuentas.cs:32`) | **Cierra el supuesto** de [C81] §7.2 («se supone `'SUPER'`») |
| Escrituras en un `GET` | `GET /api/impresion/documento|ticket|nota/...` registra la impresión y su línea de bitácora (`ImpresionEndpoints.cs:26-38`; `ReimpresionService.cs:80-108`) | El candado por método no las ve: §5.4 |
| Migraciones | Última: `20261010130522_BitacoraLogSoloInsercion` (`src/GPOS.Core/Datos/Empresa/Migraciones/`). La versión esperada es la última (`VersionEsquemaNg.cs:27`) | La nueva va después |
| Errores libres en la base de empresa | Usados: 51300-51349, 51351-51386, 51389, 51390, 51394, 51397-51400 y 51405-51407. Libres: **51350, 51395, 51396 y 51401-51404**. **[v2]** 51387-51393 están reservados por ADR-78 (dato del arquitecto-datos) (búsqueda en `Migraciones/*.cs`) | **[v2]** Se usan 51403 (`doc.Documento`) y 51404 (piso de NCF, V2.1) |
| Errores de `GPOS_SYSDATA` | Reserva 52001-52019 (`ADR-081.md:76`); C usa 52001-52007 en [C81]. En `src` no se usa ninguno | A propone 52008 y 52009 |

### 1.2 Alcance

1. **P-7:** marca externa del último desbloqueo, por prefijo, en `GPOS_SYSDATA`. R2 y R3 exigen que el último probado sea mayor o igual que la marca. Recomposición al liberar `GPOS_SYSDATA` (P-81A-12).
2. **Respaldo completo automático** de la base de la empresa y de `GPOS_SYSDATA` después de cada desbloqueo.
3. **CR-01:** candado de toda base restaurada:
   - **empresa:** el estado `RESTAURADA` de H-11;
   - **sucursal:** el mismo mecanismo y el mismo esquema. En la entrega 1 no hay bases de sucursal (`CLAUDE.md`, «Datos») [V]. Un nodo con otros nodos activos queda en `REQUIERE_CENTRAL`, sin R3, hasta la entrega 2;
   - **`GPOS_SYSDATA`:** según D-11.
4. **P-3:** confirmar el siguiente cheque de cada cuenta en R3.
5. **Middleware común** para los dos candados, con una sola lista de marcas y la prueba de inventario de rutas.
6. **Pantallas:** la tarjeta actual ampliada, la franja global y, con D-11, la pantalla «Restauración del Sistema» sin el factor.
7. **Revisión** de los dos ajustes de pruebas de B (§13.4).

**Fuera de alcance:**
- el factor TOTP y todo lo que depende de él (C, fase A);
- la reconciliación de nodos con la central (entrega 2);
- el diario electrónico (H-14);
- H-2 y H-3 (siguen en la cola de A, después de este PR).

---

## 2. Módulos y dependencias

| Módulo | Cambio | Depende de |
|---|---|---|
| `GPOS.Contracts` | `Admin/Restauracion.cs`: `MarcaP7Dto`, `ChequeraRestauracionDto`, `ChequeraConfirmadaDto`, `RespaldoPosteriorDto`; códigos nuevos. `Seguridad/Cuentas.cs`: `SesionInfo.SistemaRestaurado` y `EmpresaRestaurada` (aditivos, `false` por omisión); `EstadoRestauracionSistema`, `LiberarCandadoRequest` y `ResultadoLiberacionSistema` (contrato de [C81] 5.14) | — |
| `GPOS.Core/Sistema/Restauracion/` (nuevo; es la carpeta que fija [C81] §2) | `CandadoRestauracionSistema` (singleton; falla cerrado), `RestauracionSistemaService` (reconciliar, consultar, liberar), `MarcaP7Service` (leer, registrar, recomponer), `RespaldoPosteriorService` (cola y ejecución) | `Consultas/Sistema/Restauracion/*` (SQL escrito a mano, D81-01) |
| `GPOS.Core/Infraestructura` | `ComprobadorEsquemaEmpresas` lee también el estado del candado; `ICandadosRestauracion` es la fachada para servicios y trabajos | — |
| `GPOS.Core/Servicios/RestauracionSitioService.cs` | P-7 (validación y registro), P-3, orden de liberación y encolar el respaldo | `MarcaP7Service`, `RespaldoPosteriorService` |
| `GPOS.Core/Servicios/Modulos/Sitio/PlanDesbloqueo.cs` | Recibe las marcas y las chequeras (sigue siendo una función pura) | — |
| `GPOS.Api/Seguridad/ModoCandadoRestauracion.cs` (nuevo) | Middleware, marcas `PermitidaConCandado(Candados)` y `SoloConsulta`, encabezado `X-GPOS-Candado` | Core |
| `GPOS.Api/Servicios/TrabajoVigilanciaRestauracion.cs` (nuevo) | Al arrancar y cada 15 s: reconcilia `GPOS_SYSDATA` y refresca el singleton; recompone las marcas en segundo plano. Ejecuta la cola del respaldo | Core |
| `GPOS.Api/Endpoints/*` | Marcas del candado en las rutas (§5.4); R4; 5.14.1 y 5.14.2 en `AdminEndpoints` (grupo `/api/super`); regla de P-81A-11 en `AuthEndpoints` (`/login`) | Core |
| `GPOS.Web`, `GPOS.UI.MAUI` | `RestauracionSitio.razor` ampliada (las dos copias); franja global en el layout; `ApiClient` lee `X-GPOS-Candado` y el 503; pantalla `/super/restauracion-sistema` | Contracts |
| Base de empresa | Migración `H11CandadoChequeras`, después de `BitacoraLogSoloInsercion` (§10.1) | — |
| `GPOS_SYSDATA` | SQL idempotente al final de `EsquemaSistema.ActualizarAsync` (§10.2) | — |

**Sin proyectos nuevos y sin ciclos:** Api → Core → Contracts; Web y MAUI → Contracts.

---

## 3. C4 (componentes)

```
 Web / MAUI / API directa / dispositivos
            │ HTTPS + JWT
            v
 GPOS.Api: … UseAuthorization → CambioClave → ModoEsquemaPendiente → VersionEsquemaEmpresa
                                → **ModoCandadoRestauracion** → GuardaSitio → endpoint
                                       │   │
          ICandadoRestauracionSistema ─┘   └─ ComprobadorEsquemaEmpresas (caché 15 s por empresa)
                    ▲                                          │ lee sync.EstadoEmision
   TrabajoVigilanciaRestauracion (arranque + 15 s)             v
     │ EXEC dbo.ReconciliarRestauracionSistema          Base de empresa: 51330 (emisión, caja) + 51403 (doc.Documento)
     │ SELECT dbo.EstadoRestauracionSistema
     │ recomposición de marcas P-7 (lee sync.Reconciliacion de cada empresa)
     │ cola del respaldo posterior → BACKUP … COPY_ONLY (empresa y GPOS_SYSDATA)
     v
 GPOS_SYSDATA: RestauracionSistema (+ vista y 2 procedimientos), BitacoraSeguridad, MarcaDesbloqueoNcf, RespaldoPosterior
            ▲
 Backup Tool (devops): toma los .bak de RespaldoPosterior para la copia fuera del equipo y la retención
```

---

## 4. Modelo de dominio

### 4.1 Los dos candados

| | Candado de empresa (y de sucursal) | Candado del sistema (`GPOS_SYSDATA`) |
|---|---|---|
| Detección | `sync.EstadoEmision.Restaurada = 1` (el fork actual es nulo o distinto de `ForkRegistrado`), **o** `EmisionBloqueada = 1` con `MotivoBloqueo = 'RESTAURACION'`. Es la clasificación `RESTAURADA` / `REQUIERE_CENTRAL` de `RestauracionSitioService.Clasificar` (`:178-185`) [V] | Vista `dbo.EstadoRestauracionSistema.Restaurada = 1` ([C81] §7.2, bloque B): el fork es distinto de `RestauracionSistema.ForkRegistrado`, es nulo o falta la fila |
| Cuándo se detecta | Al arrancar (`ComprobarAlArrancarAsync`), en cada petición de la empresa (caché de **15 s**) y en el motor, de inmediato (disparadores) | Al arrancar, **antes de atender**, y cada 15 s |
| Fallo seguro | La vista falla cerrada (fork nulo → restaurada). Si la base no responde, la operación falla por sí sola | El singleton arranca **activo** hasta la primera lectura correcta; ante un error de lectura conserva el último estado |
| Quién entra | Todos (CR-01: «las consultas siguen permitidas») | **Solo el SUPER** (P-81A-11): los demás reciben 503 `SISTEMA_RESTAURADO` después de la contraseña correcta |
| Qué se rechaza | Toda escritura no marcada en una sesión de esa empresa (PC-6) | Toda escritura no marcada, en **cualquier** base (P-81A-11) |
| Liberación | **R3** (SUPER, motivo de 15 a 200, bitácora y una transacción) | **5.14.2** (SUPER, motivo de 10 a 400, huella y bitácora de seguridad). Con la fase A, además `otp` y autenticación reciente (C) |
| Orden | Después de liberar el sistema | Primero |

**Estados combinados (lo que ve el middleware):** `Candados = Ninguno | Sistema | Empresa | Sistema+Empresa`.

### 4.2 Marca P-7

- **Agregado `MarcaDesbloqueoNcf`** (filas de solo inserción): `EmpresaCodigo`, `NodoId` (1 en la entrega 1), `Prefijo` (el de `fiscal.SecuenciaNcf`, p. ej. `B02` o `E31`), `UltimoProbado bigint`, `Origen` (`DESBLOQUEO` o `RECOMPOSICION`), `ReconciliacionId`, `ForkEmpresa`, `RegistradoUtc` (lo pone la base) y `RegistradoPor`.
- **Marca vigente** = `MAX(UltimoProbado)` por (`EmpresaCodigo`, `NodoId`, `Prefijo`).
- **Por qué con `NodoId`:** en la entrega 2, cada nodo emite desde sus propios bloques del mismo prefijo (ADR-53, cláusula 9). Una marca solo por empresa y prefijo rechazaría el desbloqueo legítimo de un nodo con un bloque más bajo. El costo hoy es una columna.
- **Invariantes:**
  - **I-9.** La marca nunca baja: no hay `UPDATE` ni `DELETE` (disparadores 52008; con RG-14, además `DENY`).
  - **I-10.** En R2 y R3, para cada secuencia vigente cuyo prefijo tiene marca: `UltimoProbado ≥ marca`. Un `null` («no emitió») con marca es un error.
  - **I-11.** Si la marca de un prefijo es mayor que el `Hasta` de toda secuencia vigente de ese prefijo, el desbloqueo no procede. La pantalla pide registrar la secuencia que continúa el rango (R-D5 de [D11]; PC-2).
  - **I-12.** La marca efectiva para validar es `MAX(marca de GPOS_SYSDATA, cortes de las reconciliaciones confirmadas de la propia base)`.
- **Fuente de la recomposición:** `sync.ReconciliacionNcf.UltimoConocido` (el corte) unida a `fiscal.SecuenciaNcf.Prefijo`, de las reconciliaciones con `Estado = 'C'` y `Causa IN ('RESTAURACION','TRASLADO')`. Se ejecuta en cuatro momentos:
  - al liberar `GPOS_SYSDATA`, en todas las empresas (P-81A-12);
  - al arrancar, en segundo plano;
  - en R1 y R2 de la empresa (I-12);
  - después de un fallo al registrar la marca.

### 4.3 Respaldo posterior

- **Agregado `RespaldoPosterior`:**
  - `Id`, `Origen` (`DESBLOQUEO`);
  - `EmpresaCodigo`, `ReconciliacionId`;
  - `BaseDatos` (nombre de la base), `Archivo`;
  - `Estado` (`P` pendiente, `E` en curso, `C` completado, `F` fallido);
  - `SolicitadoUtc`, `TerminadoUtc`, `Intentos`, `Error` (texto neutro).
- **Dos filas por desbloqueo** (empresa y `GPOS_SYSDATA`).
- **Ejecución:** fuera de la transacción de R3, porque `BACKUP` no puede ir dentro de una transacción. Hay un solo trabajador en segundo plano. Los fallos se reintentan 3 veces y después quedan en `F`, con el aviso en R1 y el botón R4.
- **Nombre del archivo:** `<base>_DESBLOQUEO_<reconciliacion>_<AAAAMMDD_HHmmss>.bak`, en `InstanceDefaultBackupPath`, con `COPY_ONLY, INIT, CHECKSUM`.
  - `COPY_ONLY` no corta la cadena del cliente: es la regla de MD-32 y de la evaluación de Backup Tool (`docs/operaciones/2026-10-04-respaldos-con-backup-tool.md:156`) [V].

### 4.4 Eventos

| Dónde | Evento | Cuándo |
|---|---|---|
| `audit.Bitacora` de la empresa (más `_LOG` por `PuenteCfg`) | `CHEQUERA_CONFIRMADA_RESTAURACION` (una línea por cuenta) | R3 con P-3 |
| ídem | `MARCA_P7_REGISTRADA` | Después de registrar la marca, como espejo legible |
| ídem | `RESPALDO_POSTERIOR` (resultado) | Al terminar el respaldo de la base de empresa |
| `dbo.BitacoraSeguridad` (`GPOS_SYSDATA`; tabla del bloque A de [C81]) | `SISTEMA_RESTAURADO` (A), `CANDADO_RESTAURACION_LIBERADO` (A), `ACCESO_RECHAZADO_CANDADO` (M) | Como en [C81] §4.4 |
| ídem | `MARCA_P7_RECOMPUESTA` (I), con el detalle por empresa y prefijo, y las empresas que no se pudieron leer | Al liberar el sistema y al arrancar, solo si cambió algo |
| ídem | `RESPALDO_POSTERIOR_FALLIDO` (A) | Tercer fallo |

---

## 5. Contratos de la API interna

Convenciones de [H11] §5: `ProblemDetails` con `codigo`, aislamiento por la empresa de la sesión y ninguna ruta recibe el código de empresa.

### 5.1 Rutas existentes que cambian (R1 a R3)

| # | Ruta | Cambio | Marca del candado |
|---|---|---|---|
| R1 | `GET /api/admin/sitio/restauracion` | `EstadoRestauracionDto` gana `IReadOnlyList<MarcaP7Dto> Marcas`, `IReadOnlyList<ChequeraRestauracionDto> Chequeras`, `bool SistemaRestaurado` y `RespaldoPosteriorDto? UltimoRespaldo`. En `NORMAL` muestra el último desbloqueo y el estado de su respaldo | `GET`: pasa |
| R2 | `POST …/vista-previa` | `DesbloqueoRestauracionRequest` gana `IReadOnlyList<ChequeraConfirmadaDto> Chequeras`. `Errores` gana I-10, I-11 y las reglas de P-3. Si el sistema tiene candado, el error es «Primero el Super Usuario debe liberar el sistema» | `SoloConsulta` ([C81]: «R2 como consulta») |
| R3 | `POST …/desbloquear` | Mismo pedido. Antes de abrir: **orden** (409 `LIBERAR_SISTEMA_PRIMERO`) y marca **legible** (503 `MARCA_NO_DISPONIBLE`). Después del commit: registra la marca y encola el respaldo. `ResultadoDesbloqueoDto` gana `Chequeras`, `Marcas` y `Respaldos` (las 2 filas en `P`) | `PermitidaConCandado(Empresa)`: libera **solo** el candado de empresa; el del sistema lo rechaza. Con la fase A, C le agrega `RequiereAutenticacionReciente` («R3 como acción sensible») |
| **R4** (nueva) | `POST /api/admin/sitio/restauracion/respaldo` | Reintenta los respaldos `F` del último desbloqueo de la empresa de la sesión. `RequiereSuper`, límite `Desbloqueo`. **202** con `RespaldoPosteriorDto[]`; 409 `SIN_RESPALDO_PENDIENTE` | `PermitidaConCandado(Sistema \| Empresa)` |

### 5.2 DTO nuevos (`GPOS.Contracts/Admin/Restauracion.cs`)

```csharp
public sealed record MarcaP7Dto(string Prefijo, long UltimoProbado, string UltimoNcf, DateTime RegistradoUtc,
    string Origen /* DESBLOQUEO | RECOMPOSICION */, bool CubiertaPorSecuenciaVigente);   // false → I-11

public sealed record ChequeraRestauracionDto(short CuentaBancariaId, string Cuenta, string? Banco,
    int SiguienteEnBase, int? UltimoChequeEnBase /* MAX(número) de banco.DocBanco clase CHK de la cuenta */);

public sealed record ChequeraConfirmadaDto(short CuentaBancariaId, int SiguienteConfirmado, string Referencia /* 5..100: talonario consultado */);

public sealed record RespaldoPosteriorDto(long Id, string BaseDatos, string Estado /* P | E | C | F */, string? Archivo,
    DateTime SolicitadoUtc, DateTime? TerminadoUtc, int Intentos, string? Error);
```

**Validaciones nuevas** (R2 las informa en `Errores`; R3 responde 422 `VALIDACION`):

1. **I-10:** «El último NCF probado de B02 (B0200000140) es menor que el del último desbloqueo registrado (B0200000150, 2026-10-10). Revise la evidencia: la base se restauró de un respaldo anterior a ese desbloqueo.»
2. **I-11:** «El último desbloqueo de B02 llegó a B0200000500 y ninguna secuencia vigente de B02 lo alcanza. Registre primero la secuencia que continúa el rango.» Sin sugerir «No generar comprobante» (regla del 2026-10-02).
3. **P-3:**
   - `Chequeras` cubre **exactamente** las cuentas con fila en `banco.Chequera`;
   - `SiguienteConfirmado ≥ MAX(SiguienteEnBase, UltimoChequeEnBase + 1)` y `≤ 999999999` (`CK_Chequera_Siguiente`, `BanConfiguracion.cs:19`) [V];
   - `Referencia` de 5 a 100 caracteres.

### 5.3 Códigos nuevos

| HTTP | `codigo` | Causa |
|---|---|---|
| 503 | `BASE_RESTAURADA` | Middleware: escritura no permitida con el candado de empresa. También es la traducción del 51403 |
| 503 | `SISTEMA_RESTAURADO` | Middleware (escritura con el candado del sistema, o cualquier petición de un usuario no SUPER) y `/login` de un no SUPER con la contraseña correcta (P-81A-11). Código definido en [C81] 5.13 |
| 409 | `LIBERAR_SISTEMA_PRIMERO` | R3 con el sistema con candado (defensa en el servicio; el middleware ya da 503) |
| 503 | `MARCA_NO_DISPONIBLE` | R3 sin poder leer la marca en `GPOS_SYSDATA`: falla cerrado y no se escribe nada |
| 409 | `SIN_RESPALDO_PENDIENTE` | R4 sin respaldos `F` |
| 409 | `RESTAURACION_ESTADO_CAMBIO` / `SISTEMA_NO_RESTAURADO` | 5.14.2 ([C81]; errores 52004 y 52005) |

Mensajes:
- Empresa: «La base de datos de la empresa se restauró de un respaldo. Solo se permiten consultas hasta que el Super Usuario la revise y la desbloquee.»
- Sistema: el de [C81] §8.8.3.

### 5.4 Guarda común: `ModoCandadoRestauracion`

**Posición:** `app.UseModoCandadoRestauracion()` entre `UseVersionEsquemaEmpresa()` y `UseGuardaSitio()` (`Program.cs:248-250`).
- Va después de la versión del esquema porque, con la versión correcta, la vista ya tiene `Restaurada`.
- Va después de la autorización porque el 401 o 403 de un token inválido se resuelve antes.

**Algoritmo:**

```
activos = (sistema.Activo ? Sistema : 0) | (claim empresa && FuenteEmpresa(empresa).Activo ? Empresa : 0)
si activos = 0                                   → siguiente
agrega X-GPOS-Candado: "sistema" | "empresa" | "sistema,empresa"
si Sistema ∈ activos y el principal es un USUARIO de nivel ≠ SUPER (según el token y la cuenta)
      y la ruta no es /api/auth/salir            → 503 SISTEMA_RESTAURADO           (P-81A-11)
si GET o HEAD                                    → siguiente                        (consulta)
si la ruta tiene SoloConsulta                    → siguiente
si la ruta tiene PermitidaConCandado(c) y (c ⊇ activos) → siguiente
si no                                            → 503 SISTEMA_RESTAURADO si Sistema ∈ activos; si no, BASE_RESTAURADA
```

**Marcas** (`GPOS.Api/Seguridad/ModoCandadoRestauracion.cs`):

```csharp
[Flags] public enum Candados { Ninguno = 0, Sistema = 1, Empresa = 2, Ambos = 3 }
public sealed record PermitidaConCandado(Candados Cuales);   // .PermitidaConCandado(Candados.Ambos)
public sealed record SoloConsulta;                           // POST que solo lee: .SoloConsulta()
```

**Lista blanca de lectura (`SoloConsulta`):**
- R2;
- `POST /api/reportes/{id}/ejecutar`, `/api/reportes/diseno/detectar` y `/vista-previa`;
- `POST /api/consulta-facturas/consulta`;
- `POST /api/numeracion/series/{tipo}/vista-previa` y `/modo-sucursal/vista-previa`;
- `POST /api/admin/formatos/vista-previa`;
- `POST /api/admin/empresas/{codigo}/probar`;
- `POST /api/impresion/reimpresion` (PC-4).

**Lista blanca de escritura (`PermitidaConCandado`):**

| Ruta | Cuales | Motivo |
|---|---|---|
| `POST /api/auth/login`, `/empresa`, `/salir`, `/clave` | Ambos | Entrar y salir; cambio obligatorio (`GSF`, vía b de C) |
| `POST /api/restaurante/dispositivos/token` | Ambos | Latido del dispositivo ([C81] §6.5). Sus escrituras de negocio se rechazan |
| R3 | **Empresa** | Es la liberación de la empresa (D-10) |
| R4 y `POST /api/admin/respaldos` | Ambos | Respaldar no es negocio y conserva la evidencia |
| 5.14.2 `…/sistema/restauracion/liberar` | **Sistema** | Es la liberación del sistema |
| `POST /api/super/reloj/resolver` | Ambos | S9 de [C81] |
| `POST /api/admin/ncf-secuencias` | **Empresa**, solo **alta** y solo el **SUPER** mientras dure el candado (el servicio lo comprueba) | I-11 y R-3 de [H11] (PC-2) |
| Rutas de C (fase A): `/login/alta`, `/login/factor`, `/reautenticar`, `/factor/*`, 5.9 y 5.10 | Ambos | C las marca en sus tandas ([C81] §8.8.4) |

**Escrituras dentro de un `GET` (no las ve el método):** la impresión de documentos, tickets y notas registra la copia y su línea de bitácora. **Se permiten** como efecto de auditoría de una consulta (PC-4). PF-36 las lista en una tabla aparte («GET con efecto»). Si mañana aparece una ruta nueva de ese tipo y no está en esa tabla, la prueba falla.

**Prueba de inventario (PF-36 de [C81], común a los dos candados):**
- toda ruta `POST`, `PUT`, `PATCH` o `DELETE` del `EndpointDataSource` está sin marca, o en la lista aprobada de esta sección con su marca y su `Candados` exactos;
- hoy hay unas 125 rutas de escritura (conteo de `Map{Post,Put,Delete,Patch}` en `src/GPOS.Api/Endpoints`) [V].

**Convivencia:**

| Con | Regla |
|---|---|
| **Dispositivos** (KDS, comanderas, estación) | No son usuarios: la regla de P-81A-11 no los toca. Sus `GET` pasan y sus escrituras se rechazan. `/token` pasa. P-81A-13 (a): la pantalla del sistema lista los dispositivos activos |
| **Agente de impresión** | Solo usa `/api/restaurante/dispositivos/token` y `/actual` (`src/GPOS.AgenteImpresion/Estacion/ClienteDispositivo.cs:110`) [V]: sigue funcionando. La cola de comandas (ADR-114) todavía no existe; cuando exista, sus rutas de escritura quedan sin marca, es decir, rechazadas |
| **Canalización** | Un token con `cambiar_clave = 1` recibe antes el 403 de `CambioClaveObligatorio`; `/clave` pasa los dos. Con un esquema distinto, gana el 503 de `VersionEsquemaEmpresa`. `GuardaSitio` va después |
| **Modo limitado** (`ModoEsquemaPendiente`) | Una empresa sin esquema no tiene `sync.EstadoNodo`, así que no hay candado de empresa. Con el candado del sistema, «Crear / actualizar esquema» queda rechazado (es DDL) y «Probar» pasa (`SoloConsulta`) |
| **Autorización de supervisor** (`POST /api/pos/autorizar`) | Sin marca: rechazada ([C81] 5.12) |
| **API de reportes de B** (ADR-109) | Solo lectura y en otro proceso: no le afecta |

### 5.5 Rutas del candado del sistema (contrato de [C81] 5.14, en la versión sin factor)

- **5.14.1 `GET /api/super/sistema/restauracion`:** sin cambios respecto de [C81], salvo dos campos agregados:
  - `SuperConFactor` vale 0 hasta la fase A;
  - **`Marcas`**: la vista previa de la recomposición, por empresa y prefijo, con las empresas que no responden.
- **5.14.2 `POST /api/super/sistema/restauracion/liberar`:**
  - **Entrada:** `LiberarCandadoRequest(Motivo, Huella)`.
  - **Permisos:** `RequiereSuper` + límite propio de 5 por minuto. **Con la fase A, C agrega** `otp` y `RequiereAutenticacionReciente` sin cambiar la ruta.
  - **Efecto:**
    1. recompone las marcas leyendo cada empresa registrada (las que no responden quedan en la lista; R3 las recompone por I-12);
    2. `EXEC dbo.LiberarCandadoRestauracion`;
    3. refresca el singleton en el acto.
  - **Cambio de contrato respecto de [C81]:** responde **200** `ResultadoLiberacionSistema(IReadOnlyList<MarcaP7Dto por empresa> Recompuestas, IReadOnlyList<string> EmpresasSinLeer)` en lugar de 204, porque la recomposición tiene que informarse. Es un acuerdo técnico con C: no requiere firma.

### 5.6 Inicio de sesión (P-81A-11)

En `/login`, después de validar la contraseña (`AuthEndpoints.cs:37-60`) [V]:
- si el candado del sistema está activo y la cuenta no es SUPER: 503 `SISTEMA_RESTAURADO` con el texto firmado, más el evento `ACCESO_RECHAZADO_CANDADO`;
- con la contraseña incorrecta, sigue el 401 uniforme, para no abrir un oráculo.

`SesionInfo.SistemaRestaurado` y `EmpresaRestaurada` se llenan en `login` y `/empresa`.

---

## 6. Interfaces entre módulos

```csharp
// GPOS.Core/Sistema/Restauracion — singleton; falla cerrado (contrato de [C81] §6.1, construido por A)
public interface ICandadoRestauracionSistema { bool Activo { get; } DateTime? DesdeUtc { get; } void Actualizar(EstadoRestauracionSistemaFila f); }

// Fachada para servicios y trabajos (capa 2)
public interface ICandadosRestauracion
{
    bool SistemaActivo { get; }
    ValueTask<bool> EmpresaActivaAsync(string empresa, CancellationToken ct);   // ComprobadorEsquemaEmpresas, caché 15 s
    void Invalidar(string empresa);                                           // la llama R3 al confirmar
}

public interface IMarcaP7Service
{
    Task<IReadOnlyDictionary<string, MarcaVigente>> LeerAsync(string empresa, short nodo, CancellationToken ct);  // lanza si no puede leer
    Task RegistrarAsync(string empresa, short nodo, int reconciliacionId, Guid fork, IEnumerable<(string Prefijo, long Corte)> cortes, string usuario, CancellationToken ct);
    Task<ResultadoRecomposicion> RecomponerAsync(IEnumerable<string>? empresas, string actor, CancellationToken ct);  // inserta solo lo que sube
}

public interface IRespaldoPosteriorService
{
    Task<IReadOnlyList<RespaldoPosteriorDto>> EncolarAsync(string empresa, int reconciliacionId, string usuario, CancellationToken ct);
    Task<IReadOnlyList<RespaldoPosteriorDto>> ReintentarAsync(string empresa, CancellationToken ct);
}
```

- **`ComprobadorEsquemaEmpresas`:**
  - la consulta de `VersionEsquema` agrega un tercer resultado: `Restaurada`, `EmisionBloqueada` y `MotivoBloqueo` de `sync.EstadoEmision`, solo si `COL_LENGTH('sync.EstadoEmision','Restaurada')` no es nulo;
  - `EstadoEsquemaEmpresa` gana `bool CandadoRestauracion`;
  - `VigenciaCorrecta` pasa de 1 min a **15 s** (lectura de unas decenas de filas por empresa cada 15 s: despreciable [I]).
- **Capa 2 (trabajos):**
  - `TrabajoNotificaciones` omite la empresa con candado y omite todo con el candado del sistema (`EmpresaAsync`, `TrabajoNotificaciones.cs:96`);
  - `TrabajoRncDgii` omite la descarga con el candado del sistema;
  - `TrabajoReloj` sigue: es mantenimiento del reloj protegido, no negocio ([C81] §8.8.3);
  - las semillas y el DDL del arranque también corren.

### 6.1 Flujo de R3 ampliado (sobre [H11] §6.1)

0. **Antes de abrir:**
   - `candados.SistemaActivo` → 409 `LIBERAR_SISTEMA_PRIMERO`;
   - `marcas = MarcaP7.LeerAsync(empresa, nodo)`; si falla → 503 `MARCA_NO_DISPONIBLE`;
   - I-12: `MAX` con los cortes de la propia base.
0b. **Chequeras (nivel de documentos del orden firmado):** se toman los bloqueos `GPOS.Chequera:{cuenta}` en una sola pasada ordinal, **antes** de la apertura (que está en el nivel de configuración). Así se respeta el orden de ADR-45 (`Comun.cs:239-246`) [V].
1. a 5. Como en [H11]. `PlanDesbloqueo.Calcular` recibe además `marcas` y `chequeras` (I-10, I-11 y P-3).
5b. **P-3:** `UPDATE banco.Chequera SET Siguiente = @confirmado` e `INSERT sync.ReconciliacionChequera`, una cuenta por vez en orden de `CuentaBancariaId`; bitácora `CHEQUERA_CONFIRMADA_RESTAURACION`.
6. `usp_ConfirmarReconciliacionLocal` con **C9** (§10.1) y commit.
7. **Fuera de la transacción:**
   - `MarcaP7.RegistrarAsync(...)` con el corte por prefijo. Si falla, el resultado lleva el aviso «La marca del desbloqueo se registrará en segundo plano» y la vigilancia la recompone desde la base, que ya tiene la reconciliación confirmada;
   - `RespaldoPosterior.EncolarAsync(...)`;
   - `candados.Invalidar(empresa)`.
   - Las escrituras vuelven en menos de 1 s, en vez de esperar los 15 s de la caché.

**Por qué la marca va después del commit y no antes:** si se escribiera antes y la transacción de la empresa se deshiciera, la marca quedaría por encima de lo que realmente se usó. El próximo desbloqueo exigiría un último NCF que nunca se emitió, y no habría salida. Después del commit, el peor caso es una marca atrasada por unos segundos, y la recomposición la corrige.

*Alternativa descartada:* una transacción distribuida (MSDTC) entre las dos bases. Express la admite [I], pero agrega un servicio y su configuración en cada equipo por un caso que la recomposición ya cubre.

---

## 7. Estructura de proyectos y carpetas

```
src/GPOS.Contracts/Admin/Restauracion.cs                          (DTO y códigos nuevos)
src/GPOS.Contracts/Seguridad/Cuentas.cs                           (SesionInfo +2; EstadoRestauracionSistema, LiberarCandadoRequest, ResultadoLiberacionSistema)
src/GPOS.Core/Sistema/Restauracion/CandadoRestauracionSistema.cs, RestauracionSistemaService.cs, MarcaP7Service.cs, RespaldoPosteriorService.cs
src/GPOS.Core/Consultas/Sistema/Restauracion/ConsultasRestauracionSistema.cs, ConsultasMarcaP7.cs, ConsultasRespaldoPosterior.cs   (SQL a mano; parámetros con el tipo de su columna)
src/GPOS.Core/Consultas/Sitio/ConsultasRestauracion.cs            (+ chequeras, cortes de la propia base, cheques emitidos)
src/GPOS.Core/Data/Sistema/EsquemaSistema.cs                      (SQL de §10.2)
src/GPOS.Core/Infraestructura/EsquemaEmpresasNg.cs, Motor/VersionEsquema.cs, CandadosRestauracion.cs
src/GPOS.Core/Servicios/RestauracionSitioService.cs, Modulos/Sitio/PlanDesbloqueo.cs
src/GPOS.Core/Datos/Empresa/Migraciones/2026101xxxxxxx_H11CandadoChequeras.cs + SqlMigracionesH11CandadoChequeras.cs
database/empresa/gpos-empresa-2026101xxxxxxx_H11CandadoChequeras.sql   (regenerado con --idempotent; sustituye al anterior)
src/GPOS.Api/Seguridad/ModoCandadoRestauracion.cs; Servicios/TrabajoVigilanciaRestauracion.cs, Inicializacion.cs
src/GPOS.Api/Endpoints/*.cs                                       (marcas §5.4; R4; 5.14 en AdminEndpoints; /login en AuthEndpoints)
src/GPOS.Web/Components/Compartidos/RestauracionSitio.razor, FranjaCandado.razor; Layout; Pages/Admin/RestauracionSistema.razor; Servicios/ApiClient*.cs
GPOS.UI.MAUI/… (las mismas copias)
tests/GPOS.Tests/ModeloNg/CandadoRestauracionTests.cs, MarcaP7Tests.cs, RestauracionSistemaTests.cs, InventarioCandadoTests.cs
tests/GPOS.Web.Tests/…, tests/GPOS.UI.MAUI.Tests/… (bUnit)
```

### 7.1 Pantalla: la tarjeta «Restauración de la Base» ampliada

Se mantiene donde está: pestaña Diagnóstico de `Pages/Admin/Numeracion.razor:102-104`, Web y MAUI [V]. El título va con mayúsculas de título (RG-30).

| Estado | Lo nuevo |
|---|---|
| Cualquiera, con el **sistema** con candado | Alerta arriba: «El sistema se restauró de un respaldo. Primero el Super Usuario debe revisarlo y liberarlo en Administración › Restauración del Sistema; después podrá desbloquear esta base.» La vista previa sigue disponible; «Desbloquear…» queda deshabilitado |
| `RESTAURADA`, SUPER, bloque de secuencias | Columna **«Último desbloqueo registrado»** (el NCF de la marca, con fecha y origen). Si la marca supera el último NCF de la base, se marca la fila: «La base es anterior al último desbloqueo». Con I-11, alerta con el botón **«Registrar Secuencia»**, que abre el alta de secuencias NCF en un diálogo (PC-2) |
| `RESTAURADA`, SUPER, bloque nuevo **«Chequeras»** (P-3) | Por cuenta: banco y cuenta, «Siguiente en la base», «Último cheque emitido en la base» y el campo **«Siguiente cheque en blanco»**, con el botón «Igual al de la base» (copia el mayor de los dos), más «Referencia del talonario». Sin cuentas con chequera, el bloque no se muestra |
| Diálogo de confirmación | Resumen con las chequeras; la casilla agrega «y el siguiente cheque de cada cuenta» |
| Resultado | Además de lo de [H11]: «Respaldo posterior: base de la empresa *en curso / hecho (archivo, hora) / falló*; base del sistema *…*». Con un fallo, botón **«Reintentar Respaldo»** (R4) |
| `NORMAL` | La línea verde, más «Último desbloqueo: *fecha*, reconciliación *n*; respaldo posterior *hecho / falló* [Reintentar]» |
| ADMIN | Solo las alertas, sin formulario (como hoy) |

**Franja global** (layout de Web y MAUI). Aparece con `SesionInfo.SistemaRestaurado` o `EmpresaRestaurada`, con el encabezado `X-GPOS-Candado` de cualquier respuesta o con un 503 `SISTEMA_RESTAURADO` o `BASE_RESTAURADA`. **No cierra la sesión.**
- Con el candado del sistema, el texto de [C81] §15.9.
- Con el de la empresa: «La base de datos de *{empresa}* se restauró de un respaldo. Solo se permiten consultas hasta que el Super Usuario la revise y la desbloquee.»
- El SUPER ve además **[Revisar]**, que lleva a la tarjeta o a la pantalla del sistema.
- `ApiClient` trata los dos 503 **antes** de la regla general (`src/GPOS.Web/Servicios/ApiClient.cs:149-151`, citado en [C81]).

**Pantalla «Restauración del Sistema»** (`/super/restauracion-sistema`, solo SUPER; con D-11). Es [C81] §15.11 sin lo del factor:
- estado y forks abreviados;
- último evento previo;
- lista de revisión: usuarios inhabilitados o con la contraseña cambiada después, empresas registradas y **dispositivos activos** (P-81A-13 a);
- **«Marcas que se recompondrán»** por empresa y prefijo, más las empresas que no responden;
- el aviso del orden de liberación;
- el motivo y **[Liberar el Sistema]**.

C le agrega los datos del factor en su T7 y T8.

El texto definitivo es del diseñador UX (entrega en el Cierre).

---

## 8. Requisitos de seguridad de arquitectura

- **Autenticación:** sin cambios hasta la fase A. La liberación del sistema la hace un SUPER con contraseña hasta que C agregue `otp` y la autenticación reciente.
  - **Riesgo transitorio:** entre las dos uniones, la liberación del sistema no pide el segundo factor. Es Bajo hoy, porque todo es desarrollo y DEMO, y se cierra con la fase A antes del primer cliente.
- **Autorización:**

  | Acción | Quién | Dónde se comprueba |
  |---|---|---|
  | R3 y R4 | SUPER (H-13) | Ruta y servicio |
  | 5.14.x | SUPER | Ruta; en el procedimiento, el error 52007 ([C81] bloque B) |
  | Alta de secuencias con candado | Solo el SUPER | Servicio |

  La regla de P-81A-11 se aplica en `/login` y en el middleware: según el token **y** según la cuenta, como `ModoEsquemaPendiente.cs:52-61`.
- **Aislamiento:**
  - la marca lleva `EmpresaCodigo`, que sale de la sesión (nunca del cuerpo);
  - la recomposición lee cada empresa con su propia cadena (`IConexionesEmpresa`);
  - ninguna ruta recibe el código de empresa.
- **Integridad de la marca:**
  - solo inserción, con disparadores `INSTEAD OF UPDATE` y `INSTEAD OF DELETE` (52008) que se recrean y se habilitan en cada arranque (D81-06);
  - con RG-14: `DENY UPDATE, DELETE, ALTER` y escritura solo por `dbo.RegistrarMarcaP7` con `EXECUTE AS OWNER`, que inserta solo si sube.
  - **Riesgo residual:** sin RG-14, la cuenta de la API puede deshabilitar el disparador (A-09 aceptado, R-06 de [C81]).
- **Fallo seguro:**
  - el singleton del sistema arranca activo;
  - sin poder leer la marca no hay desbloqueo;
  - la vista de la empresa falla cerrada;
  - una ruta nueva sin marca queda rechazada.
- **Secretos:** no hay secretos nuevos. El respaldo usa la cuenta de la API, así que no hace falta una clave de Backup Tool en la configuración (ADR-44). Los `.bak` quedan sin cifrar en `InstanceDefaultBackupPath`, igual que hoy con «Respaldar ahora»: esa exposición ya existe (N-3 de la evaluación de Backup Tool). La custodia y el cifrado fuera del equipo son de devops.
- **Permisos de SQL nuevos para la cuenta de la API** (devops, con RG-14):
  - `BACKUP DATABASE` en `GPOS_SYSDATA` y en cada base de empresa (`db_backupoperator`), que ya hace falta hoy para `RespaldoService`;
  - `EXECUTE` sobre los procedimientos de §10.2.
- **Oráculos:** el 503 de P-81A-11 solo sale con la contraseña correcta; los tiempos son iguales a los del 401 [I]. Lo revisa el auditor.

---

## 9. Sincronización

No aplica en la entrega 1.
- En la entrega 2, una base de sucursal restaurada queda en `REQUIERE_CENTRAL` y la libera la reconciliación con la central (cláusula 9).
- La marca ya está separada por `NodoId`.
- Si el nodo tiene su propio `GPOS_SYSDATA`, la detección de §4.1 se repite por nodo ([C81] §9).

---

## 10. Entregas al arquitecto-datos

### 10.1 Base de empresa: migración `H11CandadoChequeras` (después de `20261010130522_BitacoraLogSoloInsercion`)

1. **Disparador del candado sobre `doc.Documento`** (`AFTER INSERT, UPDATE`):
   - si `sync.EstadoNodo` está restaurado (misma condición que 51330: fork nulo o distinto, o `EmisionBloqueada = 1`), **THROW 51403** «La base fue restaurada: no se registran documentos hasta desbloquearla (CR-01).»;
   - conserva la excepción de `gpos.reaplicacion` (entrega 2);
   - cubre borradores, emisión, anulación y cualquier cambio de un documento, que es todo el negocio documental (ventas, compras, inventario, cobros, pagos y bancos).
   - **El arquitecto-datos decide si lo funde** con `TR_Documento_Nace` y `TR_Documento_Inmutable` (`DisparadoresNg.cs:31-32`) para compartir la lectura.
   - **Medida obligatoria:** `Ola4AplicacionEmision` y la 8.2 (5), recalibrada a 0,55 ms; tope de +0,03 ms por emisión [I].
   - **Las migraciones de datos futuras sobre `doc.Documento`** deshabilitan y reactivan el disparador, con el patrón que ya existe (`SqlMigracionesOla4OrdenRecibida.cs:67`).
2. **`DisparadoresNg`:** registrar el disparador nuevo para que «Crear / actualizar esquema» lo recree.
3. **`sync.usp_ConfirmarReconciliacionLocal`** (`CREATE OR ALTER`) con la regla **C9 (P-3)**:
   - cada cuenta con fila en `banco.Chequera` tiene su fila en `ReconciliacionChequera` de esta reconciliación;
   - `banco.Chequera.Siguiente = SiguienteConfirmado`;
   - `SiguienteConfirmado ≥ SiguienteLocal` y `> MAX(número de cheque)` de `banco.DocBanco` en la cuenta.
   - Si falla: 51329 con la regla «C9».
4. **`sync.ReconciliacionChequera`:** columna `Referencia varchar(100) NULL`, como en `ReconciliacionNcf`.
5. **Traducción:** 51403 → 503 `BASE_RESTAURADA` en `ErroresNumeracion` (como 51330 en `:341-344`).
6. **`Down`** con la convención 51399 y la prueba PD-01 con el nombre fijo de la migración (§13.4).
7. **[v2]** Error del piso de NCF: **51404** (V2.1). 51392 está reservado por ADR-78: no se usa. El número final lo asigna el arquitecto-datos.

### 10.2 `GPOS_SYSDATA`: SQL idempotente en `EsquemaSistema.ActualizarAsync`

| Objeto | Origen | Nota |
|---|---|---|
| `dbo.BitacoraSeguridad`, sus 2 índices, sus 2 disparadores y `ENABLE` | **Bloque A de [C81], sin cambios** (texto firmado, D81-05 y D81-06) | Sin `PurgarBitacoraSeguridad` ni su trabajo: los construye C en T2 |
| `dbo.RestauracionSistema`, la vista `dbo.EstadoRestauracionSistema` y `dbo.LiberarCandadoRestauracion` | **Bloque B de [C81], sin cambios** | Validar contra una restauración real (pendiente desde [C81]). `Nivel = 'SUPER'` queda verificado (§1.1) |
| `dbo.ReconciliarRestauracionSistema` | Bloque B **sin** los pasos que dependen de columnas que aún no existen: sin `SelloSeguridad` ni `SesionTokenId` (CS-1, CS-2), y sin el `UPDATE` de `UsuariosFactor`. **Sí** cierra las sesiones (`SesionId = NULL`, `SesionesRevocadas = @ahora`; columnas existentes, `EsquemaSistema.cs:48-54` [V]) | C lo reemplaza con el texto completo (`CREATE OR ALTER`) en su T5b |
| `dbo.MarcaDesbloqueoNcf` | Nuevo (§4.2): PK `Id bigint IDENTITY`; índice `(EmpresaCodigo, NodoId, Prefijo, UltimoProbado DESC)`; `CHECK (Origen IN ('DESBLOQUEO','RECOMPOSICION'))`, `CHECK (UltimoProbado >= 0)`; `RegistradoUtc DEFAULT SYSUTCDATETIME()`. `Prefijo varchar(3)` y `EmpresaCodigo nvarchar(30)` (texto Unicode en `GPOS_SYSDATA`: ADR-50 no aplica) | Disparadores `INSTEAD OF UPDATE` y `INSTEAD OF DELETE` → **52008** |
| `dbo.RegistrarMarcaP7` (`EXECUTE AS OWNER`) | Nuevo | Inserta solo si `@UltimoProbado > MAX` vigente; devuelve las filas insertadas |
| `dbo.RespaldoPosterior` | Nuevo (§4.3); `CHECK` de `Estado` y `Origen`; índice `(Estado, SolicitadoUtc)` | Estado del trabajo; lo lee devops |
| Permisos con RG-14 | Los de [C81] §7.4, más `GRANT EXECUTE ON dbo.RegistrarMarcaP7`, `DENY INSERT, UPDATE, DELETE, ALTER ON dbo.MarcaDesbloqueoNcf` y `GRANT SELECT, INSERT, UPDATE ON dbo.RespaldoPosterior` | — |

Errores **52008** (marca inmutable) y **52009** (reserva). Quedan apartados para A dentro de la reserva 52001-52019. Hay que avisarlo a C y al documentador.

### 10.3 Volumen y costo

- La marca ocupa una fila por prefijo y desbloqueo (menos de 1 KB por desbloqueo); el respaldo posterior, dos filas.
- El disco de los `.bak` es de devops: **2 copias completas por desbloqueo**. Una empresa de Express ocupa como máximo 10 GB por base [V, límite de la edición]; un desbloqueo es un evento raro.
- Costo de infraestructura: USD 0.

---

## 11. Riesgos

| Id | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-9 | Una ruta de escritura mal marcada | Media / alto | Rechazo por omisión; PF-36 con la lista aprobada; revisión del auditor (R-13 de [C81]) |
| R-10 | **Restauración sin fork nuevo.** **[v2] Verificado por C (C2-04):** adjuntar una copia anterior de los `.mdf` y `.ldf` conserva el fork y la base no se detecta. Revertir una instantánea de la base sí lo cambia. Una máquina virtual revertida entera no se cubre | Baja / alto | **[v2]** Detección por regresión al arrancar y cada 5 min (V2.3), más el latido si se firma PC-10. Guía de devops: solo `RESTORE`; ni copias adjuntadas ni instantáneas de la máquina virtual con las bases en uso |
| R-11 | **Restaurar la empresa y `GPOS_SYSDATA` desde respaldos anteriores al último desbloqueo, a la vez:** la marca no se puede recomponer | Baja / alto | El respaldo posterior de las dos bases (D-9); riesgo Medio aceptado hasta H-14 (ADR-53, precisión 1, punto 9) |
| R-12 | Restaurar sin detener la API (contra R-6): hasta 15 s sin candado en la capa HTTP | Baja / bajo | Los disparadores 51330 y 51403 actúan de inmediato; R-6 en la guía |
| R-13 | El respaldo posterior falla (disco lleno o sin permiso) | Media / medio | Estado `F`, alerta a devops y R4. La marca ya quedó registrada |
| R-14 | Choque de archivos con C (fase A: `AuthEndpoints.cs`, `AdminEndpoints.cs`, `Program.cs`, `EsquemaSistema.cs`, `Cuentas.cs`, `ApiClient.cs`) y con H-2 de A (`fiscal.Comprobante`, migración siguiente) | Media / calendario | §13.3: este PR entra primero; C y H-2 se rebasan |
| R-15 | El disparador de `doc.Documento` pasa el presupuesto de rendimiento | Baja / medio | Medir en 8.2 (5); fundirlo con los existentes |
| R-16 | Una escritura de negocio dentro de un `GET` que no esté listada | Baja / medio | Tabla «GET con efecto» en PF-36; regla de revisión: ninguna escritura de negocio nueva en un `GET` |

---

## 12. Preguntas (cada una con su opción por omisión)

| # | Pregunta | Opciones | Recomendación y costo [I] |
|---|---|---|---|
| **PC-1** (coordinación B; con acuerdo de C) | ¿Quién construye el núcleo del candado de `GPOS_SYSDATA` (detección, reconciliación sin factor, liberación, regla de P-81A-11, `BitacoraSeguridad`)? | (a) **A, en este PR**; C agrega lo del factor. (b) C, en su T5b, como en [C81] | **(a).** Cierra R-16 de [C81]. P-81A-12 lo necesita para recomponer la marca. Evita que dos árboles toquen `EsquemaSistema.cs` y `AuthEndpoints.cs` por el mismo motivo. A: +0,55 sp; C: su T5b baja de 0,9 a ≈ 0,35 sp. En total, ≈ 0 sp. *Por omisión:* (a) |
| **PC-2** (propietario) | Con la base de empresa con candado, ¿se pueden **dar de alta** secuencias NCF (las registradas después del respaldo, I-11)? | (a) **Sí, solo el alta y solo el SUPER**, mientras dure el candado. (b) Dentro del propio R3. (c) No: se registran después de desbloquear | **(a).** Con (c) no se puede desbloquear cuando la marca supera el rango de la base (I-11). (b) complica R3. 0,05 sp. *Por omisión:* (a) |
| **PC-3** (propietario y devops) | ¿Quién ejecuta el respaldo posterior? | (a) **La API** (`COPY_ONLY` de las dos bases, en segundo plano); Backup Tool toma los archivos para la copia fuera del equipo. (b) Backup Tool, a pedido de la API por su interfaz | **(a).** Sin secretos nuevos ni dependencia de una herramienta que aún no cumple MD-32. Sigue el patrón existente. 0,15 sp en A y ≈ 0,1 sp en devops. (b) agrega una clave de Backup Tool en la configuración: ≈ 0,3 sp. *Por omisión:* (a) |
| **PC-4** (propietario) | Con candado, ¿se puede **imprimir y reimprimir** (registra la copia y su línea de bitácora)? | (a) **Sí**, como consulta con su registro de auditoría. (b) No | **(a).** Imprimir no transacciona, y el cliente puede necesitar la copia durante la revisión. 0 sp. *Por omisión:* (a) |
| **PC-5** (coordinación B) | ¿Un PR o dos? | (a) **PR-2a:** middleware, candado de empresa, disparador, P-7, P-3 y respaldo (≈ 1,85 sp). **PR-2b:** núcleo del candado de `GPOS_SYSDATA` y recomposición al liberar (≈ 0,55 sp). (b) Uno solo (≈ 2,4 sp) | **(a)** si la fecha importa: PR-2a sale unos 1,5 días antes. Con (a), P-81A-12 queda completo solo con PR-2b. *Por omisión:* (b) |
| **PC-6** (propietario) | Con la base de **empresa** con candado, ¿se rechazan también las escrituras de `GPOS_SYSDATA` hechas desde una sesión de esa empresa (usuarios, perfiles)? | (a) **Sí**, todo lo de esa sesión (simple; basta cambiar de empresa). (b) Solo lo que escribe en la base de la empresa: hay que clasificar cada ruta por base | **(a).** Es más simple y seguro, y el SUPER puede administrar desde otra empresa. (b) cuesta +0,05 sp y otra lista que mantener. *Por omisión:* (a) |

---

## 13. Pruebas de aceptación, coordinación con C y revisión de los ajustes de B

### 13.1 Pruebas (con restauraciones reales: `BACKUP COPY_ONLY` → actividad → `RESTORE WITH REPLACE` → `ClearPool`, como CA-H11 de [H11] §13)

| Id | Caso | Esperado |
|---|---|---|
| CA-CR-01 | **Empresa restaurada** | R1 `RESTAURADA`. `POST` de una venta, un artículo y un precio → 503 `BASE_RESTAURADA`, sin cambios en filas ni contadores. `GET` → 200 con `X-GPOS-Candado: empresa`. `INSERT` directo de un borrador y anulación en el motor → 51403; caja → 51330. R2 200. R3 200 → las escrituras pasan en menos de 1 s y el encabezado desaparece |
| CA-CR-02 | **`GPOS_SYSDATA` restaurada** (base temporal `GPOS_TEST_SYS_*`): respaldo → alta de un usuario y de un dispositivo → `RESTORE` → arranque | Sesiones cerradas. **Un solo** `SISTEMA_RESTAURADO` aunque se reinicie dos veces. USER y ADMIN con la contraseña correcta → 503 y `ACCESO_RECHAZADO_CANDADO`; con la incorrecta → 401. El SUPER entra y consulta. `POST /api/admin/usuarios` → 503. **R3 de una empresa restaurada → 503 `SISTEMA_RESTAURADO`**. La lista muestra el dispositivo. Liberar → 200 con `Recompuestas` → R3 pasa |
| CA-CR-03 | **Base de «sucursal»** (empresa con otro nodo activo en `sync.Nodo`) restaurada | Candado; R1 `REQUIERE_CENTRAL`; R3 409; las escrituras siguen en 503 |
| CA-CR-04 | Restauración **sin detener** la API | Disparadores de inmediato; 503 HTTP en 15 s o menos |
| CA-P7-01 | Desbloqueo con corte B02 = 150 | Una fila `DESBLOQUEO` en la marca; `audit.Bitacora` `MARCA_P7_REGISTRADA` |
| CA-P7-02 | Restaurar un respaldo **anterior** a ese desbloqueo; último probado 140 | R2: error I-10; R3: 422. Con 150 → pasa |
| CA-P7-03 | Marca 500 y secuencia vigente hasta 300 | Error I-11. Alta de la secuencia por el SUPER con candado → pasa; por el ADMIN → 503 o 403 (PC-2) |
| CA-P7-04 | `UPDATE` o `DELETE` sobre `MarcaDesbloqueoNcf` | 52008; `DISABLE TRIGGER` y nuevo arranque → habilitado otra vez |
| CA-P7-05 | `GPOS_SYSDATA` inaccesible durante R3; fallo forzado al registrar la marca después del commit | 503 `MARCA_NO_DISPONIBLE`, sin cambios. Con el fallo posterior: aviso en el resultado y la vigilancia la recompone en el siguiente ciclo |
| CA-P7-06 | **P-81A-12:** desbloqueo (marca 150) → restaurar `GPOS_SYSDATA` desde un respaldo previo (sin marca) → liberar | Marca recompuesta a 150 desde `sync.Reconciliacion`; `MARCA_P7_RECOMPUESTA`. Variante con la empresa también restaurada a un punto anterior: queda documentado el residual R-11 |
| CA-RESP-01 | Desbloqueo | Dos filas `C`; los dos `.bak` existen y pasan `RESTORE VERIFYONLY … WITH CHECKSUM`. Ruta inválida → `F` tras 3 intentos y `RESPALDO_POSTERIOR_FALLIDO`; R4 → `C` |
| CA-P3-01 | Chequeras | Falta una cuenta, `SiguienteConfirmado` menor que el último emitido + 1, o referencia corta → 422. Correcto → el primer cheque sin número después toma el confirmado. Regla C9 rota a mano → 51329 «C9» |
| CA-INV-01 | Inventario de rutas (PF-36) | Toda ruta de escritura sin marca o en la lista de §5.4 con su `Candados`; tabla «GET con efecto» |
| CA-MW-01 | Middleware (unitaria, como PF-08) | `GET` pasa; `POST` sin marca → 503; `SoloConsulta` pasa; `PermitidaConCandado(Empresa)` con el sistema activo → 503; estado inicial del sistema activo hasta la primera lectura |
| CA-CONV-01 | Convivencia | Token con `cambiar_clave` y el sistema con candado → `/clave` pasa. Modo limitado → «Probar» pasa y «Esquema» → 503. Dispositivo → `GET` pasa, `/token` pasa y una escritura → 503. Supervisor → 503 |
| CA-JOB-01 | Trabajos | Las notificaciones no tocan la empresa con candado; el RNC no descarga con el candado del sistema; el reloj sigue |
| CA-UI-01 | bUnit, Web y MAUI | Estados de §7.1; franja con el encabezado y con el 503, sin cerrar la sesión; «Desbloquear…» deshabilitado con el sistema con candado; bloque de chequeras; «Reintentar Respaldo» |
| CA-REND-01 | Rendimiento | 8.2 (5) ≤ 0,55 ms con el disparador nuevo (ajuste de B). La lectura del candado agrega como mucho una consulta por empresa cada 15 s |

**Suites:** `tests/GPOS.Tests`, con el filtro oficial y nunca dos suites completas a la vez (`CLAUDE.md`). Las pruebas del sistema apuntan `ConnectionStrings:Sistema` a `GPOS_TEST_SYS_*`, **nunca al `GPOS_SYSDATA` real**.

### 13.2 División del trabajo con C (fase A de ADR-81)

| Pieza | A (este PR) | C (fase A) |
|---|---|---|
| Middleware `ModoCandadoRestauracion`, marcas, encabezado y PF-36 | **Construye** | Marca sus rutas nuevas (lista de [C81] §8.8.4) |
| Fuente del candado de empresa | **Construye** | — |
| Fuente del sistema (`ICandadoRestauracionSistema`, `TrabajoVigilanciaRestauracion` cada 15 s) | **Construye** (PC-1 a) | Puede sumar la lectura por petición de CS-3; no es necesaria |
| `RestauracionSistema`, la vista y `LiberarCandadoRestauracion` (bloque B) | **Construye sin cambios** | — |
| `ReconciliarRestauracionSistema` | Versión sin factor | **Texto completo** en T5b (sello, `SesionTokenId`, `UltimoPaso`, `CodigosRevividos`) |
| `BitacoraSeguridad`: tabla, índices y disparadores (bloque A) | **Construye sin cambios** | `PurgarBitacoraSeguridad`, su trabajo, `BitacoraSeguridadService` con el limitador (D81-10) y la consulta 5.11 |
| 5.14.1 y 5.14.2 | **Construye** (200 con la recomposición) | Agrega `otp` y `RequiereAutenticacionReciente`; `SuperConFactor` |
| P-81A-11 en `/login` y en el middleware | **Construye** | La conserva al rehacer `/login` en dos pasos (T4) |
| `SesionInfo.SistemaRestaurado` | **Lo define** | Agrega `MinutosInactividad` |
| R3 como acción sensible | — | `RequiereAutenticacionReciente` en R3 (T6) |
| Marca P-7 y recomposición (P-81A-12) | **Construye** | — |
| Pantalla «Restauración del Sistema» | Versión sin factor | Aviso P-D81-01 y datos del factor |
| Errores de `GPOS_SYSDATA` | 52003-52007 (de C, implementados por A) y 52008-52009 (de A) | 52001, 52002 y 52010-52019 |

**Orden de unión:** este PR entra primero. C rebasa T2 a T5b sobre él. Los objetos son idempotentes (`IF OBJECT_ID … IS NULL` y `CREATE OR ALTER`) y el texto es el firmado, así que no hay deriva.

**Un solo editor por árbol:** A no toca la rama de C ni C la de A. Los archivos comunes (`AuthEndpoints.cs`, `AdminEndpoints.cs`, `Program.cs`, `EsquemaSistema.cs`, `Cuentas.cs` y `ApiClient.cs`) solo cambian en serie. H-2 de A va después de este PR (migración siguiente).

### 13.3 Esfuerzo total de la instalación con PC-1 (a)

- A: +2,4 sp.
- C: −0,55 sp (T5b de 0,9 a ≈ 0,35).
- Duplicación evitada: ≈ 0,1 sp [I].

### 13.4 Revisión de los dos ajustes de B (`45190fa`)

| Ajuste | Dictamen | Detalle |
|---|---|---|
| `DesbloqueoRestauracionMigracionTests.PD01`: nombre fijo `20261010100307_H11DesbloqueoRestauracion` y `Pendientes` después de aplicarla | **Aprobado** | Es correcto: H-11 ya no es la última migración y, con la base en H-11, `verificar` debe decir `Pendientes` (código 2, DM-02). El nombre fijo sigue el patrón de la constante `Ola4` de la misma clase. El caso «al día» lo cubre la prueba de `Verificar` con todas las migraciones. Para la migración nueva, la prueba análoga se escribe **así desde el principio**: nombre fijo y `Down` hasta `BitacoraLogSoloInsercion` |
| `SeparacionTokensTests.QueNoRechazanAsync` acepta 429 | **Aprobado con observaciones** (Baja) | **Causa verificada:** el método compartido lo usa también `DispositivosK1Tests` (`:1116-1119`), cuya fábrica tiene los límites **habilitados** (`:85`); la de `SeparacionTokensTests` los deshabilita (`:56`). El limitador va antes de la autorización (`Program.cs:240-241`) y la partición `Desbloqueo` es por usuario, con 5 por minuto (`LimitesPeticiones.cs:29,57-58`): el mismo token que recorre R2 y R3 en varios tipos agota el cupo.<br>**El problema:** aceptar 429 en **todas** las rutas debilita la prueba. Una ruta con límite y **sin** autorización pasaría si el limitador cortara primero.<br>**Corrección propuesta:** aceptar 429 solo en las rutas cuyo metadato tiene `EnableRateLimitingAttribute`. Para esas, una prueba aparte con una partición limpia (usuario nuevo, o la fábrica de `SeparacionTokensTests`, que ya tiene `GPOS:Limites:Habilitado=false` en `:56`) que exija 401 o 403. Esfuerzo: 0,02 sp, dentro de este PR |

---

## 14. Esfuerzo [I], ±40 %

| Parte | sp |
|---|---|
| Middleware, marcas en unas 125 rutas, encabezado y PF-36 | 0,35 |
| Fuente de empresa (comprobador, caché e invalidación) y capa 2 (trabajos) | 0,15 |
| Migración de empresa: disparador 51403, C9, columna y medición | 0,15 |
| P-7: tabla, procedimiento, servicio, validaciones I-10 a I-12, registro y recomposición | 0,25 |
| Respaldo posterior: cola, ejecución, R4 y estados | 0,15 |
| P-3: chequeras en R1, R2 y R3, con el bloqueo ordinal | 0,10 |
| Pantallas: tarjeta (Web y MAUI) y franja | 0,30 |
| Pruebas con restauraciones reales de empresa y sucursal, bUnit y corrección de SeparacionTokens | 0,30 |
| Correcciones de QA y de seguridad | 0,10 |
| **Subtotal sin D-11** | **1,85** |
| **D-11** (PC-1 a): núcleo del candado del sistema, `BitacoraSeguridad`, 5.14, P-81A-11, pantalla del sistema y prueba de restauración real de `GPOS_SYSDATA` | **0,55** |
| **Total** | **2,4 (de 1,45 a 3,35)** |

**Fecha del PR [I]:**
- A unos 0,9 sp por día de un desarrollador (la velocidad de 4,6 sp por semana de [C81]), son **unos 2,5 a 3 días hábiles**.
- Si la fecha se había calculado para P-7 sola (0,15 a 0,2 sp, [D11] §14), **se mueve unos 2 días hábiles**.
- Con PC-5 (a), PR-2a sale en unos 2 días y PR-2b alrededor de 1 día después.
- **Costo:** unos USD 3.600 a 4.800 (USD 1.500 a 2.000 por sp, la base de [C81]). Infraestructura: USD 0. Disco de los respaldos: el de devops.

---

### Cierre
- Estado: Completado (diseño, **versión 2**). Preguntas **Pendientes de firma**:
  - PC-1 a PC-6, con PC-2 recomendada ahora en (c);
  - **PC-7 a PC-10**, que requieren la firma del propietario (precisión de la cláusula 9 de ADR-53 y extensión de P-7).

  Todas tienen opción por omisión. **C2-01 impide publicar mientras no se construya.**
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\blueprint-h11-p7-candado-2026-10-10.md` (versión 2, con los cambios marcados [v2] y la sección V2).
- Supuestos:
  - (1) el fork cambia con todo `RESTORE … WITH RECOVERY` y con la reversión de una instantánea de la base; no cambia al adjuntar una copia, como verificó C (C2-04);
  - (2) el bloque B de [C81] funciona con una restauración real, sin probar;
  - (3) unos 0,9 sp por día;
  - (4) unas 125 rutas de escritura, por conteo de texto;
  - (5) los disparadores 51403 y 51404 caben en el presupuesto de 8.2 (5);
  - (6) `EXECUTE AS OWNER` lee el fork (PD-05);
  - (7) **[v2]** la lectura sin caché del candado en las escrituras cuesta unos 0,2 ms;
  - (8) **[v2]** 51401-51404 están libres (búsqueda en `Migraciones/*.cs`); 51387-51393 son de ADR-78 (arquitecto-datos).
- Decisiones candidatas a ADR (como precisiones de ADR-53, cláusula 9, y de ADR-81):
  - D-6 a D-12;
  - **[v2]** D-13 (último momento congelado en la primera detección);
  - **[v2]** el piso de NCF por prefijo (PC-7), los bloques `C` en el desbloqueo (PC-8), la zona sin bloque (PC-9) y el latido de numeración (PC-10), una vez firmados;
  - la detección por regresión;
  - la reserva de 51403, 51404, 52008 y 52009;
  - el cambio de 5.14.2 a 200.
- Entregas a otros agentes:
  - **arquitecto-datos (A)** → §10, más **[v2]**:
    - `fiscal.PisoNcf`, `sync.ReconciliacionPiso`, la regla C10 y `TR_SecuenciaNcf_Piso` (51404);
    - C3 y C4 con los bloques `C`;
    - la zona sin bloque;
    - `sync.DeteccionRestauracion` y `usp_RegistrarDeteccion`;
    - `usp_BloquearPorRegresion`;
    - si se firma PC-10, el latido en `GPOS_SYSDATA`;
  - **desarrollador-backend** → §5, §6, §13.4 y V2.1 a V2.5;
  - **desarrollador-frontend** → §7.1 con la declaración por prefijo (V2.1);
  - **disenador-ux-ui** → los textos, con la tarjeta agrupada por prefijo;
  - **especialista-pos** → P-3 y PC-4, más **[v2]** PC-7 a PC-9 con el contador (piso y zona sin bloque);
  - **devops** → PC-3 y la guía de R-10 **[v2]** (sin copias adjuntadas ni instantáneas de la máquina virtual);
  - **qa** → §13.1 y CA-H11-19 a 22; **[v2]** decisión de B sobre el filtro de carga (C2-06);
  - **auditor-seguridad** → §5.4, §8 y **[v2]** el piso;
  - **equipo C (vía B)** → §13.2, sin cambios en la división;
  - **arquitecto-maestro / B** → PC-1 a PC-10 y el aviso de la fecha (V2.7);
  - **documentador-tecnico** → las reservas de errores.
- Próximo paso recomendado: que el propietario firme PC-7 a PC-10, sobre todo PC-7, que cierra C2-01; que B decida PC-1 y PC-5; y que el arquitecto-datos diseñe la migración con el piso y la detección congelada.
