# Revisión adversarial independiente del PR #220 (2026-10-24)

PR: «NavMenu: opciones de administración de la cuenta restringida a su sucursal (ADR-93, TA-P08)». Rama a/menu-restringir-sucursal, commit 2ee29cc7. Solo lectura: diff y árbol de la rama vía `git show origin/...`; no se compiló ni se ejecutaron pruebas (no verificado).

## Recomendación: APROBADO CON OBSERVACIONES
Una observación Media (H-1) conviene corregir antes de unir; el resto son Bajas o aceptadas por el propio PR.

## Lo verificado
- Servidor como autoridad: SÍ. `AdminEndpoints.cs:21` aplica `RequiereAdminSinRestriccion()` a todo `/api/admin`; los grupos hermanos (conciliación, motivos, sucursales, listas de precios, formatos, importaciones, licencia, numeración, políticas, reportes, RNC, restauración, exportaciones) también la llevan. La política (`AdminSinRestriccion.cs:41-52`) falla cerrado y lee la bandera y el nivel de GPOS_SYSDATA vía `IAlcanceAlmacenes.SinRestriccionAsync`, no del token. El menú no es la única barrera.
- Acceso por URL: las páginas `admin/*` siguen alcanzables (sin guarda de ruta), pero todas sus llamadas `api/admin/*` devuelven 403 `RESTRICCION_SUCURSAL_ADMIN`. No se obtiene dato ni acción. El PR lo declara como pendiente.
- Web y MAUI: las dos copias de `NavMenu.razor` quedan idénticas (mismo hash de blob 3e33cdcf) y hay una prueba que lo comprueba. No hay más copias del menú.
- SUPER: `Seguridad.cs:153` fija `RestringirSucursal = UsuarioAlcance.Restringe(nivel, bandera)`, que excluye al SUPER; el menú no repite la comprobación de nivel, pero depende de ese valor.
- Pruebas: 5 (1 + 2 de Theory + 1 + 1). La prueba 1 falla sin `BloqueadaPorRestriccion`; las demás pasan sin el cambio por diseño (controles negativos y paridad). La afirmación «fallan 2 de 5» del PR se debe a las dos de la prueba de las dos copias... en rigor solo la 1 depende del cambio; la segunda falla solo si se rompe la paridad. No reproducido.
- Verificado también: Dispositivos (`tablas/restaurante/dispositivos`) usa `/api/restaurante/dispositivos`, fuera de `/api/admin`: el servidor no lo bloquea y el menú no lo oculta; coherente.

## Hallazgos

### H-1 (Media) «Listas de Precios» sigue visible para el restringido y el servidor la rechaza
- Evidencia: NavMenu.razor:208 `new("Listas de Precios", "tablas/listas-precios", Permisos.ListasPrecios)`; `PreciosEndpoints.cs:15` `/api/admin/listas-precios` con `.RequiereAdminSinRestriccion()`; `ApiClient.Precios.cs:7`.
- Escenario: ADMIN restringido (con el privilegio, que el ADMIN tiene por nivel) ve la opción, la abre y recibe 403. Es exactamente lo que el PR dice evitar. El filtro por prefijo `admin/` mide la ruta de la página, no el endpoint que usa; cualquier opción de menú cuya página llame a `/api/admin` con ruta distinta cae igual.
- Remedio: ocultar `tablas/listas-precios` para el restringido (añadir a una lista de rutas bloqueadas, o mejor, marcar en `Opcion` un indicador `SoloSinRestriccion` en vez de deducirlo del prefijo), más prueba. Revisar el resto de opciones con ruta fuera de `admin/` cuyo cliente use `api/admin/*` (barrido hecho: solo Listas de Precios y, ya cubiertas por prefijo, las demás).

