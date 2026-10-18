[Decisión preparada por el Arquitecto Maestro (equipo B)]  Estado: **Pendiente de firma**

# DB-7, tramo D0: hoja de firma del diseño del acceso multiempresa v1

- **Fecha:** 2026-10-18
- **Preparado por:** Arquitecto Maestro del equipo B (coordinador)
- **Firma:** el propietario (sección 3)
- **Entregables evaluados:**
  - blueprint v3: `docs/arquitectura/2026-10-18-db7-blueprint-v3.md` (árbol de `master`, sin commit), al que llamo **BP3**;
  - modelo de datos: `traspasos/B/2026-10-18-db7-d0-modelo-datos.md` del área común, al que llamo **DAT-D0**;
  - revisión de seguridad con su relectura: `traspasos/B/2026-10-18-db7-d0-revision-seguridad.md` del área común;
  - decisión firmada: `docs/decisiones/2026-10-18-decision-db7-calendario.md` (DB7-01 a DB7-07) y su hoja `traspasos/B/2026-10-18-propuesta-calendario-db7.md`.

> **Nada de esto existe todavía en el código.** La membresía, la validación por empresa, el inicio en dos pasos, ES256 y el cupo por empresa son diseño (BP3, sección 1 y 2.1). Esta hoja firma el diseño, no una implementación.

---

## 1. Resumen ejecutivo

1. **Qué cierra el diseño:** H-01 (no hay relación cuenta↔empresa), H-02 (ADMIN global) y H-07 (lista anónima de empresas), más H-06 en los reportes con P-D0-08. También H-09, H-12, H-13 y H-14 (BP3 1.2).
2. **Dictamen del auditor de seguridad:** «Aprobado con observaciones» tras la relectura. Los dos hallazgos Altos (SD0-01 y SD0-02) y los Medios SD0-03 a SD0-06 quedan cerrados en el diseño; SD0-07 a SD0-10, bien resueltos; las contradicciones de texto N-1 a N-7, aplicadas (revisión, «Dictamen final para pasar a la firma»).
3. **Costo que agregó la revisión** (*inferido*): de 0,7 a 0,9 sp sobre los 13,5 a 17,5 sp firmados en DB7-01 (D1 +0,3; D2 +0,1; D5 +0,3 a 0,5; BP3 15).
4. **Efecto en el calendario:** la holgura sigue en 2 días hábiles, ahora más justa; el punto de control del **2026-11-20** (DB7-07) gana peso. La hoja del diseño tenía objetivo de firma el 10-31: vamos adelantados.
5. **Infraestructura y licencias:** ningún costo. El TPM se usa con el proveedor de Windows (BP3 1.4).
6. **Requisitos que no son preguntas** (no se votan, se cumplen):
   - **RQ-R12 en D1** (antes P-D0-03): todo texto del diseño gráfico que llega a la plantilla se escapa y la imagen se valida en lista blanca (`svg+xml` se rechaza). Unas 0,15 sp. Es **condición de publicación** y lo audita D6 (BP3 10.3).
   - **La v1 se publica solo con D1 a D5 unidos.** Entre D1 y D5 la definición de los reportes sigue siendo global (condición del auditor sobre SD0-01).
7. **Puntos para firma:** 12 (sección 3). En todos, la recomendación tiene el acuerdo del auditor (revisión, sección 6).

---

## 2. Cumplimiento de estándares y ADR

- **Proyectos:** no se crea ninguno (BP3 1.4 y 7).
- **`GPOS_SYSDATA`:** no es base de empresa; el `varchar` por omisión de ADR-50 no aplica. El esquema pasa a la **versión 6** por `GPOS.Migracion sistema` (BP3 5.1; DAT-D0 S-1).
- **Orden de bloqueos:** padrón → `dbo.Usuarios` → `dbo.UsuariosEmpresas` → lo demás (ADR-83). El cupo se serializa con la fila del padrón, sin `sp_getapplock` (BP3 11.1, punto 7). DB-7 no toma bloqueos de documentos.
- **ADR:** no hace falta un ADR nuevo. Cada punto firmado se registra como **precisión** del ADR que se indica en su encabezado, sin reescribir el texto firmado (el mismo criterio de la hoja del calendario, sección 11).
- **Principio rector:** cada punto dice qué rompe, a quién afecta, por qué se justifica y cómo se migra. No hay ningún cliente en producción; lo que cambia afecta al DEMO y a GSF.

