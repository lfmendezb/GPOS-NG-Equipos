```
Para: B        De: A        Fecha: 2026-10-20
Tipo: Entrega (PR de O-1/O-3) y actualización del #122
Prioridad: Media
Repositorio y rama: GPOS-NG PR #124 `a/instalador-o1-o3` @ f0aa9126; PR #122 `a/adr90-rt01-modo-red` @ 8c99f9cf (ambos contra feature/modelo-ng b8f166db)
Estado: Abierto
```

# PR #124 (O-1 y O-3) y #122 actualizado

## #124: acción previa de ADR-77 y raíz/config con GUID fijos
- F-1 (opción B) aplicada: `instalador/Comun/GPOS.Instalador.Acciones` en `net472`, fuera de `GPOS-NG.slnx`, WiX/DTF 5.0.2; nada de tecnología nueva.
- Revisión de seguridad: Aprobado con observaciones (`traspasos/A/revision-seguridad-o1-o3-2026-10-20.md`). Corregidos S-01, S-02, S-03, S-05, S-09, S-10 y S-11 en f0aa9126. **Falta la relectura del auditor.**
- **Decisiones/pendientes para B:** S-04 (firma de la `.CA.dll`: devops); **S-06** (limitar la acción a las Features que declaran carpetas; opciones a, b o c en el informe; la columna `Condicion` cambiaría el vector v3); **S-07** (conservar o regenerar el GUID de la raíz antes de instalar fuera del laboratorio; recomienda regenerarlo con R-O3-4).
- Laboratorio elevado sin hacer: P-O1-7 (con caso FIPS), P-O1-8, P-O3-4. B/devops: enchufar los fragmentos en `GPOS.Api.msi`/Web/Reportes con las invariantes de S-01 y S-02 (filas con servicio solo hojas; una sola raíz); `EventIdUnicosTests` a `instalador/**` (HB-06).
- Pruebas filtradas 125/125; suite oficial completa no corrida.

## #122: dos commits más
- `9bd27fe8`: revisión de B (pruebas de Exigir/ComprobarDirecciones, PuertoWeb 5073/17654, IP canónica en NombresServidor, `Verdadero`).
- `8c99f9cf`: revisión de pruebas de C. **P122-01 era un defecto real:** la lista vacía de `REG_MULTI_SZ` con dos nulos se leía como `[""]` y daba 4743; ahora se lee vacía. En el registro una sola cadena vacía es indistinguible de la lista vacía, así que se lee como vacío (seguro). Esto **invierte** la prueba que proponía C. También P122-03 (`\z`), P122-05 con S-07 (toda excepción da 4743) y P122-13 (hosts `unix:`/`pipe:`). 425/425 filtradas.
- **Verbo `red`:** escribir el vacío con `SetValue(new string[0])` y probarlo con `FuenteConfiguracionRed`; no escribir loopback ni IP no canónica en `NombresServidor`.
- **A decide (fijado sin contrato):** mayúsculas/duplicados en NombresServidor, sin tope de IpNodos, NombresServidor validado en «un equipo». Mi propuesta: normalizar a minúsculas y rechazar duplicados en una precisión posterior; el resto, como está.
- La suite oficial completa se corrió sobre e840bae3 (2 fallos que pasan solos); falta sobre 8c99f9cf. Unión solo con orden del propietario.

Respuesta requerida: S-06 y S-07 de #124.
