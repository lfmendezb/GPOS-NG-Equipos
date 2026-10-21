```
Para: A        De: B        Fecha: 2026-10-21
Tipo: Encargo (dos tareas nuevas)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (#127 unido en `a6cb479e`); PR #134 (ADR-93)
Estado: Abierto
```

# Dos tareas nuevas para A

Nada se une sin orden expresa del propietario.

## Tarea 1: S-03, S-04, S-05 y S-07 de su revisión del #127
Son de `src/GPOS.Api/Servicio/ModoServicioApi.cs`, el mismo archivo donde PR-4 retira `FijarEscuchaPorOmision`: por eso las toma A y no mi desarrollador, para no chocar en el archivo.
- **Dónde:** dentro de PR-4 o en un PR justo antes, a su criterio; si es aparte, apílenlo de modo que PR-4 se apile sobre él.
- **S-03:** el modo servicio no puede depender solo de detectar el Administrador de servicios. Argumento `--servicio` desde el MSI (como la estación con `--estacion`) y falla cerrada ante un falso negativo. El instalador de la API aún no existe: el código lleva el argumento y la prueba; el `ServiceInstall/@Arguments` lo agrega el PR del instalador.
- **S-04:** que la falla al leer el token o la falta del origen de eventos deje el evento 4767 (hoy el servicio no arranca, pero sin el evento).
- **S-05:** el filtro `GPOS*` en Información lleva usuario y origen al registro de Aplicación (`ModoServicioApi.cs:81`): redúzcanlo a lo necesario.
- **S-07:** un solo cálculo del SID de la cuenta virtual (`IdentidadProceso` y `CuentaServicioVirtual` hoy lo calculan dos veces).
- **S-06** (unificar el código de salida con el de ADR-90) sigue en su PR-4.
- Pruebas con filtro por clase; la suite oficial la corre B en `LFMB`. **Plazo:** junto con PR-4, antes del 2026-11-02.

## Tarea 2: revisión de seguridad del ADR-93 (#134)
El ADR-93 («Tarjetas de Artículos, foto por artículo y banco de imágenes») está firmado por el propietario (2026-10-21) y registrado en el PR #134 (rama `b/adr93-tarjetas-foto`; `docs/adr/ADR-093.md` y la hoja `docs/decisiones/2026-10-21-hoja-firma-tarjetas-articulos.md`). Que su auditor-seguridad revise, **antes de que se construya la foto individual (pieza E-2)**:
- **TB-03:** las guardas de la carpeta del banco, que ahora configura el ADMIN (no solo el SUPER): lista de carpetas base que solo el SUPER amplía, no solapar la raíz de otra empresa, carpetas del sistema, marca HMAC, rechazo de enlaces y uniones, bitácora de seguridad con motivo.
- **H-1:** el correo al ADMIN cuando cae el banco: que no filtre rutas absolutas, servidores ni secretos.
- **TN-02:** el permiso y el alcance de la foto y de la lista de ambiguos.
- **TA-P08:** que el filtro por almacenes de la sucursal no filtre existencias de otras sucursales.
- Entrega: informe en `traspasos/A/`. **Plazo: 2026-11-07.** Si algo contradice lo firmado, lo marcan como pregunta; no se reabre el ADR por sí solos.

Respuesta requerida: acuse con fechas.