---

## 3. Puntos para firma

Marque una opción por punto. «Según la recomendación» firma la opción recomendada de cada punto.

### P-D0-01 · Llave de firma ES256: llave del TPM sin certificado (precisión de ADR-41; texto de SES-14 y N-11 del estándar)
- **Opciones:**
  - **(a) recomendada:** una llave guardada en el TPM del servidor central (Microsoft Platform Crypto Provider), sin certificado. Se identifica por la huella de su llave pública.
  - (b) un certificado en el almacén de la máquina con la llave en el TPM, como dice hoy el texto del estándar.
- **Qué rompe:** solo el texto de SES-14 y N-11, que habla de certificados. Nada visible.
- **A quién afecta:** a GSF y a devops, que aprovisionan con `GPOS.Migracion aprovisionar --llave-firma` en lugar de emitir un certificado.
- **Por qué se justifica:** un certificado agrega emisión y vencimiento sin valor, porque nadie valida una cadena. Ya existe el mismo patrón en `LlaveSitio` (ADR-109). Ahorra de 0,1 a 0,2 sp (*inferido*). Sin TPM, hay una vía explícita (`--sin-tpm --motivo`) con vigencias más cortas y aviso (SD0-09).
- **Cómo se migra:** no hay nada que migrar; es la primera llave ES256.
- [ ] (a) recomendada  [ ] (b)

### P-D0-02 · Token de los dispositivos (cocina y comanderas) al retirar la clave actual (precisión de ADR-121)
- **Opciones:**
  - **(a) recomendada:** el token de dispositivo pasa a ES256 con la **misma** llave del sitio, con su tipo y su audiencia propios, que lo separan del token de usuario.
  - (b) una clave simétrica aparte solo para dispositivos.
- **Qué rompe:** los tokens de dispositivo vigentes (duran 15 minutos). El dispositivo pide uno nuevo con su secreto, sin volver a emparejarse (*inferido* del código; D2 lo prueba).
- **A quién afecta:** a las pantallas de cocina y a las comanderas, que hoy solo están en el DEMO.
- **Por qué se justifica:** retirar `Jwt:Clave` (DB7-04) lo exige. (b) dejaría un secreto simétrico en la configuración, en contra de lo firmado. Según el auditor, una segunda llave no reduce el riesgo, porque tendría la misma custodia. Además, la emisión exige la empresa habilitada y el módulo activo (SD0-12). Costo: unas 0,1 sp dentro de D2.
- **Cómo se migra:** al desplegar.
- [ ] (a) recomendada  [ ] (b)

### P-D0-04 · Contraseña de 12 caracteres para quien pasa a ADMIN de una empresa (regla H-15 aplicada a las membresías)
- **Contexto:** hoy el ADMIN necesita 12 caracteres (`PoliticaClaves.cs:14`). Con membresías, una persona con una contraseña de 10 puede pasar a ADMIN de una empresa. La contraseña se guarda como hash, así que no se puede saber su largo. **Con cualquier opción**, la regla de contraseñas pasa a usar el nivel más alto de las membresías de la persona (SD0-04), para que no pueda volver a 10.
- **Opciones:**
  - (a) no forzar nada: la regla de 12 se aplica la próxima vez que la persona cambie su contraseña. Queda un ADMIN con 10 caracteres hasta entonces.
  - **(b) recomendada:** al dar el nivel ADMIN a una cuenta que no tenía ninguno, se le marca «debe cambiar la clave». En su siguiente acción, la interfaz la lleva a cambiarla, ya con la regla de 12. La conversión del DEMO aplica lo mismo.
  - (c) igual que (b), pero guardando un indicador «la contraseña ya cumple 12» al elegirla; solo se fuerza el cambio a quien no cumple. Una columna nueva; unas 0,05 sp más.
