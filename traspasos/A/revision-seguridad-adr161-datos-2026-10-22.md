# Revisión de seguridad del diseño de datos del ADR-161 (maestro «Tipo de identificador fiscal»)

- **Fecha:** 2026-10-22 · **Revisor:** auditor-seguridad (equipo A) · **Modo:** solo lectura (sin compilar, sin SQL, sin commit).
- **Objeto:** PR #162, rama `origin/b/adr161-datos`, `docs/datos/2026-10-22-adr-161-tipo-identificador-fiscal.md` (353 líneas; se cita «§n»). Contexto: la propuesta `docs/propuestas/2026-10-22-adr-161-propuesto-tipo-identificador-fiscal.md` (no hay `docs/adr/ADR-161.md` en la rama) y la revisión de B `traspasos/B/2026-10-22-revision-ddl-adr161.md` (usada como contexto).
- **Código contrastado:** `origin/feature/modelo-ng` (rama de construcción), con `git show`/`git grep`.
- **Convención:** [V] verificado en el texto o en el código citado; [I] inferido.
- **Veredicto (recomendación técnica, C2): Aprobado con observaciones.** No hay hallazgos Críticos ni Altos. Hay 4 Medios que conviene cerrar antes de construir (o firmar como riesgo aceptado) y 4 Bajos.

## 1. Alcance y superficie

- Superficie nueva: dos tablas `cat` por empresa, una columna FK en `cat.Cliente`/`cat.Suplidor`, siembra y relleno en una migración de EF, rutas `/api/super/tipos-identificador` (escritura, solo SUPER), `/api/catalogos/tipos-identificador` (lectura), columna opcional en la importación y copia entre empresas del mismo dueño (Q-TI-7).
- Fuera de alcance: código del servicio y de la API (no existe todavía, §3 cabecera «Nada de esto está construido»), vistas `rpt` (M-5 va en migración aparte, §11).

## 2. Resumen de hallazgos

| ID | Sev. | Título |
|---|---|---|
| R161-01 | Medio | Los tipos no numéricos (`SoloDigitos = 0`) aceptan cualquier carácter: sin juego de caracteres declarado |
| R161-02 | Medio | El 409 de Q-TI-5/M-2 entrega identificaciones íntegras de terceros al SUPER (personal de la plataforma) |
| R161-03 | Medio | Sin validación del dígito verificador para los tipos RNC/cédula, aunque el validador ya existe en el código |
| R161-04 | Medio | La derivación por omisión y el relleno clasifican a la persona física con RNC como `EMPRESA`: menos protección por defecto (M-5 y Q-TI-9 abiertos) |
| R161-05 | Bajo | La inmutabilidad de `Codigo` es solo regla del servicio, pese a que copia, importación y relleno dependen de ella |
| R161-06 | Bajo | Borrar un tipo «sin uso» deja el historial temporal apuntando a un Id inexistente |
| R161-07 | Bajo | La siembra puede quedar a medias en silencio si la tabla ya existía con otro contenido |
| R161-08 | Bajo | El `Down` borra sin guarda las clasificaciones corregidas a mano |

Fuera del ADR-161 (para el coordinador): **O-1** el código `51618` ya lo usa `ComandosCambioRnc.ErrorOtroCambio` (ver §7).

## 3. Checklist OWASP (Top 10 2021) aplicado al diseño

| Punto | Estado | Nota |
|---|---|---|
| A01 Control de acceso | Observación | SUPER por ruta (§9, ADR-35) [V]; copia entre empresas sin control de «mismo dueño» descrito en datos (entrega al backend); R161-02 |
| A02 Criptografía | No aplica | Sin datos cifrados nuevos; la identificación ya existe en claro en `cat.Cliente` (fuera de este ADR) |
| A03 Inyección | Bien, con R161-01 | Sin SQL dinámico con entrada de usuario: siembra y relleno usan literales; parámetros tipados `varchar(20)`/`char(1)`/`smallint` (§4) [V]. Sin expresiones regulares nuevas: validación por largo y `char.IsAsciiDigit` (§3.2.1) [V]; el `LIKE` del CHECK es un patrón fijo, sin retroceso (sin ReDoS) [V] |
| A04 Diseño inseguro | Observación | R161-03, R161-04 |
| A05 Configuración | Bien | Sin `GRANT` nuevos (§9) [V]; `gpos_app` sin `ALTER` necesario |
| A06 Componentes | No aplica | Sin dependencias nuevas |
| A07 Autenticación | No aplica | |
| A08 Integridad | Observación | Migración idempotente por `MigrationId`, por `Codigo` y `IS NULL` (§7.1-7.3) [V]; R161-05, R161-07, R161-08 |
| A09 Registro y monitoreo | Bien | Cambios del SUPER y relleno a `audit.Bitacora` (§5, §7.3) [V], tabla con `DENY UPDATE, DELETE ... TO gpos_app` (guion acumulado, línea 1141) [V]; el 409 no deja línea (BT-05), aceptable |
| A10 SSRF | No aplica | |

