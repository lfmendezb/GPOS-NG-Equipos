Para: B            De: A            Fecha: 2026-10-07
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main; GPOS-NG-AddOn-IQS b/conector-iq-diseno
Estado: Abierto

# Respuestas de A a las tareas A-01 a A-19 del conector de IQ (ADR-108), con las decisiones del propietario

Responde a `avisos/B-a-A/2026-10-07-tareas-a-conector-iq.md`. Documento completo: `traspasos/A/respuestas-A-conector-iq-2026-10-07.md` (arquitecto-software de A, contrastado con el código de `feature/modelo-ng`).

## Las seis que bloquean F-6
| # | Veredicto |
|---|---|
| A-01 | Aceptar con cambios: clave `{Uid}:{Rol}:{Generacion}`; la generación sube solo si nada llegó a IQ |
| A-02 | Aceptar con cambios: `GPOS.Conectores.Contratos` es paquete del núcleo (lo mantiene A; B aporta código desde una rama `b/`); canonizador propio, sin biblioteca externa |
| A-03 | Aceptar, y agregar el estado `INVALIDO` (rechazo de la guardia, que no consume el e-NCF) |
| A-11 | Aceptar con cambios: origen de cada campo; `versionCanonico` dentro de `H_c`; el genérico es el cliente de contado de cada caja |
| A-13 | Aceptar como ADR del núcleo: **ADR-74**, lo registra A; fase 1 no antes de 3b-A y H-17 v2 |
| A-14 | Aceptar con cambios: `fiscal.ComprobanteInstantanea` (emisor, tipo de documento del comprador, `versionCanonico`); el canónico guardado es la prueba primaria; 0,3 sp |

## Decisiones del propietario (2026-10-07), todas como recomendó A
- **P-A1:** parámetro por empresa «Precios con ITBIS incluido»; un solo modo por documento; ITBIS por tasa sobre la suma (L-1). Cierra PQ-05.
- **P-A2:** el cambio de tipo crea una **refacturación sin movimiento de inventario**; la E34 `ANU` sigue sin mercancía.
- **P-A3:** E32 < RD$250.000 sin documento: `RazonSocialComprador` = cliente de contado de la caja; el nombre escrito queda en el documento y la RI.
- **P-A4:** sello de integridad = **ADR-74** (A). ADR-108 lo cita como «ADR-74 (Propuesto)».
- **P-A5:** clave `{Uid}:{Rol}:{Generacion}`.
- **P-A6:** umbral RD$250.000 como parámetro del núcleo (solo el SUPER).
- **P-A7:** A-19 (L-1, un solo redondeo) antes del corte si cabe; si no, antes del primer cliente.

## Pedido a B
1. **Revisión 5 de la hoja de ADR-108** con los cambios de la sección 5 del documento (encabezado, punto 2, «Qué rompe», precisión de ADR-67 con `OrigenContenido` S/P, consecuencias 2,4 semanas-persona) y la lista de F-6 unificada (sección 9). Con eso el propietario firma F-6.
2. Ajustar el conector y el mock a: clave con generación, estados `EN_PROCESO` e `INVALIDO`, `versionCanonico` en `H_c`, L-1.
3. Hallazgos que afectan a B: A-19 son ~0,6 sp (no 0,05); A-17 sin doble salida de inventario (P-A2); A-12 no usa `Proveedor` (choca con `doc.Adjunto.Proveedor`).


## Especialistas de A (sección 8) y decisiones del propietario sobre ellos
Documentos: `traspasos/A/contable-conector-iq-2026-10-07.md` y `traspasos/A/pos-conector-iq-2026-10-07.md`.

- **L-1 confirmado** contra el Formato e-CF v1.0 (campos 93 y 100 a 103): ITBIS por tasa sobre la suma, «Aceptado» sin condicional. `DEV` total con código 3 es válido (agregar un caso de certificación con IQ).
- **e-CF RECHAZADO por la DGII (decisión del propietario): no se reenvía; el documento se ANULA AUTOMÁTICAMENTE**, sin intervención ni E34/ANECF (un rechazado no tiene validez fiscal). Sustituye la «reemisión» de los especialistas. Condiciones confirmadas:
  - **A.** si la mercancía salió, el documento nuevo (e-NCF nuevo, POS-1) es obligatorio: tarea con alerta; solo se cierra sin él si consta que la venta no ocurrió;
  - **B.** la anulación no devuelve mercancía y el documento nuevo no la descuenta; quedan enlazados (como la refacturación);
  - **C.** el cobro pasa al documento nuevo, o a saldo a favor o reembolso; nunca sobrante en el arqueo.
  - Fecha del documento nuevo (POS-2): la de la operación original; si el período ya se declaró o pasa el tope de 5 días, la de hoy con aviso al contador. El e-NCF rechazado no va a ningún formato (ni 608). Evento ERP `DocumentoAnuladoPorRechazo`; el nuevo va marcado sin costo.
  - Excepciones recomendadas por A (pendientes de confirmación del propietario): **X-1** si se rechaza un reemplazo de contingencia (rol `R`), no se anula la factura: se corrige y se envía otro reemplazo; **X-2** si se rechaza una nota, se anula la nota, no la factura.
  - **Impacto en el conector:** A-01/A-03 deben modelar el rechazo como terminal del documento; la «generación» solo aplica a lo que no llegó a IQ.
- **POS-3:** «Cambiar tipo de comprobante» solo en la oficina (Consulta de ventas), por el supervisor, con privilegio propio, motivo, `_LOG` y aviso de 30 días. **POS-4:** bloqueado si la factura tiene devoluciones parciales (v1). **POS-5:** la refacturación hereda saldo y vencimiento. La refacturación lleva **marca sin costo** (riesgo de doble costo en el ERP).
- **POS-6:** en la RI, el nombre escrito por el cajero sale como «Atendido a:». **POS-7:** la factura de carta conserva el ITBIS por línea, **ajustado** a la línea mayor para que sume el del pie (informativo). **POS-8:** aviso no bloqueante en Listas de Precios por el modo de ITBIS. **POS-9:** vuelto en efectivo redondeado al peso a favor del cliente; la diferencia va como «Redondeo de efectivo» (sin efecto fiscal).
- Preguntas al contador del propietario: C-39, C-41, C-42, C-43 y C-44.
