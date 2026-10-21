```
Para: A        De: B        Fecha: 2026-10-21
Tipo: Aviso (N-1 unido; órdenes del propietario) y encargo
Prioridad: Alta
Repositorio y rama: GPOS-NG `feature/modelo-ng` fc7f07f2; PR #124 (`a/instalador-o1-o3`)
Estado: Abierto
```

# N-1 unido, D-1 del #124 y laboratorio de ADR-90

## 1. N-1 está unido: PR-4 se puede abrir
El propietario ordenó (chat, 2026-10-21) unir el #127 y el #132 a `feature/modelo-ng`: **#127 en `a6cb479e` y #132 en `fc7f07f2`**. `Program.cs` tiene las cuatro líneas de `ModoServicioApi` al principio. **PR-4 ya puede apilarse** sobre `feature/modelo-ng` (ventana de F-5: 2026-10-28 a 2026-11-06; B pidió terminar antes del 2-nov).
- PR-4 retira `FijarEscuchaPorOmision` (línea de `Program.cs`, función y constante de `ModoServicioApi`, entrada de `LineasServicio` en `ApiModoServicioArquitecturaTests`) y actualiza `OrdenMiddleware`, como ya lo aceptaron. Su regla para el servicio sin modo (escucha solo en *loopback* en 5071, armado por el código de RT-05) queda como **decisión de A**.
- **Suite oficial filtrada** sobre la punta del #132 (que contenía el #127), 2026-10-21: 4120 correctas, 4 fallidas que pasan solas (`BaseNoDisponibleApiTests.H11S01…`, `Rg14Lote2Tests.Estricto_exige…`, `NumeracionMotorTests.CP103…`, `CompraVariableTablaTests.C10…`), 37 omitidas.
- **S-03, S-04, S-05 y S-07** de su revisión del #127: los toma el desarrollador de B en un PR aparte (menos de un día). **S-06** (unificar el código de salida con el de ADR-90) queda para su PR-4. **S-01 y S-02:** la API no se instala como servicio fuera del laboratorio hasta PR-4; así queda dicho en la descripción del PR.

## 2. D-1 del #124: aprobado
El propietario aprobó: **quitar `config\` del MSI de la estación y dejar solo la raíz** (ADR-77, punto 5: un instalador no declara carpetas de otro componente).
- En `instalador/Comun/Fragmentos/RaizGposNg.wxs`, el componente `ConfigGposNg` sale del grupo que usa el MSI de la estación; lo declaran la API y Reportes (que son los dueños de `config\`). Ajusten la fila de la acción previa, el vector y las pruebas.
- Aprovechen para cerrar lo que B anotó en su revisión de contrato: D-3 (con `REMOVE=EstacionImpresion` la acción aún corre: apliquen `NOT &F = 2`), D-4 (la descripción del PR y el csproj de la acción cita solo la v2), P-O1-5 (faltan los SID de `GPOS.Api`, `GPOS.Web` y `GPOS.Reportes` en la comprobación) y la nota de registro del GUID nuevo en ADR-77 (S-07).
- El #124 **no se une** hasta que A suba esos cambios y el auditor relea; la orden de unión es del propietario.

## 3. Laboratorio de ADR-90
- **Quién ejecuta (decisión del propietario, 2026-10-21): B ejecuta y A revisa la evidencia.** El QA de A deja de ser quien construye y ejecuta; revisa los informes y la evidencia que B produzca (L-1 a L-16 del documento de operaciones de la API incluidos) y dice si alcanzan. Ajusten su plan: qué evidencia esperan de B (formato, capturas, bitácoras), con qué redacción de secretos y cuándo.
- **Hipervisor:** VirtualBox 7 con el paquete de extensión, **ya instalado** por el propietario en `LFMB`. Las VM van en `M:\VM`. C entregó el rediseño (`traspasos/C/2026-10-21-rediseno-laboratorio-adr090-virtualbox.md`): N, F, S y N-L caben con una VM activa; B (navegadores) exige detener el trabajo de B; V y R rebasan el techo de 8 GB con SQL arrancado.
- **Fecha:** su estimación de RT-02 es 2026-11-23; la fase 1 debe quedar lista antes. B la coordina con C y con usted cuando las imágenes estén montadas.

Respuesta requerida: acuse con la evidencia que A espera recibir de B para revisar, y la fecha de PR-4.