- **Qué rompe:** con (b) y (c), la persona ascendida cambia su contraseña en ese momento. «Debe cambiar la clave» es de la cuenta: si asciende en A, también se le pide al entrar a B (el auditor lo considera aceptable).
- **A quién afecta:** a los nuevos ADMIN de una empresa y a los ADMIN del DEMO, que la conversión deja como ADMIN de cada empresa (DB7-02).
- **Por qué se justifica:** es la única forma de cumplir H-15 sin pedir la contraseña en claro. (b) cuesta unas 0,05 sp. (c) es más precisa, pero en el DEMO convertido el indicador nace en 0, así que el efecto inicial es el mismo que (b) (*inferido*).
- **Cómo se migra:** la conversión deja con «debe cambiar la clave» a las cuentas que salen con alguna membresía ADMIN (DAT-D0 7.3, paso 8 d).
- [ ] (b) recomendada  [ ] (a)  [ ] (c)

### P-D0-05 · Lo que pasa a la fase 2 por no estar en el alcance firmado (mitigación de R-6 de la hoja del calendario)
- **Opciones:**
  - **Recomendada:** confirmar que pasan a la fase 2, sin fecha: el correo de la cuenta (IDN-05), la huella del contenido en la bitácora (TRZ-07) y las alertas al SUPER por intentos sostenidos, respaldo repetido e identidad rechazada (TRZ-10 y SES-13 (d)). Las alertas que ya existen por ADR-83 no cambian.
  - Alternativa: incluirlas en la v1, con un costo de 0,8 a 1,2 sp (*inferido*).
- **Qué rompe:** nada de lo que existe. El ADMIN no ve un campo de correo y el SUPER no recibe esas alertas en la v1. Los ataques sostenidos de contraseña solo se ven en la bitácora; los frenan los bloqueos por (cuenta, IP) y global.
- **A quién afecta:** al SUPER (soporte de GSF).
- **Por qué se justifica:** ninguna de estas reglas cierra H-01, H-02 ni H-07, y la holgura del calendario (2 días) no admite 1 sp más.
- **Cómo se migra:** se agregan en la fase 2 sin cambiar contratos (los datos que se intercambian solo crecen).
- [ ] Pasan a la fase 2 (recomendada)  [ ] Incluirlas en la v1

### P-D0-06 · Sin validación local de la firma en la API de reportes en la v1 (precisión de DB7-04 (b) y de ADR-41)
- **Opciones:**
  - **Recomendada:** no construirla en la v1. La API de reportes pregunta a la API principal en cada petición (introspección, sin caché), y la principal valida la firma y el estado de acceso.
  - Alternativa: validar también en local como primer filtro. De 0,2 a 0,3 sp (*inferido*): un archivo de llaves públicas protegido según ADR-77 y la rotación de llaves en dos lugares.
- **Qué rompe:** nada. DB7-04 (b) decía «aunque valide la firma en local»; esto lo precisa.
- **A quién afecta:** a nadie fuera del código.
- **Por qué se justifica:** con la introspección obligatoria y sin caché, la validación local no agrega seguridad y duplica la rotación. Hay un solo punto de decisión del acceso. La API de reportes deja de decidir con los datos del token (SD0-08).
- **Cómo se migra:** si algún día se quita la introspección, se agrega la validación local; el token ya lleva la audiencia de reportes.
- [ ] Sin validación local en la v1 (recomendada)  [ ] Validar también en local

### P-D0-07 · Conversión del DEMO de las cuentas restringidas a una sucursal (precisión de DB7-02, ADR-39)
- **Contexto:** hoy la restricción de sucursal es de la cuenta. Se evalúa por el **código** de sucursal dentro de la empresa elegida, así que un cajero restringido entra a otra empresa si allí existe una sucursal con el mismo código (H-08) y, además, por H-01. *Corrección del 2026-10-18 (DX-2):* la versión anterior decía que (b) daba acceso «sin restricción»; no es así.
- **Opciones:**
  - **(a) recomendada:** las cuentas **con** restricción reciben membresía **solo** en su empresa predeterminada, con la misma restricción. Las cuentas **sin** restricción reciben membresía en todas las empresas habilitadas, con la sucursal predeterminada solo en su empresa predeterminada. Los perfiles se copian a cada empresa con el mismo código, con las excepciones de la cuenta.
  - (b) el texto literal de DB7-02: membresía en todas las empresas habilitadas, con la restricción copiada en cada una.
