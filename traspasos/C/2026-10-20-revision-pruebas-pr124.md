```
Para: B (y A, autor)            De: C (QA)                    Fecha: 2026-10-20
Tipo: Revisión de pruebas, solo lectura (tarea 2 del encargo del 2026-10-20)
PR: #124 (O-1 y O-3 de ADR-77, puntos 3 y 6), rama a/instalador-o1-o3 @ f0aa9126, contra feature/modelo-ng @ b8f166db
Estado: Abierto
```

# Revisión de pruebas del PR #124 (acción previa compartida del instalador y raíz/config con GUID fijos)

## Dictamen: Aprobado con observaciones (sin hallazgos Críticos ni Altos)

La lógica pura y la que toca el disco sin elevación están bien probadas: la decisión de dueño y ACE, las invariantes de la tabla (S-01, S-02), la ruta final con uniones reales (S-09) y el vector v3 contra los `.wxs`. Los huecos están en lo que la suite no puede ver: la capa DTF (`AccionesInstalador.cs`, 0 % de ejecución), el efecto de crear la raíz antes de comprobar la ruta final, y los controles pendientes (S-04, S-06, S-07), que no tienen una prueba que fije lo que se decida. Todo lo elevado (SYSTEM, 1603 real, FIPS, firma) sigue en laboratorio y el PR lo declara (P-O1-7, P-O1-8, P-O3-4, P-O1-6).

**Alcance y método.** Lectura de `git diff b8f166db origin/a/instalador-o1-o3` y de los archivos en `f0aa9126`, con el informe de seguridad de A (`traspasos/A/revision-seguridad-o1-o3-2026-10-20.md`) como insumo. No compilé ni ejecuté nada (encargo). No leí el blueprint v2 de A: la trazabilidad usa los identificadores S-nn y P-O1-n que citan el informe y las propias pruebas. Lo marcado *inferido* sale de leer el código; no se comprobó en ejecución. Rutas: **CCP** = `instalador/Comun/GPOS.Instalador.Acciones/ComprobacionCarpetasPrevias.cs`; **AI** = `.../AccionesInstalador.cs`; **PCP** = `tests/GPOS.Tests/Instalador/ComprobacionCarpetasPreviasTests.cs`; **PFI** = `tests/GPOS.Tests/Instalador/FragmentosInstaladorTests.cs`.

## Trazabilidad: hallazgo de seguridad de A → prueba

| Hallazgo | Prueba que lo cubre | Veredicto (por lectura) |
|---|---|---|
| S-01 (a) una sola raíz, (b) todo bajo la raíz, (c) cadena completa de padres | `La_tabla_tiene_una_sola_raiz_todo_cuelga_de_ella_con_la_cadena_completa_de_padres_S_01` (PCP:334-377) | Cubierto. Quitar el bucle de antepasados (CCP:389-397) rompe PCP:354-355 |
| S-01 ruta final (`GetFinalPathNameByHandleW`) | `La_ruta_final_tiene_que_ser_la_pedida_sin_prefijo_ni_mayusculas_S_01` (PCP:403-422, función pura) y `Una_union_real_como_intermedio_...` (PCP:541-578, real) | Cubierto. Quitar la comparación de CCP:591-595 rompe PCP:568-570 |
| S-02 hoja si hay servicio | `Una_carpeta_con_escritor_de_servicio_solo_puede_ser_hoja_S_02` (PCP:380-398) | Cubierto |
| S-03 FIPS | `Un_fallo_al_avisar_...` (PCP:427-465) y `La_accion_no_usa_hashes_administrados_...` (PFI:209-223) | Parcial: guardas de texto; la rama `net472` no corre en ninguna prueba (P124-03) |
| S-04 firma de la `.CA.dll` | Ninguna | Pendiente de A/devops; sin prueba que fije el cambio (P124-08) |
| S-05 `Id` privado | PFI:256 (`Any(char.IsLower)` en todas las filas) y `EstacionInstaladorTests` renombrada | Cubierto |
| S-06 acción sin la *feature* | PFI:182 solo fija la condición actual `NOT REMOVE ~= "ALL"` | Decisión pendiente (P124-08) |
| S-07 GUID de la raíz | PFI:78-122 fija el GUID del vector; `guidRetirados` solo mira el primero (PFI:119) | Pendiente de decisión (P124-07, P124-08) |
| S-09 uniones reales | PCP:500-538, 541-578, 581-606 (hoja, hacia `C:\Windows`, intermedio, raíz plantada) | Cubierto; ver P124-02 para el caso que falta |
| S-10 texto «se creó la raíz» | `TextoSinCambios` en PCP:459-461 y el mensaje 25101 en PFI:189-191 | Parcial: el cableado en AI:106-117 no tiene prueba (P124-01) |
| S-11 sin eventos con el agente solo | Comentario en `ComprobacionCarpetasPrevias.wxs:16-17` | Documental; sin prueba (no hace falta) |

