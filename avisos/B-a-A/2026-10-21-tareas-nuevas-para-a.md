```
Para: A        De: B        Fecha: 2026-10-21
Tipo: Encargo (tareas nuevas; propuesta)
Prioridad: Media
Repositorio y rama: GPOS-NG `master` y `feature/modelo-ng` (según la tarea)
Estado: Abierto
```

# Tareas nuevas para A

Lo anterior sigue vigente y va primero: PR-4 de ADR-90 y los arreglos del #124 antes del 2026-11-02. Estas tareas son **después** de eso, o en paralelo solo si la capacidad de la PC A (8 GB, 2 compilaciones a la vez) lo permite. **Nada se une sin orden expresa del propietario.** Las fechas son propuestas de B; díganme si no caben.

## Tarea 1: PR del instalador con `--servicio` y firma de la `.CA.dll`
- **Qué:**
  - `ServiceInstall/@Arguments="--servicio"` (R-01 de la revisión de #136), con la comprobación del origen `GPOS.Api` y del camino de reserva en L-1/L-2.
  - Firma de la `.CA.dll` en `construir.ps1` (S-04 del #124); al hacerlo, quitar el `Skip` de la prueba estricta.
  - Pruebas P-O1-7 con FIPS.
- **Por qué es de A:** conocen el instalador (#124) y el modo servicio (#136). R-01 es condición antes de instalar fuera del laboratorio.
- **Depende de:** la unión del #124 y del #136.
- **Fecha propuesta:** 2026-11-13.

## Tarea 2: revisión de seguridad de la Ola 5, tramo 4 (T4-01, T4-02, T4-04)
- **Qué:** revisar cada PR cuando B lo abra (el plan prevé T4-01 hacia el 27-oct, T4-04 hacia el 2-nov y T4-02 después del 16-nov). Informe en `traspasos/A/`, como los anteriores.
- **Foco:** el render fuera de la principal, el token de servicio de 5 minutos para los programados (Q-T4-04, firmada) y la red saliente bloqueada.
- **Fuente:** `docs/arquitectura/2026-10-19-ola5-tramo4-plan-de-trabajo.md`.
- **Fecha:** 5 días hábiles desde que B avise de cada PR.

## Tarea 3: revisión de seguridad de D1 de DB-7 (T1-1 a T1-4)
- **Qué:** esquema v6 de `GPOS_SYSDATA`, núcleo de acceso, membresías y verbo `accesos --convertir`.
- **Fuente:** `docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md` y `docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md`.
- **Fecha propuesta:** el diseño antes del 2026-11-02 (solo lectura); los PR, cuando B los abra (T1-1 el 11-02 al 11-03).
- **Por qué:** DB-7 es condición de publicación del primer cliente.

## Tarea 4 (opcional, recortable): T4-03, Chromium aislado
- **Qué:** Chromium bajo `NT SERVICE\GPOS.Reportes`, con la comprobación del sandbox y el perfil sin permisos sobrantes (R-T4-07).
- **Por qué es de A:** es lo más cercano a lo que ya hacen con ADR-90 y ADR-77.
- **Aviso:** el plan la marca recortable, así que va al final. Si la toman, avisen para no duplicar con B.
- **Fecha propuesta:** semana del 2026-11-23.

## Pendiente de A ya pedido (no es nuevo)
La lista de rutas de inventario que no filtran por sucursal (S-16 de su revisión del ADR-93), con la que B decide el reparto del trabajo entre E-1 y un cambio aparte.

Respuesta requerida: acuse con fechas, indicando cuáles aceptan.
