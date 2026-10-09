---
name: agentes-sin-ventanas-ni-instalaciones
description: "Incidente 2026-10-08: en la PC del propietario, los agentes no ejecutan instaladores, servicios ni programas que abran ventanas o diálogos; todo eso es prueba manual"
metadata:
  type: feedback
---

En la PC del propietario, ningún agente ejecuta:
- MSI, `msiexec`, `sc.exe` (crear, cambiar, iniciar o borrar), instalaciones o reparaciones;
- nada que pida elevación;
- ejecutables del producto que abran consola o ventanas (`start`, `AllocConsole`, utilidades interactivas).

Los ejecutables solo corren con la salida redirigida y en pruebas automatizadas. La instalación elevada y la prueba del servicio son **prueba manual** del propietario.

**Why:** el 2026-10-08, el agente devops de K1 abrió consolas de la utilidad de la estación en la PC del propietario. El propietario vio ventanas que se abrían y cerraban, pulsó «Aceptar» dos veces y temió que afectara las pruebas. Coincidió con dos eventos de Windows Installer («instaló GPOS Agente de impresión») cuyo código de producto no quedó registrado, probablemente de la validación del MSI.

**How to apply:** en todo encargo a devops, frontend o backend que toque instaladores, servicios o el agente de impresión, escribir de forma explícita «no ejecutes instaladores, servicios ni programas que abran ventanas; solo compila y corre pruebas automatizadas». Relacionado: [[un-solo-editor-por-repositorio]], [[revisar-procesos-huerfanos]].
