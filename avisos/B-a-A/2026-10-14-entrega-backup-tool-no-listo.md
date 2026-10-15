```
Para: A            De: B            Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Normal
Repositorio y rama: Backup Tool master 1c92b98 y origin/n01-bloqueo-subida-sin-llave ad76544
Estado: Abierto
```

# Backup Tool: revisión para producción como producto independiente. Veredicto: NO LISTO

El propietario pidió revisar si Backup Tool se puede desplegar en producción **de modo independiente a GPOS NG**. La integración con GPOS NG (MD-54, P0 y piloto) quedó fuera del veredicto.

Fue solo revisión: no se cambió código, no se unió ninguna rama y no se instaló nada.

## Veredicto
- **No listo**, tanto `master` como `master` + n01.
  - Seguridad da Rechazado.
  - Devops da No listo.
- Cerrar los bloqueantes cuesta unos 2 sp (inferido, ±30 %), más un ensayo en un equipo limpio.

## Cifras
- Compilación en Release: 0 errores en los dos árboles.
- Pruebas: master **107/107** y n01 **303/303**.
- En LFMB, la restauración falla con NU1301 porque falta `C:\Users\lfmen\source\NugetLocalFeed`. Se restauró solo con nuget.org.

## Bloqueantes (detalle con archivo:línea en el informe)
- **B1. Crítica:** no hay instalador versionado. `deploy/` no existe en ninguna rama ni en el disco.
- **B2. Crítica:** el servicio corre como LocalSystem y la carpeta de datos hereda «Modificar» para Authenticated Users. Falta firmar ADR-0004.
- **B3. Crítica:** la retención rompe la cadena de restauración (`RetentionService.cs`; política sembrada de 7 días y 3 copias por día).
- **B4. Alta:** paquetes vulnerables. `WebAssembly.Server` 10.0.12, `Cryptography.Pkcs` 10.0.0 y 10.0.12, y `Cryptography.Xml` 10.0.12.
- **B5. Alta:** `master` sube los `.7z` sin cifrar. El cifrado está en n01, que sigue sin unir.
- **B6. Alta:** la API permite cambiar la ruta de 7-Zip, lo que equivale a ejecutar código como el servicio.
- **B7. Alta:** no hay alerta por ausencia de respaldos y `/health` responde 200 en `degraded`.
- **B8. Alta:** no hay recuperación ante desastre ni reversión.
- **B9. Alta (inferido):** HTTPS sin certificado.
- **B10. Alta hasta S-3a:** literal con forma de clave en `tests/BackupService.Tests/ApiKeySecurityTests.cs:123` de master y en el historial desde `1bd735f`. No se reproduce aquí.

## Pendientes del propietario
- Unir n01: **bloquea**.
- Firmar ADR-0004: **bloquea**.
- Comparar el literal de `1bd735f` con la clave real (S-3a): **bloquea** hasta conocer el resultado.
- BT-01 a BT-09: no bloquean si la versión 1 solo respalda bases.
- L-2 a L-5: obligatorios en cada instalación nueva.
- K-1 a K-5: no bloquean una instalación nueva, salvo que S-3a dé «coincide».
- **K-5:** la transcripción de la sesión de B que hizo esta revisión también contiene el literal y entra en la purga.

## Documentos
- Informe: `Backup Tool/docs/operaciones/2026-10-14-revision-despliegue-produccion.md`. Está en el árbol de trabajo, **sin commit**: lo confirma el propietario.
- Informes de los agentes (auditor-seguridad y devops): carpeta de notas de la sesión de B, `backup-tool-seguridad.md` y `backup-tool-devops.md`.

## Para A
Por ahora no hay tarea. Si el coordinador lo encarga, A puede tomar B3, B4, B6 o B7 en ramas `a/` del repositorio de Backup Tool, **cuando el propietario haya unido n01**.
