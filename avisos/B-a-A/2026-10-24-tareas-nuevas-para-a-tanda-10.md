Para: A (copia para C)        De: B        Fecha: 2026-10-24
Tipo: Encargo (tanda 10; el propietario pidió asignar el mayor número de tareas posible para pasar a las pruebas con las VM)
Prioridad: Alta
Estado: Abierto

# Tareas nuevas para A (tanda 10), además de las tandas 7 a 9
Leí tu acuse (`2026-10-23-acuse-tanda-8-y-respuestas-msi-d4-d5.md`) y las fechas que propones: valen. D-5 ya está firmada como (c) (ver `2026-10-23-d5-firmada-opcion-c.md`), así que tu propuesta de cambiar el dueño tras crear la base queda descartada. Mismas reglas: PR con la plantilla, nada se une sin orden del propietario, evidencia ejecutada, máximo 3 compilaciones a la vez.

## Lo que desbloquea las VM (primero)
1. **Paquetes del laboratorio de `restaurar` (#223):** publica desde `a/pr-d2-manifiesto` (tu sha final tras R-04, R-09, P-D2-04, D-4 y O-1 a O-3) con `Publicar-PaqueteDemo.ps1 -Destino Demo -ConApiReportes` (Release) **dos paquetes, PQ-A y PQ-B**, con el SHA-256 del `.7z` y de `manifiesto.sha256`, y avísame la ruta. Fecha: **28-oct**. Sin esto no corro RS-01 a RS-12.
2. **SF-03 de C (F1):** `sistema --login-api` antes de `--anclar` falla con `AnilloSinAncla` en una instalación nueva. El orden firmado de las fases no cambia (el `--anclar` va dentro de `esquema`), pero el orden **interno** de `FaseEsquema` debe ser: `sistema --login-api` → `anillo --anclar` → `sistema --cuentas-iniciales --confirmar-sellado`. Ajústalo en tu diseño del paso de empresa y cuentas y avísame si el blueprint 3.3 hay que corregirlo.
3. **#225 (T4-06), rebase y arreglos de C (Aprobado con observaciones):** H225-02 (rebasar sobre `feature/modelo-ng` @ `1b310591`; conflicto en `NotificacionesReportesTests.cs`), H225-01 (la expresión regular de `AuditoriaAdr109Tests.cs:40` tiene 0x08 donde dice `\b`) y H225-03 (afirmar el autor en la evidencia del programado). Avisa el sha a C para repetir sus pruebas. Fecha: **29-oct**. Valora H225-04 (5xx a 503, JSON inválido a 400), H225-05 y H225-06. Con esto M-2 del #217 queda cerrado al unir.

## Seguridad y decisiones
4. **C-T01 (Media; Alta si la frontera de sucursal cubre toda lectura de ventas):** los enlaces del tablero llevan a `ConsultaFacturasService`, que no aplica la restricción de sucursal (lista, detalle por número, búsqueda y exportación). C recomienda (a) aplicar el alcance ya, ~0,5 dp. **Lo decide el propietario** y se lo llevo yo. Prepara mientras tanto el diseño: dónde entra el alcance, la columna de sucursal en `ng.Documentos` (C no la confirmó), falla cerrada, y los casos de CT01. No implementes hasta mi aviso.
5. **C-T04 y T4-08:** pon en la hoja D-03 la precisión «todas las rutas de datos» (las 4 rutas `/interno/render/*` no pasan por el contexto, y no es fuga) y que T4-08 herede el escenario de CT01 como prueba de partición.
6. **Revisión de seguridad de F1 (#228):** C la dejó en «Rechazado mientras SF-01 (Alta) siga abierta». Yo corrijo SF-01 a SF-04 y SF-06 en F1 (~0,3 dp, hoy y mañana). Tu revisión se hace sobre el sha corregido (te lo aviso); no empieces antes. Cuando la hagas, mira además SF-05 (instalaciones que ya usaban el anillo por llaves sueltas, 0 hoy) y SA-12 y SA-14.

## Documentación
7. **Procedimiento del `GPOS.Api.msi` (tanda 8, punto 5):** adelanta el esqueleto con lo ya firmado (restart, restart, none; `Start="auto"`; la actualización conserva `Environment` y DACL); los valores definitivos esperan al sha final de `b/t1b-api-msi`, que te doy en cuanto cierre la primera ventana de laboratorio.
8. **Guía del técnico del paso de empresa (D-5):** qué pide el instalador (ser sysadmin de la instancia), qué mensaje ve si no lo es, qué deja hecho `aprovisionar` y cómo comprobarlo con `verificar`. Una página, en `docs/operaciones/`.

Orden sugerido: 1, 3, 2, 4, 5, 6 (cuando te avise), 7, 8. Respuesta requerida: acuse con fecha por punto; el sha de los paquetes (punto 1) en cuanto exista.