- **Guarda que aplica con cualquier opción (SD0-10):** esta regla solo corre con `--instalacion-demo`. Sin esa marca, la conversión es mínima: una sola membresía USER en la empresa predeterminada, sin ningún ADMIN, y la lista de lo pendiente para que el SUPER lo complete.
- **Qué rompe:** con (a), un cajero restringido del DEMO deja de entrar a otras empresas, a las que hoy entra por H-01 y por la coincidencia de códigos.
- **A quién afecta:** a quien prueba el DEMO.
- **Por qué se justifica:** (a) es más restrictiva que hoy y que (b); no conserva un acceso que depende de que coincidan códigos de empresas distintas, y no crea membresías que ocupan cupo en empresas a las que la persona no puede entrar.
- **Cómo se migra:** el SUPER agrega membresías después, desde «Cuentas». DAT-D0 7.3 ya aplica (a).
- [ ] (a) recomendada  [ ] (b)

### P-D0-08 · Reportes por empresa (SD0-01, Alta; cierra H-06 en los reportes; precisión de PRV-07 del estándar y de ADR-38 y ADR-40)
- **Hecho verificado:** las definiciones de los reportes, con su SQL, están en una tabla global sin empresa (`SistemaDbContext.cs:226-259`), y `/api/admin/reportes` guarda cualquier reporte y borra cualquiera que no sea del sistema (`ReportesService.cs:105-149`). Con el ADMIN por empresa, el ADMIN de A podría cambiar la consulta de un reporte que se ejecuta en B, o borrar los de B.
- **Opciones:**
  - **(a) recomendada: reportes por empresa.** Cada reporte personalizado pertenece a una empresa; los reportes del sistema no tienen empresa y solo los cambian la semilla o el SUPER; el ADMIN los **duplica** en su empresa para modificarlos. Un reporte de otra empresa responde «no existe». El permiso de un reporte vale solo en su empresa. Va en D5; la estructura y la conversión, en D1. De 0,3 a 0,5 sp (*inferido*).
  - (b) mínima: crear y borrar reportes pasa a ser solo del SUPER hasta la fase 2. Unas 0,05 sp.
- **Qué rompe:**
  - con (a), un reporte personalizado que hoy ven todas las empresas pasa a ser una copia en cada una; un cambio en una ya no afecta a las demás; el ADMIN ya no modifica los reportes del sistema (los duplica);
  - con (b), el ADMIN deja de diseñar y de borrar reportes en la v1, y GSF tendría que diseñarlos por el cliente.
- **A quién afecta:** al ADMIN que diseña reportes y a GSF.
- **Por qué se justifica (a):** es la remediación de H-06 de la auditoría de origen y lo que ya preveía el modelo de datos del 2026-09-29. Conserva el diseñador para el ADMIN, que es parte de lo que el usuario conoce (principio rector). El auditor confirma que **las dos opciones cierran SD0-01**.
- **Cómo se migra:** la conversión del DEMO deja cada reporte personalizado en la primera empresa habilitada, con su mismo número, y lo copia a las demás con permisos equivalentes; la prueba de equivalencia (Q23) lo compara. Las reglas de notificación que apuntan a esos reportes se reasignan después, empresa por empresa (ver la nota 4.1).
- [ ] (a) recomendada  [ ] (b)

### P-D0-D01 · Registro protegido (padrón) con una entrada para toda cuenta habilitada (precisión del punto 9 de ADR-83, DB7-05)
- **Opciones:**
  - **(a) recomendada:** una entrada de cuenta por cada cuenta habilitada, sea SUPER o no.
  - (b) el texto literal: entradas de cuenta solo para el SUPER.
- **Qué rompe:** nada visible. Cuesta unos 40 bytes por cuenta.
- **A quién afecta:** a nadie fuera del código.
- **Por qué se justifica:** con (b), quien escribe directamente en la base podría reponer una contraseña y un sello antiguos de una cuenta y entrar con la contraseña vieja (SH-5, caso 5 de DAT-D0 3.5). El auditor la califica de **necesaria**.
- **Cómo se migra:** con el verbo de conversión.
- [ ] (a) recomendada  [ ] (b)

### P-D0-D02 · Qué ve el ADMIN en la bitácora (precisión de DB7-03, ADR-37)
- **Opciones:**
  - **(a) recomendada:** los accesos y los movimientos de membresía (altas, bajas, suspensiones y cambios de privilegios) de su empresa.
  - (b) solo los accesos.
