# Traspaso del equipo B: corte de luz, 2026-10-09

**Sin agentes activos.** El trabajo se detuvo de forma ordenada. Todo quedó subido a GitHub y los árboles quedaron limpios. Seguimos en la PC B (7,8 GB); el equipo nuevo aún no está listo.

## Construcción interrumpida (retomar primero)
- **Ola 5, tramo 2:** rama **`b/ola5-tramo2-wip`** (`f1d6025`), en la carpeta `GPOS-B-ola5-construccion` (queda en esa rama).
  - **Hecho a medias:** traducción de filtros del diseñador, generador de la consulta, caché del esquema, sesión del diseñador, contexto, catálogos, registrados de inventario y página en pantalla, con 3 archivos de pruebas nuevos.
  - **Estado:** el agente informó «Compila», pero **no corrió la suite completa**.
  - **Al retomar:**
    1. compilar y correr `tests/GPOS.Reportes.Tests`;
    2. seguir el orden del encargo: paginación con D-04 y D-05, D-03 sucursal, registrados, rutas y exportación (D-01 y D-02), contexto `rptsis` contra interfaces;
    3. al terminar, unir a `b/ola5`.
  - Diseño: `docs/arquitectura/2026-10-09-ola5-api-reportes-tramo2.md`, con D-01 a D-05 firmadas.
  - Documentación: solo los comentarios normales (está suspendida hasta el MVP).

## Hecho hoy (subido)
- Diseño del tramo 2 con D-01 a D-05 firmadas (precisión de ADR-109, master `fb2b513`); hallazgos para A publicados (sucursal, nvarchar, totales).
- Hoja de producción y reportes por vertical **firmada** (`5b47427`), con PR-07 = carta de disponibilidad. **ADR-125** registrado en master (`50d20b0`), con precisiones de ADR-11, 109, 111, 112, 113, 120 y 122.
- ADR-11: grupos y perfiles de los privilegios de cocina y Farmacia (`ee2f45a`).
- ADR-122: módulo de licencia **`COMANDERA`** (`bf72a5f`).
- **Conector IQ listo para la prueba en el ambiente de IQS** (`b/conector-iq-instalador`, `222a3b2`, 593/593). Instrucciones: `GPOS-NG-AddOn-IQS-instalador\docs\operaciones\2026-10-09-prueba-ambiente-pruebas-iqs.md`.
- Avisos a A: meta del MVP (60 % de los flujos de punta a punta), documentación (suspendida hasta el MVP), ADR-125, privilegios y COMANDERA.

## Pendiente del propietario
1. **Firmar la hoja de «Por despachar»** (`b/verticales-diseno`, `91d90cb`, `docs/decisiones/2026-10-09-hoja-firma-por-despachar-fecha-alcance.md`): PF-01 a PF-06 y las respuestas a PF-Q1 (¿hay un cliente piloto con encargos desde el primer día?) y PF-Q2 (fecha en que se mide el MVP).
2. **IQS:** pedir la URL de pruebas, el usuario y la clave, y el RNC de la cuenta. Construir el MSI 0.4.3 en Release, instalarlo y correr el paso 1 de la prueba controlada.
3. Enviar al contador C-38 y C-40 a C-42 (y decidir C-47 a C-50).
4. Ejecutar `herramientas\Consultar-ConduceAjusteAdmCloud.ps1` (AddOn; puede esperar).

## Esperando a A
- Acuse de la meta del MVP y la lista de flujos, la fecha y lo que se aplaza.
- Corridas oficiales de T-57 el 14-oct (la meta 1, ≤ 52 ms, se midió en ≈ 94-102 ms); cierre de la ola 4 hacia el 15-oct; 3b hacia el 22-oct; commit de partida de `b/ola5`; `rptsis` y `GPOS.Migracion`.

## Aplazado por el propietario
- AddOn al final (Polaris PQ-25; contrato AdmCloud 4.9.5 y variantes M/S). Excepción: la prueba de IQ en su ambiente.
- Documentación total, guía de usuario y «Bajo el capó»: hasta el MVP del 60 %.

## Al abrir la próxima sesión
1. Programar la revisión del área común cada 30 minutos (regla 8).
2. Leer este traspaso.
3. Retomar `b/ola5-tramo2-wip`.
