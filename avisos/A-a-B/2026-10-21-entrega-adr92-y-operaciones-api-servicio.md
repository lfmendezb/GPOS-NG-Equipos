```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Entrega (tareas 1 y 2 del encargo del 2026-10-21; falta la revisión de seguridad del #127)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/` (propuestas, sin decisión)
Estado: Abierto
```

# Entrega: respuestas técnicas de ADR-92 y operaciones de `GPOS.Api` como servicio

## ADR-92 (propuestas; nada decide)
- **Datos:** `traspasos/A/adr92-respuestas-datos-2026-10-21.md` (TT-P1 a TT-P5, CS-P2 a CS-P4). **CS-P2 (para antes del 2-nov):** `NumeroCaso varchar(30) COLLATE Latin1_General_BIN2 NULL` y `Urgencia bit NULL` en `BitacoraSeguridad`; `CK_BitacoraSeguridad_Caso` (nuevo), `CK_BitacoraSeguridad_IngresoSuper` (mismo nombre que D1, ampliado) y `CK_BitacoraSeguridad_CierreUrgencia`; índice filtrado por caso. Trae la DDL lista (bloque 5 b, sustituye D1:924-926), el reverso y las pruebas; T1-1 debe comparar la definición de un CHECK ya existente y rehacerlo. **Hallazgo Alto en TT-P2** (para la firma de la fase TT): `cat.Cliente` y `cat.Suplidor` son temporales con historia de 10 años, y el `UPDATE` que anonimiza copia los datos personales al historial: la supresión no los retira de la base; propongo bloqueo con acceso restringido por omisión y un verbo de `GPOS.Migracion` si el abogado exige anonimizar.
- **Software:** `traspasos/A/adr92-respuestas-software-2026-10-21.md` (TT-P6, CS-P1, CS-P5 a CS-P7). **Hallazgo que cambia CS-P6:** en DB-7 toda sesión lleva una empresa, así que cerrar una urgencia sin entrar a una empresa exige una vía propia (`GET/POST /api/auth/super/urgencias[/{caso}/cierre]` con preautorización o sesión).
- **Para reconciliar tú:** el documento de software menciona «un indicador "exige caso" por evento en el catálogo» para CS-P2 y el de datos usa un CHECK solo sobre `INGRESO_SUPER` (con CS-P1 abierto, el resto lo impone la API). Son compatibles; conviene decidir uno.
- **Para el propietario (vía B):** P-92-S1 a S4 (reglas R1 a R3 con prueba de arquitectura; `--caso` en los verbos de `GPOS.Migracion`, que amplía el ADR del SUPER al técnico; cierre y lista de urgencias; rutas `/api/titulares` con DTO cerrados) y lo que cambia lo que ve cada persona. **Preguntas para el contador:** Q-TT1-a, Q-TT5-a. **Para el especialista-pos:** Q-TT1-b, Q-TT5-b y la lista de campos de TT-02, que bloquea la construcción de TT. **Para el abogado:** las retenciones.
- La escritura autorizada solo con preautorización (TT-P6) es la primera de su tipo: va al auditor-seguridad.

## `GPOS.Api` como servicio (N-1)
- `traspasos/A/operaciones-gpos-api-servicio-2026-10-21.md` (para `docs/operaciones/`): solo `SeChangeNotifyPrivilege`, con cada privilegio no pedido justificado. **Corrige mi plano v2:** `ConvertidorPdf` sí lanza Chrome o Edge (PuppeteerSharp); la lista no cambia (el hijo hereda el token) pero L-9 y L-10 del laboratorio deben pasar antes de firmarla, con una escalera de privilegios si fallan (nunca `--no-sandbox`). SID esperado calculado: `S-1-5-80-546908902-3265840057-98699379-1016526221-3413751906` (se confirma con `sc showsid`).
- **Hallazgo Bajo:** el perfil temporal del navegador no se borra y el TEMP de la cuenta virtual no está definido (también se escribe el RNC); recomienda `%ProgramData%\GPOS NG\Api\tmp\` (cambio de código mío o tuyo).
- **Hasta PR-4** no es instalable la cadena completa con el verbo `red` antes del MSI (`FijarEscuchaPorOmision` fija `urls` y `ArranqueRed` daría 4744): instalar sin `red`. Dieciséis pruebas de laboratorio elevado (L-1 a L-16, 0,5 a 1 dp), en el equipo que fije B. Documento «listo para decisión», instalación «no lista».
- **Falta** la revisión de seguridad del #127 (en marcha); te aviso al entregarla (antes del 27-oct).

Respuesta requerida: ninguna.
