```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Entrega + Encargo
Prioridad: Media
Repositorio y rama: GPOS-NG b/devops-publicacion @ e6457402 (desde 7898beeb; sin unir)
Estado: Abierto
```

# A-N3 hecha por B (`b/devops-publicacion`, `e6457402`)

## Qué hay
- **CR-04 (b) y CR-11:** `instalador/Publicacion/Comprobar-PublicacionRelease.ps1` lee los metadatos sin cargar los ensamblados y falla si encuentra cualquiera de estos:
  - un recurso `*Desarrollo.json`;
  - un `GPOS*` sin optimizar;
  - `*.Tests.dll`, `testhost*` o `xunit*`;
  - `appsettings.Development.json`.

  `Publicar-PaqueteDemo.ps1` lo llama antes de comprimir. También rechaza `DefineConstants`, `Configuration` y `Optimize` en el entorno.
- **Hallazgo nuevo (comprobado):** con `DefineConstants=DEBUG` en el entorno, una compilación `-c Release` sale optimizada pero incrusta y admite las llaves de desarrollo. Lo cierra **CR-04 (a)**: el destino `ComprobarDebugCoherente` en `GPOS.Criptografia.csproj`. B verificó tres casos: Debug compila, Release compila y Release con `DEBUG` falla.
- **SEG-RG14-02:** el guion exige ahora `-Destino Demo|Cliente`, sin valor por omisión. Con `Cliente` falla si el paquete fija `ModoIdentidad = Amplio`. Hoy falla siempre, a propósito, porque `Comun-Demo.ps1` fija Amplio. **Desde ahora el DEMO se publica con `-Destino Demo`** (nota en la guía de actualización).
- **Documentos:** `docs/operaciones/2026-10-15-lista-publicacion-release.md` y `…-informe-a-n3.md`.
- **Lo que no se probó:** el guion completo de punta a punta, porque necesita 7-Zip y MAUI. La primera corrida real será el próximo DEMO.

## NeverBlock
- **Hoy el residual no aplica.** La API usa la cuenta de Windows de quien instaló y el código no tiene ningún `CREATE LOGIN … WITH PASSWORD`. En `.\SQLEXPRESS`, `gsf` tiene `CHECK_POLICY` en 0 y `sa` está deshabilitado. En `.` solo existe `sa`, deshabilitado.
- **La autenticación contenida está en 0 en las dos instancias** y D-04 (a) la necesita. Quedó como M6 en la lista.

## Encargos que salen de aquí
- **A (desarrollador I):**
  - el bloqueo de DL-02 (a) en código (en Release no se crean cuentas al arrancar; con licencia `Produccion` o `Beta` no se arranca en Amplio);
  - el paso S0, que crea los logins de la variante S y el de Backup Tool con `CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF`;
  - el hallazgo `LOGIN_SERVICIO_CON_POLITICA` en `GPOS.Migracion verificar` (unos 0,1 días-persona).
- **Arquitecto Maestro:** incorporar M3 (sin Amplio) y M5 (logins de servicio sin política de bloqueo) a PUB-06. ADR-44 está firmado y no se editó: va a la firma del propietario.
- **Auditor de seguridad:** verificar la suposición de que la política de bloqueo de cuentas no se aplica a los usuarios contenidos.
