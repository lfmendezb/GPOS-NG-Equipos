```
Para: B y C        De: A            Fecha: 2026-10-17
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG #63 (a/sl-sello-padron @ afc8bdb1, base feature/modelo-ng @ e80f4654)
Estado: Abierto
```

# PR #63: SL «Sello y padrón» (ADR-83; DL-01, DL-02 y DL-05)

## Qué entra
- **Sello de habilitación:**
  - cubre el SHA-256 del `PasswordHash` y `FactorAlta` (DL-05);
  - se comprueba en el inicio de sesión (antes que la contraseña y con hash ficticio), en cada petición (401) y en el autorizante.
- **Padrón de sellos:**
  - es la fuente del cupo;
  - tiene copia en disco y el evento `PADRON_DISCO_AUSENTE`.
- **Rutas y verbos:**
  - S-01 publicada;
  - S-02 y S-04 sin mapear hasta la fase A;
  - verbos `sistema --cuentas-iniciales`, `sellos --legitimar`, `sellos --purgar` y `verificar`.
- **DEMO:** el instalador y el actualizador hacen el sellado inicial.
- **Sin DDL nuevo.**

## Verificación
- **Arquitecto:** Conforme con correcciones; C-1 a C-5 aplicadas. Informe en `traspasos/A/validacion-sl-sello-padron-2026-10-17.md`.
- **Seguridad:** Aprobado con observaciones, sin Críticos ni Altos; SL-01 y SL-03 a SL-10 corregidas. Informe en `traspasos/A/revision-seguridad-sl-sello-padron-2026-10-17.md`.
- **Pruebas dirigidas en la PC A (SQL 2019):** 1097/2/1. Las 2 son del 12834 sin el #48. `Sellos` + arquitectura, repetida por A: 55/55.

## Para C
- **Suite oficial del #63**, como dice la delegación.
- **Fase A de ADR-81 (#57), para conectar:**
  - `IFactorSuper`, en `Program.cs` y en `ComandoSellos.Factor`;
  - `UsuariosService.CambiarFactorAsync(codigo, escribirFactor)`, que toma primero el padrón y escribe el factor en la misma transacción;
  - S-02 y S-04, con `RequiereAutenticacionReciente()`: ver `SellosEndpoints.cs`;
  - la prueba `SellosEnLaApiTests` cambia en ese PR.
- **El arquitecto recomienda unir el #63 antes que la fase A**, porque los dos tocan los mismos cinco archivos. Después, la fase A rebasa.

## Para B: orden de unión
SL **no es neutro para T6**: agrega la verificación del sello en cada petición, con una caché de 15 s. Va **después del 27-oct**, salvo que B decida otra cosa.

## Para firma (B → propietario)
**SL-F1 (confirmación de ADR-83, punto 2):** al restaurar `GPOS_SYSDATA` desde un respaldo legítimo, las cuentas cuyo sello cambió después de la copia quedan fuera del padrón, aunque sea el SUPER.
- **(a) Recomendada:** no se reconcilian solas, porque eso reabriría SEG-L2-07. El SUPER las legitima una por una, con control del cupo (`sellos --legitimar`, ya incluido). Al liberar el candado CR-01 se informa cuántas quedaron fuera (entrega a H-11, unos 0,1 dp).

**SL-F2 (precisión de ADR-83, punto 7):** `sellos --resellar` (R-S1), la recuperación con acta, no estaba asignado.
- **Reglas propuestas:**
  - solo funciona si ningún padrón verifica;
  - muestra la lista y pide confirmar y motivo;
  - deja un evento crítico;
  - si las cuentas superan el cupo, la empresa queda `EnExceso`.
- **(b) Recomendada:** construirlo antes de la primera licencia de pago, no necesariamente antes del corte.

Detalle y texto de hoja en la validación, §SL-F1 y §SL-F2.

## Pendiente fuera del PR
- **SL-02:** procedimiento de restauración en `docs/operaciones/`.
- **Devops:** la misma `GPOS:Licencia:Carpeta` para la API y `GPOS.Migracion`.
- **Frontend:** la pantalla de S-01.
- **Siguiente de A:**
  - **EV-01:** listas del modelo cerrado de la autorización en `FormatoLicencia`;
  - **RN:** cambio de RNC, con DL-03 firmada. `--legitimar` ya entró en SL.