## 4. Hallazgos

**R161-01 · Medio · Tipos no numéricos sin juego de caracteres.**
- Evidencia [V]: §3.2.2 solo exige largo y, con `SoloDigitos = 1`, dígitos; `CK_Cliente_Identificacion` para `P` solo exige `LEN BETWEEN 5 AND 20` (`MaeConfiguracion.cs:328-333`); `Rnc.Normalizar` quita solo guiones y espacios (§1). La propuesta habla de «5 a 20 caracteres alfanuméricos» (TI-02), pero ninguna regla lo hace cumplir.
- Escenario: un pasaporte o carnet importado con espacios no separables, tabuladores, caracteres de ancho completo o un primer carácter `=`/`+`/`@`. Se guarda (o, al convertirse a `varchar` 1252, se sustituye en silencio por `?` [I]), no coincide en búsquedas ni en la detección de duplicados y, si un reporte exporta a XLSX/CSV, puede interpretarse como fórmula [I].
- Remediación: para los tipos con `SoloDigitos = 0`, normalizar a mayúsculas y admitir solo `[A-Z0-9]` (comprobación por caracteres, sin expresión regular). Como defensa en profundidad, ampliar `CK_*_Identificacion` en la rama `P` con `Identificacion NOT LIKE '%[^A-Z0-9]%' COLLATE Latin1_General_BIN`. Si el especialista confirma que algún documento real lleva guion u otro símbolo, se agrega explícitamente. Costo: 0,25 dp más una prueba de importación.

**R161-02 · Medio · El 409 lista identificaciones íntegras al SUPER.**
- Evidencia [V]: Q-TI-5 «se rechaza con 409 y la lista de registros» (§3.2.5, §3.3 a); la consulta que lo respalda devuelve `Id, Identificacion` (§4, `IX_Cliente_TipoIdentificador ... INCLUDE (Identificacion)`). La bitácora ya excluye la identificación (BT-06), pero la respuesta no. El SUPER es personal de la plataforma (GSF), no de la empresa cliente.
- Escenario: el SUPER endurece una regla del tipo `PERSONA_FISICA` y recibe cédulas completas de cientos de clientes de una empresa ajena a su organización. Va contra la minimización de la Ley 172-13 [I: interpretación legal a confirmar] y queda en la caché o en el registro del navegador o del proxy.
- Remediación: el 409 devuelve la cantidad, `Codigo` del cliente o del suplidor y la identificación enmascarada (como en `rpt`: `*******` más los 4 últimos), con un tope (`TOP (@n)` ya previsto). La identificación íntegra solo se ve en la pantalla del maestro, con «Ver datos personales». Sin costo de datos; 0,1 dp en el servicio.

**R161-03 · Medio · Sin dígito verificador para RNC y cédula.**
- Evidencia [V]: §3.2.2 valida solo largo y dígitos; el código ya tiene la validación con dígito verificador para S-03 (`src/GPOS.Core/Dominio/Configuracion/Empresa.cs:175` en modelo-ng: módulo 11 para el RNC) y `FormatoRnc.EsValido` solo mira el largo (`src/GPOS.Contracts/Fiscal/FormatoRnc.cs:35`).
- Escenario: un error de digitación en el RNC del comprador pasa la regla del tipo `EMPRESA` y llega al comprobante fiscal; el rechazo, si lo hay, aparece en la emisión del e-CF y no en el alta [I: depende de la DGII y del conector].
- Remediación: agregar al tipo una marca `ValidaDigitoVerificador bit NOT NULL DEFAULT 0` (sembrada en 1 para `EMPRESA` y, si el especialista lo aprueba, para `PERSONA_FISICA`) que el servicio aplica con el validador existente, como rechazo o como advertencia según la respuesta a P-1. Costo: una columna y 0,25 dp. *Alternativa descartada:* validar siempre el dígito en el código, porque rompe los casos conocidos de cédulas antiguas que no lo cumplen [I] y quita al SUPER la configuración.

