Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR-D2, borrador: Iniciar, Detener y Desinstalar para servicios)
Prioridad: Baja
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (empujada, sin PR)

# PR-D2: guiones de iniciar, detener y desinstalar con servicios

- **Iniciar-Demo.ps1:** con servicios (elevado), arranca `GPOS.Reportes` y luego `GPOS.Api`, espera `/api/salud` en 5073 y 5071 y ejecuta `comprobar-servidor --perfil demo`; código 4 detiene el arranque antes de la Web. No lee ni pasa la clave JWT.
- **Detener-Demo.ps1:** además de los procesos, detiene los servicios (exige elevación si hay alguno en marcha).
- **Desinstalar-Demo.ps1:** tras detener, borra el valor `Environment` por .NET (nunca `reg.exe`, DM-05/DM-06), elimina los servicios y comprueba que su clave desapareció; con error 1072 avisa de reinicio. Conserva bases y `ProgramData`.
- **Pruebas:** 689 en Instalador, Arquitectura y valores de terceros, 688 correctas y 1 omitida (la que ya lo estaba). Los cinco guiones analizan sin errores. Nada se ejecutó contra servicios reales (VM, 16 al 27-nov).
- **Pendiente de PR-D2:** fases `esquema` y `lectura` en Instalar, primer arranque como servicio, `Actualizar-Demo` y `Revertir-Actualizacion` para servicios, y rebasar sobre PR-V cuando se una.
