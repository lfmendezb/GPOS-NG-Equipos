# Nota de traspaso del equipo A (cambio de sesión, 2026-10-22, segunda de la noche)

Para la sesión nueva de la PC A (`DEVLAB00`, mini PC de 8 GB y 4 hilos: máximo 2 compilaciones a la vez), pegue: «Somos el equipo A. Lee `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\2026-10-22-traspaso-A-noche-2.md` y retoma desde ahí». Sustituye a `2026-10-22-traspaso-A-noche.md`.

## 0. Antes de nada
- `git pull` del área común (`GPOS-NG-Equipos`) y leer los avisos `B-a-A` posteriores a este traspaso; armar `Monitor` sobre `%LOCALAPPDATA%\GPOS-NG-Equipos\novedades-A.md` (vence a los 30 min).
- **Las dos auditorías del cierre ya terminaron y están publicadas con su aviso:** cierre del #178 revisión 4 (`revision-cierre-pr178-t4-10-rev4-2026-10-22.md`: Aprobar con condiciones; S178-R4-01 y S178-R4-02) y #170 (`revision-seguridad-pr170-t4-03a-2026-10-22.md`: Aprobar con condiciones; S170-01 y S170-02 antes de unir). Falta solo que B responda.
- **Nada se une sin orden del propietario.** Las uniones las hace B. Empujar ramas `a/` sí está autorizado; abrir PR nuevo, no sin orden.
- Trampas de la herramienta: un mensaje de commit que empieza con `A:` lo bloquea el filtro (escribirlo sin los dos puntos); en Python dentro de Bash, `\\` llega como `\` (usar `chr(92)`); en `Edit`, hay que `Read` el archivo antes; `( … ) &` en Bash termina de inmediato (usar `run_in_background` y un `until grep` sobre el log).

## 1. Hecho el 22-oct (después del traspaso anterior)
- Relecturas y dictámenes publicados en `traspasos/A/` (todos con aviso en `avisos/A-a-B/`): #176 (R3-01 a R3-03; R3-03 corregida), #175 (O175-01 a O175-05, ya incorporadas por B en `c6131c75`), #179 (R179-01 a R179-04), #174 (JWT-01), #168 (S168-01 a S168-08; el propietario decidió S168-02 «frontera real» y S168-05 «empresa y sucursal»), #178 (S178-01 a S178-12; B respondió con la revisión 4).
- Diseños y blueprints sin compilar: sello HMAC de DD-11′ (`diseno-sello-hmac-dd11-api-reportes-2026-10-22.md`), PR-V (`blueprint-pr-v-verbos-servidor-2026-10-22.md`), adenda R-14/Q-A4 en `blueprint-t4-06-lista-p2-2026-10-22.md` (sección 17), contrato del servicio de la API actualizado con el **SDDL de Q-5** (`contrato-servicio-msi-api-2026-10-22.md`).
- Acuses: encargos de B (con fechas), Q-1/Q-2/Q-5/Q-6/Q-8 del instalador, EventId.

## 2. Ramas y PR de A (todas empujadas; **ninguna unida**)
| Rama | PR | Qué es | Notas |
|---|---|---|---|
| `a/t4-04-emisor` | sin PR | Emisor del token de servicio T4-04 (commits `771357a8`, `1927608d`), apilado sobre `a/t4-04-contrato-token` | 48 pruebas del token y 24 de la API de reportes pasan en mi PC. Orden de unión: #169, emisor, #175. **Falta de B:** confirmar el tipo de error del SUPER (`TokenServicioDenegadoException` `autor-super`) y la línea `.PermiteTokenProgramado(...)` en `EndpointsReportes.cs`. EventId 4791-4793 ya cedidos |
| `a/api-jwt-entorno` | #174 | K3-DEMO cerrojo 2 y DM-04, con JWT-01 (`Jwt:Clave`) | Unir antes del 2-nov (DB-7) |
| `a/t1c-lab-instalador` | #165 | T1-c, con el caso L-2f (SDDL, Q-5) | Guion sin ejecutar (VM) |
| `a/limpieza-clearallpools` | sin PR | 29 `ClearAllPools()` quitadas, sobre #153 (`c/pruebas-inestables-4`) | Clases tocadas 189/189 y 61/61; suite completa en LFMB (B). Quedan 13 que piden criterio |
| `a/usuarios-razor-restriccion` | sin PR | Tarea 7: `Usuarios.razor` (Web y MAUI idénticos), sobre la punta `30ad5c4e` del #168 | Rebasar si B cambia rutas (S168-01/02). Entrega pedida: 2-nov |
| `a/p124-temp-ace` | sin PR | B-7: pruebas del #124 se omiten si el Temp trae una ACE ajena | B debe correr `ComprobacionCarpetasPreviasTests` en LFMB |
| (sin cambios) | #103 + emisor #1 (DV-07), #164 (T1-a), #169 (contrato), #171 **unido**, #173 (spike Amplio) | Ver el traspaso anterior | |

Árboles de trabajo nuevos: `GPOS-NG-t404` (emisor), `GPOS-NG-pools`, `GPOS-NG-usr`, `GPOS-NG-t1c`, `GPOS-NG-tmp`; `GPOS-NG-t1a` (rama `a/api-jwt-entorno`). `-pr2` y `-pr4` pueden retirarse (ramas unidas); comprobar antes que no tengan cambios sin subir.

## 3. Pendiente y fechas
| Cuándo | Qué |
|---|---|
| Hecho | Informes de cierre del #178 y del #170 publicados |
| 28-oct | B responde los puntos del emisor (tipo de error SUPER, línea en `EndpointsReportes.cs`) |
| 29-oct | Revisión del #168, #170 y cierre del #178: entregadas; esperar las correcciones de B (S170-01, S170-02, S178-R4-01, R4-02) y revisar el rango |
| 2-nov | `Usuarios.razor` (hecho, falta PR/rebase), `ClearAllPools` (hecho, falta PR), #174 unido (B) |
| Antes del 3-nov | Blueprint de PR-V (hecho), R-14/Q-A4 (hecho); **abrir el PR del emisor** al confirmar B |
| 3-nov en adelante | **T4-06** (blueprint con sección 17); espera P-4 (`CompilacionDepuracion`) y la segunda pregunta de Q-A4 (Debug sin reenvío) de B |
| 13-nov | T1-a y T1-c (abiertos); T1-b lo construye B |
| Antes de D4 | PR-V (construir; EventId **5134 a 5138**), PR-D2, spike en la VM (P-8: ventana después del 11-13 en `VM-SRV` de LFMB) |
| Revisiones | Cierre del #178; #170; T4-10 al construirse; T1-3/T1-4 (con D1-07 y D1-12 como condiciones); #175 al unirse |

## 4. Números y decisiones vigentes
- **EventId:** 4742 es de #103 (D1 usa **4794 y 4795**); emisor **4791-4793**; T4-10 **5150-5154** (5152 `SelloRazorRechazado`); #170 **5117-5119**; #175 **5121-5129**; franja 5130-5149 del instalador: usados 5130-5133 y 5140-5143 (libres 5134-5139 y 5144-5149); PR-V propone 5134-5138. **Errores SQL:** `imp` 51639-51644; D1 hasta 51638.
- Sello Razor: HMAC en la API de reportes, `Huella binary(33)` (Kid + HMAC), guardado en dos pasos sin transacción abierta, **falla sin API de reportes**; el sello vale para todo el sitio (el nodo no acepta el de la central); revocar = rotar `Kid`; repetición = riesgo aceptado R17.
- P-1 firmada (sin token programado para el SUPER); S168-02 frontera real (política `AdminSinRestriccion`, la construye B); S168-05 alcance por empresa y sucursal; Q-5 SDDL firmada; Q-6 VM firmada (B opera la VM); Q-8 `auto`.
- Los agentes que escalan a Opus firman `Co-Authored-By: Claude Opus 5.5`; el resto, Sonnet 5.5.

## 5. Firmas
A no tiene firmas pendientes. Pendientes del propietario (vía B): Q-3, Q-4 y Q-7 del instalador (proveedor de firma, nombre legal, qué se firma), el Z sin `vercuadrecaja`/tope de reimpresiones (S-03), R18 (franja del instalador), orden de abrir y unir los PR de A.
