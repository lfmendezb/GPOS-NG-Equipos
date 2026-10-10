```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega | Hallazgo
Prioridad: Alta
Repositorio y rama: GPOS-NG demo/2026-10-08 (6f07a7f) y feature/modelo-ng (302dab5)
Estado: Abierto
```

# Ensayo de la actualización del DEMO: listo para decisión (DM-01 Alta)

Responde a `B-a-C/2026-10-09-ensayo-demo.md`. Se ensayó todo **sobre copias** `GPOS_TEST_DEMO_*`. **Guía para el propietario:** `traspasos/C/2026-10-09-guia-actualizacion-demo.md`.

## Inventario
- **Instalado:** el paquete «2026-10-07» (`demo/2026-10-07`, `5ad4e78`) en `C:\GSF\PROYECTO ARGON\GPOS-Demo-Socio-2026-10-07`, autocontenido win-x64.
- **Arranque:** a mano, con `Iniciar-Demo.ps1` (API en el puerto 5071 y Web en el 5054); no es un servicio.
- **`GPOS_DEMO`:** 8 migraciones, hasta `Ola3EmisionLigera`.
- **Mecanismo oficial de actualización:** `GPOS.Migracion actualizar` para la base de empresa; `GPOS_SYSDATA` se actualiza al iniciar la API.

## Cifras (esta máquina, sola)
| Paso | `demo/2026-10-08` | `feature/modelo-ng` |
|---|---|---|
| Respaldo `COPY_ONLY` (23 MB + 92 MB) | 0,12 s + 0,42 s | igual |
| Restauración (empresa / sistema) | 0,5 s / 1,1 s | igual |
| `actualizar`, 1.ª pasada | 3,4 s (3 migraciones) | 4,9 s (19 migraciones) |
| 2.ª pasada | 2,8 s, «no aplicó cambios» | 2,9 s |
| Esquema de `GPOS_SYSDATA` | sin cambios | 4 tablas `Dispositivos*` (0,2 s; idempotente) |
| Importar 10 suplidores y 30 clientes (`datos-demo`) | validar 0,4 a 6,9 s (en frío), importar 0,3 a 1,1 s | validar 0,8 a 5,6 s, importar 0,3 a 1,0 s |
| Revertir restaurando el respaldo | 0,5 s por base | igual |

- **Idempotencia: sí.** Comparé una huella completa entre las dos pasadas (definiciones con SHA-256, columnas, índices, propiedades, filas y sumas de control de las 249 tablas) y no hay diferencias. Solo cambia la fecha de 7 objetos heredados (DM-09).
- **Datos conservados: sí.** Las 228 tablas que ya existían quedan intactas, salvo los ajustes que las migraciones hacen a propósito (ClaseFiscal607 de NOTACREDITO, `ClienteContadoId` de CAJA2 y los catálogos nuevos).
- **Pruebas filtradas:** 17/17 con `demo/2026-10-08` y 18/18 con `feature/modelo-ng`.
- **`ImportacionTercerosTiempoTests` queda dentro de los topes,** y el estancamiento del 2026-10-07 no se reproduce.

## Hallazgos
| Id | Sev. | Hallazgo | Para |
|---|---|---|---|
| **DM-01** | **Alta** | **Revertir restaurando el respaldo deja la base sin poder emitir**: el disparador lanza el error 51330 porque cambió el `recovery_fork_guid` (MD-59). No hay comando, servicio ni pantalla para desbloquearla (H-11 de ADR-53, decidido, no construido) y `actualizar` no vuelve a registrar el fork. Evidencia: `SqlMigracionesOla3EmisionLigera.cs:49-55`, `Aprovisionamiento.cs:118-120,208-233` y `GPOS.Migracion/Program.cs:51-63`. **Ninguna actualización a un cliente real hasta resolverlo** | A (arquitecto-datos y backend) |
| DM-02 | Media | `verificar` devuelve 0 aunque la base esté RESTAURADA, y `Iniciar-Demo` dice «al día» (`Program.cs:63-71`) | A |
| DM-03 | Baja | Aviso falso de «intercalación vacía» cuando la base tiene AUTO_CLOSE y estaba cerrada (`Aprovisionamiento.cs:108-112`) | A |
| DM-04 | Media | `GPOS_DEMO` y `GPOS_SYSDATA` tienen AUTO_CLOSE activo y el aprovisionamiento no lo apaga: arranques en frío de 4 a 6 s. Candidato a ADR: AUTO_CLOSE OFF obligatorio | arquitecto-datos |
| DM-05 | Media | No existe un paquete del DEMO del 2026-10-08 ni scripts de actualización y reversión en el repositorio; los de la ronda 1 solo están en un .7z de OneDrive | B / devops |
| DM-06 | Media | `feature/modelo-ng` no tiene `eb7bd62`, `f7646be` ni `87b90f8` (ronda 2), que el DEMO instalado ya tiene: actualizar a `feature/modelo-ng` quitaría 3 mejoras visibles | B: unir el PR #6 |
| DM-07 | Baja | El DEMO nunca tuvo un respaldo propio (`msdb`) | propietario |
| DM-08 | Baja | Aplicar a mano el SQL de `EsquemaSistema` con `sqlcmd` sin `-I` falla en un índice filtrado (1934) y deja la base a medias. Por la API no pasa | técnicos y arquitecto |
| DM-09 | Info | Cada `actualizar` vuelve a crear 7 objetos heredados con la misma definición; se ejecuta con la API detenida | — |

**Otros riesgos:**
- El **disco C: está al 98 %** (6,5 GB libres; bajaron a 2,9 GB durante el ensayo).
- Los programas viejos no aceptan un esquema más nuevo, así que base y programas se revierten juntos.

## Recomendación de C
- **Actualizar el DEMO ahora a `demo/2026-10-08`:** solo 3 migraciones, no toca el esquema de `GPOS_SYSDATA` y conserva la ronda 2.
  - Falta el paquete publicado (DM-05).
  - Si hubiera que revertir, la salida es reinstalar el paquete del 2026-10-07 (por DM-01).
- **Pasar a `feature/modelo-ng`** cuando el #6 esté unido y se corte una rama `demo/` nueva, con el mismo procedimiento.
- **Memoria de SQL Server (propuesta, no aplicada):**

  | Equipo | Mínimo / máximo |
  |---|---|
  | Este equipo y un cliente con 8 GB | 512 / 2.048 MB |
  | Cliente con 4 GB | 256 / 1.024 MB |

  - El búfer de Express no pasa de unos 1.410 MB, así que el máximo actual de 3.072 MB no sirve, y el mínimo actual retiene 1 GB.
  - `.\BARTENDER` no tiene tope: 512 MB si se usa.

## Bases reales intactas y limpieza
- **Bases reales sin modificar:** `GPOS_DEMO` y `GPOS_SYSDATA` tienen el mismo historial de migraciones, la misma fecha de última modificación de esquema, el mismo fork, las mismas opciones y los mismos conteos antes y después.
- **Nada de la aplicación corrió contra las copias:** no se ejecutó la API ni la Web.
- **Limpieza:** se borraron las bases `GPOS_TEST_DEMO_*`, los `.bak` y los worktrees temporales; no queda ningún proceso dotnet. Las bases ajenas no se tocaron.

**C completó todas las tareas asignadas por B** (PR #9, #7 y #6, y el ensayo del DEMO). Queda disponible para el siguiente encargo.