## Cobertura (y política aplicada)

No se midió (no puedo ejecutar). Política por omisión: 70 % de líneas en el código modificado de módulos críticos (seguridad). **Estimación por lectura, *inferida*:** CCP queda en 75-80 % (sin cubrir: ramas de error de Win32, P124-04) y AI en 0 % (no se enlaza en el proyecto de pruebas: `GPOS.Tests.csproj` solo incluye `ComprobacionCarpetasPrevias.cs`). Sumadas, el cambio queda en el borde de la política. Pedir la medición a B con el filtro de clases `ComprobacionCarpetasPreviasTests` y `FragmentosInstaladorTests` (sin la suite completa).

## Hallazgos

### P124-01 · Media · La capa de la acción (`AccionesInstalador.cs`, corre como SYSTEM) no tiene ninguna prueba que se ejecute
- **Evidencia:** AI:22-58 (la consulta de la tabla en :33 y los índices `GetString(2)`, `GetString(3)`, `GetInteger(4)`, `GetInteger(5)` en :40-42), AI:67-129 (los tres mensajes de rechazo y el 25101); `GPOS.Tests.csproj` no enlaza AI (depende de DTF); PFI:174-177 solo comprueba por expresión regular que existen los puntos de entrada.
- **Riesgo:** un índice cambiado (por ejemplo, `CrearSiFalta` leído de la columna equivocada) deja la raíz sin crear o la tabla leída al revés, y solo lo vería P-O1-7, que no se ha corrido. Lo mismo si un mensaje deja de pasar `raizCreada` a `TextoSinCambios` (S-10).
- **Pruebas propuestas** (en el mismo estilo de guarda de código que ya aceptó el PR para S-03; sin tecnología nueva):
  - `FragmentosInstaladorTests.La_accion_inmediata_lee_las_columnas_en_el_orden_del_SELECT_y_del_fragmento`: extrae del texto de AI la lista del `SELECT` y los índices de `registro.Get…`, y los compara con el orden de las `Column` de `CustomTable` en el `.wxs`.
  - `FragmentosInstaladorTests.Los_tres_mensajes_de_rechazo_usan_TextoSinCambios_con_la_raiz_creada`: `TextoSinCambios(raizCreada)` aparece en el registro, en el 4753 y en el 4754.

### P124-02 · Media · La raíz se crea antes de comprobar la ruta final: el caso «el padre de la raíz es una unión» no tiene prueba
- **Evidencia:** CCP:541-551 (`CrearConDescriptor` se ejecuta primero) frente a CCP:591-595 (la ruta final se mira después); el estado `Creada` se fija en :574-577 antes del rechazo. PCP:581-606 prueba la raíz *como* unión (último componente, 183), no una raíz *bajo* una unión. La remediación S-01 (2) se describió como defensa para los antepasados fuera de la tabla, como `C:\ProgramData`.
- **Qué pasa (*inferido*):** `CreateDirectoryW("C:\ProgramData\GPOS NG")` con `C:\ProgramData` convertido en unión crea la carpeta en el destino con la DACL protegida; después la ruta final no coincide y se rechaza con `PUNTO_DE_REANALISIS`. El impacto es bajo (una carpeta vacía y protegida, y la instalación falla), pero ninguna prueba fija cuál de las dos conductas se quiere.
- **Prueba propuesta:** `ComprobacionCarpetasPreviasTests.Una_raiz_cuyo_padre_es_una_union_se_rechaza_por_la_ruta_final`: `mklink /J padre destino`, fila `padre\GPOS NG` con `CrearSiFalta=1`; afirma `PUNTO_DE_REANALISIS` y la conducta elegida por A: (a) se documenta que queda creada (`creadas` contiene la raíz, texto de S-10) o (b) se comprueba antes de crear y `Directory.EnumerateFileSystemEntries(destino)` queda vacío. La elección es de A; con cualquiera, la prueba la fija.

