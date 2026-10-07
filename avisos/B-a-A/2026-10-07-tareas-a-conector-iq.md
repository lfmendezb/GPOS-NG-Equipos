```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-diseno (3df3b1a) y b/conector-iq-mock (1293d0e)
Estado: Abierto
```

# Conector de e-CF con IQ Solution: tareas A-01 a A-19 para el equipo A

El propietario firmó el 2026-10-07 casi toda la hoja de ADR-108 (conector de e-CF con IQ). Quedan tareas que son **del núcleo de GPOS NG**: por la cláusula 73.7, el conector nunca toca el núcleo.

## Dónde está todo (repositorio `GPOS-NG-AddOn-IQS`, rama `b/conector-iq-diseno`)

| Documento | Ruta |
|---|---|
| Hoja de firma (revisión 4) | `docs/decisiones/2026-10-07-hoja-firma-adr108-conector-iq.md` |
| Registro de lo que decidió el propietario (**manda sobre la hoja**) | `docs/decisiones/2026-10-07-respuestas-propietario-df.md` |
| Diseño del conector (revisión 3) | `docs/integraciones/2026-10-07-conector-iq-diseno.md` |
| Preguntas, con la tabla de tareas de A | `docs/integraciones/2026-10-07-conector-iq-preguntas.md`, sección 4 |
| UX del núcleo (aprobada) | `docs/ux/2026-10-07-ux-ecf-avisos-y-ri.md` |
| Sello de integridad (seguridad) | `docs/seguridad/2026-10-07-huella-sha256-json-ecf.md` y `docs/seguridad/2026-10-07-revision-dp10-ancla-adjunto.md` |
| Cuestionario enviado a IQ | `docs/integraciones/2026-10-07-cuestionario-iq-solution.html` |
| Mock local de IQ (190 pruebas) | rama `b/conector-iq-mock`, `src/GPOS.Conector.Iq.MockIq` |

## Firmado por el propietario el 2026-10-07

- **Bloques:** F-1, F-2, F-3, F-4, F-5, F-7, F-8, F-9 (provisional) y F-10.
- **Decisiones:** DF-01 a DF-08, DP-01 a DP-15 (DP-10 v3, DP-11 precisada) y UX-01 a UX-04.
- **Aplazado:** solo F-6, el texto de ADR-108. Espera la respuesta de A a A-01, A-02, A-03, A-11, A-13 y A-14.
- **Sin decidir:** PQ-14 y PQ-15.

## Tareas para el equipo A

| # | Tarea | Decisión |
|---|---|---|
| A-01 | Clave `{Uid}:{Rol}` desde la PK `(DocumentoId, Rol)` de `fiscal.Ecf` | D-03 |
| A-02 | Llevar el contrato del protocolo y el canonizador `gpos-jcs-1` a `GPOS.Conectores.Contratos` | D-02 |
| A-03 | Estado `EN_PROCESO` en `fiscal.Ecf` | D-10 |
| A-04 | Publicar de forma genérica la identidad de Windows de la API (tubería con nombre) | D-12 |
| A-05 | Prorratear los descuentos globales en las líneas | D-09 |
| A-06 | Quitar `CK_Ecf_Proveedor` (con `'IQSOLUTION'`) del DDL de `feature/modelo-ng` (`docs/datos/2026-10-04-h0-ddl-entrega1.sql:1026`) | 73.7 |
| A-07 | Contenido del comprobante canónico: emisor, indicadores, referencias, perfil y descubrimiento | D-07 |
| A-08 v2 | Pesables: cantidad a 2 decimales, precio derivado con 4, `cantidadOriginal` y `precioOriginal` | DF-02 |
| A-09 | Plazo del reemplazo desde la salida de la contingencia; `finContingencia` | D-11 |
| A-10 | La interfaz ERP ignora el rol `R` (reemplazos); conciliación mensual | D-11 |
| A-11 | Campos del sobre: `totalDocumento`, `montoTotalNcfModificado`, `finContingencia`, `nombreClienteGenerico` y `lineasPesables` | D-02 |
| A-12 | Precisión de ADR-67, punto 2: evidencia `Origen = SISTEMA` siempre y XML `PROVEEDOR` opcional, 10 años, sin papelera | D-15, C-02 |
| A-13 | Sello de integridad con DP-10 v3: ancla `.gposancla`, llave `GPOS.Sello.Ancla`, ventana «Auditar comprobantes fiscales», resultados de solo inserción y verificador CLI | F-10, SI-01 |
| A-14 | Instantánea fiscal del documento como única fuente del canónico | D-03 |
| A-15 | Identificación del comprador de la E32: forma del documento, restricción al guardar desde RD$250.000, bloqueo del pasaporte y cliente genérico | DF-01 |
| A-16 | Parámetro del ámbito de la propina; regla del 18 % solo con ITBIS incluido | DF-07 |
| A-17 | Cambio de tipo con E34 más documento nuevo; aviso del ITBIS a más de 30 días con línea en `_LOG`; reporte mensual «Notas de crédito con más de 30 días» | DF-05 |
| A-18 | Fecha del reemplazo igual a la del B; si la secuencia se autorizó después, el caso pasa al contador | DF-04 |
| A-19 | Cálculo L-1 de los totales en el núcleo: un solo redondeo y `MontoTotal` igual a lo cobrado | DF-03 |

Costo estimado para A: núcleo de ADR-108 unas 0,6 semanas-persona, más el sello de integridad unas 5,0 (fases 0, 1 y completa). Los dos se estiman con ±50 %.

## Pedidos a A

1. **Responder A-01, A-02, A-03, A-11, A-13 y A-14.** Con eso el propietario puede firmar F-6, y A o el documentador registran ADR-108 en `master`.
2. **ADR del sello de integridad:** es una decisión del núcleo, aparte de ADR-108. Si lo registra B, sería el ADR-109. Indiquen quién lo registra.
3. **Precisiones de ADR existentes que trae ADR-108:** ADR-44, punto 2 (diario SQLite del conector como cola técnica transitoria) y ADR-67, punto 2 (evidencia y XML como contenido de origen sistema).
4. **Calendario:** las tareas del núcleo se construyen después de la ola 4, como el despachador genérico. Mientras tanto, B construye el conector contra el mock y un simulador del núcleo.

## Estado de B en este repositorio

- Mock local de IQ terminado: rama `b/conector-iq-mock`, 190 de 190 pruebas.
- Conector, entrega 1 (modelo, `gpos-jcs-1`, mapeo, guardia de salida y cliente de IQ), en curso: rama `b/conector-iq-construccion`, sin subir.
