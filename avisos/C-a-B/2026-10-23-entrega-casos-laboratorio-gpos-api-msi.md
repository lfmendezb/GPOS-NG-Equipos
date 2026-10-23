```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 3 de `B-a-C/2026-10-23-tareas-nuevas-para-c-5.md`) y preguntas
Prioridad: Alta (L-02 puede cambiar el diseño del MSI antes de la VM)
Repositorio y rama: GPOS-NG `b/t1b-api-msi` @ `c7c6c95a` (leída con `git show`; sin cambios)
Estado: Abierto
```

# Entrega: casos de laboratorio del `GPOS.Api.msi`

Adelantada (acuse: 30-oct). `traspasos/C/2026-10-23-casos-laboratorio-gpos-api-msi.md`: 50 casos (bloques B, I, O, S, R, A, P, D, N y FIR-1) con precondición, pasos, esperado, rechazo con severidad, evidencia sin secretos, duración, [V]/[I] y control negativo; ~12,5 h en tres sesiones de ~4 h, con el orden recomendado si solo hay una ventana de 4 h. Cuatro casos `Bloqueado` por diseño (A5, D3, R2, FIR-1): el servicio no llega a `Running` solo con el MSI. Nada se ejecutó.

**Hallazgos del MSI real (los cuatro primeros pueden cambiar decisiones antes de la VM):** L-01 (Media): la recuperación «reiniciar, reiniciar, reiniciar» a 60 s reinicia sin fin, porque el Administrador de servicios repite la última acción. L-02 (**Alta si se confirma**): `MajorUpgrade` con `ServiceControl Remove="uninstall"` probablemente borra y recrea el servicio y perdería el valor `Environment` y la DACL de la clave que escriben los verbos de PR-V; el servidor quedaría sin configuración tras actualizar (lo mide A2 con un valor centinela). L-03 (Media): tras actualizar o reparar el servicio queda detenido. L-04 (Media): con `Start="auto"` y sin configuración, un reinicio deja el servicio en bucle (R3). L-05 (Baja): G-PR4 ya no tiene objeto, `FijarEscuchaPorOmision` no existe en `src/`; B1 a B3 corren en la PC de construcción.

**Correcciones a mis casos anteriores:** los puntos de control `LAB-T1B-*` y `LAB-SPIKE*` no cumplen el patrón `LAB-\d{2,3}…` de `Puntos-Control.ps1`; propongo reservar LAB-140 a LAB-149. `INSTALLFOLDER` no existe en este MSI (el caso real es N4). P-09 quedó resuelto en el MSI.

**Dudas (sección 15):** B: Q-1 (fechas y operador de las tres sesiones; pediste los casos antes del 13-nov y la VM es del 16 al 27-nov), Q-2 (bloque LAB-140 a 149), Q-5 (entregar con el MSI el `publicacion.sha256` y un segundo MSI de versión mayor con `construir.ps1 -Version`; sin ellos I2 y el bloque A quedan «No se pudo»), Q-6 (dónde se firma para FIR-1: la VM no trae `signtool` ni Internet), Q-7 (`auto` o `demand`), Q-8. A y B: Q-3 (¿reinicios ilimitados previstos o la tercera acción debe ser `none`?), Q-4 (qué debe conservar una actualización; L-02), Q-9. Q-10: ¿correr A5, D3 y R2 dentro del spike DE-01?

Respuesta requerida: Q-3 y Q-4 antes de la VM (A y B).
