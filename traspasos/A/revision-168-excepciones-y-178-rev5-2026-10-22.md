# Revisión de A: #168 (política AdminSinRestriccion y lista de excepciones) y #178 revisión 5

Equipo A · 2026-10-22 (noche) · lectura estática: no compilé el #168 de B ni corrí sus pruebas (compilé solo la rama `a/usuarios-razor-restriccion` rebasada sobre `11207ad7`: Web, 0 errores).

Alcance: #168 punta `11207ad7` (`AdminSinRestriccion.cs`, `AdminEndpoints.cs`, `UsuariosService.cs`, pruebas `AdminSinRestriccionHttpTests`) y `docs/datos/2026-10-22-t4-10-vistas-imp.md` de #178 punta `af9e4123`, solo lo cambiado desde la revisión 4 que revisé (`38a80c96`).

## Dictamen

- **#168: Aprobar con observaciones.** Sin hallazgos Altos ni Medios. La lista de excepciones es coherente y cada ruta permitida queda acotada en el servicio.
- **#178 rev. 5: Aprobar.** S178-R4-01 a R4-07 quedan incorporadas; hay dos observaciones Bajas para la construcción.

## #168

**Verificado [V]**
- La política cubre todo `/api/admin` (el grupo `g` y los grupos de Importaciones, Impresión, Licencia, Notificaciones, Numeración, Políticas, Precios, Exportaciones, Diseñador, Restauración y RNC) y los tres grupos que se mapean fuera de `g` (`diagnostico`, `motivos-anulacion`, `sucursales/{codigo}`). `empresas` hereda de `g`.
- El alcance se resuelve con el estado guardado en `GPOS_SYSDATA`, no con el token; cuenta inexistente o inhabilitada falla cerrada (`ManejadorAdminSinRestriccion`). Una ruta nueva nace cerrada.
- Las 8 rutas permitidas están acotadas en el servicio: `GET usuarios` filtra con `CuentasGestionablesAsync`; `POST usuarios`, `cerrar-sesiones`, `inhabilitar`, `desbloquear` y `pos/usuarios` (POST/DELETE) pasan por `ExigirCuentaEnAlcanceAsync` o `ExigirGestionableAsync`. Una cuenta que no existe da el mismo 403 que una ajena (sin oráculo de existencia).
- M-168-2: al crear, el restringido solo crea cuentas restringidas a su empresa y sucursal; ninguno cambia la bandera ni la empresa o sucursal de una cuenta restringida (`ExigirRestriccionSinCambiosAsync`). Solo el SUPER asigna el nivel SUPER.
- `/api/admin/reportes` de la API de reportes no usa esta política, pero `PuedeDisenar => EsAdmin && !RestringirSucursal` (`ContextoReportes.cs:43`) deja el mismo resultado: el restringido recibe 403 del diseñador.
- El evento `ACCESO_RECHAZADO_SUCURSAL` lleva método, plantilla de la ruta y código, sin valores de la petición, con el limitador de D81-10.

