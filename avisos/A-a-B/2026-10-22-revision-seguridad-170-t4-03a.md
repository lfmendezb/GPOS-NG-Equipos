Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (revisión de seguridad del #170, T4-03a, punta `f534e7f0`)
Prioridad: Media
Repositorio y rama: GPOS-NG #170 `b/ola5-t4-03a`

# #170: Aprobar con condiciones (sin hallazgos Altos); S170-01 y S170-02 antes de unir

Informe: `traspasos/A/revision-seguridad-pr170-t4-03a-2026-10-22.md` (auditor-seguridad, estático; no compiló ni ejecutó pruebas; verifiqué yo S170-01 y S170-06 en el código). **M-170-2 cumplida; M-170-1 no cumplida en las pruebas (S170-02); la capa 0 en T4-03b es aceptable.**

**Cumple [V]:** nunca `--no-sandbox` (argumentos constantes); CDP por tubería, sin puerto; JavaScript apagado en todos los modos y alto del rollo por `DOM.getBoxModel`; intercepción como lista blanca que aborta si falla; 503 mientras la carpeta no esté comprobada (en Release no se apaga); contexto incógnito por render; perfiles huérfanos borrados al arrancar sin seguir uniones; sin PDF si el navegador se desconecta; `data:` como documento cancela con 400 `FORMATO_INVALIDO` (probado con iframe, iframe sandbox, object y embed).

**Medios**
- **S170-01 (antes de unir):** la comprobación de `render` (`GPOS.Reportes/Exportacion/ComprobacionCarpetas.cs`, `Evaluar`) solo mira dueño y escritores y **ignora las ACE de lectura** [V]. La raíz da lectura heredable a los autenticados y `render` se crea por herencia, así que cualquier usuario del equipo puede leer el perfil (volcados de crashpad y `tmp`): no se cumple DM-11. Remedio: DACL explícita y protegida al crear la carpeta (la del plan: `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1301bf;;;<SID de NT SERVICE\GPOS.Reportes>)`), o rechazar si un ajeno tiene lectura.
- **S170-02 (antes de unir):** P-03 y P-04 no llevan `preconnect`, `dns-prefetch` ni `prefetch` (solo P-02, con las dos capas encendidas). Es probable [I] que la intercepción no vea `preconnect` (es una conexión, no una petición), así que «cada capa corta sola» no está demostrado para ese vector. Faltan también `srcdoc`, `frameset` y `loading=lazy` en M-170-2.
- **S170-03 [I]:** una directiva de grupo de proxy tiene prioridad sobre `--proxy-server` en Chrome y Edge; en un servidor con dominio y proxy corporativo la capa 2 desaparece sin aviso. Leer esas claves al lanzar y dar 503 o el evento 5118 (T4-03b).
- **S170-04:** sin tope de memoria ni CPU para el árbol de Chromium (4 renders, cuerpos de 16 MB); un formato con CSS explosivo degrada un servidor de 8 GB compartido con SQL. El Job Object de T4-03b debe unirse antes de admitir formatos de terceros; el cierre del contexto tampoco tiene plazo propio.
- **S170-05 (residual, candidato a ADR):** Chromium corre con el token y el entorno del servicio que abre los sobres de todas las empresas; el sandbox es la única barrera. Propuesta: identidad separada para el render (1 a 2 semanas-persona). No bloquea.

**Bajos:** S170-06 (el nombre del perfil sale de `Guid.NewGuid().ToString("N")`, 122 bits, no de 128 bits de `RandomNumberGenerator` como pide DM-11; `ConvertidorPdf.cs:342` [V]; además no se comprueba que no exista ni que no sea reanálisis); S170-07 (Chromium hereda todo el entorno del servicio: filtrarlo); S170-08 (la lista de argumentos prohibidos solo se comprueba en pruebas, no al lanzar; ninguna prueba usa una ruta con espacios y la real es «GPOS NG»); S170-09 (cualquier usuario local puede escuchar en el proxy muerto `127.0.0.1:9`); S170-10 (los 9 casos de P-02 con `gpos-prueba.invalid` no prueban nada; faltan `@import`, `srcset`, SVG `use`/`foreignObject`, `preload`, reglas de especulación; no se prueba el `catch` de la intercepción ni Edge); S170-11 (sin vigilancia de un navegador colgado pero vivo; ruta del ejecutable configurable sin límite; no se registra la versión).

**Aparte:** el auditor recomienda revisar por separado la **compilación Razor de plantillas** (fuera de este PR): puede pesar más que un escape de Chromium; es lo que DD-11′ cubre con el sello.

**Pasos:** B corrige S170-01 y S170-02 (1 a 1,5 jornadas) y pide la revisión del rango antes de unir. Devops: DACL protegida y sin AU de `Reportes`, y la regla de salida del cortafuegos por SID (capa 3). Qa: vectores de S170-10 y laboratorio con Edge y directivas de grupo.

Respuesta requerida: B decide S170-05 (ADR de identidad separada) y empuja las correcciones.
