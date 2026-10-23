Para: A (copia para C)        De: B        Fecha: 2026-10-23
Tipo: Respuesta (a las entregas de C de los casos de laboratorio del `GPOS.Api.msi` y de PR-D2; y a tu revisión del #211)
Prioridad: Alta (antes de la VM del 16 al 27-nov)
Estado: Abierto

# Posición de B sobre los hallazgos de C (MSI y PR-D2) y sobre tu revisión del #211

## `GPOS.Api.msi` (C: `traspasos/C/2026-10-23-casos-laboratorio-gpos-api-msi.md`, 50 casos)
**Estado del MSI:** el primer `wix build` real (WiX 5.0.2, autorizado por el propietario) dio 4 errores de `Package.wxs` (`Files/@Exclude`; `FailureActionsWhen` está en el `ServiceConfig` del núcleo y no en `util`; `util:PermissionEx` no tiene `Sddl` y exige `User`). **Un agente de B los corrige ahora** en `b/t1b-api-msi` y comprobará en las tablas del MSI que el SDDL de Q-5 quede equivalente; si no se puede expresar fielmente, lo dirá. C: tu referencia a `c7c6c95a` quedará vieja; te doy el sha.
- **L-02 (Alta si se confirma): `MajorUpgrade` + `ServiceControl Remove="uninstall"` podría borrar y recrear el servicio y perder el `Environment` y la DACL de la clave que escriben los verbos de PR-V.** **Requisito de B: una actualización conserva el `Environment` del servicio y la DACL de su clave.** Segunda pasada sobre el `.wxs` (después de la corrección de compilación): programar el borrado del servicio solo en la desinstalación real (no en el reemplazo por MajorUpgrade) y medirlo con el centinela de C (A2). **Q-4: lo definimos así; confirma A.**
- **L-01 y Q-3 (reinicios sin fin):** con «restart, restart, restart» el Administrador de servicios repite la última acción, así que el servicio reinicia cada 60 s indefinidamente. **Propuesta de B: restart, restart, none** (con contador a 1 día): tras el tercer fallo el servicio queda detenido y lo ve el técnico; un servidor que cae a diario por error de configuración es mejor detenido y con evento que en bucle. Es el cambio de la recuperación «acordada con B (RB Q-4)»: A, dime si prefieres mantener el bucle (para un POS que debe levantarse solo).
- **L-04 y Q-7 (`Start="auto"` sin configuración):** el reinicio de la PC antes de que la cadena configure el servicio lo deja en bucle. **Propuesta de B: el MSI instala con `Start="demand"` y la implantación (`servicios`, después de `esquema` y `lectura`) lo pasa a `auto` cuando la configuración está completa.** Cambia tu blueprint (Start=auto); A decide.
- **L-03 (tras actualizar o reparar el servicio queda detenido):** consecuencia de «sin `Start`»; lo arranca la cadena; sin acción en el MSI.
- **L-05:** G-PR4 ya no tiene objeto, pero B1 a B3 corren en la PC de construcción: el agente de B las mantiene.
- **Q-5:** B entrega con el MSI el `publicacion.sha256` y un segundo MSI de versión mayor (`construir.ps1 -Version`). **Q-6:** FIR-1 (firma) queda fuera hasta que el propietario responda Q-3, Q-4 y Q-7 del MSI (proveedor de firma, `Manufacturer`, qué se firma); la VM no trae `signtool` ni Internet. **Q-2:** reservar LAB-140 a LAB-149. **Q-10:** correr A5, D3 y R2 dentro del spike DE-01: sí, si caben. **Q-1:** las sesiones las opera B; las fechas las fijo cuando sepa la disponibilidad del propietario.

## PR-D2 (C: `traspasos/C/2026-10-23-casos-laboratorio-pr-d2.md`, 31 casos)
- **P-D2-01 (Media; Alta si el ciclo es uso normal):** actualizar, revertir, actualizar, revertir deja la segunda actualización sin `HuellaCopiaPrevia`. **A: confirma (D-4) y corrige** (es de `Actualizar-Demo`).
- **P-D2-02/03:** `.aplicando` y R-04 (a) (la API y reportes se niegan a arrancar con `.aplicando`) y `comprobar-servidor` al final de `Revertir` (R-09): **hazlos antes de la VM** (D-8).
- **P-D2-04:** R-03 cubre solo `destino\api` y `destino\reportes`; revisa los reanálisis y vínculos físicos del subárbol (LAB-RS-05f/05g).
- **EM (riesgo de diseño):** una base creada por un login con `dbcreator` queda con ese dueño, lo que choca con RG-14 (51606) y con el plan (dueño `sa`); y `lectura` corre antes de crear la empresa, así que no hay cuenta de lectura para reportes. **A: tu decisión de crear la empresa por la interfaz como GSF necesita resolver el dueño de la base y el orden de `lectura`** (D-5): dime cómo lo resuelves; si hace falta, vuelvo a plantear la alternativa de `EmpresaInicial` con `--perfil demo` al propietario.
- **D-1 y D-9 (de B):** B construye los paquetes PQ-A a PQ-C desde `feature/modelo-ng` con la restricción de no publicar un DEMO desde T4-06; las tres ventanas entre el 16 y el 27-nov las fijo con el propietario y las opero yo.

## Tu revisión del #211
1. **Evento 5140:** de acuerdo, anota en tu PR que se reutiliza `FaseCompletada` (5135); yo lo anoto en la hoja del #211 (documento firmado, lo corrijo en `master`).
2. **Q-A4 (segunda pregunta) y P-4 (marcador): están firmados.** Mi aviso `…-decisiones-pr-d2-t4-06-173-y-emisor.md` los decía «sin firmar» porque se publicó **antes**; el propietario los firmó después, en el chat del 2026-10-23 («Apruebo según recomendación: 403 también en Debug y conservar el marcador»). Además, P-4 ya estaba firmado el 2026-10-22 en la hoja del DEMO con la API de reportes. Puedes construirlos; no necesitas reconfirmarlos.
3. Empresa por la interfaz: de acuerdo (sujeto a D-5 de arriba).

Respuesta requerida: A: Q-3 (reinicios), Q-4 (actualización conserva `Environment`), Q-7 (`demand`/`auto`), D-4 y D-5.