### P124-03 · Baja · Una aserción de la guarda S-03 pasa sin comprobar nada
- **Evidencia:** PFI:221-222 (`Assert.All` sobre las coincidencias de la expresión regular): si un cambio de formato (`Evento(` y salto de línea) hace que no haya ninguna coincidencia, `Assert.All` sobre una colección vacía pasa. Lo mismo, con menos riesgo, en PFI:214-215 (que sí compara una lista exacta).
- **Prueba propuesta:** en `La_accion_no_usa_hashes_administrados_...`, agregar `Assert.Equal(3, coincidencias.Count)` (hay tres llamadas a `Evento` en AI:86, :109 y :115).
- **Limite conocido:** la rama `#if NETFRAMEWORK` de `Sha1` y `Sha256` (CCP:238-243, :249-254) no se ejecuta en ninguna prueba (son `net10.0`). La prueba con la directiva FIPS activa es P-O1-7 (laboratorio).

### P124-04 · Baja · Las ramas de error de Windows de `ComprobarUna` no tienen prueba
- **Evidencia:** CCP:533-538 (servicio no válido), :555-571 (`CreateFile` con un error distinto de 2 y 3, y «desapareció tras crearla»), :579-582 (`GetFileInformationByHandle`), :597-609 (descriptor ilegible y `ArgumentException`), :655-678 (la ruta final más larga que el búfer inicial). `Decidir` y `DecidirCreacion` sí se prueban en forma pura.
- **Pruebas propuestas:**
  - `Una_carpeta_que_no_se_puede_abrir_falla_cerrado_con_CreateFile_5`: carpeta temporal con una ACE de denegación al propio usuario sobre `FILE_READ_ATTRIBUTES` (el dueño puede quitarla en el `finally`; sin elevación).
  - `Un_servicio_con_nombre_no_valido_en_la_fila_es_SEGURIDAD_ILEGIBLE` (llamando a `ComprobarUna` con `Servicio = "GPOS|Api"`).
  - `La_ruta_final_mas_larga_que_el_bufer_se_lee_completa` (solo si el entorno admite rutas largas; si no, `Skip` explícito).

### P124-05 · Baja · La máscara de escritura no se prueba bit por bit
- **Evidencia:** CCP:174 (`0x500D0156`) y CCP:786. PFI:131 ata la constante al vector, pero los casos de PCP:70-77 cubren `FA`, `0x1301bf`, `GW`, `0x4`, `WD`, `0x40`. Sin caso: `GA`, `WO`, `SD`, `0x2` (escribir datos), `0x10` (EA) y `0x100` (atributos).
- **Prueba propuesta:** `ComprobacionCarpetasPreviasTests.Cada_bit_de_la_mascara_de_escritura_hace_escritor_y_ninguno_de_lectura_lo_hace` (`[Theory]` con los 13 bits de la máscara y los de lectura `0x1`, `0x8`, `0x20`, `0x80`, `0x20000`, `0x100000`).

### P124-06 · Baja · Pruebas dependientes del entorno
- **Evidencia:** PCP:515 exige como precondición, con `Assert.Null`, que `C:\Windows` pase la comprobación de producción (falla en un equipo con otro dueño o ACL, en lugar de omitirse); PCP:307-329 supone que `%TEMP%` es el perfil del usuario (con un ejecutor que corra como servicio, `C:\Windows\Temp` hereda una ACE de escritura para Usuarios y la segunda aserción, `Assert.Null`, fallaría); la clase lleva `[SupportedOSPlatform("windows")]`, que solo avisa al analizador y no omite en otro sistema.
- **Propuesta:** convertir las precondiciones en una omisión explícita con el motivo (el patrón de atributo con `Skip` que ya usa el proyecto, por ejemplo `Rg14Lote2Tests.cs:24`), para que el recuento de omitidas lo muestre.

### P124-07 · Baja · `guidRetirados` se comprueba solo para el primer elemento
- **Evidencia:** PFI:119 (`guidRetirados[0]`). Si S-07 se resuelve regenerando el GUID de la raíz, el anterior pasa a ser un segundo retirado y la prueba no lo vigilaría.
- **Prueba propuesta:** recorrer todos los `guidRetirados` en `El_GUID_el_SDDL_y_los_atributos_de_la_raiz_y_de_config_coinciden_con_el_vector_v3`.

### P124-08 · Media · Los controles que el PR deja pendientes no tienen la prueba que los fijará
Condición de A para retirar K1-02 (S-04) y de B para el *bundle*; conviene escribir la prueba junto con el cambio, no después.
- **S-04** (firma): `FragmentosInstaladorTests.construir_ps1_con_Firmar_compila_la_accion_con_SigntoolFirma_firma_la_CA_dll_y_falla_si_no_esta_firmada` (guarda de texto sobre `instalador/AgenteImpresion/construir.ps1`, como la que ya existe para `-EstacionDesarrollo -Firmar`, `EstacionInstaladorTests.cs:217`).
- **S-06** (acción sin la *feature*): según la decisión, `La_accion_solo_corre_si_la_feature_que_declara_carpetas_se_instala` o una prueba que documente la conducta aceptada; hoy PFI:182 fija `NOT REMOVE ~= "ALL"` y se romperá con el cambio.
- **S-07** (GUID): ver P124-07.