**R161-04 · Medio · La clasificación por omisión favorece la menor protección.**
- Evidencia [V]: la derivación de 9 dígitos va a `EMPRESA` (§3.2.4, siembra §7.2 con `EsPersonaFisica = 0`); el relleno deja como `EMPRESA` a la persona física con RNC (§7.3, MG-05); las 5 vistas `rpt` muestran íntegra la `R` (§11); Q-TI-8 y Q-TI-9 siguen pendientes (§15).
- Escenario: un comerciante persona física con RNC queda como empresa; su RNC sale completo a quien no tiene «Ver datos personales» y, con TI-07, pierde el derecho a la supresión de TT hasta que alguien lo corrija a mano.
- Remediación: desde seguridad, **firmar Q-TI-9 (b)** (enmascarar por `EsPersonaFisica` y caer a la letra cuando no hay tipo), porque su error posible es enmascarar de más, y **Q-TI-8 (a)** (409 en vez de una reclasificación en bloque). Además, que la pantalla advierta «¿Es persona física?» cuando propone `EMPRESA` (Q-TI-6 ya permite cambiarlo). Riesgo aceptable mientras todo es desarrollo; no debe llegar así al primer cliente.

**R161-05 · Bajo · Inmutabilidad de `Codigo` solo en el servicio.**
- Evidencia [V]: §3.2.8 «regla del servicio, sin disparador»; `gpos_app` tiene `UPDATE` sobre el esquema `cat` (guion, línea 430). La copia entre empresas, la importación y el relleno resuelven por `Codigo` (§6, §7.3, §7.5).
- Escenario: un defecto del servicio o una edición directa renombra `EMPRESA`; la importación con `TipoIdentificador = EMPRESA` falla o, si otro tipo toma ese código, clasifica a terceros en un tipo con otro `EsPersonaFisica`.
- Remediación: `DENY UPDATE ON cat.TipoIdentificadorFiscal (Codigo) TO gpos_app;` (permiso por columna, sin disparador; EF solo actualiza las columnas modificadas [I: confirmar con una prueba U-03 contra la base]). Costo: una línea de migración.

**R161-06 · Bajo · El borrado deja el historial sin referencia.**
- Evidencia [V]: «El historial no cuenta como uso (PF-05)» y el tipo sin uso se borra (§3.2.7); las tablas de historial temporal no tienen FK [I: así funciona el motor].
- Escenario: un cliente usó `CARNET_MIGRACION`, se reclasificó y el tipo se borró; el historial ya no permite saber con qué `EsPersonaFisica` estaba clasificado al pedir la supresión o en una auditoría. La regla del propietario («si se transaccionó, se inhabilita») admite leerlo así o no.
- Remediación: contar también el historial como uso (con `FOR SYSTEM_TIME ALL`, sin índice nuevo por el tamaño del catálogo), o registrar en `Detalle` de la bitácora del borrado el contenido completo del tipo (ya previsto en §5, verificar que incluya `EsPersonaFisica`). Pregunta P-4.

**R161-07 · Bajo · Siembra a medias sin aviso.**
- Evidencia [V]: la guarda `WHERE NOT EXISTS (... t.Codigo = s.Codigo OR t.Id = s.Id)` (§7.2) omite una fila si su Id está ocupado por otro código; los rangos y el relleno se enlazan por `Codigo` (§7.2, §7.3).
- Escenario: en una base donde la tabla se creó a mano o con una versión previa del guion, `EMPRESA` no se siembra, sus rangos no se insertan y el relleno deja todos los RNC sin tipo, sin error.
- Remediación: tras la siembra, `IF (SELECT COUNT(*) FROM cat.TipoIdentificadorFiscal WHERE Codigo IN (...los cuatro...)) < 4 THROW <código del rango de B fuera de 51618-51644>, ...`, o comprobarlo en la prueba MG-11. Poco probable porque la tabla nace en la misma migración (§6).

**R161-08 · Bajo · `Down` sin guarda.**
- Evidencia [V]: §7.4 reconoce la pérdida de las clasificaciones manuales y de los tipos del SUPER; la exportación previa es un paso manual.
- Remediación: hoy es aceptable (todo es desarrollo). Antes del primer cliente, que el `Down` aborte si existe un tipo con `Id > 4` o una asignación distinta de la derivada, salvo que se indique explícitamente.

## 5. Controles bien implementados [V]

