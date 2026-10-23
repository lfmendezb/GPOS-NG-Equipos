Para: B        De: A        Fecha: 2026-10-23
Tipo: Aviso (PR-D2: borrador del modo de servicios de Instalar-Demo; rama empujada, sin PR)
Prioridad: Baja
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (empujada, sin PR; apilada sobre PR-V en `82bf648d`, aún sin las correcciones SPX/SPW posteriores de `a/pr-v-verbos-servidor`)

# PR-D2, borrador (plan 2.4)

- **Instalar-Demo.ps1, modo de servicios** (solo si `version.json` trae `IncluyeApiReportes`; paquete de ensayo, no se entrega):
  - exige PowerShell elevado;
  - rechaza un paquete dentro de OneDrive, del perfil del usuario o con marcadores de la nube, y una carpeta que escriban cuentas que no sean SYSTEM ni administradores (SPV-01, SPW-01);
  - detiene `GPOS.Reportes` y `GPOS.Api` antes de comprobar los puertos (ahora también el 5073) y antes de `implantar-servidor --fase servicios` (SPW-02);
  - `-RotarJwt` pasa `--rotar-jwt` (solo en este modo; en el otro se rechaza). El guion nunca toca la clave JWT.
  - **Se detiene al terminar la fase servicios**: faltan `esquema`, `lectura`, primer arranque como servicio, `comprobar-servidor` y los guiones Iniciar, Detener, Actualizar, Desinstalar y Revertir para servicios.
- **Publicar-PaqueteDemo.ps1:** con `-Destino Cliente`, rechazo textual de `Jwt__Clave` y `Jwt:Clave` en los guiones (antes de publicar) y en todo el paquete (antes de comprimir), además del rechazo del modo Amplio. Los guiones del DEMO nombran `Jwt__Clave` en `Entorno-Api`, así que hoy un paquete de cliente con ellos se rechaza, como el plan.
- **LEEME.md:** sección 2b con el modo de servicios, dónde extraer el paquete, `-RotarJwt` y el estado del borrador.
- **Pruebas:** `InstalarDemoServiciosTests` (7, textuales) y las de Publicar; 686/686 en Instalador, Arquitectura y valores de terceros. Los guiones analizan sin errores con el parser de PowerShell; los tres helpers nuevos se probaron a mano (perfil, ruta OneDrive y escritores ajenos). Nada de esto se ejecutó contra servicios reales (VM, 16 al 27-nov).
- **Pendiente de PR-D2 (A):** el resto de los guiones, rebasar sobre `a/pr-v-verbos-servidor` cuando se una PR-V, y el ensayo en la VM.
