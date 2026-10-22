```
Para: C (devops) y B (coordinador)        De: C (auditor-seguridad, OSHIN-LEGION)        Fecha: 2026-10-21
Tipo: Revisión de seguridad de guiones (antes de abrir el PR)
Prioridad: Media
Repositorio y rama: GPOS-NG, rama c/laboratorio-adr090-scripts (worktree GPOS-C-laboratorio), commit 285f3c7d
Estado: Aprobado con observaciones (recomendación técnica, C2)
```

[Informe de Seguridad] Guiones del anfitrión del laboratorio de ADR-90 (VirtualBox en `LFMB`)

- **Fecha:** 2026-10-21 · **Revisor:** auditor-seguridad del equipo C (OSHIN-LEGION).
- **Objeto:** `tests/laboratorio-adr090/` de la rama `c/laboratorio-adr090-scripts`: `LEEME.md`, los 8 `anfitrion/*.ps1` y `anfitrion/herramientas/Comun-Laboratorio.ps1`. El encargo hablaba de archivos «sin commit», pero durante la revisión apareció el commit `285f3c7d` («Laboratorio de ADR-90: guiones del anfitrión…»). El árbol de trabajo es idéntico a ese commit, así que esta revisión vale para `285f3c7d`. No modifiqué ningún guion.
- **Requisitos contra los que reviso:**
  - diseño v3 (`traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`), secciones 3 y 7.2, con la regla LS-11;
  - mi revisión anterior (`traspasos/C/2026-10-20-revision-seguridad-laboratorio-adr090.md`, LS-11);
  - el rediseño con VirtualBox (`traspasos/C/2026-10-21-rediseno-laboratorio-adr090-virtualbox.md`, 3.2 a 3.6);
  - el encargo de B (`avisos/B-a-C/2026-10-21-asignaciones-scripts-laboratorio-y-plan-e1.md`, tarea 6);
  - ADR-44, falla cerrada, nada se instala ni se arranca sin orden, una VM a la vez.
- **Qué ejecuté** (C6). No llamé a VBoxManage ni borré nada.
  1. Una batería de 26 textos de prueba contra `Redactar-Texto`, cargando solo `Comun-Laboratorio.ps1`, en PowerShell 7.6.7 y en Windows PowerShell 5.1.26100. Los secretos eran de mentira. **Se escapan 25 de los 26** (sección 4, SL-01 y SL-10).
  2. Un prototipo de las reglas propuestas. Pasa los 13 casos de `Probar-Redaccion.ps1` y cubre 24 de los 26 casos de la batería en las dos versiones. Está en el scratchpad de la sesión, fuera de los repositorios.
  3. Una prueba del paso de argumentos a un programa nativo (`python -I`) con un texto que lleva comillas dobles. En 5.1 el argumento **se parte en varios**; en 7.6 llega entero (SL-05).
- **Marcas:** [V] verificado (en el código, en el comportamiento comprobado aquí o contra el código del producto en `origin/feature/modelo-ng` `e3e729c1`). [I] inferido; incluye el comportamiento de VirtualBox 7.2.22, que no pude probar porque este equipo no lo tiene.

> Esto es una recomendación técnica (C2). Las correcciones las hace el devops de C; B las prueba en `LFMB`.

---

## 1. Alcance y superficie revisada

