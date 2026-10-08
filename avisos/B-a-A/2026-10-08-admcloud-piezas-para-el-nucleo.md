```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG b/conector-admcloud-diseno (sección 16 de docs/arquitectura/2026-10-08-nucleo-conectores-erp.md)
Estado: Abierto
```

# Conector AdmCloud: decisiones del propietario y piezas que el núcleo necesitaría (A-1 a A-10)

El propietario dio el 2026-10-08 varias decisiones sobre el conector de AdmCloud (`docs/decisiones/2026-10-08-respuestas-propietario-admcloud.md`). Las que tocan el núcleo:
- **En los maestros manda el ERP.** Los artículos proceden de AdmCloud. Un maestro creado en GPOS NG, como un cliente, solo es válido cuando se sincroniza y tiene el **GUID que asigna AdmCloud**.
- **Las sucursales en modo nodo publican directo a AdmCloud desde su nodo.** La central publica lo suyo y lo de las sucursales en línea, y nunca reenvía lo que publicó un nodo.
- **El e-CF está bien acoplado:** el núcleo y la ventana conocen el estado del firmado sin releer.
- **Terminología:** «Ubicación» de AdmCloud es el almacén de GPOS NG; «Depósito» de AdmCloud es la «Ubicación» de GPOS NG.
- **AdmCloud no tiene relación con el conector de IQ.**

El diseño revisado del núcleo común (X-2, unas 3,55 sp; **sin firmar todavía**) propone estas piezas del núcleo de A. Es la sección 16, y A estima unas 0,25 sp dentro de T-29 y de la entrega 2:
- **A-1:** DDL de `integ.Correspondencia` (GUID externo por maestro y documento, con `NodoOrigenId`). **Pedimos reservar ya el nombre.**
- **A-2:** la sincronización de ADR-53 lleva la correspondencia: sube lo nacido en el nodo y baja lo de la central y lo que viene del ERP.
- **A-3:** subida a la central de la conciliación y del resumen de envíos del nodo.
- **A-4:** confirmar el origen de los maestros: clientes con llave del rango del nodo (`SecCliente`) y artículos solo en la central.
- **A-5:** aplicadores de entrada en los servicios de artículos y clientes, con origen `ERP`. El alta manual de artículos queda bloqueada si el ERP es el dueño (pregunta NC-12 al propietario).
- **A-6:** el evento `EstadoComprobanteCambiado` en el despachador de e-CF de T-29. La ventana se entera por eventos del servidor (SSE) en `GET /api/eventos/documentos`.
- **A-7:** `IClienteConectores` habilitado en el rol `Sucursal`.
- **A-8:** el validador de la licencia del nodo lee `CONECTOR_ERP`.
- **A-9:** las precisiones de 73.8 de ADR-73 y de la línea 31 de ADR-53, que redacta el arquitecto-maestro de B.
- **A-10:** el estado del maestro frente al ERP en pantallas y en la API, y la regla de uso de un maestro pendiente de sincronizar que firme el propietario (NC-16).

**Verificado en `f21b788`:** `NodoOrigenId` ya existe (`DocConfiguracion.cs:67`). Con eso la central no reenvía lo del nodo, sin necesidad de una marca nueva.

Todo esto se construye **después del corte** (ADR-73). Cuando el propietario firme la hoja de AdmCloud, B confirma la lista. A puede objetar o precisar desde ya.
