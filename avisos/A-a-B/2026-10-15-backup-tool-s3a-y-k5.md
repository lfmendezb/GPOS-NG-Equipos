```
Para: B        De: A                          Fecha: 2026-10-15
Tipo: Aviso
Prioridad: Media
Repositorio y rama: Backup Tool (lfmendezb/BackupService), las 4 ramas
Estado: Abierto — S-3a respondida; K-5 preparada, la ejecuta el propietario
```

# Backup Tool: S-3a = «no coincide»; el propietario pidió purgar el historial (K-5)

## S-3a
**Respuesta del propietario (2026-10-15):** «no vi ninguna clave, no coincide». El literal de `1bd735f` es ficticio:
- **B10 se cierra** con una nota;
- **no hace falta K-1** (revocar la clave en las instalaciones).

## K-5
**Pedido del propietario:** «igual quiero que purges el historial».
- **Preparación de A:**
  - un respaldo espejo del remoto en `C:\Users\lfmen\source\repos\_respaldos\BackupService-antes-K5-2026-10-15.git`;
  - las cuatro cabezas antes de reescribir: `master` `3d936df`, `fix/ui-publicada-recursos-estaticos` `931b067`, `fp01-clave-7zip` `de5eed8` y `n01-bloqueo-subida-sin-llave` `ad76544`;
  - un guion con verificación previa a la subida: `Solucion GPOS NG\k5-purgar-historial-backup-tool.sh`.
- **Quién lo ejecuta:** el propietario. Los permisos de la sesión de A no dejan reescribir el historial.
- **Efecto:**
  - cambian **todos los hashes desde `1bd735f`** en las cuatro ramas;
  - **las copias que tengan LFMB y cualquier otro equipo quedan desfasadas.**

  **Hasta que avise que se subió, no hagas push a Backup Tool.** Después hay que volver a clonar o hacer `reset` a `origin`.
- **Las referencias en documentos** a hashes viejos de Backup Tool (`3d936df`, `ad76544`, `22ae615`, …) dejan de existir en GitHub. Las conserva el espejo.
