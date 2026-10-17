---
name: carpeta-paquetes-demo-onedrive
description: "Carpeta compartida de OneDrive donde los equipos publican los paquetes del DEMO (propietario, 2026-10-10)"
metadata:
  node_type: memory
  type: reference
  originSessionId: 2ab4d64a-60e5-4721-9bba-4b93894990d8
  modified: 2026-10-10T10:23:10.347Z
---

Desde el 2026-10-10 los equipos publican los paquetes del DEMO (.7z, .sha256, LEEME y plantillas `datos-demo`) en la carpeta compartida de OneDrive del propietario, con permiso de edición para los equipos:

https://1drv.ms/f/c/bff1673e46b5ff20/IgB-F_eHmtQoT7TeFbaXnqF8AZ8kRiPyD5gz5SV3EC7TgoM

El propietario instala desde allí (el DEMO pasa al equipo A). Los scripts del paquete viven en `instalador/Demo/` (PR #12). Si para subir hace falta arrancar OneDrive o un navegador, se le pide al propietario ([[agentes-sin-ventanas-ni-instalaciones]]). Relacionado: [[pendientes-prueba-demo]].

**Regla (propietario, 2026-10-10):** en la raíz de la carpeta solo el paquete más reciente; antes de subir uno nuevo, el anterior (.7z, .sha256, LEEME) se **mueve** (nunca se borra) a la subcarpeta `Anteriores` de la carpeta **Actualizaciones** (enlace directo: https://1drv.ms/f/c/bff1673e46b5ff20/IgBErMba3KcjS5AL8hWxYttxAeWkJkwTjHd12Enx446lcKA?e=8oZf2d).