- **Qué rompe:** con (b), el ADMIN no ve las altas, bajas ni cambios de privilegios de su empresa, que el estándar (TRZ-01) pone en su bitácora.
- **A quién afecta:** al ADMIN.
- **Por qué se justifica:** es la lectura de ADR-37 y de TRZ-01. Ningún texto que vea el ADMIN nombra otra empresa (criterio QA-28).
- **Cómo se migra:** es un dato del catálogo de eventos.
- [ ] (a) recomendada  [ ] (b)

### P-D0-D03 · Cuánto se guardan los eventos de la cuenta y los accesos denegados (precisión de DB7-03, ADR-37)
- **Opciones:**
  - **(a) recomendada:** 5 años, como el resto de la bitácora de acceso.
  - (b) 2 años.
- **Qué rompe:** nada. Son unos 2 MB más en 5 años.
- **A quién afecta:** al SUPER.
- **Por qué se justifica:** ADR-37 los incluye en la bitácora de acceso de 5 años; la firma de DB7-03 solo fijó 2 años para factor, licencia y sello. **Condición del auditor:** queda sujeto al dictamen legal pendiente (Ley 172-13), porque se guardan códigos de usuario e IP.
- **Cómo se migra:** es un dato del catálogo.
- [ ] (a) recomendada  [ ] (b)

### P-D0-D04 · Conversión del DEMO cuando una empresa excede su cupo (precisión de DB7-05; ADR-34 y punto 9 de ADR-58)
- **Opciones:**
  - **(a) recomendada:** el verbo se detiene y lista las empresas. Solo convierte con `--aceptar-exceso --motivo-exceso "<motivo>"`, y deja esas empresas en exceso (`EnExceso`), con el motivo en la bitácora.
  - (b) convertir siempre.
  - (c) no convertir nunca con exceso.
- **Qué rompe:** con (c), el DEMO sin licencia (cupo 0) no se podría convertir.
- **A quién afecta:** a GSF.
- **Por qué se justifica:** es el mismo criterio de SL-F2 (b): se decide con la lista a la vista y con motivo.
- **Cómo se migra:** no aplica.
- [ ] (a) recomendada  [ ] (b)  [ ] (c)

### P-D0-D05 · El SUPER en la bitácora que ve el ADMIN (precisión de SUP-04 del estándar y de ADR-35)
- **Opciones:**
  - **(a) recomendada:** se muestra «Super Usuario», sin su código, con el motivo, la fecha, la IP y el canal.
  - (b) mostrar el código del SUPER.
- **Qué rompe:** con (a), el ADMIN no distingue entre varios SUPER. La trazabilidad completa queda en la vista del SUPER.
- **A quién afecta:** al ADMIN.
- **Por qué se justifica:** concilia SUP-04 (no exponer al SUPER) con ADR-35 (el ingreso del SUPER es visible para el ADMIN).
- **Cómo se migra:** está en la consulta de la bitácora del ADMIN (Q8).
- [ ] (a) recomendada  [ ] (b)

---

## 4. Notas informativas (sin firma)

### 4.1 Condición agregada por el arquitecto de datos (N-6): reglas de notificación suspendidas
- Con P-D0-08 (a), las reglas de notificación están en la base de cada empresa y se reasignan a los reportes copiados **después** de la conversión (DAT-D0 7.3, paso 11). Si una base no responde, el verbo termina con error y nombra las empresas pendientes; mientras tanto, esas reglas se suspenden (falla cerrado).
- **Lo nuevo:** tras repetir `accesos --convertir --solo-reglas`, las reglas suspendidas por esta causa **solo vuelven a correr cuando su ADMIN las reactiva** (DAT-D0 7.3, paso 11). El auditor proponía reactivarlas solas; el arquitecto de datos eligió la variante más conservadora.
- **Qué cambia para el usuario:** después de la conversión, el ADMIN de una empresa afectada tiene que reactivar a mano esas reglas. Solo ocurre en el DEMO y solo si el paso 11 no terminó a la primera. Si prefiere que se reactiven solas, indíquelo en la firma.

