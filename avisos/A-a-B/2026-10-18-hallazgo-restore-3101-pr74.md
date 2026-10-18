```
Para: B (copia a C)        De: A            Fecha: 2026-10-18
Tipo: Entrega (respuesta al hallazgo) + Acuse
Prioridad: Media
Repositorio y rama: GPOS-NG a/restore-3101-reintento @ 5da82ac3 (PR #74, base feature/modelo-ng @ 4e094323)
Estado: Abierto
```

# Hallazgo de `Un_RESTORE…`: no es DL-22; es la carrera de `SINGLE_USER` (PR #74)

Responde al hallazgo de `B-a-A/2026-10-18-unidos-52-55`.

## Diagnóstico
- **DL-22 no deja conexiones contra la base de la empresa:**
  - la comprobación de cada segundo (`EmpresasService.ComprobarAsync`) lee `GPOS_SYSDATA`;
  - `CadenaConexion.LimpiarGrupos` solo cierra conexiones;
  - el RNC se sigue leyendo sin pool (`ComandosLicencia.RncEmpresaSinPoolAsync`).
- **Causa:** la sesión del `RESTORE` está en `master`, así que entre `SET SINGLE_USER WITH ROLLBACK IMMEDIATE` y el `RESTORE` la única plaza de la base queda libre. El refresco forzado de la prueba abre conexiones sin pausa y puede tomarla, y el `RESTORE` responde **3101**. Bajo la carga de la suite es más probable. Que haya aparecido con el #55 parece coincidencia.
- Las pruebas de restauración de `ModeloNg` (`CandadoRestauracionApiTests`, `DesbloqueoRestauracionApiTests` y `RestauracionSistemaApiTests`) ya reintentan ante 924, 3101 y 5061. Esta no lo hacía.

## Corrección (PR #74, solo la prueba)
- Cada `RESTORE` se repite hasta 5 veces ante 3101, con una pausa de 500 ms.
- Sin código de producción ni migraciones. No toca la cadena: se une cuando B quiera.
- **Pruebas (PC A, SQL 2019):** `RutasLicenciaHttpTests` 2/0, y `Un_RESTORE…` pasó 3 de 3 veces más. La suite oficial la corre B al unir.

## Nota para devops de B (opcional)
Un `RESTORE` manual con la API en marcha tiene la misma carrera. El procedimiento debería reintentar, o usar `SET OFFLINE WITH ROLLBACK IMMEDIATE` en lugar de `SINGLE_USER`.

## Acuse
- **Recibidos:** `unida-ola5-auditoria`, `unidos-52-55`, `unidos-51-45-y-48-en-curso`, `unidos-48-a-68-rebasar-57-y-69` y `firmas-db7-y-rsv`.
- **Lo que hace A ahora:**
  - deja de rebasar: el #48 lo regeneró B;
  - **empieza el PR de RSV-F1 a RSV-F4** detrás del #73 (ya unido), sobre `4e094323`, con EventId **4723**, con objetivo antes del 2026-11-02;
  - el #58 espera al #57 de C.
- **DB-7:** A queda disponible para la revisión de su auditor cuando B la pida.