**Superficie que exponen los guiones:**
- **Ejecutables:** `VBoxManage.exe`, que se resuelve por un parámetro, por la variable `VBOX_MSI_INSTALL_PATH` o por el PATH, e `icacls.exe`.
- **Operaciones destructivas:**
  - `unregistervm --delete` más `Remove-Item -Recurse -Force` (`Limpiar-Anfitrion.ps1`);
  - `Remove-Item -Recurse` de `desatendida\` (`Cerrar-Preparacion.ps1`);
  - `snapshot delete` y `snapshot restore`.
- **Secretos:**
  - la clave de la instalación desatendida: archivo temporal, DPAPI y los archivos auxiliares de VirtualBox;
  - todo lo que llegue en la evidencia de las VM: código de emparejamiento, `Secreto` de la estación, tokens `disp+jwt`, cadenas de conexión y blobs DPAPI.
- **Texto del operador que llega a VBoxManage:** `-Descripcion`, `-Usuario`, `-Idioma`, `-TipoSo`, `-Iso` y `-CarpetaVm`.
- **Salida de evidencia:** la carpeta `-Salida`, la copia de `-CarpetaInvitado` y `manifiesto.json`.

**Fuera de alcance:**
- los guiones que corren dentro de las VM (`Preparar-Vm.ps1`, `preparar-vm.sh`, `Limpiar-Laboratorio.ps1` y los demás);
- las pruebas de `tests/GPOS.Tests/Laboratorio/Tls/`;
- el cambio de `.gitignore` de LS-11;
- la instalación de VirtualBox 7.2.22 y sus vulnerabilidades conocidas: no lo verifiqué. B revisa el último parche crítico de Oracle antes de instalar.

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título |
|---|---|---|
| SL-01 | Media | La redacción no reconoce los nombres reales del producto: el código de emparejamiento (`codigo`, `c` del QR) y las claves compuestas (`SecretoEstacion`, `userPassword`, `client_secret`…) se escapan |
| SL-02 | Media | `.evtx`, `.png` y `.jpg` se copian sin redactar por omisión: una captura del QR o del código, o un registro de Aplicación, sale tal cual |
| SL-03 | Media | La salida de `unattended install` se imprime en la consola y en el mensaje de error; VBoxManage muestra las claves en esa salida [I] |
| SL-04 | Media | El borrado recursivo no comprueba puntos de reanálisis (*junctions*) y la raíz `M:\VM` es un parámetro libre |
| SL-05 | Baja | Inyección de argumentos en Windows PowerShell 5.1 por comillas en el texto del operador; parámetros libres que van a las plantillas de instalación |
| SL-06 | Baja | VM y puntos de control se identifican por nombre, no por UUID; `Get-PuntosControl` falla abierta |
| SL-07 | Baja | La clave de la instalación desatendida deja restos fuera de `desatendida\`: en el invitado, en el medio auxiliar y en el ACL de la carpeta de la VM |
| SL-08 | Baja | La salida de la evidencia solo rechaza los repositorios git; acepta carpetas sincronizadas con la nube |
| SL-09 | Baja | La huella SHA-256 completa de un archivo pequeño no copiado permite recuperar un secreto corto por fuerza bruta |
| SL-10 | Baja | Patrones genéricos que se escapan y archivos UTF-16 sin BOM que se «redactan» sin ningún reemplazo |
| SL-11 | Baja | No se fija ni se comprueba el escritorio remoto de VirtualBox (VRDE) ni las carpetas compartidas antes de «base» |
| SL-12 | Baja | «Una VM a la vez» y la memoria libre solo se comprueban en `Preparar-Anfitrion.ps1`, no al arrancar |
| SL-13 | Baja | `Resolver-VBoxManage` ejecuta cualquier ejecutable sin verificar su firma |
| SL-14 | Baja | `-Accion Eliminar` sin `-Vm` apunta a las tres VM; borrar «base» no pide confirmación; una VM a medio crear queda sin marcador |
| SL-15 | Baja | Inexactitudes del LEEME: la versión solo se exige en 2 guiones, no en «todos» |

**Recuento:** ningún hallazgo Crítico ni Alto; 4 Medios y 11 Bajos. **Esfuerzo total estimado:** 1 a 1,5 días-persona de C, más 1 hora de B para confirmar los [I] en `LFMB`. Costo de infraestructura: USD 0.

---

## 3. Checklist OWASP Top 10 (2021), aplicado a guiones de laboratorio

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Bien: guarda positiva del anfitrión y triple condición para tocar una VM (marcador, `.vbox` dentro de la raíz y nombre del catálogo). Observaciones: SL-04, SL-06 y SL-14 |
| A02 Fallos criptográficos | Bien: clave de 192 bits con `RandomNumberGenerator` y DPAPI del usuario. Observación: SL-09 (huella de secretos cortos) |
| A03 Inyección | Los argumentos van como arreglo, sin `Invoke-Expression` ni `cmd /c`. Observación: SL-05 (comillas en 5.1) |
| A04 Diseño inseguro | Observación: SL-02 (copia sin redactar por omisión) |
| A05 Configuración | Bien: NAT retirado y comprobado, sin portapapeles ni arrastrar y soltar, red interna. Observaciones: SL-11 (VRDE y carpetas compartidas) y SL-12 |
| A06 Componentes vulnerables | No verificado en esta sesión (VirtualBox 7.2.22); lo revisa B antes de instalar |
| A07 Identificación y autenticación | La clave de las VM sale del azar y se guarda con DPAPI. Observaciones: SL-03 y SL-07 |
| A08 Integridad | Bien: huella SHA-256 de la imagen antes de crear y versión fija 7.2.22. Observación: SL-13 (firma de VBoxManage) |
| A09 Registro y monitoreo | Observaciones: SL-01, SL-03 y SL-10 (secretos en la evidencia y en la consola) |
| A10 SSRF | No aplica |

---

## 4. Dictamen por punto del encargo

1. **Guarda del anfitrión y VM ajenas.**
   - Bien [V]. Los 7 guiones que operan llaman a `Confirmar-Anfitrion` antes de tocar nada:
     - `Preparar-Anfitrion.ps1:45`;
     - `Crear-VmLaboratorio.ps1:59`;
     - `Cerrar-Preparacion.ps1:34`;
     - `Puntos-Control.ps1:40`;
     - `Ajustar-Reloj.ps1:44`;
     - `Recoger-Evidencia.ps1:43`;
     - `Limpiar-Anfitrion.ps1:36`.
   - `Probar-Redaccion.ps1` no la llama, por diseño.
   - La guarda exige que las dos fuentes, `COMPUTERNAME` y CIM, valgan exactamente `LFMB`, y falla cerrada si una no se lee (`Comun-Laboratorio.ps1:69-80`).
   - Para tocar una VM se exige el nombre del catálogo (`ValidateSet`), el marcador y que el `.vbox` esté dentro de la raíz (`Comun-Laboratorio.ps1:185-203`). Antes del borrado se exige además que la carpeta no sea la raíz y que se llame como la VM (`Limpiar-Anfitrion.ps1:60-65`).
   - Huecos: los puntos de reanálisis y la raíz parametrizable (SL-04), y la identidad por nombre (SL-06).
2. **Clave de la instalación desatendida.**
   - **Es aceptable para un laboratorio:** VM aislada, clave al azar, archivo temporal en una carpeta restringida antes de escribirlo y borrado en `finally`.
   - El riesgo del borrado normal de los auxiliares, que el LEEME declara, lo doy por aceptable: quien pueda leer restos del disco de `M:` ya puede leer los discos de las VM.
   - **Falta:**
     - no imprimir la salida de `unattended install` (SL-03);
     - limpiar los restos de la clave dentro del invitado y en el medio auxiliar (SL-07);
     - restringir el ACL de la carpeta de la VM (SL-07).
3. **Redacción y política de copia.** Es el punto más débil.
   - La batería deja escapar el código de emparejamiento con los nombres reales del producto y las claves compuestas (SL-01), además de varios patrones genéricos (SL-10).
   - La política «binarios tal cual» contradice LS-11 (SL-02).
   - La negativa a escribir dentro de un repositorio git está bien hecha: recorre los padres, detecta también los *worktrees* porque `.git` puede ser un archivo y rechaza `GPOS-NG-Equipos`, lo que obliga al paso humano de revisión. Le falta rechazar las carpetas sincronizadas (SL-08).
4. **Acciones destructivas.**
   - Bien: `SupportsShouldProcess` con `ConfirmImpact = 'High'` en `Limpiar-Anfitrion.ps1:24`, `-WhatIf` y el apagado dentro del bloque `ShouldProcess`. `unregistervm --delete`, sin `--delete-all`, no borra la imagen ISO compartida [I: manual 7.2].
   - Huecos: SL-04 y SL-14.
5. **Inyección por argumentos.**
   - No hay inyección de intérprete de órdenes.
   - En Windows PowerShell 5.1, una comilla doble dentro de `-Descripcion` parte el argumento (verificado; SL-05).
   - Los nombres de los puntos de control están acotados por una lista de patrones admitidos (`Comun-Laboratorio.ps1:52`), lo cual está bien.

---

## 5. Hallazgos

### SL-01 · Media · La redacción no reconoce los nombres reales del producto

- **Riesgo.** LS-11 exige que `Recoger-Evidencia.ps1` no copie los códigos de emparejamiento ni el `Secreto` de la estación. La regla de pares clave=valor (`Comun-Laboratorio.ps1:280`) solo reconoce `codigo[_-]?emparejamiento`, `pairing[_-]?code` y palabras clave sueltas delimitadas por `\b`. El producto usa otros nombres [V]:
  - el código del alta y del canje se llama `Codigo` (`codigo` en JSON): `src/GPOS.Contracts/Restaurante/Dispositivos/Dispositivos.cs:112` (`EmparejamientoDto`) y `:116` (`EmparejarRequest`);
  - el QR SD-10 lo lleva en la clave `c`, `{"v":1,"c":código,…}`: `src/GPOS.Core/Servicios/Modulos/Restaurante/Dispositivos/ServicioDispositivos.cs:234`. Además viaja escapado dentro del campo `qr` del DTO;
  - el código tiene 8 caracteres Crockford y vale 10 minutos: `src/GPOS.Core/Dominio/Restaurante/Dispositivos/Dispositivo.cs:19`, `:106-118`.

  Resultados de la batería [V, PS 5.1 y 7]:
  - se escapan sin ningún reemplazo:
    - JSON con `"codigo"`;
    - JSON con `"c"`, en claro y escapado dentro de `qr`;
    - la etiqueta «Código de emparejamiento:», con tilde y espacios;
    - `userPassword` y `adminPassword`, que son el formato de la salida de VBoxManage, ver SL-03;
    - `SecretoEstacion`, `ClientSecret`, `client_secret` y `access_token`, porque `\b` no separa `_` ni el cambio de mayúscula;
  - se redactan a medias:
    - un valor entre comillas con espacios;
    - una clave con `;` entre comillas.

  El `Secreto` de la estación como `"secreto"` sí se redacta.
- **Probabilidad e impacto.** La probabilidad es alta: LAB-36 y los casos de la fase 2 producen justo esas respuestas JSON. El impacto es bajo: secretos de laboratorio, el código vence en 10 minutos y los dispositivos se revocan al terminar. La severidad queda en Media porque es el control que pide LS-11 y la evidencia redactada se publica en el área común.
- **Remediación** (unas 3 horas con las pruebas). En `Redactar-Texto`:
  1. Regla de contexto para el código, antes de la de pares: `(?i)(?<q>[\x5C]?["'])(?<k>codigo|c)\k<q>(?<s>\s*:\s*)(?<q2>[\x5C]?["'])[0-9A-HJKMNP-TV-Z]{8}\k<q2>` → `${q}${k}${q}${s}${q2}[REDACTADO]${q2}`. Conserva el escapado del `qr`. Redacta de más un `"codigo"` de negocio de 8 caracteres, cosa aceptable en evidencia de laboratorio.
  2. Etiqueta en texto: `(?i)(c[oó]digo(?:\s+de)?\s+(?:emparejamiento|alta|canje))(\s*[:=]?\s*)(\S+)` → `$1$2[REDACTADO]`.
  3. Sustituir la regla `:280` por una que acepte la palabra clave dentro de un nombre compuesto y consuma el valor entre comillas completo: `(?i)\b([\w.-]*?(?:password|passwd|pwd|contrase(?:ñ|n)a|clave|secreto|secret|token|api[_-]?key|codigo[_-]?emparejamiento|pairing[_-]?code)[\w.-]*)(\s*["']?\s*[:=]\s*)(?:(["'])[^"'\r\n]*\3|[^"'\s,;}<]+)` → `$1$2$3[REDACTADO]$3`.
  4. Añadir a `Probar-Redaccion.ps1` un caso por cada forma de la lista anterior, armando los secretos por partes como ya hace.

  El prototipo con estas reglas pasa los 13 casos actuales en PS 5.1 y 7.

### SL-02 · Media · Binarios copiados sin redactar por omisión

- **Riesgo.** `Recoger-Evidencia.ps1:103` y `:110-116` copian tal cual cualquier `.evtx`, `.png` o `.jpg`, aunque la ayuda dice «Todo pasa por la redacción» (`:10`).
  - Una captura de LAB-36 (alta manual o por QR) o de la pantalla de alta de un dispositivo contiene el código y el QR SD-10, con la URL y los SPKI. Es justo lo que LS-11 prohíbe copiar.
  - Un `.evtx` no tiene por qué ser solo CAPI2: el de Aplicación recoge lo que escriban la API y sus dependencias, y el de Seguridad trae cuentas y nombres de equipo.
- **Remediación** (1 hora).
  1. Por omisión, los binarios se tratan como «NO copiado: solo presencia».
  2. Se copian únicamente con `-IncluirBinarios <nombres>`, una lista explícita de archivos, y el manifiesto los marca con `Tratamiento = 'sin redactar: revisión visual obligatoria del auditor'`.
  3. Para CAPI2, exportar dentro de la VM a XML (`wevtutil qe Microsoft-Windows-CAPI2/Operational /f:xml`) para que pase por la redacción.
  4. Escribir en el procedimiento de B que no se capturen las pantallas del código ni del QR.

### SL-03 · Media · La salida de `unattended install` se imprime

- **Riesgo.**
  - `Crear-VmLaboratorio.ps1:141` manda cada línea de `unattended install` a `Escribir-Info`.
  - Si VBoxManage falla, `Invocar-VBox` mete toda la salida en el mensaje de la excepción (`Comun-Laboratorio.ps1:135`).
  - [I] `VBoxManage unattended install` imprime un bloque «Using values:» con los valores efectivos, entre ellos las claves. Lo sé por el código fuente de las versiones 6.1 y 7.0; no lo verifiqué en la 7.2.22.
  - Si es así, la clave queda en texto plano en la consola, en cualquier transcripción y, si el guion lo lanza un agente, en el registro de la conversación guardado en disco. Eso choca con ADR-44 y con la frase del LEEME «Nunca va en la línea de órdenes» (`LEEME.md:84`), que es cierta pero incompleta.
  - La regla de redacción actual tampoco reconoce `userPassword` ni `adminPassword` (SL-01).
- **Remediación** (30 minutos).
  1. `unattended install` con la salida descartada: imprimir solo «terminó con código N».
  2. Añadir a `Invocar-VBox` un `-SalidaSensible` que omita la salida en el mensaje de error, o que la pase por `Redactar-Texto` ya corregido.
  3. B confirma en la primera ejecución en `LFMB` si la 7.2.22 imprime las claves. Si las imprimió antes de esta corrección, rehace la VM: clave nueva.

### SL-04 · Media · Borrado recursivo sin comprobar puntos de reanálisis; raíz parametrizable

- **Riesgo.**
  - `Confirmar-RutaDentroDe` (`Comun-Laboratorio.ps1:94-100`) compara textos de ruta: no resuelve *junctions* ni enlaces simbólicos.
  - `Remove-Item -LiteralPath … -Recurse -Force` (`Cerrar-Preparacion.ps1:65`, `Limpiar-Anfitrion.ps1:69`) borra un árbol que puede contener un punto de reanálisis. Uno típico: alguien mueve `Snapshots` o `Logs` a otra unidad con un *junction*.
  - [I] En Windows PowerShell 5.1, `Remove-Item -Recurse` puede recorrer el enlace y borrar el contenido del destino. Es un comportamiento conocido de 5.1, corregido en PowerShell 7; no lo probé aquí porque el encargo prohíbe borrar.
  - `Get-ChildItem -Recurse` (`Recoger-Evidencia.ps1:104`) también puede seguir *junctions* en 5.1 [I] y copiar archivos de fuera de `-CarpetaInvitado`.
  - Además, `-CarpetaVm` es un parámetro libre en los 6 guiones. La constante `$script:CarpetaVmPorOmision` (`Comun-Laboratorio.ps1:26`) está definida pero ningún guion la usa. Con `-CarpetaVm C:\` la garantía «solo dentro de `M:\VM`» desaparece. El marcador se sigue exigiendo, así que no se borra una VM ajena, pero sí una del laboratorio que viva en cualquier sitio.
- **Probabilidad e impacto.** Probabilidad baja; impacto alto e irreversible fuera del laboratorio, en la PC de trabajo de B, que tiene sus repositorios.
- **Remediación** (1 a 2 horas).
  1. Raíz fija: usar `$script:CarpetaVmPorOmision`. Otra raíz solo con `-PermitirOtraRaiz`, y aun así rechazar la raíz de una unidad, `%USERPROFILE%`, `%SystemRoot%`, `%ProgramFiles%` y cualquier ruta dentro de un repositorio git.
  2. Antes de borrar, recorrer el árbol, sin seguir enlaces, junto con la raíz y cada antecesor, y detenerse si algún elemento tiene el atributo `ReparsePoint`.
  3. Borrar con `[System.IO.Directory]::Delete($ruta, $true)`, que elimina el enlace sin entrar en él [I: comportamiento de .NET], o exigir PowerShell 7 para los guiones que borran.
  4. En `Recoger-Evidencia.ps1`, saltar los directorios con `ReparsePoint` y dejarlos anotados en el manifiesto.

### SL-05 · Baja · Inyección de argumentos en 5.1 y parámetros libres

- **Riesgo.**
  - `-Descripcion` (`Puntos-Control.ps1:29`) se concatena en `--description=` (`:62`). En Windows PowerShell 5.1, una comilla doble dentro del texto parte el argumento y añade opciones a `snapshot take` [V: probado con un programa nativo en 5.1.26100; en 7.6 llega entero]. El texto lo escribe el propio operador, así que no hay frontera de privilegios, pero basta pegar un texto con comillas.
  - `-Usuario`, `-Idioma` y `-TipoSo` (`Crear-VmLaboratorio.ps1:41`, `:46-47`) no se validan y van a las plantillas de la instalación desatendida. Que VirtualBox escape el YAML de Ubuntu es [I].
- **Remediación** (30 minutos).
  - Defensa central: `Invocar-VBox` rechaza cualquier argumento que contenga `"` o caracteres de control.
  - Validaciones:
    - `-Descripcion`: `ValidatePattern('^[\p{L}\p{N} .,:;()_+/-]{0,200}$')`;
    - `-Usuario`: `^[a-z][a-z0-9_-]{2,19}$`;
    - `-Idioma`: `^[a-z]{2}_[A-Z]{2}$`;
    - `-TipoSo`: debe estar en `Get-TiposSo`.

### SL-06 · Baja · Identidad por nombre y falla abierta en la lista de puntos de control

- **Riesgo.**
  - Todas las operaciones usan el nombre de la VM y el de la instantánea. VirtualBox admite instantáneas con el mismo nombre [I], por ejemplo una tomada a mano desde la interfaz. `Limpiar-Anfitrion.ps1:49-53` filtra por marcador, pero borra **por nombre**, y puede borrar otra instantánea con el mismo nombre que no lleve el marcador. Lo mismo pasa en `Puntos-Control.ps1:84-87`.
  - `Get-PuntosControl` (`Comun-Laboratorio.ps1:224`) trata cualquier fallo de VBoxManage como «sin instantáneas»: si la VM está bloqueada por otra sesión, `Cerrar-Preparacion.ps1:39` no ve «base» y toma una segunda.
- **Remediación** (1 hora).
  - Leer `SnapshotUUID-n` y operar por UUID; detenerse si un nombre aparece repetido.
  - Resolver una vez el UUID de la VM y exigir que su nombre sea único.
  - Aceptar el fallo como lista vacía solo si la salida coincide con el mensaje de «sin instantáneas» que B confirme en la 7.2.22.

### SL-07 · Baja · Restos de la clave desatendida fuera de `desatendida\`

- **Riesgo.**
  1. **Dentro del invitado [I].**
     - Windows Setup deja copias en `C:\Windows\Panther\`. Si la plantilla de VirtualBox configura el inicio de sesión automático, la clave queda en `Winlogon\DefaultPassword` o como secreto LSA.
     - Ubuntu guarda el *hash* en `/var/log/installer/autoinstall-user-data`.
     - El punto de control «base» los conserva en todas las fases.
  2. **En el medio auxiliar [I].** `unattended install` puede montar su medio auxiliar (VISO) en otra unidad. Entonces `Cerrar-Preparacion.ps1:56` (SATA, puerto 1) no lo desmonta, y el registro de medios queda apuntando a archivos ya borrados.
  3. **En el ACL de la carpeta de la VM [I].** `credencial.dpapi.json` (`Crear-VmLaboratorio.ps1:131-132`) y los discos de la VM heredan el ACL de `M:\VM`. En un volumen que no es de sistema, ese ACL suele dar Modificar a «Usuarios autenticados» [I: B lo comprueba con `icacls M:\VM`]. Importa con la opción 3 del rediseño, 4 (una cuenta de Windows aparte para A).
  4. **Sin forma de leer la clave.** No hay un guion para leer la credencial, así que el operador improvisará y puede acabar imprimiéndola.
- **Remediación.**
  - `Preparar-Vm.ps1` y `preparar-vm.sh` (de B, fuera de este PR) borran esos restos y desactivan `AutoAdminLogon` antes de «base». Opcional: rotar la clave en el invitado.
  - `Cerrar-Preparacion.ps1` se detiene si `showvminfo` muestra algún medio con ruta bajo `desatendida\`.
  - `Restringir-Carpeta` sobre la carpeta de la VM al crearla.
  - Un `Leer-Credencial.ps1` que copie la clave al portapapeles del anfitrión y lo vacíe a los 30 segundos, sin imprimirla.
  - Esfuerzo: 1 hora más lo que toque a B dentro de la VM.

### SL-08 · Baja · La salida de la evidencia acepta carpetas sincronizadas

- **Riesgo.** `Recoger-Evidencia.ps1:46-53` solo rechaza los repositorios git. Una `-Salida` en OneDrive, carpeta que B ya usa para los paquetes del DEMO, sube a la nube los binarios sin redactar de SL-02 antes de la revisión del auditor.
- **Remediación** (15 minutos). Exigir que `-Salida` quede bajo `M:\VM\evidencia`, o rechazar las rutas bajo `$env:OneDrive`, `$env:OneDriveConsumer`, `$env:OneDriveCommercial` y `%USERPROFILE%`.

### SL-09 · Baja · Huella completa de archivos pequeños no copiados

- **Riesgo.** El manifiesto publica el SHA-256 completo de cada archivo no copiado (`Recoger-Evidencia.ps1:118-119`). Si un archivo contiene solo un secreto corto, se recupera por fuerza bruta: el código de emparejamiento son 40 bits, y un PIN de mesero menos. La huella truncada de los blobs DPAPI (`Comun-Laboratorio.ps1:287`) es de texto cifrado y no tiene ese problema.
- **Remediación** (15 minutos). Para archivos de menos de 256 bytes, anotar solo la presencia y el tamaño; o usar HMAC-SHA256 con una llave por recogida guardada con DPAPI en el anfitrión, que no se publica.

### SL-10 · Baja · Patrones genéricos que se escapan y texto UTF-16

- **Riesgo** [V, batería]. Se escapan:
  - `Authorization: Basic …` y los encabezados `Cookie` y `Set-Cookie`;
  - `sqlcmd … -P <clave>`, `-Password <clave>` y `ConvertTo-SecureString '<clave>'`;
  - *hashes* bcrypt (`$2b$`) y argon2;
  - una llave PEM sin la línea `END` (registro truncado);
  - una llave PKCS#8 o SEC1 P-256 en base64 sin cabecera PEM. El oráculo usa P-256;
  - las cargas de Data Protection (`CfDJ8…`): cadenas de conexión cifradas o *cookies*;
  - `<masterKey>` y `<encryptedSecret>` del anillo, que con `CifradorAnillo` no lleva la cabecera DPAPI;
  - un JWE de 5 partes;
  - un valor YAML de bloque (`password: |`).

  Además, `ReadAllText` (`Recoger-Evidencia.ps1:108`) lee como UTF-8 un archivo UTF-16 sin BOM: el texto queda con NUL intercalados, ninguna regla coincide y se copia como «redactado» con 0 reemplazos.
- **Remediación** (1 hora). El prototipo cubre todos los casos menos YAML y UTF-16 con estas reglas:
  - `(?i)\b((?:Proxy-)?Authorization)(\s*[:=]\s*)([A-Za-z][\w+.-]*)\s+[^\s"',;]+` y `(?i)\b(Set-Cookie|Cookie)(\s*:\s*)[^\r\n]+`;
  - `(?i)(?<=^|\s)(--?(?:password|passwd|pwd|secret|token|clave))(\s+|=)("[^"]*"|'[^']*'|\S+)`, más `-P` en mayúscula y sin `(?i)`;
  - `(?i)(ConvertTo-SecureString\s+(?:-String\s+)?)("[^"]*"|'[^']*')`;
  - `\$(?:[1-7y]|2[abxy]|argon2(?:id|i|d))\$[^\s"':]{8,}`;
  - el PEM sin `END` hasta el final del texto, después de la regla del PEM completo;
  - presencia y huella para:
    - `(?:MIG[HT]AgEAMBMGByqGSM49AgEGCCqGSM49AwEH|MHcCAQEEI|MIIE[vw]AIBADANBgkqhkiG9w0BAQEFAAS)[A-Za-z0-9+/=]*`;
    - `\bCfDJ8[A-Za-z0-9_-]{16,}`;
    - `(?is)<(encryptedSecret|masterKey)\b.*?</\1>`;
  - JWE `eyJ[A-Za-z0-9_-]{5,}(?:\.[A-Za-z0-9_-]*){4}`, antes de la regla del JWT.

  Para UTF-16: leer con `UTF8Encoding($false, $true)`, que lanza ante bytes no válidos, y tratar como no copiable todo texto con `\0`. Para YAML: no copiar archivos `.yaml` o `.yml` que contengan `password:` seguido de `|` o `>`.

### SL-11 · Baja · VRDE y carpetas compartidas no se fijan ni se comprueban

- **Riesgo** [I].
  - Para ver una VM sin ventana, el operador puede activar VRDE.
  - Con el paquete de extensiones, el servidor RDP de VirtualBox escucha en todas las interfaces del anfitrión, y por omisión sin autenticación. La consola de la VM quedaría expuesta a la red local de `LFMB`.
  - `Cerrar-Preparacion.ps1:43-53` solo comprueba las tarjetas de red antes de «base»: no mira VRDE ni las carpetas compartidas.
- **Remediación** (20 minutos).
  1. `--vrde=off` en `Crear-VmLaboratorio.ps1:99-104`.
  2. `Cerrar-Preparacion.ps1` exige `vrde="off"` y que no haya `SharedFolderName*` en `showvminfo`.
  3. Si alguna vez hace falta VRDE: `--vrde-address=127.0.0.1` con autenticación externa.

### SL-12 · Baja · «Una VM a la vez» y la memoria no se aplican al arrancar

- **Riesgo.** `Crear-VmLaboratorio.ps1 -Arrancar` (`:140`, `:150-151`) y el arranque posterior no comprueban qué VM corren ni la memoria libre. Esa comprobación solo existe en `Preparar-Anfitrion.ps1:68-93`, que es un paso aparte. En la PC de trabajo de B, una tercera VM o una sin memoria pone en riesgo la estabilidad del anfitrión.
- **Remediación** (30 minutos). Llevar la comprobación de memoria y de VM ajenas a una función de `Comun-Laboratorio.ps1` y llamarla antes de todo arranque.

### SL-13 · Baja · VBoxManage sin verificación de firma

- **Riesgo.** `Resolver-VBoxManage` (`Comun-Laboratorio.ps1:107-118`) acepta cualquier ruta que le den: el parámetro, la variable de entorno o el primer `VBoxManage.exe` del PATH. Un ejecutable colocado en una carpeta del PATH en la que el usuario puede escribir correría con los argumentos del laboratorio.
- **Remediación** (15 minutos). `Get-AuthenticodeSignature` con `Status = Valid` y el firmante de Oracle (el sujeto exacto lo confirma B [I]); preferir la ruta bajo `%ProgramFiles%`.

### SL-14 · Baja · Confirmaciones de las acciones destructivas

- **Riesgo.**
  - `-Vm` vale por omisión las tres VM (`Limpiar-Anfitrion.ps1:27`): `-Accion Eliminar` sin `-Vm` las apunta a todas, y la respuesta «Sí a todo» del aviso de confirmación las borra.
  - `Puntos-Control.ps1` tiene `ConfirmImpact = 'Medium'` (`:24`): borrar «base» con `-IncluirBase` (`:83`) no pide confirmación.
  - Si `Crear-VmLaboratorio.ps1` falla entre `createvm` y `setextradata` (`:90-92`), la VM queda registrada sin marcador. Falla cerrada, pero `Limpiar-Anfitrion.ps1` tampoco la limpia y hay que hacerlo a mano.
- **Remediación** (20 minutos).
  - `-Vm` obligatorio con `-Accion Eliminar`.
  - `ConfirmImpact` alto, o `$PSCmdlet.ShouldContinue`, para borrar «base».
  - En `Crear-VmLaboratorio.ps1`, un `try/catch` que, si falla después de `createvm`, imprima la orden exacta de limpieza manual.

### SL-15 · Baja · Inexactitudes del LEEME (C6)

- **Evidencia.**
  - `LEEME.md:69` dice que todos los guiones exigen la versión. Solo lo hacen `Preparar-Anfitrion.ps1:51-52` y `Crear-VmLaboratorio.ps1:61-62`. `$script:VersionVBoxEsperada` (`Comun-Laboratorio.ps1:27`) no se usa.
  - `LEEME.md:84` omite la salida de SL-03.
  - El cambio de `.gitignore` de LS-11 sigue pendiente (`.gitignore:241` solo tiene `*.pfx`). El LEEME lo declara fuera de este PR, lo cual es correcto, pero debe entrar antes de la primera recogida.
- **Remediación** (20 minutos). `Confirmar-VersionVBox` en `Comun-Laboratorio.ps1`, llamada después de `Resolver-VBoxManage` en todos los guiones, y corregir el LEEME.

---

## 6. Controles bien implementados

- **Guarda positiva del anfitrión:** con dos fuentes, sensible a mayúsculas, en falla cerrada y antes de cualquier efecto en los 7 guiones que operan.
- **Triple condición para tocar una VM:** catálogo (`ValidateSet`), marcador y `.vbox` dentro de la raíz. Para eliminar se añaden «no es la raíz» y «la carpeta se llama como la VM». Las VM ajenas se listan y no se tocan.
- **Clave:** 192 bits de `RandomNumberGenerator`, nunca en la línea de órdenes. La carpeta se restringe (sin herencia: el usuario, SYSTEM y Administradores) **antes** de escribir el archivo, que se borra en `finally`. La credencial se guarda con DPAPI antes de instalar.
- **Red:** red interna; NAT solo para preparar, retirado y comprobado de forma positiva en las tarjetas 2 a 8 antes de «base». Sin portapapeles, sin arrastrar y soltar, sin audio.
- **Integridad:** SHA-256 de la imagen antes de crear nada; versión fija 7.2.22.
- **Evidencia:**
  - todo tipo desconocido queda sin copiar, con su presencia;
  - carpeta restringida y nueva en cada recogida;
  - negativa a escribir dentro de un repositorio git, incluidos los *worktrees*;
  - manifiesto con huellas;
  - los blobs DPAPI quedan como presencia y huella truncada.
- **Sin inyección de intérprete:** los argumentos van como arreglo; los nombres de los puntos de control tienen una lista de patrones admitidos.
- **Destructivo:** `ShouldProcess` con confirmación alta y `-WhatIf` en la limpieza; el apagado está dentro del bloque confirmado; `--delete` y no `--delete-all`.
- **Honestidad:** cada orden lleva su marca [V] o [I], y el LEEME declara lo no probado y el riesgo de los auxiliares. `Probar-Redaccion.ps1` arma los secretos falsos por partes.
- **Sin secretos en el repositorio:** revisé los 10 archivos y la única huella es la pública de la imagen de Ubuntu.

---

## 7. Remediaciones priorizadas

| Orden | Hallazgos | Cuándo | Esfuerzo |
|---|---|---|---|
| 1 | SL-03 | Antes de que B ejecute por primera vez `Crear-VmLaboratorio.ps1 -Desatendida` | 30 min |
| 2 | SL-04 y SL-14 | Antes de la primera ejecución de `Cerrar-Preparacion.ps1` o `Limpiar-Anfitrion.ps1` | 2 h |
| 3 | SL-01, SL-02, SL-08, SL-09 y SL-10, con sus casos en `Probar-Redaccion.ps1`, más el `.gitignore` de LS-11 | Antes de la primera ejecución de `Recoger-Evidencia.ps1` | 5 h |
| 4 | SL-05, SL-06, SL-11, SL-12, SL-13 y SL-15 | En el mismo PR, si cabe; si no, antes de la fase 1 | 3 h |
| 5 | SL-07 (la parte del invitado) | Con los guiones de dentro de la VM (B) | 1 h + B |

Lo más barato que cierra el riesgo es corregir todo en este mismo PR antes de unirlo: son cambios locales en 4 archivos y no tocan el diseño. Alternativa descartada: unir ahora y corregir después. Exigiría que B se acuerde de no recoger evidencia ni limpiar hasta tener las correcciones, y esa dependencia de la memoria es justo lo que las guardas quieren evitar.

---

## 8. Recomendación

**Aprobado con observaciones** (recomendación técnica, C2). No hay hallazgos Críticos ni Altos: se puede abrir el PR. Recomiendo no pedir la unión hasta corregir los 4 Medios (SL-01 a SL-04), y en todo caso aplicarlos antes de los usos indicados en la sección 7. La unión la ordena el propietario.

### Supuestos
1. El comportamiento de VirtualBox 7.2.22 es [I]: que imprima las claves en «Using values» (SL-03), los nombres repetidos de las instantáneas (SL-06), el medio auxiliar VISO (SL-07) y VRDE sin autenticación (SL-11).
2. Lo de Windows PowerShell 5.1 con `Remove-Item -Recurse` y `Get-ChildItem -Recurse` ante *junctions* (SL-04) es [I] y no lo probé, porque el encargo prohíbe borrar. El paso de argumentos con comillas (SL-05) sí está verificado.
3. Que el ACL por omisión de `M:\VM` dé Modificar a «Usuarios autenticados» (SL-07) es [I].
4. Que `LFMB` tenga una sola cuenta de Windows hoy. Si se adopta la opción 3 del rediseño, 4, SL-07 punto 3 sube de prioridad.
5. Los nombres de los campos del producto se leyeron en `origin/feature/modelo-ng` `e3e729c1`.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-21-revision-seguridad-scripts-laboratorio.md` (nuevo)
- Supuestos: los cinco de arriba
- Decisiones candidatas a ADR: Ninguna (herramienta de laboratorio, no arquitectura del producto)
- Entregas a otros agentes:
  - devops de C: corregir SL-01 a SL-06 y SL-08 a SL-15 en la rama `c/laboratorio-adr090-scripts`, con los casos nuevos en `Probar-Redaccion.ps1`;
  - devops de B:
    - confirmar en `LFMB` los [I] de SL-03, SL-06, SL-07 y SL-11, y el ACL de `M:\VM`;
    - en `Preparar-Vm.ps1` y `preparar-vm.sh`, borrar los restos de la instalación desatendida y desactivar `AutoAdminLogon` antes de «base» (SL-07);
    - el `.gitignore` de LS-11;
  - auditor-seguridad: revisar la primera evidencia real antes de que se publique en el área común (diseño v3, 7.4).
- Próximo paso recomendado: el devops de C aplica SL-01 a SL-04 en la misma rama, vuelve a correr `Probar-Redaccion.ps1` con los casos nuevos y abre el PR sobre `feature/modelo-ng` con este informe enlazado.