- Aislamiento por empresa por la propia base y la FK (§1, U-17); la copia entre empresas va por `Codigo`, sin sobrescribir el destino (§6).
- Restricciones declarativas fuertes: `UQ` de código, CHECK de código en intercalación binaria, letra con índice único filtrado, `LetraActiva`, rangos 5-20 coherentes con `CK_*_Identificacion` (§3.1).
- FK sin cascada en todo (§3.1, ADR-08); borrar con uso es imposible en el motor.
- A-1 cierra la derivación ambigua con `IsAsciiDigit`, que no acepta los dígitos Unicode de otros sistemas de escritura (§3.2.1).
- La letra fiscal, el 606 y la copia en la venta no cambian (§5, §12): el ADR no altera ningún dato fiscal emitido.
- El relleno es idempotente, no pisa correcciones, deja una línea de bitácora con cantidades y ningún dato personal; su JSON se arma con enteros (§7.3).
- `ISoloCentral` impide editar el catálogo en un nodo (§6); sin permisos nuevos de base; los reportes no tocan `cat` (§9).
- Ningún valor de tercero queda en el código: los cuatro tipos son siembra editable por el SUPER y la derivación se guía por datos (`LetraPorOmision`, §3.2.4). Las descripciones del sembrado son del propietario (Q-TI-1 a Q-TI-4), no de un proveedor.

## 6. Preguntas para especialistas

- **P-1 (especialista-contable / fiscal):** ¿la DGII rechaza un e-CF cuyo RNC o cédula del comprador no cumple el dígito verificador? ¿Hay cédulas válidas antiguas que no lo cumplen? Define si R161-03 es rechazo o advertencia.
- **P-2 (especialista-pos / fiscal):** ¿qué caracteres llevan en la práctica los pasaportes y el carnet de migración de la DGM (guion, barra)? Define el juego de R161-01.
- **P-3 (especialista-contable):** si una persona jurídica queda clasificada como `PERSONA_FISICA` (rango 9 admitido por Q-TI-2) y pide la supresión, ¿qué obligación de conservación fiscal prevalece? Afecta a TI-07 y ADR-92.
- **P-4 (propietario):** ¿un tipo que solo aparece en el historial «tiene referencias» según la regla de eliminar solo sin referencias? (R161-06)
- **P-5 (propietario, con reportes):** firma de Q-TI-8 y Q-TI-9 (R161-04).

## 7. Códigos de error y marcas de migración

- El diseño **no introduce códigos `THROW`**: los rechazos son HTTP 409/422 del servicio (§3.2) [V, sin `THROW` ni `RAISERROR` en el documento]. **Sin colisión con 51618-51644.** Si se adopta la guarda de R161-07, el código debe salir del rango de B y fuera de 51618-51644.
- Marca de migración: `AAAAMMDDhhmmss_Adr161...`, posterior a `20261021001638_Ola5VistasTramo4`, con regeneración si se une otra antes (§7.1) [V]. Sin colisión.
- **O-1 (fuera del ADR-161):** `src/GPOS.Core/Infraestructura/Motor/ComandosCambioRnc.cs:16` define `ErrorOtroCambio = 51618` (commit `e0a99019` de A, 2026-10-18, que lo movió desde 51616) [V]. Si el rango 51618-51644 quedó reservado para D1 de B después de esa fecha, hay una colisión real [I]. El coordinador debe confirmar si se mueve el código de A o se corre el inicio del rango de B.

## 8. Remediaciones priorizadas

1. R161-02 (máscara en el 409): 0,1 dp, antes de construir el servicio.
2. R161-01 (juego de caracteres y CHECK de `P`): 0,25 dp, junto con A-1.
3. R161-03 (`ValidaDigitoVerificador`): una columna y 0,25 dp; depende de P-1.
4. R161-04: firmar Q-TI-8 (a) y Q-TI-9 (b).
5. R161-05 (`DENY UPDATE` de columna): una línea; R161-07 y R161-08 antes del primer cliente.
6. O-1: confirmarlo con el coordinador antes de reservar más códigos.

## Cierre
- Estado: Aprobado con observaciones (recomendación técnica; la firma es del propietario).
- Artefactos: `GPOS-NG-Equipos/traspasos/A/revision-seguridad-adr161-datos-2026-10-22.md`.
- Supuestos: la construcción será sobre `origin/feature/modelo-ng` tal como está; la comprobación del dígito verificador citada (`Empresa.cs:175`) es la de S-03; no se leyó el código de exportación a XLSX (R161-01, parte de fórmulas, inferida).
- Decisiones candidatas a ADR: marca `ValidaDigitoVerificador` por tipo y juego de caracteres de los tipos no numéricos, como precisiones de TI-02.
- Entregas a otros agentes: arquitecto-datos (B) → R161-01, 03, 05, 07 y 08 en el diseño; desarrollador-backend → R161-02 y el control de «mismo dueño» en la copia Q-TI-7; especialista-contable/pos → P-1 a P-3; coordinador → O-1.
- Próximo paso recomendado: que B incorpore R161-01 a R161-03 en el documento y lleve Q-TI-8/Q-TI-9 a la firma del propietario.
