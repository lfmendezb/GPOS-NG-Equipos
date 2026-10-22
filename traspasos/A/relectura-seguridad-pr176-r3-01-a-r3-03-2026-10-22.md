# Relectura de seguridad del PR #176 (R3-01, R3-02, R3-03) · equipo A · 2026-10-22

Alcance: diff de `b/dat-d1-r3` (2 documentos, sin código) contra mi revisión `revision-seguridad-dat-d1-rev3-2026-10-22.md`. Marcas: [V] verificado por lectura; [I] inferido.

**Recomendación: Aprobar con correcciones menores (R3-01 y R3-02) y Corregir R3-03 antes de que T1-4 lo construya.** El #176 puede unirse (es diseño); las correcciones se hacen en el mismo PR o en un seguimiento antes de T1-4.

## R3-01 · Cerrada, con dos restos
- [V] El `@ckCaso` del bloque 5 b es el texto firmado de H-13 (`LIKE '%[A-Z0-9]%'` y `NOT LIKE '-%'`, en BIN2). La prueba nueva cubre `------`, `--MOTIVO`, `-ABC12` y `123`, acepta `A-----` y `123456`, y trae la mutación.
- Resto 1 [V]: la tabla 3.1 (DAT:138) aún dice que la regla de H-13 «es solo una **propuesta**», y el encabezado (DAT:3) aún dice «dos puntos esperan decisión». Contradicen el bloque 5 b.
- Resto 2 [V]: DAT:193 no dice que C# aplica la misma regla de H-13 ni que comprueba ASCII **antes** de `ToUpperInvariant` (U+0131 y U+017F pasan a «I» y «S» [I]). Es la tercera viñeta de mi remediación y no se incorporó.

## R3-02 · Aceptada, con un resto que contradice la lista blanca
- [V] La condición es una lista blanca (Desarrollo o Demostración, firma verificada; sin licencia o vencida: 51622) y tiene prueba.
- Resto [V]: el párrafo de D1-03 (DAT:1241) sigue diciendo que la comprobación usa «la misma función con la que la API se niega a arrancar en Amplio (`Program.cs:441-442`… no lo verifiqué)». Esa función es una lista negra que deja pasar con `Vigente` nulo (`EstadoLicenciaService.cs:425-426`). Hay que reescribirlo para que T1-4 no reutilice esa condición.
- T1-4 debe exponer un verificador de licencia que `GPOS.Migracion` pueda llamar (hoy es un método de instancia de la API [V]).
- Pendientes menores (no bloquean): confirmación escrita `--confirmar DEMO:<n>` (Q-V2-08) y rechazo si alguna vez hubo licencia de Producción o Beta [I].

## R3-03 · Corregir: tal como está no cierra el ataque
La propuesta de B (`ConversionId` más `service_broker_guid` y `create_date` como columnas de `ConversionAccesos`, y el mismo `ConversionId` en la marca) tiene tres problemas.

1. **Son columnas en claro.** Quien puede reemplazar la fila (el escenario de R3-03) escribe también los valores actuales de la base destino, y la comprobación «coincide con la identidad actual» pasa. La marca está en `Configuracion`, que la API escribe, así que tampoco ata nada. El vínculo solo vale si la identidad y el `ConversionId` forman parte del **texto autenticado** (el propósito de la protección de `Membresias` y del padrón), de modo que quien no tenga las llaves no pueda reescribirlos [I].
2. **La identidad elegida puede no diferenciar la copia.** `RESTORE` conserva el `service_broker_guid` salvo con `NEW_BROKER`, y no verifiqué qué `create_date` toma una base restaurada [I]. No se puede apoyar la defensa en que la copia «tenga otro» valor. Hay que probarlo en una instancia real antes de fijarlo.
3. **Se perdió la segunda referencia fuera de la tabla.** Mi remediación pedía el SHA-256 del texto protegido en `ValorNuevo` del evento `ACCESOS_CONVERTIDOS_INSTALACION` (bitácora de solo inserción, `DENY UPDATE, DELETE` para la API). Es la única referencia que la API no puede reescribir y no está en el #176.

**Corrección que pido para T1-4:**
- El propósito autenticado de `Membresias` y del padrón incluye: `InstalacionId`, `ConversionId`, `MomentoUtc`, `Modo`, el anillo de la licencia vigente, el SHA-256 de `PadronV1` y la identidad de la base. Se genera una sola vez al convertir y se guarda también en la marca.
- El SHA-256 del texto protegido va en `ValorNuevo` del evento de la bitácora.
- D3 y Q23 recalculan y comparan ambos antes de sellar, y se detienen (51622) si algo no coincide. D3 se niega a sellar una instantánea de modo DEMO si el anillo ya no es Desarrollo o Demostración.
- Prueba nueva: `ConversionAccesosTests.Una_instantanea_de_una_copia_restaurada_no_se_acepta`, con una copia hecha por `RESTORE` (con y sin `NEW_BROKER`) en la misma instancia. Debe fallar si se quitan los campos del texto autenticado (mutación).
- El diseño del formato lo confirma el arquitecto-software con D3; el arquitecto-datos solo reserva las columnas.

## Para unir
- #176: aprobado para unir si B corrige los restos de R3-01 y R3-02 y reemplaza el texto de R3-03 por la corrección anterior. Si prefiere unir ya, R3-03 queda como condición de T1-4 con este texto.
- T1-1: sin otra condición mía. T1-4: R3-02 y R3-03 corregida; sin ellas, **Rechazado**.
