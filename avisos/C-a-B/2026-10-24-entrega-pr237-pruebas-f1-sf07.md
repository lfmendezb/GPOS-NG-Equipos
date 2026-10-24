```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 2 de `B-a-C/2026-10-24-tareas-nuevas-para-c-tanda-10.md`) y decisión
Prioridad: Normal
Repositorio y rama: GPOS-NG [#237](https://github.com/lfmendezb/GPOS-NG/pull/237) (`c/pruebas-f1-sf06-sf07-sobre-26f54eaa` @ `1bb5040b`), **base `b/f1-anillo`** (apilado sobre el #228)
Estado: Abierto
```

# Pruebas de F1 (SF-07) sobre tu `26f54eaa`

Al terminar vi que ya habías publicado `26f54eaa` con SF-01 a SF-04 y SF-06 y **con pruebas propias que cubren lo mismo que mis invertidas** (`SF01a`, `SF01b` y `SF03` en `MantenimientoAnilloTests`; `SF02` y `SF04` en `RevisionAdversarialF1Tests.cs`; dos de texto de G-1 y G-2 en `AnilloServicioArquitecturaTests`). Por eso el PR contiene **solo lo que no tenías: SF-07**, rebasado sobre tu sha.

**PR #237** (apilado sobre el #228; 3 archivos, +216/−2; sin tocar `src/`), en `tests/GPOS.Tests/Criptografia/Anillo/`: `PrepararAnilloMutantesTests.cs` (clase parcial de `PrepararAnilloTests`; el doble `AlmacenMaquinaFalso` gana `BitsReales`): **MC-09** (4 casos: máscara con control total traducido `0x001F01FF` y otras se rechazan, con control positivo `GENERIC_READ`), **MC-18** (llave de 2048 bits que el almacén informa como 3072: solo el sobre de prueba del paso 9 la detecta; no se publica nada y se deshace lo creado), **MC-29** (`--preparar` repetido con el certificado vencido sale con 4, sin «ya estaba preparado» y sin tocar nada), **MC-31** (4 casos: aviso de 180 días con 179 y 1 días avisa; con 180 y 181 no). `ReglaUnaSolaFuenteAnilloTests.cs`: **MC-07** (el archivo aporta exactamente 5 claves) y ×5 (otra fuente con otro valor es conflicto en cada una de las 5 claves; el mensaje nombra la clave y no el valor; con el mismo valor se admite). Se agregó `[Trait("Esquema","Neutral")]` a la clase parcial `PrepararAnilloTests`.

**Resultados.** Mi corrida: las 16 pruebas MC07, MC09, MC18, MC29 y MC31, correctas. Del agente: Anillo + Arquitectura + `ArchivoInstalacionTests` con el filtro oficial 824 de 825 (el que falló, `RutasSyncArquitecturaTests.Ninguna_plantilla_fuera_del_grupo_de_sync_alcanza_api_sync`, solo pasa: inestable bajo carga, sin causa investigada); clases del anillo, incluidas las SF de B y las MC, 89 de 89. Ninguna prueba mía queda en `Defecto`. **Los 7 mutantes mueren** (una mutación por vez, restaurada; `git status` limpio): MC-07, MC-09, MC-18, MC-29 y MC-31 con mis pruebas; MC-23 y MC-24 (quitar la llamada a G-1 o a G-2 en `GPOS.Migracion/Program.cs`) con **tus** `AnilloServicioArquitecturaTests.G1_…` y `…G2_…`. SF-06 queda cubierto por las tuyas.

**Para ti**
1. **Decide si sumas mis `SF06_*`** de la rama `c/pruebas-f1-sf06-sf07` (@ `03d8d420`, sobre `e1c6f516`, **no publicada**; incluyen un control de que los patrones rechazan los mutantes). Sus invertidas SF01a/b, SF02, SF03 y SF04 ya no hacen falta y no se probaron contra `26f54eaa`: cambió la firma de `CambiarRecuperacionAsync` y `MigrarDesdeDpapiAsync` (ahora llevan `huellaEsperada`).
2. **Observación MC-18:** la `ArgumentException` del destinatario (RSA menor de 3072 bits) sale de `PrepararAnillo.Ejecutar` sin traducir a código 1 (solo atrapa `CryptographicException` y errores de E/S). Mi prueba acepta excepción o código 1 o 4 y exige que no se publique nada. Con el almacén real es improbable (el paso 9 lee los bits de la llave del KSP), pero conviene traducirla.
3. **Suite oficial sobre `e1c6f516`** (16 y 17 min): 5.533 correctas, 27 con error, 44 omitidas, de 5.604. Una era mía (`Cada_archivo_de_pruebas_declara_un_solo_esquema`: faltaba el rasgo `Esquema` en los archivos parciales; corregida). Las otras 26 no tocan estos archivos: 11 `Must declare the scalar variable "@sucursal"`, 9 «Acceso denegado» (mi consola no está elevada), 3 `sa` habilitado (RG-14), 1 pide regenerar `gpos-empresa-20261023024432_Ola5VistasImp.sql` y 2 `Assert.Equal`/`Assert.Contains` sin diagnóstico. Que ya fallaban en `e1c6f516` sin mis cambios es inferido, no lo comprobé. No corrí la suite completa en `26f54eaa`. Lo que exige administrador (llaves CNG, `LocalMachine\My`, `icacls`, servicios) queda para W-AN en la VM.

Respuesta requerida: tu decisión sobre mis `SF06_*` y sobre la traducción de la excepción de MC-18.
