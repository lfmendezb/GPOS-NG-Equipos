```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 9 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8.md`) y preguntas
Prioridad: Media (SP-02 y SP-08 conviene decidirlos antes del 23-nov)
Repositorio y rama: GPOS-NG `feature/modelo-ng` (#173 unido) y `b/t1b-api-msi` @ `1232d0af`; sin cambios
Estado: Abierto
```

# Plan del laboratorio del spike DE-01 (Amplio, 23-nov)

`traspasos/C/2026-10-24-plan-laboratorio-spike-de01.md`. 31 casos, cada uno con precondición, pasos, esperado, rechazo con severidad, evidencia sin secretos, duración, [V]/[I] y control negativo: preparación SPK-P0; spike DE-01 y DE-10 a DE-16; negativos DE-01-N1 a N6 (N4 en cuatro variantes); Chromium de la principal con lo aplicable de T4-03 (SPK-C1 a C5); MSI con el servicio vivo (SPK-M0, M1, A5, R2, R4, D3, D5 y R3). Mapa de L-1 a L-4 de T4-03: L-1c, L-1d, L-2a/b y L-3a/b/c caben en SPK-C1 a C5 usando la cuenta `NT SERVICE\GPOS.Api` de la principal; L-1a/b, L-1e, L-2c y L-4a/b quedan fuera, cada uno con su motivo. Tres sesiones, con reparto VM-SRV / VM-PUESTO y puntos de control LAB-150 a LAB-152: S-1 (23-nov mañana) 3 h 20, S-2 (23-nov tarde) 4 h 25, S-3 (24-nov) 3 h 25; total ≈ 11 h (±50 %), con prioridad si solo hay una ventana de 4 h. Lista de revisión de evidencia (secciones F a I, que se suma a las A a E de `revision-evidencia.md`). Estado de mis P-01 a P-11 sobre el #173: atendidos por A P-01, P-02, P-05, P-06 y P-07; siguen abiertos P-03, P-04, P-10 y P-11. No compilé ni ejecuté nada en VM; todo se leyó con `git show`.

**Respuesta a mi Q-10 (A5, D3 y R2 dentro del spike):** sí se pueden correr, pero no dentro del servicio que crea el guion. `DE-01-preparar` crea el servicio con `sc create`, no con el MSI: sobre ese servicio A5 y D3 no son ejecutables (sería el caso N3) y R2 solo mediría a `sc` (el spike pone `restart ×3`; el MSI de `1232d0af`, `restart, restart, none`). Propongo una segunda rama de la misma sesión: restaurar `LAB-150-sql-listo` (el punto previo a crear el servicio, con SQL y el paso 0), instalar el MSI v1, darle la configuración del spike y correr A5, D3, R2/R4, D5 y R3 sobre el servicio real del MSI. Exige un cambio chico en `Probar-Spike-Amplio.ps1`: un parámetro `-ServicioDelMsi` (~0,25 dp [I]); puedo escribirlo si lo confirmas (Q-3). Esa rama no entra en el veredicto D-2, que sale solo de la rama pura. Con el servicio vivo se cierra además L-02 de forma funcional (si tras actualizar el servicio arranca, el `Environment` sobrevivió) y se miden L-03, L-04, L-15 y el token vivo con el evento 4770.

**Hallazgos de lectura antes de la VM (SP-01 a SP-10)**
- **SP-08, candidato Alto (lo califica el auditor de A):** la principal lanza Chromium con PuppeteerSharp sin `Pipe` (`src/GPOS.Api/Impresion/ConvertidorPdf.cs`); es probable que el puerto de depuración quede abierto en loopback. Si es así, un usuario local alcanzaría un navegador que corre como `NT SERVICE\GPOS.Api`. El puerto es [I]; lo confirma SPK-C3, que mide solo la conexión TCP sin enviar ningún comando. Además el perfil va a `GetTempPath()` y nunca se borra (SPK-C2).
- **SP-02, Alta para el laboratorio:** el guion escribe `Environment` con la clave JWT real antes de proteger la DACL de la clave del servicio y sin `try/catch`; si `SetAccessControl` falla, la clave queda bajo la DACL por omisión, que probablemente da lectura a Usuarios. SPK-P0 paso 7 lo mide con un servicio de prueba.
- SP-01: `DE-12` termina siempre en `No se pudo` con código de salida 3 porque `render` no existe en el spike; es esperado y hay que anotarlo. SP-05 y SP-06: `DE-16-retirar` no sirve en la rama del MSI (se usa `msiexec /x`); el paso 8 del spike («no arranca solo») es cierto solo en la rama pura porque el MSI trae `Start=auto`. SP-09: la recuperación `restart ×3` del spike deja un bucle cada 60 s que contamina los eventos del negativo siguiente; cada negativo lleva su propio `$desde` y termina deteniendo el servicio.

**Dudas (Q-1 a Q-12, sección 13; las que cambian el calendario)**
- B: Q-1 (¿se confirman 23 y 24-nov y quién opera cada sesión?), Q-2 (reservar LAB-150 a LAB-159), Q-3 (¿aceptas las dos ramas y el cambio `-ServicioDelMsi`?, ¿lo escribo yo o A?), Q-6 (¿qué navegador se fija y entran Edge, Chrome y System Informer sin Internet? la principal prueba Chrome primero), Q-7, Q-9 (¿caben VM-SRV y VM-PUESTO encendidas a la vez en LFMB durante S-2?), Q-10 (`config` cerrado o vector v3), Q-11 (commit y entrega del MSI v2).
- A: Q-4 (¿se reordena el guion, DACL de la clave antes del valor, antes del 23-nov?), Q-5 (sonda funcional), Q-12 (SP-01 y SP-07). Auditor de A: SP-08 y Q-8 (¿es conocida y aceptada la ausencia de `Pipe` en el render de la principal?) antes del 23-nov.

**Sin verificar:** todo lo [I]: el puerto de depuración, el comportamiento del SCM con `none`, `Stop="both"` y `afterInstallExecute` con el servicio vivo, la DACL por omisión de las claves de servicio y el efecto de `-LocalUser`. Las fechas de VM no están confirmadas por el propietario.

Respuesta requerida: Q-1, Q-3 y Q-6 de B y Q-4 de A antes del 16-nov; con Q-3 escribo el cambio de guion y el plan queda ejecutable.
