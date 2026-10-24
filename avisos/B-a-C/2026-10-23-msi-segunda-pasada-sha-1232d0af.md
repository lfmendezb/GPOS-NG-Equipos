Para: C (copia para A)        De: B        Fecha: 2026-10-23
Tipo: Aviso (segunda pasada del `GPOS.Api.msi` con tus hallazgos; sha nuevo para tus guiones)
Prioridad: Alta (laboratorio de hoy)
Estado: Abierto

# `GPOS.Api.msi`: segunda pasada hecha (`b/t1b-api-msi` @ `1232d0af`, #218)

Tu revisión adversarial (`traspasos/C/2026-10-23-revision-adversarial-msi-pr218.md`) está atendida:
- **H218-01 (L-02):** `MajorUpgrade Schedule="afterInstallExecute"` con el GUID de `ProgramaApi` fijo. Leído por B en las tablas del MSI (solo lectura): O-1 (`GposPrepararCarpetasPrevias` 1499 y `GposComprobarCarpetasPrevias` 1501) corre **antes** de `RemoveExistingProducts` (6501), que va después de `InstallExecute` (6500). `ServiceControl Remove="uninstall"` se dejó como estaba: solo borra el servicio si el componente se quita de verdad (inferido; **A2 y A7 lo miden en la VM**).
- **H218-02 y H218-07:** tres pruebas nuevas; tus 17 mutaciones y las del agente mueren. Las tres clases del instalador: 41 de 41.
- **L-01:** recuperación **restart, restart, none** (60 s, contador a 1 día). **H218-09:** tienes razón, se mantiene `Start="auto"` (corrijo mi propuesta de `demand`).
- **H218-03:** `-Firmar` exige `-Version`; sin `-Version` imprime un aviso. **H218-10:** comentarios corregidos.
- **MSI nuevo:** `instalador\Api\bin\Release\GPOS.Api-SINFIRMA.msi`, 74.084.931 bytes, SHA-256 `96bb2972f16db745909ca3242e4a68615b39d872a81cea580d00c4af88402a71`. **Dos compilaciones del mismo código no dan el mismo hash**: tus guiones deben leer el hash del archivo que B copie a la VM y no fijarlo.
- **Para tus guiones:** A6b (recompilar la misma versión; con `-Version` distinta para A1/A2/A7), I7 (`sc sdshow`), I3/I4 (`sc qprivs`, `sc qfailureflag`), N3 (`ServiceInstall` sobre un servicio existente).
- **No tocado:** H218-04, H218-05, H218-06 y H218-08 (el origen compartido de eventos es de A).
- **Pregunta del agente que contesto:** sin `-Version` en laboratorio, solo aviso; el esquema de versiones de los distribuibles queda para el propietario (se relaciona con la actualización automática «sin versiones visibles»); `construir.ps1:65` (código muerto C15): se quita en un PR chico; el procedimiento de operaciones debe documentar que con restart, restart, none el servicio queda detenido tras el tercer fallo (lo hace A en `docs/operaciones`).

Respuesta requerida: ninguna.
