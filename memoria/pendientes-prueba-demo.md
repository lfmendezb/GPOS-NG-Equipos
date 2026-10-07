---
name: pendientes-prueba-demo
description: "Mejoras que el propietario levantó en las pruebas de la empresa DEMO (2026-10-03); hechas, en prueba y pendientes"
metadata:
  node_type: memory
  type: project
  originSessionId: 2d7f126f-da10-49d8-816e-0263756730c0
  modified: 2026-10-04T00:54:17.006Z
---

Levantadas por el propietario el 2026-10-03 en las pruebas con la empresa DEMO. Pidió trabajarlas "cuando sea conveniente según el cronograma".

**Hechas en la rama `feature/lote-pantallas`, commit `cdb0c3d`** (sale de `6566f15`, RG-04/05). El QA las dio por "Aprobado con observaciones" y el propietario las probó a mano el 2026-10-03.
- Observaciones bajas del QA, para la segunda tanda:
  - "Nuevo" dentro de una factura importada del POS vuelve a importar la captura.
  - Validar el permiso en `ImportarDesdePosAsync`.
  - Un fixture JSON y varios comentarios todavía dicen "→" o "Aplicar esquema".

Contenido del lote:
- Reportes: los filtros se pliegan al ejecutar.
- Tablero: Exportar habilitado en "Consultar facturas vencidas". La causa era que la Consulta de facturas no se redibujaba al cargar.
- POS → factura a crédito: solo una captura sin guardar; traslada cliente, productos, descuentos, vendedor y notas (recortadas a 200); no traslada los pagos; al guardar vuelve al POS vacío y al cancelar, con la captura intacta. El propietario aceptó la limitación del F5 en Web.
- RG-26, RG-27, RG-28, RG-29 y RG-31.
- En la prueba no se pudo verificar el traslado de vendedor y notas: no hay maestro de vendedores (Nota 5) y el POS no tiene campo de notas.

**Segunda tanda (2026-10-03):**
1. Consulta de facturas: plegar las opciones y destacar los datos, igual que en Reportes. Rápida.
2. Diálogo Nuevo cliente: si el cliente ya tiene código, el botón debe decir "Actualizar y usar" y guardar los datos nuevos en el maestro. Revisar el permiso de modificar clientes.
3. Cerrar sesión con cambios sin guardar, en un documento o un maestro: advertir antes de cerrar. No aplica al cierre forzado de "Forzar nuevo inicio de sesión" en Usuarios y permisos. Afecta a todas las pantallas.
4. POS: Enter en el RNC o la cédula lanza la consulta, igual que el botón, que se mantiene. Rápida.
5. **Ventana nueva, Empleados:** datos generales y las casillas Inhabilitado y Es ejecutivo de ventas. Solo los empleados habilitados y ejecutivos de ventas aparecen en el campo Vendedor de todas las ventanas. Necesita diseño de datos por la compatibilidad con BP2 (tabla de vendedores existente) antes de construir.
6. POS, lista de ventas: los iconos Imprimir, Enviar por correo y Devolución deben ser más grandes, aptos para pantalla táctil sin solaparse. Rápida.
- **Campo Notas en el POS:** aprobado el 2026-10-03; va en la segunda tanda.
- **Nota 2, decisión del propietario (2026-10-03):** dividir el privilegio.
  - La ventana completa de Cliente maneja datos sensibles.
  - El diálogo rápido se formaliza con el nombre **"Cliente Ágil"**. Tiene datos que un cajero puede y debe actualizar.
  - La empresa podrá asignar un privilegio propio para modificar los datos de Cliente Ágil, independiente del de la ventana Cliente.
  - El servidor debe limitar la actualización a los campos de Cliente Ágil.
- RG-27 (número con ancho fijo): aprobado por el propietario en la prueba manual.
- **Orden aprobado:**
  1. QA del lote 1 y commit.
  2. Segunda tanda: notas 1, 2, 4 y 6, más Notas en el POS.
  3. En paralelo, diseño de Empleados y Vendedores con el arquitecto-datos.
  4. Después, la nota 3 y la construcción de Empleados.

**Pendientes de antes:** usuario limitado a su empresa predeterminada; se cruza con ADR-34 (membresía por empresa, firmada y no construida).

Relacionado: [[no-generar-comprobante-permiso-bitacora]], [[clasificacion-empresas-pendiente]].

