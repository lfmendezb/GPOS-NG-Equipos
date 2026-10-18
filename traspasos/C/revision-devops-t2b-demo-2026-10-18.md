# Revisión DevOps: T2 (b) de ADR-126 en los guiones del DEMO (2026-10-18)

Alcance: solo lectura de instalador/Demo en el worktree GPOS-C-intermitentes (rama c/t2b-archivo-instalacion). No se ejecutó nada.

**Veredicto: Listo con observaciones** (ningún hallazgo Crítico ni Alto).

## Verificado

- Publicar-PaqueteDemo.ps1:100 copia `scripts\herramientas` con `-Recurse` y sin filtro: el ejemplo viaja en el paquete. Los controles de las líneas 122-134 solo miran `app\` y no tocan el ejemplo.
- Actualizar-Demo.ps1:17 y :90-93: `config\` solo se respalda con `robocopy /E` (no `/MIR`); la actualización no la espeja ni la borra. Los `/MIR` de :54, :125 y :130 afectan a `herramientas` y `app\*`, no a `config`. El `GPOS.Api.json` del usuario se conserva.
- Revertir-Actualizacion.ps1:93-100 restaura solo `app\*` y `version.json`; no toca `config`. Se conserva el archivo del usuario.
- Desinstalar-Demo.ps1:47-48 mueve `config` entera a `respaldos\desinstalado_<marca>`, y con ella el `GPOS.Api.json` activo. Es igual que `instalacion.json` y `secretos.dpapi`. Nada se borra.
- Entorno de cada proceso:
  - API: `Entorno-Api` (Comun-Demo.ps1:352), usado por Iniciar-Demo.ps1:65 y Instalar-Demo.ps1:147.
  - Web: `Entorno-Web` (Comun-Demo.ps1:378), usado por Iniciar-Demo.ps1:80.
  - Migración: `Entorno-Migracion` (Comun-Demo.ps1:360-364) incluye la clave.
- Compatibilidad con PowerShell 5.1 y StrictMode:
  - El literal de hashtable con `(Get-RutaDemo 'config')` es válido.
  - `$api[$k]` sobre un hashtable no falla si falta la clave.
  - `Test-Path` y `Copy-Item -Force` en Instalar-Demo.ps1:97-98 son correctos.
  - `$PSScriptRoot` apunta a `scripts\`, y `herramientas\` está allí.
  - No hay sintaxis de PS 7.
- DACL: `Restringir-Carpeta` (Comun-Demo.ps1:118-123) se aplica a `config` antes de copiar el ejemplo (Instalar-Demo.ps1:95-98), que hereda el permiso (OI)(CI). Sin elevación no hay `%ProgramData%\GPOS NG`, así que usar `config` del DEMO es la alternativa correcta. Nada que objetar: el filtro de claves permitidas (`GPOS:RncDgii`) hace que el archivo no admita secretos aunque la DACL de ADR-77 no se compruebe.

## Hallazgos

1. **Media. Las llamadas a GPOS.Migracion sin entorno no reciben la variable.**
   - `Invoke-Migracion` simple se usa en Instalar-Demo.ps1:113 (`crear`), Actualizar-Demo.ps1:137 (`actualizar`) y Comun-Demo.ps1:267 (`verificar`). Solo `sistema` pasa por `Invoke-MigracionConEntorno` (Instalar:135, Actualizar:161).
   - Hoy es inocuo: Migración no usa `GPOS:RncDgii` y el archivo es opcional. Si una tanda posterior permite más claves, esos tres pasos leerían `%ProgramData%\GPOS NG\config\GPOS.Migracion.json` en vez de la carpeta del DEMO.
   - Recomendación: hacer que `Invoke-Migracion` fije siempre la variable en el proceso, o pasar `Entorno-Migracion` en esas tres llamadas.
2. **Baja. Los DEMO ya instalados no reciben el ejemplo.** Solo Instalar-Demo.ps1:97-98 copia el ejemplo a `config\`. Actualizar-Demo.ps1 lo deja en `herramientas\` pero no lo copia a `config\`. Se puede agregar una copia condicional (solo si no existe) en el paso 4, o documentar la ruta `herramientas\GPOS.Api.json.ejemplo` en el LEEME.
3. **Baja. Solo hay ejemplo para la API.** Web y Migración también leen `config\GPOS.Web.json` y `config\GPOS.Migracion.json`, pero no hay ejemplo ni documentación en el LEEME. Conviene decir en el LEEME que el DEMO solo documenta el de la API y cómo se activa (copiar a `GPOS.Api.json` y reiniciar con Iniciar-Demo).
4. **Baja. El ejemplo se puede activar tal cual.** `padron.example.com` no es una URL real, y copiarlo sin editar rompe la descarga del padrón. El ejemplo no tiene marca visible, y JSON no admite comentarios. Alternativa: usar un marcador evidente, como `https://<servidor>/RNC_CONTRIBUYENTES.zip`.
5. **Informativa. Fuera de los guiones.** `GPOS__ArchivoInstalacion__Carpeta` (ArchivoInstalacion.cs:188) también funciona en Release y redirige la capa 3 fuera de la raíz de ADR-77. Lo mitiga la lista de secciones permitidas. Para el servicio instalado, conviene decidir si se ignora la variable fuera del DEMO.
6. **Informativa. Desinstalar mueve el `GPOS.Api.json` activo a `respaldos\desinstalado_<marca>`.** Una reinstalación parte sin él; hay que copiarlo de vuelta. Conviene decirlo en el LEEME.

## Entregas
Ninguna a otros agentes; los hallazgos 1 a 4 los resuelve quien mantiene los guiones del DEMO.