### H-2 (Baja) Lista permitida acoplada al prefijo y a un arreglo manual
- Evidencia: NavMenu.razor:~138-142 (`PrefijoAdmin`, `RutasAdminDelRestringido`). Si el servidor amplía la lista de excepciones (`PermitidaAlAdminRestringido`, AdminEndpoints.cs:134-330) o mueve una pantalla, el menú se desincroniza sin que nada falle. La prueba solo fija las dos rutas actuales. La lista de excepciones del servidor está además «pendiente de aprobación del propietario» (AdminSinRestriccion.cs, remarks).
- Remedio: una prueba de guarda que cruce las rutas del menú con los endpoints marcados (o al menos documentar en el ADR/estado.json). Condición: no unir el menú como «Construido» mientras la lista de excepciones no esté aprobada; dejarlo Parcial como propone el PR.

### H-3 (Baja) Sobre-ocultamiento de «Período Fiscal»
- Evidencia: opción `admin/periodo-fiscal` (permisos Período fiscal | Reportes fiscales | Clase de agente) usa `/api/fiscal/...` (AdminEndpoints.cs, periodo y clase-agente fuera del grupo admin), que el servidor NO bloquea. El prefijo `admin/` la oculta al ADMIN restringido aunque tenga el privilegio (p. ej. perfil Contador). Es una divergencia menú/servidor en sentido seguro (oculta de más), pero contradice «solo oculta lo que el servidor rechaza».
- Remedio: confirmar con el propietario si el restringido debe declarar el período; si sí, excepción en el menú; si no, bloquear también en el servidor.

### H-4 (Baja) Menú obsoleto ante cambio de la bandera en sesión
- Evidencia: `SesionInfo.RestringirSucursal` solo se arma en el login (Seguridad.cs:149-153; único constructor); el menú lee `Info` sin refrescar. Si el SUPER activa o quita la restricción mientras hay sesión, el menú no cambia hasta el nuevo inicio de sesión. Seguridad no afectada (el servidor consulta la base en cada petición); sí UX (403 con menú completo, o menú recortado de más). Efecto atenuado si el cambio de bandera revoca sesiones (no verificado).
- Remedio: aceptar y documentar, o refrescar `SesionInfo` en el cierre de sesiones que ya hace M-168-2.

### H-5 (Baja) Las pantallas por URL directa muestran el 403 sin explicación
- Aceptado por el PR. Recomendado: que el cliente mapee `RESTRICCION_SUCURSAL_ADMIN` a un mensaje comprensible (hoy no hay ninguna referencia al código en GPOS.Web/MAUI) o redirija. No bloquea.

### H-6 (Informativa) Descripción del PR desactualizada y cobertura de pruebas
- La descripción dice base `b/sesioninfo-restringir-sucursal` (#212 sin unir); `gh` informa base `feature/modelo-ng` y la diferencia contra ella es de solo 3 archivos (el servidor ya está en la base). Corregir la descripción y el orden de unión.
- No hay prueba de: SUPER con la bandera en true (el menú ocultaría; depende del servidor), USER (no ve `admin/` por `EsAdmin`), cambio de `Info` con el componente ya renderizado, ni de las rutas `super/*` para el restringido. Las pruebas leen el HTML por `href` que empieza con «admin/», lo que no detectaría H-1 (ruta fuera de ese prefijo).
- ADMIN vs USER vs SUPER: ADMIN restringido ve solo usuarios/perfiles (probado); ADMIN libre y SUPER conservan todo (probado); USER no ve administración por `Tiene("admin")` (inferido del código, no probado).

## Condiciones para unir
1. Resolver H-1 (ocultar Listas de Precios) con su prueba, o registrar por escrito que se acepta.
2. Corregir la descripción (base real y estado del #212) y confirmar que 955/955 y 673/673 corren sobre la base correcta.
3. Mantener la entrada de estado en «Parcial» hasta que el propietario apruebe la lista de excepciones (H-2) y se decida H-3.
4. H-4 y H-5 pueden ir como pendientes anotados.
