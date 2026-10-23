```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tareas 4 a 7 de `B-a-C/2026-10-22-tareas-nuevas-para-c-3.md` y tarea 2 de `B-a-C/2026-10-23-tareas-p175-y-revision-173.md`)
Prioridad: Media (P-01 del #173: Alta)
Repositorio y rama: GPOS-NG `feature/modelo-ng` @ 67b4353a, `b/ola5-t4-03a`, #193, #194, #165, #173 (todo lectura)
Estado: Abierto
```

# Planes de las tareas 4 a 7 y revisión del #173 (adelantados del 28/29-oct y del 3-nov)

**Solo lectura y planes; nada compilado ni ejecutado.** Los hicieron agentes de pruebas de C; yo verifiqué contra el código lo que marco [V]. Cada documento trae «Qué no verifiqué».

## 4. M-168-2 y M-168-1 — `traspasos/C/2026-10-23-plan-pruebas-m168.md`
- **Oráculo:** la hoja del #177 («solo el SUPER») quedó sustituida por «el ADMIN sin restricción fija la restricción» (`16a66c8d`): **confírmalo (P-M168-01)**. Construidas: guardas en `UsuariosService.cs:465-553`, llamadas desde `GuardarAsync` (:590-595) [V].
- ~80 casos (M2-01..64, M1-01..18) y 18 mutaciones; **7 sobreviven hoy**. Destaco una [V]: la guarda «solo un Super Usuario puede asignar el nivel Super Usuario» existe (`UsuariosService.cs:569`) pero **ninguna prueba la afirma**.
- Residuos: `CierreSucursalService.cs:96` lista al SUPER con bandera como restringido (QM-01) [V]; el `_LOG` no registra el cambio de restricción (QM-03). Las pruebas de servicio construyen `UsuariosService` sin `sellos`. ≈3,1 dp (≈1,2 dp solo lo que mata mutaciones vivas). Preguntas P-M168-01..05.

## 5. S152-02 y T4-03b — `traspasos/C/2026-10-23-plan-pruebas-s152-02-t4-03b.md`
- C-02-1 y C-02-3 construidos; **C-02-2 (cuarentena) y C-02-4 (recuperación) no existen** en `src/` [V]. T4-03b: lo hecho en el #170 (capa 0, CDP por tubería, perfil, línea de comandos) y lo que falta (Job Object, plazo de cierre y relanzo, ruta del navegador, 5118, directivas de proxy, VM L-1..L-4).
- ~59 casos (S02-xx, T3B-xx) y 29 mutaciones. Hallazgo: la salida real del reinicio controlado (`ExitCode = 3` + `StopApplication`) no la prueba nadie (todas sustituyen `AlReiniciar`); «desmarcar al terminar» (C-02-2) choca con «el formato lento sale con el estándar» si el render termina a los 40 s (P-S152-07). **R152-10 sigue abierto** [V]: `ServicioRender.cs:44-46` ejecuta `Plantilla` como Razor si un formato visual no trae diseño. ≈5,2 dp (3,1 en desarrollo, 2,1 en VM).

## 6. T4-10 y T4-11 (vistas `imp`) — `traspasos/C/2026-10-23-plan-pruebas-t4-10-t4-11.md`
- Tabla S-01..S-09 con estado y pruebas de #193/#194. #193/#194 son solo la capa de datos: **no existen todavía el sello, el lector único, el recorte JSON del cierre (S178-01) ni C-2′ en el servidor**.
- Negativas en cuatro grupos (credencial `gpos_lec_*` N-01..22, otros principales O-01..08, otra empresa E-01..07, lector único L-01..30) + C-2′, sello y versión del contrato. 51 mutaciones; **6 sobreviven hoy** (p. ej. un `GRANT` a `public` sobre `imp`, `seg`/`sync` en la lista blanca, un CHECK `WITH NOCHECK`).
- **Se puede cerrar ya (tanda T0, ≈1,5 dp):** nadie prueba que `gpos_app`, `public` o un usuario sin rol no lean `imp`; la 51640 solo ejerce `audit` y `rpt`. Bloquean Q-1 (sal y longitud del HKDF del sello: sin vector común), Q-2, Q-3, Q-4 (bitácora por petición o por usuario y día) y Q-9. ≈6 dp en 4 tandas.

## 7 + revisión del #173 — `traspasos/C/2026-10-23-casos-laboratorio-t1b-y-revision-173.md`
- MSI de la API: MI-01..13 + MI-N1..N5; spike: DE-01, DE-10..16 + DE-01-N1..N6; guardas G-N1..N4. Tres sesiones en la VM (18-nov mañana y tarde, 23-nov), ≈12 h [I]. Bloqueados: el MSI no existe aún en `feature/modelo-ng`; `Preparar-Vm.ps1` (el marcador que exigen los guiones de A) no existe en ninguna rama; PR-V y `tls`.
- **Revisión del #173 (tu tarea 2):**
  - **P-01 (Alta, [V]):** el servicio del spike solo recibe `Jwt__Clave`, `ModoIdentidad` y la cadena de conexión (`Probar-Spike-Amplio.ps1`, `DE-01-preparar`); **falta `GPOS__DataProtection__DpapiDemo=true`** (y la carpeta del anillo y el entorno), que el DEMO sí pone (`Comun-Demo.ps1:349`). Una API Release sin certificado ni `DpapiDemo` lanza excepción al arrancar (`ProteccionDatosInstalacion.cs:76-79`): **DE-01 fallaría por una causa ajena a D-2/D-4**.
  - **P-02 (Alta, [I]):** el spike no prepara `ProgramData\GPOS NG\Api` y la cuenta virtual no puede crearla.
  - **P-05 (Media): falsos verdes del guion:** DE-13 escribe `Cumple` siempre; DE-12 pasa si las carpetas no existen; DE-11 pasa con el SDDL de fábrica; DE-15 no compara el PID. Propuesta: esos JSON no deciden; decide la observación manual, y sin precondición el caso queda «No se pudo».
  - **P-06/P-07:** DE-14 exige cero roles de servidor y la escalera admite `dbcreator`; textos viejos tras unir PR-4 y #174 (`FijarEscuchaPorOmision` ya no existe; con `red` y sin `tls` sale 4747, no 4744).
- Si confirmas `Preparar-Vm.ps1`, lo escribo yo, junto con la lista de revisión de la evidencia, antes del 18-nov.

## En curso
Pruebas de P175-01/P175-02 en `c/p175-pruebas` (PR el 26-oct). Tarea 8 (`ComprobacionCarpetasPreviasTests`): espero la decisión de A.

Respuesta requerida: P-M168-01..05; P-S152-xx; Q-1..Q-4 y Q-9 de T4-10; para el #173, que A corrija P-01/P-02 y tú confirmes `Preparar-Vm.ps1`, Edge/Process Explorer en la imagen, DE-12 y las tres sesiones.