### 4.2 Residual que se acepta con la firma (SD0-14; R-DB7-11)
DAT-D0 3.5 declara que este residual «se acepta de forma expresa con la firma». Quien tenga escritura directa en `GPOS_SYSDATA` puede cambiar, sin rehacer ningún sello: «debe cambiar la clave», las revocaciones de sesión, el bloqueo y los contadores de fallos, la marca «administrada por el SUPER» y los perfiles y excepciones. **Ninguno amplía el cupo, sube el nivel ni da una membresía.** Cada uno tiene su mitigación en DAT-D0 3.5. Firmar esta hoja lo acepta; si no lo acepta, indíquelo.

### 4.3 Franjas reservadas
- **Errores del motor:** 51619 a 51625; el siguiente libre es el **51626** (BP3 5.1, DX-10; DAT-D0 4.1).
- **EventId del registro de la aplicación:** 4724 a 4729 y 4733 a 4735; el siguiente libre es el **4736** (BP3 5.1). El 4723 lo reserva RSV-F4 y los 4730 a 4732 son de la fase A de ADR-81.
- **Esquema de `GPOS_SYSDATA`:** pasa a la **versión 6**.
- El documentador los anota en ADR-82 al registrar esta hoja.

### 4.4 Qué se verifica en D6 (BP3 13.2)
1. Suite completa, sola y con el filtro oficial, más las pruebas de Web y MAUI.
2. Casos de aislamiento del estándar que aplican a la v1, con una y con dos instancias.
3. Q1 (lectura del acceso en cada petición): p95 ≤ 2 ms, y T-28 y T-57 dentro de sus topes (32,8 y 31,6 ms).
4. Auditoría del código: H-01 a H-14, ES256, desbloqueo del ADMIN, orden autorización → ámbito → cupo, sellos frente a un cambio por SQL, introspección sin caché y aislamiento estático (Q26). Incluye **RQ-R12** y **SD0-01**.
5. Verificación sin construcción de M-1 a M-4 (ADR-82 y ADR-109) y del factor del SUPER (fase A).
6. Ensayo de la conversión sobre una copia del DEMO: sin diferencias, repetible y con su registro en la bitácora.
7. Ensayo del aprovisionamiento de la llave: arranque con y sin TPM, y rotación de emergencia en menos de 15 minutos.
8. Hoja de cierre con las desviaciones respecto del diseño.

### 4.5 Restos de texto (corregidos)
Los dos restos de N-4 y N-5 en DAT-D0 quedaron resueltos antes de presentar la hoja: la línea «Uso» de 7.3 muestra `--instalacion-demo`, `--aceptar-exceso --motivo-exceso` y `--solo-reglas`, y la viñeta de 4.1 («libres 51626 a 51638») es correcta: se refiere a lo que queda libre de la franja reservada, con el 51626 como siguiente.

---

## 5. Riesgos principales (detalle en BP3 13.1)

| # | Riesgo | Mitigación |
|---|---|---|
| R-DB7-01 | Q1 sin caché pasa de 2 ms y acerca T-28 y T-57 a sus topes | Se mide en D1, no en D6. Plan B firmado en ADR-36 (plazo mayor) |
| R-DB7-02 | `GPOS_SYSDATA` como punto único de falla en cada petición | 503 cerrado, tiempo de espera de 2 s y respaldo (ADR-24) |
| R-DB7-08 | Toda la carga en el equipo B frente a la semana del e-CF exclusivo (15-nov) | Punto de control del 2026-11-20 (vías C y C′); D1 y D2 primero |
| R-DB7-11 | Columnas sin sello cambiables por SQL | Residual aceptado con la firma (nota 4.2) |
| Residual | SUPER malicioso o ejecución de código dentro de la API | Aceptado en ADR-38 (G-1); RQ-R12 cierra la vía del diseño gráfico |

---

## 6. Si el usuario firma / si rechaza

- **Si firma:**
  - B registra en `master` las precisiones de ADR-34, 35, 37, 38, 39, 40, 41, 58, 83 y 121 (y de las reglas del estándar que cita cada punto) como «Precisión del 2026-10-xx (P-D0-nn)», sin reescribir el texto firmado, y anota en ADR-82 las franjas de la nota 4.3;
  - D1 empieza en S2 (11-02), con RQ-R12 dentro;
  - el disenador-ux-ui puede empezar el diseño fino de D4 desde S1;
  - devops recibe el procedimiento de `aprovisionar --llave-firma`, la vía sin TPM y la clave HS256 nueva en caso de revertir.
