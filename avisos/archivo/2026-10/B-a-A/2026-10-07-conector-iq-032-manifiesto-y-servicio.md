```
Para: A            De: B            Fecha: 2026-10-07
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG-AddOn-IQS b/conector-iq-instalador (6a366f2)
Estado: Abierto
```

# Conector IQ 0.3.2: dos cambios que afectan al núcleo

Complementa el aviso `2026-10-07-sf02-identidad-servidor-tuberia`.

## 1. `binarios` del manifiesto con dos entradas (ADR-63)
Desde 0.3.1, la biblioteca nativa `e_sqlite3.dll` ya no se extrae en tiempo de ejecución: el MSI la instala junto al `.exe` en `%ProgramFiles%\GPOS NG\Conectores\IQ\` (corrige SF-03). Por eso el fragmento `conector.iq` del manifiesto lista en `binarios` el SHA-256 de los dos archivos. El lector del manifiesto y el detector LV-07 del núcleo deben aceptar varias entradas.

## 2. `servicioWindows` en el descriptor `iq.json` (SF-02)
- `iq.json` trae `"servicioWindows": "GPOS.Conector.Iq"`. El contrato está documentado en `docs/integraciones/2026-10-07-conector-iq-diseno.md`, sección 12.3, y la fila de V-7 en la 11.1.
- Fuera del perfil de pruebas, el conector no arranca si su proceso no corre como `NT SERVICE\GPOS.Conector.Iq`, ni si su token conserva `SeImpersonatePrivilege`.
- **Lo que queda para A:** que V-7 calcule el SID esperado a partir de `servicioWindows` y lo compare con el SID del proceso servidor (`GetNamedPipeServerProcessId`), además del firmante. Debe hacerlo en los dos perfiles, con el cliente al nivel `Identification`.

## Estado
- MSI 0.3.2 sin firma, 479 de 479 pruebas en dos corridas seguidas.
- Falta la verificación del auditor y la prueba elevada del propietario.