**Ronda 1 de mejoras del demo (2026-10-05):** documento del propietario `C:\Users\lfmen\OneDrive\Instalador\GPOS ARGON\Mejoras y Correcciones.docx` (Word en línea, enlace 1drv.ms). Pidió validarlo, resolver y **actualizar la hoja con los puntos resueltos al final**, como briefing para la próxima ronda. Puntos: (1) maestro de Ofertas en Tablas de Venta; (2) menú «Punto de Ventas» sobre Ventas con Punto de Venta y Devolución POS; (3) renombrar «Punto de venta» a «Facturación Ágil» (acceso directo igual); (4) recordar modo oscuro/claro; (5) datos del cliente plegados en Facturación Ágil; (6) Enter busca en Clientes; (7) KPI del dashboard: enlaces de Ventas y Valor del inventario, y veracidad de los datos (nota del propietario: un error ahí es catastrófico); (8) «Crear Recibo» primera opción y «Crear Devolución» segunda en Crear/Cargar de Factura a Crédito. En curso en la copia `GPOS-NG-mejoras`, rama `feature/mejoras-demo-ronda1` desde master `0be11ad`, con un desarrollador-frontend; luego backend para lo que haga falta (Ofertas, dashboard) y QA para validar los datos del dashboard. El propietario agregó el ejecutable del agente de impresión a su copia del demo en OneDrive (SHA-256 4a9aec4b…9dc2, 1.791 archivos).
- **2026-10-05:** por pedido del propietario, la hoja `Mejoras y Correcciones.docx` se reemplazó por una **guía de revisión** de los 8 puntos en orden (pedido textual, estado, cómo verificarlo, resultado ☐ Aprobado ☐ Corregir, notas, y sección «Para la próxima ronda»). Original guardado como `Mejoras y Correcciones - original 2026-10-05.docx` en la misma carpeta. Generador: `construir.ps1` en el scratchpad de la sesión (sin Node en el equipo; se edita el XML conservando estilos). Al terminar la ronda, actualizar el campo «Estado» de cada punto en esa hoja.
- **2026-10-05, ronda 1 implementada en la interfaz:** rama `feature/mejoras-demo-ronda1` (copia `GPOS-NG-mejoras`), commits `9de6567` (menú Punto de Ventas y Facturación Ágil), `cab20e0` (tema recordado), `db3d0fe` (datos del cliente plegados), `38c697c` (Enter en Clientes, Suplidores, Artículos y Consulta de facturas), `9eb94e9` (enlaces del tablero), `37f2aae` (Crear Recibo en Factura a Crédito). Web.Tests 110, MAUI.Tests 270. Sin unir a master; falta la prueba manual del propietario. Hoja de revisión actualizada con los estados. **Pendientes:** Ofertas (no hay API y nada aplica las ofertas al vender: decisión del propietario; recomendado construirlo en la ola 2 del modelo nuevo); servidor del tablero: filtro que reproduzca la tarjeta Ventas, período calculado por el servidor, conversión de monedas, totales de reportes de más de 10.000 filas, devoluciones duplicadas en el detalle de la consulta (`ConsultaFacturasService.cs:174-180`); QA debe validar los indicadores contra la base; Enter con el mismo defecto en Bitácora, Cola de correos, RNC DGII, Existencias y diálogo de Autorización.
- **Decisión del propietario (2026-10-05):** en la ronda 1 «solo trabaja la disposición visual y que el resto se integre en la ola 2». **Backlog para la ola 2 del modelo nuevo:** (a) maestro de Ofertas y su aplicación en Facturación Ágil y la facturación (ADR-15/16; tabla ya diseñada); (b) servidor del tablero: filtro que reproduzca la tarjeta Ventas, período calculado por el servidor, conversión de monedas, totales de reportes de más de 10.000 filas, devoluciones duplicadas en el detalle de la consulta, y validación de los indicadores contra la base (QA). Nota técnica: las consultas de ventas y devoluciones se reescriben en la ola 3 y los reportes en la ola 5; en la planificación de la ola 2 el arquitecto debe ubicar cada parte donde existan sus datos. Hoja de revisión actualizada con estos estados.
- **Corrección del propietario (2026-10-05): «integra cada punto en la ola que corresponda, de modo que no se retrase el cronograma».** Sustituye el backlog «todo a la ola 2». Asignación: **ola 2** (maestros): maestro de Ofertas y su aplicación en las ventas; tasas de cambio. **Ola 3** (núcleo transaccional): filtro exacto de la tarjeta Ventas, período calculado por el servidor, devoluciones duplicadas en el detalle de la Consulta de facturas. **Ola 5** (reportes): totales de reportes de más de 10.000 filas, conversión de monedas en indicadores y reportes, validación de los indicadores contra la base por QA. Al lanzar cada ola, incluir sus puntos en el encargo del desarrollador. Hoja de revisión actualizada.
- **Paquetes del demo, ronda 1 (2026-10-05):** `Solucion GPOS NG\GPOS-Demo-Socio-Actualizacion-2026-10-05.7z` (SHA-256 a1640169…2222; `Actualizar-Demo.ps1` y `Revertir-Actualizacion.ps1`) y `GPOS-Demo-Socio-2026-10-05.7z` (SHA-256 5698e66a…8f23, reinstalación completa), compilados desde `9eb94e9` (rama de mejoras), API/Web/MAUI en Release, sin `GPOS.Demo.Llaves.dll` (opción nativa de llaves, compatible con las del demo anterior), con el MSI del agente de impresión 1.0.0.0 sin firma. Verificados (a) a (e). Limitaciones: ruta del demo de 130 caracteres como máximo; actualizar con el mismo usuario de Windows que instaló.

**Ronda 1 revisada por el propietario (Word en OneDrive, 2026-10-05 16:29, SHA 9364732…f9e2):** puntos 1 a 7 «Aprobado»; punto 8 («Crear Recibo» en Factura a Crédito) sin marcar. Nuevas entradas «Para la próxima ronda» y cuándo aplicarlas (propuesta 2026-10-05): (1) segundo botón Guardar bajo los totales en Factura a Crédito, Cotizaciones, Pedidos, Solicitudes de compra, Órdenes de compra, Facturas de compra y Recibos de cobro (bajo «diferencia») → ronda 2 visual; (2) método de pago predeterminado del suplidor, sugerido en Pagos → ola 4; (3) enlace de los KPI con gráfico a una vista en tabla → ronda 2 visual (mismos datos), validación en ola 5; (4) reportes de CxC y CxP → ola 5; (5) guardar por usuario la configuración de campos de cada reporte → ola 5. Más el resto del defecto de Enter (Bitácora, Cola de correos, Obtener RNC DGII, Existencias, Autorización) → ronda 2.