- **Si rechaza P-D0-01:** se agrega la emisión del certificado y su vencimiento a D2 (+0,1 a 0,2 sp) y devops lo incluye en la implantación.
- **Si rechaza P-D0-02:** se mantiene una clave simétrica solo para dispositivos, que habrá que cifrar fuera del texto plano (I-18), y la decisión choca con DB7-04.
- **Si elige P-D0-04 (a):** se quita el cambio forzado; queda como riesgo residual aceptado un ADMIN con 10 caracteres hasta su próximo cambio. **Con (c):** el arquitecto de datos agrega la columna (+0,05 sp).
- **Si rechaza P-D0-05:** D1 y D5 suben de 0,8 a 1,2 sp y la holgura del calendario se agota; el punto de control del 11-20 pasa a ser probable.
- **Si rechaza P-D0-06:** D5 sube de 0,2 a 0,3 sp, con el archivo de llaves públicas y la rotación en dos lugares.
- **Si elige P-D0-07 (b):** el arquitecto de datos cambia el paso 3 de DAT-D0 7.3; las membresías convertidas ocupan cupo en empresas sin esa sucursal.
- **Si elige P-D0-08 (b):** se quitan del diseño `Reportes.EmpresaCodigo`, la tabla de conversión de reportes y los pasos 3 b y 11 del verbo (DAT-D0 2.6); D5 baja unas 0,25 a 0,45 sp; la nota 4.1 deja de aplicar.
- **Si elige P-D0-D01 (b):** queda abierto SH-5 (Alto) para las cuentas que no son SUPER; el auditor no lo recomienda.
- **Si elige P-D0-D02 (b), D03 (b), D04 (b o c) o D05 (b):** son cambios de datos del catálogo o del verbo, sin costo apreciable; con D04 (c), el DEMO sin licencia no se convierte.
- **Si no acepta el residual de la nota 4.2:** hay que sellar esas columnas, lo que cambia el formato del sello (DB7-05) y lo debe estimar D0 otra vez.

---

### Supuestos
1. Las cifras de esfuerzo y de tamaño son las de BP3 y DAT-D0, *inferidas* (±30 %); no las recalculé.
2. El estado del #57 y del #73 (unidos) es el que declara BP3; no lo verifiqué en el código.
3. El efecto inicial de P-D0-04 (c) en el DEMO (igual que (b)) es *inferido*: el indicador nace en 0.

### Cierre
- Estado: Completado (hoja preparada; **Pendiente de firma**)
- Artefactos: `traspasos/B/2026-10-18-hoja-firma-db7-d0.md` del área común
- Supuestos: los tres de arriba
- Decisiones candidatas a ADR: ninguna nueva; las doce son precisiones de ADR existentes
- Entregas a otros agentes: documentador-tecnico → registrar las precisiones y las franjas tras la firma
- Próximo paso recomendado: el propietario firma esta hoja (objetivo: 10-31) para que D1 empiece el 11-02

---

## Firma

«Según la recomendación» firma la opción recomendada de cada punto (P-D0-01, 02, 04 a 08 y P-D0-D01 a D05) y acepta el residual de la nota 4.2.

- [ ] Según la recomendación
- [ ] Con cambios (indicar el punto y la opción): ______________________

Firma del propietario: ______________________  Fecha: ____________

## Firma

**Firmada por Leonardo Méndez, propietario, el 2026-10-18 en la sesión de B:** «Firmo la hoja de D0 de DB-7 según la recomendación.»

- Opción recomendada en los 12 puntos: P-D0-01 (a), P-D0-02 (a), P-D0-04 (b), P-D0-05 (sí), P-D0-06 (no validar en local en la v1), P-D0-07 (a), P-D0-08 (a), P-D0-D01 (a), P-D0-D02 (a), P-D0-D03 (a), P-D0-D04 (a) y P-D0-D05 (a).
- Con la firma se acepta de forma expresa el residual sin sello de la nota 4.2 (SD0-14, R-DB7-11).
- RQ-R12 (R-12 en D1) y la publicación solo con D1 a D5 unidos quedan como condiciones, no como preguntas.
