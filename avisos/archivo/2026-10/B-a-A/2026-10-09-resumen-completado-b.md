```
Para: A            De: B            Fecha: 2026-10-09
Tipo: Informe de avance (pedido del propietario)
Prioridad: Normal
Repositorio y rama: varias (abajo)
Estado: Abierto
```

# Todo lo completado por B el 2026-10-09

## KDS: K1, listo y aprobado para unir por el propietario
- **Rama:** `b/kds-k1` hasta `cc26657`, en origin.
- **Commits:**
  - SD-01 `a4b1a9b` y `Propiedad` `df79075`, revisados por su auditor;
  - registro de dispositivos `dc40169`;
  - pantallas `ae6b7f6` y `eb8456e`, con «Emitir otro código» (KD-P12);
  - estación como servicio de Windows `44098a4`, solo en el MSI de desarrollo;
  - correcciones K1-01 a K1-07 `8d26bf2`, V-04 `add28e8` y V-01 a V-07 `c63acd0`.
- **Seguridad:** cuatro informes del auditor de B, todos «Aprobado con observaciones».
- **Pendiente para ustedes:** la unión (aviso `k1-aprobado-unir-y-decisiones`).
- **Blueprint del KDS ajustado a lo construido:** `b/restaurante-kds-diseno` `613f65d` y `974f8bd`.

## Ola 5 (`b/ola5`)
- **Revisión 4** (`a4588ee` a `e1a8724`): FactorUnidad (TC-01 a TC-05) y datos sensibles (RS-01 a RS-03 y RS-07).
- **Revisión 5** (`6f2542c` a `3de1752`): sus respuestas 1 a 6 y A-K1-01.
- **Huella vigente:** `BD78E5C1…3930C421`. `GPOS.Reportes.Tests` da 136 de 136.
- **Requiere** `ventas.Venta.TipoIdentificacionCliente`.
- **Diseño** (`b/ola5-diseno`): consultas de los reportes 17, 20 y de valuación, y respuesta contable del CNT dentro de AU-11 (`afb0ef1`, `827a42f`).

## Licencia (`[LIC]`)
- **v3.2.5,** que ustedes ya unieron a master.

## Conectores de e-CF
- **En master:**
  - ADR-123 y 124 (`afa7519`);
  - precisiones de los tres repositorios (`2931106`, `f680ccb`);
  - D-K1 a D-K8 (`6656c48`).
- **Repositorios privados:** `GPOS-NG-AddOn-Kit`, `GPOS-NG-AddOn-IQS` (pasado a privado) y `GPOS-NG-AddOn-Polaris`.
- **Kit, tandas 1 a 3, publicado hasta `0.1.0-alfa.3`** en la carpeta local (`77dbb26`, etiquetas `v0.1.0-alfa.1` a `alfa.3`).
  - Contiene la infraestructura del servicio, el motor de emisión con `IProveedorEcf`, el diario con esquema 6 y la prueba de oro contra IQ 0.4.2.
  - Revisión de seguridad «Aprobado con observaciones»: SEC-KP-01 a 04, 06, 08 y 10 cerrados.
- **Polaris, P0 a P4 y P6 parcial** (`78b3de0`).
  - Copia de la referencia de su API (28 páginas con OpenAPI) en `docs/referencia-polaris` (`54a7a8f`), autorizada por el propietario, sin el token genérico.
- **Para A:**
  - D-K4 (de acuerdo con condiciones; anotado);
  - el campo `contingenciaReemplazo`;
  - `valorProductivo` en el protocolo v1 (SEC-KP-10, propuesta);
  - las rutas `…/parametros`, `…/xml` y `…/contraste`;
  - el 503 `AMBIENTE_SIN_PARAMETRO`.
- **Reserva del prefijo `GPOS.` en nuget.org:** aprobada; la hace el propietario.

## AdmCloud
- **Contrato del conector, revisión 3** (`4b6c81b`): «Por despachar», restaurante, anticipo de eventos y el ITBIS sin diferir.
- **Evidencia del 2026-10-09** (`77c7883`):
  - estados del firmado de AdmCloud: 1 Aceptado, 2 En espera, 5 Rechazado y 6 Error (Fortech); solo se consulta con 2;
  - **`ImpactStock` confirmado en el alta** por el sincronizador en producción.
- **Respuestas del propietario a AC-48 a AC-53** (`57c518b`): el respaldo F-1 queda retirado.
- **Correo a Fortech:** borrador listo en el correo del propietario, con las preguntas AC-40 a AC-47, AC-52 y la propina legal (AC-32); lo envía él.

## Verticales: venta fraccionada, «Por despachar» y anticipo de eventos
- **Blueprint v2** (`fc5d4e2`, `b/verticales-diseno`), con todas las respuestas del propietario. Estimación: unas 6,6 semanas-persona, de ellas **3,9 de A**.
- **UX de las pantallas** (`8eb21ba`).
- **Contabilidad:** CT-Q1 a CT-Q8 y la evaluación de las decisiones del propietario (`16cbc65`, `66c49be`).
- **Adenda del cuestionario del contador,** C-38 a C-46, con «Pérdida» (`2f22ffc`, `9f8778a`).
- **ADR-113 en master con las precisiones del 2026-10-09** (`22aa819` a `cd9b9fa`):
  - kárdex contra la orden o el conduce;
  - marca «Por despachar» y sus decisiones;
  - no hay conduces de retorno;
  - anticipo facturado con propina proporcional y «Cerrar anticipo sin evento»;
  - conteo de cajas y sueltas separado en los fraccionables;
  - «Venta por Despachar» en el Restaurante;
  - reserva dura anotada para la entrega 2.
- **Ventanas de las verticales con FactorUnidad** (`302283e`) y Farmacia (`5018cf1` a `50be736`).

## Otros
- **Login con HTTP 400 del DEMO:** reportado con los registros; ustedes ya lo corrigieron.
- **Regla nueva de los agentes:** ningún instalador, servicio, programa con ventanas ni intérprete en la PC del propietario.
