```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Encargo (orden del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG (bases indicadas en cada tarea)
Estado: Abierto
```

# Encargo para C: cuatro tareas que A le transfiere

El propietario, en la sesión de A, dijo: «Sí, publica el encargo para C con las tareas 1 a 4 (Para: B y C).»

Las cuatro son trabajo corto, compatible con la restricción de OSHIN-LEGION (aviso `C-a-B/2026-10-17-equipo-c-inestable`):
- nada de suites completas, cargas ni mediciones;
- compilar, correr pruebas dirigidas y hacer commit y push al cerrar cada tramo.

La suite oficial de cada PR la corre B en LFMB, o A.

**Orden de unión firmado:** #63 (SL) → #67 (RN) → #57 (fase A) → #58. Las ramas apiladas se rebasan cuando se unan sus bases.

## 1. T-n de la fase A de ADR-81 sobre SL y RN
- **Base:** `a/rn-cambio-rnc` @ `da474174` (#67, apilada sobre el #63), en una rama `c/` propia. El #57 se rebasa sobre la punta que deje el #67, porque toca los mismos cinco archivos que SL.
- **Qué conectar** (el detalle está en el aviso `A-a-B/2026-10-17-pr63-sl-sello-padron`, §Para C, y en la validación `traspasos/A/validacion-sl-sello-padron-2026-10-17.md`):
  - **`IFactorSuper`** con la lectura real de `UsuariosFactor`, en el `db` recibido:
    - en `Program.cs`, la línea `AddSingleton<IFactorSuper>(SinFactorSuper.Instancia)`;
    - en `ComandoSellos.Factor`.
  - **`UsuariosService.CambiarFactorAsync(codigo, escribirFactor)`** para el alta y la baja del factor. Toma el padrón primero, escribe el factor dentro de la misma transacción y vuelve a sellar.
  - **S-02 y S-04** (`SellosEndpoints.cs`) y **S-03** (`CambioRncEndpoints.cs`), mapeadas con `RequiereAutenticacionReciente()` y dadas de alta en `RutasLicenciaAprobadas.json`. Las pruebas de arquitectura `SellosEnLaApiTests` y `CambioRncEnLaApiTests` cambian a propósito.
  - **Catálogo de eventos:** sumar `CUENTA_LEGITIMADA`, `PADRON_PURGADO`, `PADRON_RESELLADO`, `CUENTAS_FUERA_DE_PADRON`, `PADRON_DISCO_AUSENTE`, `CAMBIO_RNC_SUPER` y `CUENTA_CON_FACTOR`. Hay que alinear los nombres: en el catálogo de C están en PascalCase y SL los escribe en MAYÚSCULAS_CON_GUION.
- **Seguridad:** factor, sello y licencia. Corresponde «Escalado a Opus» para el desarrollador y la revisión del auditor.

## 2. Pantallas web de SL y RN (GPOS.Web y, si aplica, MAUI)
- **Base:** `a/rn-cambio-rnc` @ `da474174`.
- **Qué construir:**
  - **S-01:** lista de cuentas sin sello (`GET /api/super/usuarios/sin-sello`), solo para el SUPER, con el motivo de cada una y cómo recuperarla (`sellos --legitimar` o `--purgar`).
  - **S-05:** eventos de los verbos (`GET /api/super/eventos-servidor`). Una lista en Diagnóstico y un aviso al SUPER cuando entra, si hay eventos nuevos.
  - **RNC en la configuración:** editable para el ADMIN solo si la empresa no tiene RNC (RN-F1). Ya fijado, queda de solo lectura y se muestra el mensaje del 409 `RNC_SOLO_SUPER`.
  - **Liberación del candado de `GPOS_SYSDATA`:** mostrar `cuentasFueraDePadron` y `recuperacion`. Estos campos llegan con SL-F1, en una rama de A que todavía está en corrección; esta parte se hace cuando A abra ese PR.
- **Diseño:** sigue los patrones existentes de Diagnóstico y Empresas. Si falta un diseño, pídelo al diseñador UX.
- **Pruebas:** Web.Tests (y MAUI.Tests si aplica).

## 3. R-5: una carpeta de licencia por anfitrión de prueba
- **Base:** `feature/modelo-ng` @ `e80f4654`, en un PR propio. Es neutro para T6: se une después del 27-oct, en cualquier hueco.
- **Problema:** las fábricas de prueba de la API comparten una sola carpeta de licencia por proceso (`CarpetaLicenciaPruebas`). Cada anfitrión reescribe el `padron` de los demás y deja eventos `PADRON_DISCO_AUSENTE` falsos. Validación `traspasos/A/validacion-sl-f1-f2-2026-10-17.md`, punto 5.
- **Corrección:** una carpeta por anfitrión, que se borra al terminar.
- **Coordinación:** el archivo es de L1b-2. Avisa a A por `A-a-B`/`C-a-B` antes de cambiar el contrato de las fábricas.
- **Pruebas:** dirigidas, las de licencia y sellos que usan las fábricas.

## 4. Diseño: el acta firmada por GSF y el reporte del resellado (L-06/L-07)
- **Qué decidió el propietario hoy** (aviso `A-a-B/2026-10-17-firma-slf01-acta-gsf`): **antes de la primera licencia de pago**:
  - el acta de `sellos --resellar` es una autorización firmada por GSF y ligada a la instalación;
  - el resellado se reporta a GSF en L-06/L-07.
- **Entregable:** un blueprint del arquitecto de software, **solo diseño**. Debe cubrir:
  - el formato del JWS de la autorización (`typ`, campos, vigencia y vínculo con `InstalacionId`);
  - cómo la emite el emisor (`GSF.EmisorLicencias`, sección 9.2);
  - cómo la verifica `--resellar` (con `VerificarCompacto`);
  - qué viaja en L-06/L-07;
  - la estimación y el reparto L/I.
- **Fuentes:**
  - la revisión de seguridad `traspasos/A/revision-seguridad-sl-f1-f2-2026-10-17.md` (SLF-01, estimada en unos 0,85 dp);
  - el blueprint de la licencia, §5, §9 y §10.
- **Revisión:** el auditor. La construcción la hace A después.

## Lo que sigue en A
- SL-F1/SL-F2: correcciones en curso; el PR va apilado sobre el #67.
- El submódulo del emisor, después de unir el #65.
- El reapunte del #67, después de unir el #63.

Acusa recibo y avisa con un aviso Entrega por cada tarea (regla 9).
