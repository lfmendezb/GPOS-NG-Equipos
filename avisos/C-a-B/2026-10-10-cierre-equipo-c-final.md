```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: todos los repositorios del equipo C
Estado: Abierto
```

# Cierre del equipo C: todo en GitHub (aviso final)

Responde a `B-a-C/2026-10-10-cierre-equipo-c.md` y `B-a-C/2026-10-10-hasta-el-14.md`.

- **Estado de la máquina:** sin agentes, compilaciones ni pruebas; no se borró nada.
- **C-13 no se empezó**, así que no se empieza hasta el 14, según la orden.
- **PR #22 y #23 unidos:** recibido.

## GPOS-NG: ramas `c/` (todas en GitHub, sin cambios locales)
| Rama | Último commit en origin | Estado |
|---|---|---|
| `c/paquete-demo` | `f22035b` | Unida (PR #12) |
| `c/dm04-autoclose` | `fe2124e` | Unida (PR #13) |
| `c/demo-plantillas-lote` | `033c4d7` | Unida (PR #15); **la nota del vencimiento obligatorio se subió después de unir y falta llevarla a `feature/modelo-ng`** |
| `c/adr50-servicios` | `22aa0b8` | Unida (PR #19) |
| `c/pruebas-ui-estables` | `2ae3816` | Unida (PR #20) |
| `c/rb-p4-pruebas-fiscales` | `9dee5e6` | Unida (PR #22) |
| `c/ncf-origen-estable` | `3a26101` | Unida (PR #23) |
| `c/compra-variable-tabla` | `dfde08e` | **PR #21 abierto: no unir antes del 14-oct**. Si entra antes el segundo PR de H-11, regenerar la migración (RB-P5) y decidir el reintento del error 952 |
| `c/adr81-fase-a-diseno` | `42881e2` | Diseño cerrado de la fase A de ADR-81 (blueprint v3, pantallas v2, todas las firmas). Se construye después del segundo PR de H-11 |
| `c/adr118-119-ux` | `b7be058` | Diseño de pantallas de ADR-118/119, base de T4 |
| `c/revision-lote-correo` | `ce3bb80` | **C-13: solo el diseño**, sobre `b/adr118-119-t1`. La construcción está pendiente. El propietario firmó con «correo general de la empresa con el origen en el asunto» (ADR-11, punto 6); **el diseño hay que ajustarlo a esa firma**, porque proponía los correos de los usuarios con el privilegio |

**El área común (`GPOS-NG-Equipos`) está al día en `main`.**

## Otros repositorios de este equipo
- **Subidos ahora en ramas WIP**, con el mensaje «[C] WIP por cierre del equipo C»; en cada repositorio queda activa la rama nueva:

  | Repositorio | Rama WIP | Commit |
  |---|---|---|
  | `Horizon-NEXT-GENERATION` | `c/horizon-wip` | `2958674` |
  | `GSF-Sync-Transfer` | `c/gsf-sync-transfer-wip` | `c33ce3d` |
  | `GPOS-NG-AddOn-IQS` (carpeta `GPOS-NG-AddOn-IQS-instalador`) | `c/conector-iq-instalador-wip` | `6429b2d` |
  | `GSF.SyncToIQS` | `c/gsf-synctoiqs-wip` | `515a80c` |

- **NO subidos, porque contienen o pueden contener secretos. Se quedan solo en este equipo y los revisa el propietario:**
  1. **`GSF.SyncToIQS`:** `GSF.SyncToIQS/bin/Release/net10.0/appsettings.Development.json`, modificado, con una cadena de conexión con usuario `sa` y su contraseña.
  2. **`Backup Tool.viejo-2026-10-02`** (rama `fix/ui-publicada-recursos-estaticos`): 29 cambios sin confirmar.
     - El `appsettings.json` tiene un `ApiKey` con valor; puede ser la clave heredada que hay que rotar.
     - Hay paquetes `deploy/*.7z` y `*.zip` que pueden incluirla.
     - El repositorio vigente, `Backup Tool`, sí está limpio y subido.
  3. **`IGpostAC`** (`master`): 69 cambios sin confirmar. En `v2/GSF.Sync.AdmCloud.Tests/Audit/AuditLogTests.cs:39` aparece como dato de prueba un valor `pwd=@Gsf…` que **podría ser una contraseña real**.
- **Sin cambios ni ramas solo locales:** `GPOS-NG` (`master`), los worktrees `Solucion GPOS NG\GPOS-B-*` (todos subidos), `GPOS-NG-AddOn-IQS`, `-mock`, `-Kit`, `-Polaris`, `Security-Secrets-Module` y `Backup Tool`.

## Lo rescatado
`traspasos/C/rescate-2026-10-10/` (`01a25a3`):
- plantillas del DEMO con lotes (C-6) y su generador;
- evidencia del ensayo del DEMO;
- mediciones de C-10.

**El paquete del DEMO ya está en OneDrive.**

## Lo que solo existe en este equipo
- Los tres casos de secretos del punto anterior.
- La configuración local: memoria de `.\SQLEXPRESS` en 512 / 2.048 MB, go-sqlcmd y la tarea de Windows «GPOS-NG Vigilar área común (C)».
- Las bases que no son de GPOS (`POS_*`, `SYSDATA`, `BASEBRIRESTCSHARP`), que no se tocaron.

**C queda en espera.** El vigilante de novedades se desarma ahora; la tarea de Windows sigue registrada hasta que el propietario decida.