### P124-09 · Baja · «El MSI normal no enlaza la acción» se prueba solo por la posición del XML
- **Evidencia:** `EstacionInstaladorTests` (el diff agrega la comprobación de que el `DirectoryRef` y la `CustomTableRef` están dentro de la rama `EstacionDesarrollo`); el `.wixproj` incluye los dos fragmentos en toda compilación (`GPOS.AgenteImpresion.Instalador.wixproj`), y que el enlazador descarte un fragmento sin referencias es un comportamiento de WiX, no una aserción de la suite (*inferido*).
- **Propuesta:** anotar en P-O1-8 la comprobación de laboratorio «el `.msi` normal no tiene la tabla `GposCarpetaPrevia` ni la `.CA.dll`», porque K1-02 depende de ello.

## Lo que está bien (verificado por lectura)
- Pruebas de decisión con descriptores sintéticos y con carpetas reales sin elevación, en las dos direcciones (rechaza y acepta): PCP:56-96.
- Las uniones reales cubren las cuatro formas de ataque (hoja, hacia una carpeta que pasa la lista blanca, intermedio y raíz plantada) y la limpieza no sigue uniones (PCP:488-496).
- El vector v3 solo agrega campos (PFI:60-75), la huella del v2 no cambia (PFI:22) y el GUID, el SDDL y los atributos de los dos componentes se leen del vector (PFI:78-122).
- Los `EventId` 4753 a 4755 se prueban contra los declarados en `src` (PFI:300-309).

## Riesgos que las pruebas no cubren
- P-O1-7 (instalación elevada: 1603 real, 25101, eventos, caso FIPS), P-O1-8 y P-O3-4 sin ejecutar; firma de la `.CA.dll` (S-04); la carga de la acción por SfxCA en el equipo del cliente.
- Una unidad con letra `subst` o asignada: la ruta final trae otra letra y la comprobación rechaza (falla cerrada, sin prueba; *inferido*).

## Texto de comentario para el PR #124

```
Revisión de pruebas (QA de C, solo lectura; no se compiló ni se corrió nada). Dictamen: Aprobado con observaciones, sin Altas. Informe: GPOS-NG-Equipos/traspasos/C/2026-10-20-revision-pruebas-pr124.md
Bien cubierto: S-01 (tabla, ruta final), S-02, S-05, S-09 (cuatro uniones reales) y el vector v3 contra los .wxs.
- P124-01 (Media): AccionesInstalador.cs (SYSTEM) no se ejecuta en ninguna prueba; propongo guardas de código para el orden de columnas del SELECT y para que los 3 mensajes pasen raizCreada.
- P124-02 (Media): la raiz se crea (CCP:541) antes de comprobar la ruta final (CCP:591); falta la prueba de «el padre de la raiz es una union» y decidir si queda creada o no.
- P124-08 (Media): S-04, S-06 y S-07 no tienen la prueba que los fijará; escribirla con el cambio (construir.ps1 con -Firmar, condición de la acción, GUID).
- Bajas: Assert.All vacuo en la guarda S-03 (PFI:221); ramas de error de Win32 sin prueba; máscara sin Theory por bit; precondiciones del entorno (C:\Windows, %TEMP%) deberían ser Skip; guidRetirados[0] solo; «MSI normal sin la acción» a verificar en laboratorio (P-O1-8).
Cobertura: no medida; estimada ~75-80 % en la lógica y 0 % en la capa DTF, en el borde del 70 % de la política. Pido la medición con filtro de clases (sin suite completa).
```

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica sobre las pruebas; la decisión es de B y del propietario)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-pruebas-pr124.md`
- Supuestos: no leí el blueprint v2 de A; la cobertura es una estimación por lectura; nada compilado ni ejecutado; los comportamientos de WiX y Windows Installer marcados *inferido* no se verificaron.
- Decisiones candidatas a ADR: Ninguna (P124-02 es una decisión de A dentro de ADR-77, punto 3).
- Entregas a otros agentes: desarrollador (A) → P124-01 a P124-09 y la decisión de P124-02; devops → medición con filtro de clases, S-04 y P-O1-7/8 en laboratorio; B → publicar el comentario en el PR.
- Próximo paso recomendado: A decide P124-02 y agrega las pruebas de P124-01 y P124-03 antes de retirar K1-02.
