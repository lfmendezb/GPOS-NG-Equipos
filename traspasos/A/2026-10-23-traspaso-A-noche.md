# Nota de traspaso del equipo A (2026-10-23, noche)

Para la sesión nueva de la PC A (`DEVLAB00`, máximo 2 compilaciones a la vez), pegue: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-23-traspaso-A-noche.md` y retoma desde ahí». Sustituye a `2026-10-23-traspaso-A-tarde.md` (sus secciones 0, 2, 4 y 5 siguen vigentes salvo lo que esta nota cambia).

## 1. Hecho después del traspaso de la tarde
- **#170 revisado** (rango `89fce5b5..03bbceea`): aprobar con condiciones, sin Críticos, Altos ni Medios. Informe `revision-seguridad-pr170-rango-03bbceea-2026-10-23.md`. Observaciones Bajas: R170-01 (el caso «iframe sandbox» de `Un_documento_data_anidado_corta_el_render` falla a veces) y R170-02 (`InternalsVisibleTo GPOS.Reportes.Api`). Aviso a B enviado.
- **#173** (`a/spike-amplio-demo`, `f37af1df`, empujado): P-01 (entorno del anillo con `DpapiDemo`), P-02 (carpeta `Api\anillo` protegida), P-05 (DE-11/12/13/15 quedan «No se pudo», salida 3), P-06 (`-EscaleraConDbcreator` en DE-14), P-07 solo el texto de DE-13. Los textos de G-PR4, T1-09, §8 de operaciones, §7 de la guía y el 4744 de L-3 no están en esta rama (avisado). Árbol: `GPOS-NG-spike`. `SpikeAmplioDemoTests` 7/7.
- **PR-D2** (`a/pr-d2-manifiesto`, `8a5e8ae5`, empujado, sin PR): rebasado sobre PR-V (`a3c71ce1`) con `push --force-with-lease` autorizado; `Instalar-Demo` llama a `--fase esquema` (con `-ActaAncla` y `-MotivoAncla`) y `--fase lectura` (tolera solo «Fase incompleta … falta red»). 691/692.
- **Tarea 7:** MAUI **compila** (`net10.0-windows10.0.19041.0`, 0 errores) en `a/usuarios-razor-restriccion`. No hay prueba de MAUI para Usuarios.
- Árbol `GPOS-NG-r170` retirado.

## 2. Esperando
- **B** (aviso `avisos/A-a-B/2026-10-23-pr-d2-empresa-y-cuentas-bloqueo.md`): elegir (a) anillo del servicio primero o (b) `DpapiDemo` provisional para el ensayo de la VM, y de quién es la pieza del anillo. **Sin eso no se escribe el paso de empresa y cuentas iniciales de PR-D2** (el anillo del servicio no tiene configuración y nadie registra la empresa). Faltan además el primer arranque como servicio, `comprobar-servidor` y un `Revertir` real.
- **B:** `tls` (antes del 18-nov); `SesionInfo.RestringirSucursal` (cuando avise, el menú de `NavMenu.razor` en ambas copias, ~0,15 dp); respuesta a R170-01/02 y a P-05 a P-07 (no requiere).
- Decisiones del propietario ya tomadas (aviso de B de las 10:55): DM-07 aceptado, SPV-03 (a) residual del DEMO con carpeta solo de administradores (ya la exige `Instalar-Demo`) y firma del manifiesto antes de D4, S170-03/04, R18.

## 3. Fechas
| Cuándo | Qué |
|---|---|
| 13-nov | #173 listo para que C cierre sus casos (P-01/02 y P-05 a P-07 ya hechos) |
| Antes del 18-nov | `tls` (B); bloque instalador; `Preparar-Vm.ps1` (C) |
| 3-nov | T4-06 (blueprint con sección 17; no empezar sin P-1 a P-3, P-4 y Q-A4 de B) |
| 16 a 27-nov | Ensayos de PR-D2 en la VM (opera B) |

## 4. Ramas
Igual que la tabla de la nota de la tarde, con estas puntas: `a/spike-amplio-demo` `f37af1df` (#173), `a/pr-d2-manifiesto` `8a5e8ae5`. `a/pr-v-verbos-servidor` sigue en `a3c71ce1`. Nada unido ni con PR sin orden del propietario.

## 5. Trampas nuevas
- Los archivos `.ps1` y `.cs` del árbol de trabajo traen CRLF (`core.autocrlf`): las pruebas que buscan `\n` fallan; normalizar con `Replace("\r\n", "\n")`. `grep -c $'\r'` en Git Bash no lo detecta bien; usar PowerShell.
- En PowerShell `$pid` es la variable automática de solo lectura (`$PID`): no asignarla.
- `sed -i` sobre un archivo que luego se edita con `Edit` obliga a `Read` otra vez.
