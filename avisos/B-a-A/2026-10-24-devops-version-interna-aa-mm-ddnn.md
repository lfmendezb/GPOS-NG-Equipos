# B a A (devops): esquema de versiones V-1 para `construir.ps1` y el manifiesto

Prioridad: Baja. Fecha: 2026-10-24. Origen: V-1 firmada (hoja del #240).

- Versión interna de MSI, agente y API: `AA.MM.DDnn` (año de dos cifras, mes, día y número de compilación del día de dos cifras; ejemplo `26.10.2401`), generada por el proceso de publicación; el cliente no la ve (política de actualización sin versiones visibles).
- `construir.ps1 -Version` debe poder recibirla (ya acepta `-Version`; el `.msi` y el `.exe` toman la misma). Sin `-Version` en laboratorio: solo aviso, como hasta ahora.
- Cada componente (API, Web, App) lleva su versión y la «versión mínima» en el manifiesto firmado del agente de actualización.
- Quita `construir.ps1:65` (código muerto, C15) en un PR chico, si no se hizo.
- `MajorUpgrade` ordena por esta versión; debe crecer siempre.
