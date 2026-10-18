```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: revisión en la PC A; registro en master en curso
Estado: Abierto
```

# Vector de ADR-77 v2: aceptado con cambios; P-77-4 y P-77-2 firmadas

Revisión del arquitecto-software de A (resumen): compatible con la v1, huella `139fb288…43ac` verificada, V2-2 a V2-5 correctos (máscara `0x500D0156` recalculada, `CREATOR OWNER`, 1603).

**El propietario firmó el 2026-10-08:**
- **P-77-4 (VV-01):** dueño adicional al arrancar solo en la carpeta de datos del propio componente y en su anillo de Data Protection; nunca en la raíz, `Conectores`, `Conectores\registro` ni en la comprobación previa del MSI; identidad verificada antes (SID declarado en una clave de HKLM escribible solo por SYSTEM y Administradores; para la API `HKLM\SOFTWARE\GPOS NG\Nucleo\IdentidadApi`); cuenta dedicada, nunca LOCAL SERVICE, NETWORK SERVICE, persona ni grupo; perfil de pruebas sin verificación no admitido en Release; el instalador no declara lo creado en ejecución.
- **P-77-2 (VV-04):** creación por herencia **dentro de la carpeta del propio componente** si el padre tiene DACL protegida y pasó la comprobación de arranque; el conector de IQ **no necesita cambio**.

**Para B (0,02 + 0,05 sp):** aplicar en la v2 **CB-1** (excluir cuentas compartidas; SID desde HKLM), **CB-2** (incluir la carpeta del anillo configurada), **CB-3** (perfil de pruebas no admitido en Release), **CB-4** (caso «la raíz ya existe»), **CB-5** (campos de VV-03 y VV-04); probar en el arranque del conector que una ACE no evaluable cuenta como escritor ajeno (Baja). Detalle: el documento de revisión va adjunto en `traspasos/A/` con este commit.
**VV-02:** identidad en `IdentidadApi`, verificada antes de `builder.Build()` en el orden identidad → privilegios → carpetas → Data Protection. **VV-05:** mapa `sids` en una v3 con N-11. **VV-06:** unificar solo los códigos del MSI. **VV-07:** la v1 se queda en `master`; A publica la v2 cuando B entregue la versión con CB-1 a CB-5 y su huella nueva.
