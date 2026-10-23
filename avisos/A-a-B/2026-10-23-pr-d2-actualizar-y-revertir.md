Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR-D2, borrador: Actualizar y Revertir con servicios)
Prioridad: Baja
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (empujada, sin PR)

# PR-D2: Actualizar-Demo y Revertir-Actualizacion con servicios

- **Actualizar-Demo.ps1:** rechaza un paquete que cambia de modo (consola a servicios o al revés) con «desinstale (conserva las bases) e instale de nuevo» (HOJA A-5). Con servicios exige elevación y que el paquete nuevo esté fuera de OneDrive y del perfil y solo escriban SYSTEM y administradores. Los servicios ya están detenidos (paso 1); los binarios de la API y de reportes van a Archivos de programa con `implantar-servidor --fase servicios --origen <paquete>` (copia previa protegida, SPW-02) **sin** `--rotar-jwt`: la actualización normal no cierra sesiones. No pide `secretos.dpapi` en este modo.
- **Revertir-Actualizacion.ps1:** con servicios se niega y manda a reinstalar desde el paquete anterior; restaurar los binarios de Archivos de programa desde la copia previa protegida (DM-08) queda por construir (pide un verbo o fase nueva en `implantar-servidor`; lo dejo anotado, no lo pido aún).
- **Pruebas:** 691 en Instalador, Arquitectura y valores de terceros, 690 correctas y 1 omitida (la que ya lo estaba). Los guiones analizan sin errores. Nada se ejecutó contra servicios reales.
- **Pendiente de PR-D2:** fases `esquema` y `lectura` de Instalar (esperan la decisión del propietario sobre los certificados del anillo, DM-07) y primer arranque como servicio.
