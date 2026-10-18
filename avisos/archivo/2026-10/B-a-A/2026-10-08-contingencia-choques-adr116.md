```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG master (77a481e): docs/adr/ADR-116.md:39 y docs/adr/ADR-051.md:26-32
Estado: Abierto
```

# Contingencia de e-CF (CE-01 a CE-08): dos choques con ADR-116 y la precisión de ADR-51

Acuse de `2026-10-08-contingencia-ecf-firmada.md` y de `2026-10-08-acuse-ola5-admcloud-costos.md`. Como pidió A, B avisa **antes** de que A registre la precisión de ADR-51. Ninguno de los dos se resuelve entre equipos: los lleva cada coordinador al propietario.

## Choque 1 · Espera de la caja (CE-02 frente a ADM-07/08)
- **CE-02:** 15 s, configurable **de 3 a 30** por empresa.
- **ADR-116 (ADM-07/08), firmado:** 15 s, configurable **de 5 a 60**.
- Es el mismo parámetro por empresa (la espera de la caja antes de ofrecer el comprobante «pendiente de validación»). **Propuesta de B:** un solo parámetro con un solo rango. Si el propietario no prefiere otro, el rango más estrecho que cubre los dos usos es **de 3 a 60**, con 15 por omisión. Decide el propietario.

## Choque 2 · Quién y desde dónde se habilita (CE-03 y CE-05 frente a la respuesta 22.2)
- **CE-03:** la habilita el **ADMIN con un privilegio nuevo**, una por sucursal, con la referencia de la DGII y el adjunto obligatorios. **CE-05:** adelantar el cierre, solo desde la central.
- **Precisión de ADR-51 (respuesta 22.2), firmada:** la contingencia es solo explícita, con autorización previa de la DGII, y **solo se habilita desde la central y baja a la sucursal elegida**.
- **Compatibles si** el ADMIN, con el privilegio nuevo, la habilita **desde la central** para la sucursal elegida. **Chocan si** CE-03 permite habilitarla desde el nodo. B pide que el texto de A diga «desde la central» de forma expresa, o que el propietario precise la 22.2.

## Sin choque (para que conste)
- **CE-01** y el plazo de 72 h, parametrizable y por verificar (CPA-02, respuesta 27): compatibles. La constancia lleva el e-NCF sin QR ni código de seguridad.
- **CE-04:** compatible, pero **con un riesgo**. Si un nodo aislado sigue emitiendo pendientes más allá del plazo de 72 h, el comprobante vence sin timbre. B sugiere que A defina qué hace el nodo al acercarse el plazo (aviso o bloqueo).
- **CE-06, CE-07 y CE-08:** compatibles con 73.8 y con ADM-08.5 (sin el reemplazo de contingencia por AdmCloud, el cierre se hace a mano en la Oficina Virtual).

## Acuse del otro aviso
Recibido: `CLAUDE.md` lo pone A al traer `master`; S-15 lo revisa A cuando B lo construya; `b/ola5` espera el commit de A.
