```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-diseno (b40939f), b/conector-iq-construccion (c3db950), b/conector-iq-instalador (36b4c96)
Estado: Abierto
```

# ADR-108 Aceptado (F-6 firmado el 2026-10-07): registrarlo en `master` y confirmar K-16, K-18 y K-19

El propietario firmó **F-6** el 2026-10-07. Con eso la hoja de ADR-108 queda **firmada completa** y **ADR-108 pasa a Aceptado**.

## 1. Registrar ADR-108 en `master` de GPOS NG (pedido)
- **Texto:** sección 7 de `docs/decisiones/2026-10-07-hoja-firma-adr108-conector-iq.md` (revisión 5), rama `b/conector-iq-diseno` del repositorio `GPOS-NG-AddOn-IQS` (`b40939f`).
- **Firma:** registro `docs/decisiones/2026-10-07-respuestas-propietario-df.md`, sección «Firma de F-6».
- **Precisiones que trae ADR-108**, que conviene anotar también en los ADR afectados:
  - **ADR-44, punto 2:** el diario SQLite del conector es una cola técnica transitoria cifrada, con retención contada desde el acuse.
  - **ADR-67, punto 2:** evidencia y XML con `OrigenContenido` S/P, fuera de cuota y sin desmarcado.
  - **ADR-71:** un e-CF rechazado por la DGII se anula de forma automática, con el motivo de sistema «Rechazado por la DGII», y no va al 608. Es provisional hasta la respuesta del contador a C-43.
  - **ADR-51:** primer conector de e-CF construido.
- **ADR-74** (sello de integridad): ADR-108 lo cita como «ADR-74 (Propuesto)». Lo registra A, como se acordó en P-A4.
- **Índice** `docs/adr/README.md`: ADR-108 está en el rango del equipo B (100 a 129).

## 2. Confirmar (no bloquean la firma; están en la sección 2.6 de la hoja)
- **K-16:** X-1 no cabe en la PK `(DocumentoId, Rol)`, que admite un solo comprobante `R` por documento. Se pide una excepción expresa: un reemplazo rechazado pasa a la generación siguiente del mismo `Uid:R` con **otro e-NCF**, porque el rechazado queda consumido. A debe confirmarla y guardar la historia de los `R`.
- **K-18:** una respuesta 400 de validación de IQ deja el documento sin salida. Llegó a IQ, así que no admite generación nueva, y no es un rechazo de la DGII, así que no se anula. Propuesta: `CONFLICTO` con revisión humana. Lo cierran los arquitectos de A y B.
- **K-19:** la clave `{Uid}:{Rol}:{Generacion}` mide hasta **42 caracteres** con `Generacion` `tinyint`, no 40. El propietario firmó 42.

## 3. Para el lado del núcleo (A-04 y A-13)
- **Identidad de la API para la tubería (A-04):** el conector lee `HKLM\SOFTWARE\GPOS NG\Nucleo\IdentidadApi`, que puede ser un SID o `DOMINIO\cuenta`. El contrato y el fragmento WiX están en `docs/operaciones/2026-10-07-instalador-conector-iq.md`, sección 4.2, rama `b/conector-iq-instalador`.
- **Entrada `conector.iq` del manifiesto (ADR-63):** es una propuesta en el mismo documento. El agente nunca pasa `FORZAR`.

## 4. Estado del conector
- **Pruebas:** entregas 1 a 3, ajuste a la respuesta de A y corrección de una carrera en la recepción, con 453 de 453 pruebas en 14 corridas seguidas. Antes de esas corridas hubo una falla aislada que no se pudo capturar.
- **Instalador:** MSI 0.3.0 sin firma construido; queda pendiente la prueba elevada del propietario.
- **Seguridad:** re-revisión final en curso.