**Observaciones (todas Bajas, ninguna bloquea la unión)**
- **O168-01 · EventId 5120 sin asignar en el reparto.** `AuditoriaRestriccionSucursal` usa `EventId(5120)`. No lo tengo en mi lista de rangos (#170: 5117-5119; #175: 5121-5129), así que queda libre entre ambos; confirmar que `EventIdUnicosTests` lo cubre y anotarlo en el reparto.
- **O168-02 · El limitador pierde el detalle del segundo sondeo.** Es uno por minuto, evento y usuario. Si un restringido recorre varias rutas en el mismo minuto, solo queda la primera en la bitácora. Es el comportamiento de D81-10 y es aceptable; basta anotarlo en la hoja para que nadie espere un rastro completo del barrido.
- **O168-03 · Efecto aceptado, no un defecto.** Un USER restringido con conciliación, motivos de anulación, cierre de sucursal o listas de precios recibe 403 en esas rutas (el propietario lo aceptó en la hoja del #187). Lo señalo solo para que el perfil de ejemplo «Contador» y las pruebas de humo no lo den por regresión.
- **O168-04 · Cliente.** Falta que la Web y MAUI oculten las opciones denegadas y que el evento nuevo tenga etiqueta en español. `PaginaBase` ya muestra el mensaje del servidor ante cualquier 403, así que nada se rompe mientras tanto. `Usuarios.razor` (rama `a/usuarios-razor-restriccion`, `48bce01e`) está rebasado sobre la punta y compila; la parte del menú es una tarea aparte y no la he hecho.
- **O168-05 · Cobertura de pruebas.** Las cinco pruebas de `AdminSinRestriccionHttpTests` que vi cubren el 403 por ruta, la lista abierta, la lista de usuarios, la configuración POS y la bitácora. No vi una que recorra por reflexión los endpoints de `/api/admin` para exigir la política (el comentario de la clase dice que la guarda `AdminSinRestriccionTests` lo hace; no la abrí). Si existe, basta con citarla en la hoja; si no, es la prueba que impide que una ruta nueva nazca abierta.

## #178 revisión 5 (solo lo cambiado)

**Cerrado [V]**
- S178-R4-01: el X sin montos usa `CierreSinMontosDto`, cerrado y con la lista exacta de campos de `imp.Cierre`, sin colecciones ni `decimal`; prueba estructural por reflexión y prueba de datos (sin cifras ni «dif.»). `imp.Cierre` ya no tiene montos (doc 2.3 y prueba 9), así que la prueba estructural es coherente.
- S178-R4-02: decidido por el propietario; `GET /api/efectivo/movimientos-caja` queda para `CuadreCaja` o `ReportesEfectivo` (hoy admite también `AperturaCaja`, `EfectivoEndpoints.cs:90`). Prueba 21 y R19 lo cubren. Revisé el resto de `EfectivoEndpoints`: ninguna otra ruta que admita `AperturaCaja` o `CierreX` devuelve movimientos de la caja (`/apertura` solo abre; `/cierres/{numero}/anular` devuelve 204 y es de ADMIN; `/z` exige `CuadreCaja`).
- S178-R4-03 a R4-05 y R4-07: el conjunto explícito de `Kid` aceptados, la excepción de `otp` solo en `Development`, el recorte como evento informativo y los EventId (5150-5154 para T4-10; 5134-5138 para PR-V) coinciden con mi diseño del sello.
- Costo anotado: `GPOS.Reportes.Api` no lee `auth_time`. Es mío (R20) y lo traigo al diseño del sello; hasta entonces el sellado falla cerrado.

**Observaciones (Bajas, para la construcción)**
- **O178-R5-01 · `Notas` y `MotivoAnulacion` son texto libre dentro del DTO sin montos.** Un cajero sin `vercuadrecaja` podría ver una cifra escrita en esos textos (por ejemplo «faltaron 500»). No es una fuga del sistema, la escribió una persona, pero la promesa «ningún monto» de la prueba 21 no la cubre. Opciones: dejar los dos fuera del DTO del X sin montos, o anotar en R19 que el texto libre no se filtra.
- **O178-R5-02 · El evento informativo del recorte no tiene número.** S178-R4-05 lo define («a lo sumo una línea por usuario y día») pero no dice qué EventId usa; 5150-5154 ya están asignados. Que lo tome 5155 o lo diga la hoja antes de construir.
- **Seguimiento (no es hallazgo):** S178-R4-06 sigue como propuesta con [I] («quién lee la bitácora de documentos del Z»). Conviene confirmarlo antes de construir, porque decide si se quitan o no los montos de la descripción.

## Pendiente mío tras esta revisión
- Agregar la lectura de `auth_time` en `GPOS.Reportes.Api` al diseño del sello (R20).
- Si B lo pide, la parte del menú de la tarea 7 (opciones denegadas ocultas y etiqueta de `ACCESO_RECHAZADO_SUCURSAL`).

## Resumen para quien firma
- #168: puede seguir su camino; las cinco observaciones no condicionan la unión.
- #178: la revisión 5 queda aprobada. Antes de construir T4-10, B decide O178-R5-01 y O178-R5-02.
- No unir nada sin orden del propietario.
