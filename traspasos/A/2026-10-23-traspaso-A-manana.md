# Nota de traspaso del equipo A (cambio de sesión, 2026-10-23, mañana)

Para la sesión nueva de la PC A (`DEVLAB00`, mini PC de 8 GB y 4 hilos: máximo 2 compilaciones a la vez), pegue: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-23-traspaso-A-manana.md` y retoma desde ahí». Sustituye a `2026-10-22-traspaso-A-noche-2.md`.

## 0. Antes de nada
- `git pull` del área común (`GPOS-NG-Equipos`) y leer los avisos `B-a-A` posteriores a este traspaso (el último que leí es `2026-10-23-170-p170-01-corregido-y-puntos-del-emisor.md`, 05:48). Armar `Monitor` sobre `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-A.md` (vence a los 30 min y **se pierde al cerrar la sesión**).
- **No hay agentes activos.** Uno quedó detenido al cerrarse la sesión: la **tercera revisión de seguridad de PR-V** (3 commits `79bf8905..82bf648d`: origen `GPOS.Instalacion`, verbo `red`, R4/P4). Comprobar si existe `traspasos/A/revision-seguridad-pr-v-red-origen-82bf648d-2026-10-23.md`; si no, relanzarla (auditor-seguridad, solo lectura, sobre `GPOS-NG-prv`).
- **Nada se une sin orden del propietario.** Las uniones las hace B. Empujar ramas `a/` sí está autorizado; abrir PR nuevo, no sin orden.
- Trampas: un mensaje de commit que empieza con `A:` lo bloquea el filtro; en `Edit`, hay que `Read` el archivo antes; los heredocs de Bash con Python y comillas fallan: escribir el texto con `Write` en el scratchpad y copiarlo; compilar siempre con `-m:1 -nr:false`; borrar `testhost.exe` tras cada prueba; **no ejecutar `dotnet build-server shutdown`** (lo hizo un agente y detiene compiladores de otros); un agente por árbol de trabajo (no dos editores en el mismo).

## 1. Hecho el 22 y 23-oct (después del traspaso anterior)
- **Revisiones publicadas** (todas con aviso en `avisos/A-a-B/`): #168 con `AdminSinRestriccion` y #178 rev. 5 (aprobar con observaciones / aprobar); #170 rango `f534e7f0..4d676907` (O170-01 a O170-06) y `4d676907..403da3ca` (P170-01 a P170-07); PR-V dos veces (SPV-01 a SPV-17 y SPW-01 a SPW-06). P170-01 ya lo corrigió B (`89fce5b5`), conforme.
- **EventId 5120:** choque #168/#170; B renumeró `RenderHuerfano` a 5157.
- **R20:** `auth_time` ya llega por la introspección; diseño del sello actualizado (unas 0,1 dp mías, sin construir).
- **Emisor T4-04:** B confirmó `TokenServicioDenegadoException` con `autor-super`; `.PermiteTokenProgramado(...)` lo declara mi PR del emisor (ya escrito en `a/t4-04-emisor`).
- **Uniones de B con orden del propietario:** #169, #175, #168 a `feature/modelo-ng`; #178 a `master`; antes #174, #182 a #185.
- **PR-V construido** (verbos `implantar-servidor`, `comprobar-servidor`, `red --modo un-equipo`), con las 4 decisiones de huecos del contrato (acta/motivo solo si falta el ancla; esquema no crea empresas; llave pública en `config\llave-sitio.pub` con huella comprobada; `--confirmar` eliminado) y las correcciones de seguridad de los Medios y casi todos los Bajos.

## 2. Ramas y árboles de trabajo de A (todas empujadas; **ninguna unida; sin PR salvo las marcadas**)
| Rama | Árbol | Qué es | Notas |
|---|---|---|---|
| `a/pr-v-verbos-servidor` | `GPOS-NG-prv` | PR-V, punta `82bf648d` sobre `feature/modelo-ng` `67b4353a` | 800/800 pruebas (filtro: `(FullyQualifiedName~GPOS.Tests.Servidor\|FullyQualifiedName~GPOS.Tests.Arquitectura\|FullyQualifiedName~EventIdUnicos)&Transicion!=Ola5&Transicion!=Defecto`). Sin PR. Falta: tercera revisión de seguridad; SPW-02 y SPW-03; ensayo en la VM |
| `a/pr-d2-manifiesto` | `GPOS-NG-prd2` | PR-D2, primer paso: `Publicar-PaqueteDemo.ps1` genera `manifiesto.sha256` (`8a689560`, sobre PR-V) | El script **nunca se ejecutó**; se publica con `-ConApiReportes`. Solo `app\api` y `app\reportes` |
| `a/t4-04-emisor` | `GPOS-NG-t404` | Emisor del token T4-04 (`1927608d`) | Sin PR: abrir sobre `feature/modelo-ng` al ordenarlo el propietario |
| `a/usuarios-razor-restriccion` | `GPOS-NG-usr` | Tarea 7: `Usuarios.razor` Web y MAUI (`463ba06e`), al día con el #168 unido y la hoja del #188 | Web compila; MAUI no la compilé. Falta ocultar opciones denegadas y la etiqueta en español de `ACCESO_RECHAZADO_SUCURSAL` |
| `a/limpieza-clearallpools` | `GPOS-NG-pools` | `ClearAllPools` fuera (`994cfda2`) | Queda 1, con su motivo (`Rg14Lote2Tests.cs:1300`); suite completa en LFMB (B) |
| `a/t1c-lab-instalador`, `a/t1a-firma-instalador`, `a/spike-amplio-demo`, `a/p124-temp-ace`, otras | `GPOS-NG-t1c`, `-tmp`, etc. | Sin cambios | #164 (T1-a), #165 (T1-c), #173 (spike Amplio, **sin revisar**), #103 |
Árbol `GPOS-NG-r170`: copia de solo lectura del #170 (detached); se puede retirar. Retirados: `-pr2`, `-pr4`, `-t1a`.

## 3. Pendiente y fechas
| Cuándo | Qué |
|---|---|
| Ahora | Tercera revisión de seguridad de PR-V (3 commits); leer los PR #190 y #191 (lista de cierre G-O5-T4 y hoja T4-02), #192 a #194 (estado y T4-10): ninguno pide trabajo a A hasta donde leí |
| 28-oct | B responde lo del emisor (ya respondió); P170-02 a P170-06 y el tope de 8 Mi de B |
| 3-nov | **T4-06** (lista P-2 vacía; no recortable; unión antes del 11-nov); blueprint con sección 17; espera P-4 y la segunda pregunta de Q-A4 de B |
| 9-nov en adelante | Borrador de PR-D2: falta `--rotar-jwt` en `Instalar-Demo`, extraer el paquete en una carpeta protegida **fuera de OneDrive** y detener los servicios antes de `--fase servicios`, LEEME, rechazo textual de `Jwt__Clave` en el paquete de cliente |
| 13-nov | T1-a y T1-c cerrados |
| 18-nov (am) | VM `VM-SRV`: bloque instalador (opera B); 23-nov (am): spike del modo Amplio. Lo que solo la VM confirma está en la §7 de los informes de PR-V |
| Antes de D4 | PR-V y PR-D2 unidos; SPW-02/03 |

## 4. Números y decisiones vigentes
- **EventId:** 5120 `AccesoRechazadoSucursal` (#168); 5134-5138 PR-V (origen `GPOS.Instalacion`); 5139 `ServidorConfiguracionRed`; 5150-5155 T4-10 (5152 `SelloRazorRechazado`, 5155 recorte informativo); 5156 y 5157 #170; 4791-4793 emisor; 4794-4795 D1; 5117-5119 #170; 5121-5129 #175/T4-04.
- **Decisiones del propietario:** `AdminSinRestriccion` con lista de excepciones; el ADMIN sin restricción también fija/quita la restricción por sucursal (hoja #188, construida en el #168); sello Razor para todo el sitio (R17); P-1 sin token programado para el SUPER; Q-5 SDDL; Q-6 VM operada por B; fechas de la VM propuestas por B (18 y 23-nov, **aún sin confirmar** por el propietario).
- Los agentes que escalan a Opus firman `Co-Authored-By: Claude Opus 5.5`; el resto, Sonnet 5.5.

## 5. Decisiones que esperan
- **Propietario (vía B):**
  - **SPV-03:** el manifiesto del paquete se lee sin autenticar; aceptarlo como residual del DEMO o firmarlo (antes de D4).
  - **Certificados del anillo (DM-07):** propuesta mía sin responder: el servidor genera el suyo (autofirmado, no exportable, ACL de DM-07) y recibe solo el `.cer` público de recuperación por `--recuperacion`; la privada de recuperación la guarda el propietario. Sin `.cer`, `esquema` no ancla.
  - **Abrir PR** de `a/pr-v-verbos-servidor`, `a/pr-d2-manifiesto`, `a/t4-04-emisor`, `a/usuarios-razor-restriccion`, `a/limpieza-clearallpools`, y el orden de unión.
  - Q-3, Q-4, Q-7 del instalador, S-03, R18; la unión del #170 y los P170 abiertos.
- **B:** el verbo `tls` y si el DEMO adopta HTTPS con `ModoRed=UnEquipo` (hoy `lectura` no llama a `red` porque con `ModoRed` la API exige el certificado de `HuellaApi`, 4747, y la Web y los guiones usan `http://localhost:5071`; `lectura` termina con 1 a propósito); el verbo `red` completo (`servidor-sitio`); P170-02 a P170-06; sintaxis de `red` si ADR-90 lo exige.
