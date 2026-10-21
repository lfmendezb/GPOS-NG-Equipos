```
Para: B                         De: C (QA)                    Fecha: 2026-10-20
Tipo: Revisión de pruebas, solo lectura (tareas 2 y 4 del encargo del 2026-10-20)
PR: #120 (T2-0 de DB-7), rama b/t2-0-llave-firma, commits 974128e5 (S120-01, 02, 03, 05, 06) y 8bacc925 (S120-04), cabeza 8bacc925
Estado: Abierto
```

# Revisión de pruebas de los commits de seguridad del PR #120 y respuesta sobre P120-01

## Dictamen: Aprobado con observaciones (sin Altas)

Los commits corrigen lo que pidió la revisión de seguridad y las pruebas nuevas son útiles: la regla del descriptor se prueba a fondo como función pura, el arranque falla con el 4740 cuando una llave activa no tiene la seguridad esperada, y el verbo rechaza la cuenta no exclusiva antes de escribir el evento y de crear nada. Lo que queda es de integración: **ninguna prueba que corra sin administrador ejercita el cableado real** de `AlmacenLlavesFirmaWindows.Abrir` y de `Crear` con CNG, y eso es justamente lo que reportaba P120-01.

## Conclusión sobre P120-01 (tarea 4): BAJA de Alta a Media

**Pregunta 1: ¿la comprobación de `Abrir` sigue el patrón de `LlaveSitio.Abrir` (T3-07)?** Sí en lo esencial, con tres diferencias que no la debilitan y una que pide prueba. Verificado leyendo `LlaveFirmaTokens.Windows.cs` (rama @ 8bacc925) frente a `LlaveSitio.cs`:

| Aspecto | `LlaveSitio.Abrir` / `ComprobarSeguridad` | `AlmacenLlavesFirmaWindows` |
|---|---|---|
| Qué lee | `GetProperty("Security Descr", 0x5)` (dueño y DACL) | Igual (`LlaveFirmaTokens.Windows.cs:38-39,147`) |
| Solo en el almacén de la máquina | Sí | Sí (`:142`) |
| Descriptor ilegible | Falla cerrada | Falla cerrada (`:149-152`, `:110-113`) |
| Reglas de ACE | Allow solo a Admins, SYSTEM y el servicio con `GENERIC_READ` o su equivalente; denegaciones ignoradas; tipos desconocidos rechazados | Igual (`:119-136`; misma `LecturaPermitida`, `:46`) |
| Dueño | Administradores **o SYSTEM** | Solo Administradores (`:116`): más estricto, coherente con `Descriptor` (dueño Administradores al crear) |
| El servicio debe tener el uso | No | Sí (`:136`): más estricto |
| Cómo falla | `Abrir` **lanza** `CryptographicException` | `Abrir` **no lanza**: expone `ProblemaSeguridad` (`:187`) y falla el consumidor, `ProveedorLlavesFirma` (condición 7, `ProveedorLlavesFirma.cs:161-164`, 4740) |
| Al crear | No relee | Relee el descriptor y **borra** la llave si difiere (`:237-254`) |

La diferencia de «cómo falla» es la que importa: el cierre ocurre por la disciplina del llamador, no por construcción. Hoy el único consumidor productivo es `ProveedorLlavesFirma` (la API no está conectada todavía) y `verificar` solo informa, así que el control está completo; un consumidor nuevo que llame a `IAlmacenLlavesFirma.Abrir` y use `Llave` sin mirar `ProblemaSeguridad` abriría el hueco. Queda como nota de diseño en P120S-01, no como defecto.

**Pregunta 2: ¿hay una prueba que la ejercite y falle si se quita la comprobación?** Parcialmente.
- **Sí, y fallaría:** `LlaveFirmaTokensTests.El_descriptor_de_la_llave_de_maquina_se_comprueba` (`LlaveFirmaTokensTests.cs:300-331`) cubre la función pura (dueño, otro SID con acceso, escritura del servicio, falta del uso, llave de otra identidad, descriptor ilegible). Y `Seguridad_inesperada_almacen_ilegible_y_kid_repetido_impiden_arrancar_con_4740` (`:334-363`) prueba que la condición 7 detiene el arranque con el 4740 (quitar `ProveedorLlavesFirma.cs:161-164` hace fallar `Assert.Throws`).
- **No, quitar la línea de `Abrir` no hace fallar ninguna prueba que corra sin administrador:** `LlaveFirmaTokens.Windows.cs:187` (`ProblemaSeguridad(llave, ServicioEsperado())`) y `:237` (la relectura en `Crear`) solo las ejercita `En_la_maquina_la_llave_queda_con_el_descriptor_esperado` (`:383-414`), que hace `return` en silencio si no hay consola de administrador (`:392`) y, en la variante TPM, si no hay TPM (`:395`). En una sesión normal esa prueba **aparece como aprobada sin haberse ejecutado**. Los dobles en memoria (`Inseguras`, `LlavesFirmaPruebas.cs:34,60`) saltan por encima de `AlmacenLlavesFirmaWindows`.

**Severidad: de Alta a Media.** Se baja porque ya no hay un hueco de diseño: una llave `GPOS.Api.Firma.*` con ACL ancha o dueño ajeno se rechaza (por lectura), con el patrón de T3-07, y la API no arranca con ella. Se mantiene Media y no Baja porque el control no tiene una prueba ejecutable de integración (P120S-01) y porque la prueba real en CNG (incluido el TPM, donde `Security Descr` no se verificó, *inferido*) está diferida a D6 sin registro de resultado. **Pasa a Baja** cuando ocurra una de dos cosas: (a) se agrega la prueba P120S-01 (sin administrador) o (b) B registra la ejecución del ensayo D6 (equipo, fecha, proveedor y resultado) en la hoja del PR.

## Hallazgos

### P120S-01 · Media · El cableado de `Abrir` y de `Crear` con CNG no tiene prueba ejecutable sin administrador (sucesor de P120-01)
- **Evidencia:** `LlaveFirmaTokens.Windows.cs:140-142` (`if (!Maquina) return null`), `:187`, `:237-254`; `LlaveFirmaTokensTests.cs:383-414`.
- **Qué pasa:** el almacén del usuario nunca comprueba el descriptor (`:142`), y crear en el de la máquina exige administrador, así que la suite normal no puede ejercitar la rama.
- **Propuesta (una costura mínima, sin tecnología nueva):** una propiedad `internal` en `AlmacenLlavesFirmaWindows` (por ejemplo, `ComprobarSeguridadSiempre`, falsa por omisión) que haga que `ProblemaSeguridad(llave, servicio)` también se evalúe en el almacén del usuario. Con ella, sin elevación y con el Software KSP del usuario:
  - `LlaveFirmaTokensTests.Abrir_en_modo_estricto_reporta_el_dueno_de_una_llave_creada_por_el_usuario`: la llave que crea el usuario tiene como dueño al usuario; `Abrir(...).ProblemaSeguridad` contiene «su dueño es S-1-5-21…» y no «Administradores». Falla si se quita `:187`.
  - `LlaveFirmaTokensTests.Crear_en_modo_estricto_con_otro_dueno_lanza_y_borra_la_llave`: `Crear(...)` lanza `CryptographicException` («quedó con otra seguridad… y se borró») y `almacen.Existe(nombre)` es falso después. Falla si se quita `llave.Delete()` (`:246`) o la relectura (`:237`).
  - `LlaveFirmaTokensTests.Un_consumidor_nuevo_no_usa_la_llave_sin_mirar_ProblemaSeguridad` (guarda de código, opcional): ningún archivo de `src/` fuera de `ProveedorLlavesFirma.cs` y de `ComandoLlaveFirma.cs` usa `.Llave` de un `ILlaveFirmaTokens` obtenido con `Abrir`.

### P120S-02 · Media · La condición 7 se prueba solo con la llave activa
- **Evidencia:** `ProveedorLlavesFirma.cs:162` evalúa **todas** las `conservadas`; `LlaveFirmaTokensTests.cs:337-343` marca insegura solo la activa.
- **Riesgo:** una mutación a «solo la activa» sobreviviría; en una rotación, la llave anterior (activa para validar) con ACL ancha debe impedir arrancar igual.
- **Pruebas propuestas:** `Una_llave_anterior_de_la_lista_con_seguridad_inesperada_impide_arrancar` (activa sana, anterior en `Inseguras`, ambas en `KidsValidos`) y `Una_llave_fuera_de_la_lista_con_seguridad_inesperada_no_estorba` (se descarta antes, `ProveedorLlavesFirma.cs:144-148`).

### P120S-03 · Media · Ramas de `ProblemaSeguridad` sin prueba, y una diferencia con `LlaveSitio` que conviene fijar
- **Evidencia:** `LlaveFirmaTokens.Windows.cs:118` (DACL nula), `:122-123` (denegaciones), `:134` (tipo de ACE no admitido), `:116` (dueño solo Administradores); en `LlaveFirmaTokensTests.cs:310-330` no hay casos de estas ramas.
- **Pruebas propuestas** (función pura, sin administrador):
  - `ProblemaSeguridad_rechaza_la_DACL_nula` («no tiene ACL»);
  - `ProblemaSeguridad_ignora_las_reglas_de_denegacion`;
  - `ProblemaSeguridad_rechaza_una_regla_de_tipo_no_admitido` (por ejemplo, `AccessAllowedCallback` o de objeto);
  - `ProblemaSeguridad_acepta_la_lectura_especifica_equivalente_0x00120089_del_servicio` (la rama de `LecturaPermitida`);
  - `ProblemaSeguridad_rechaza_el_dueno_SYSTEM`: **fija la decisión** de ser más estricto que `LlaveSitio.ComprobarSeguridad` (que lo acepta). Si no se quiere, la prueba debe decir lo contrario.
  - `ProblemaSeguridad_y_LlaveSitio_ComprobarSeguridad_coinciden_salvo_en_el_dueno_SYSTEM_y_el_uso_del_servicio`: una tabla de descriptores aplicada a las dos funciones, para que las dos copias de la regla no se separen sin que nadie lo decida.

### P120S-04 · Media · La traducción de errores y el borrado de `Crear` se prueban solo contra el doble
- **Evidencia:** `LlaveFirmaTokens.Windows.cs:229-233` (`NTE_PERM`/`E_ACCESSDENIED` → `UnauthorizedAccessException`) y `:241-254` (borrar si falla una comprobación posterior); la prueba nueva `ComandoLlaveFirmaTests.Una_llave_inutilizable_no_queda_persistida_y_la_falta_de_privilegios_se_distingue` (`ComandoLlaveFirmaTests.cs:152-170`) usa `AlmacenLlavesMemoria` con `ErrorAlCrear` y `CrearExportable`: prueba el verbo, no el almacén de Windows.
- **Pruebas propuestas:**
  - `LlaveFirmaTokensTests.Crear_en_la_maquina_sin_administrador_lanza_UnauthorizedAccessException` (con `Skip` explícito si la consola está elevada; la identidad válida de la prueba de `:268-297` evita el 4740): fija el `HResult` real que devuelve CNG y que ninguna llave quedó (`almacen.Existe` falso).
  - El borrado ante una comprobación fallida lo cubre `Crear_en_modo_estricto_con_otro_dueno_lanza_y_borra_la_llave` (P120S-01).

### P120S-05 · Baja · Las pruebas de ensayo pasan sin ejecutarse
- **Evidencia:** `LlaveFirmaTokensTests.cs:390,392,395` (`return`) y `:41,68,117` (otras pruebas con `if (!OperatingSystem.IsWindows()) return;`).
- **Propuesta:** el atributo con `Skip` que ya usa el proyecto (`Rg14Lote2Tests.cs:24`, xUnit 2.9.3) para «requiere administrador» y «requiere TPM», de modo que el recuento de omitidas muestre qué no corrió (continúa P120-14). Y registrar el resultado del ensayo D6 con TPM de la prueba `:383-414` cuando se corra: si el Platform Crypto Provider no expone `Security Descr`, `GetProperty` lanza y la API **no arrancaría** en un equipo con TPM (disponibilidad, no confidencialidad; *inferido*).

### P120S-06 · Baja · `--cuenta` acepta cualquier cuenta virtual de servicio; el doble del verbo prueba otra regla
- **Evidencia:** `LlaveFirmaTokens.Windows.cs:93` (`EsIdentidadExclusiva(sid, admitirIis: false)` acepta cualquier `NT SERVICE\…`, por ejemplo `NT SERVICE\MSSQLSERVER`); el `ProblemaIdentidad` del doble (`LlavesFirmaPruebas.cs:39-41`) solo mira el prefijo `NT SERVICE\`; la teoría de `LlaveFirmaTokensTests.cs:268-297` tiene solo casos negativos y un positivo (`NT SERVICE\GPOS.Api`, `:296`).
- **Efecto:** un administrador podría dar el uso de la llave a otro servicio (quedaría inútil para la API, que falla cerrada al abrirla, pero la llave existe con el uso de un servicio ajeno).
- **Propuesta:** decidir si `--cuenta` se limita a las cuentas de los servicios de GPOS (`ServiciosWindows`) y fijarlo: `La_cuenta_virtual_de_un_servicio_ajeno_a_GPOS_se_rechaza` (o, si se acepta, `…se_acepta_y_la_API_la_rechaza_al_abrir`). Es decisión de B/seguridad, no un defecto probado.

### P120S-07 · Baja · El motivo admite separadores Unicode de línea y marcas de dirección
- **Evidencia:** `ComandoLlaveFirma.cs:94` usa `char.IsControl`, que solo cubre la categoría `Cc`; U+2028 y U+2029 (separadores de línea y de párrafo) y U+202E (invierte la dirección) no son de control. La prueba `El_motivo_no_admite_caracteres_de_control` (`ComandoLlaveFirmaTests.cs:143-150`) tiene tres filas (`\n`, `\t`, escape).
- **Propuesta:** agregar filas `"motivo suficiente\u2028línea falsa"` y `"motivo suficiente\u202Egnirts"` y decidir (rechazar categorías `Zl`, `Zp` y `Cf`) o documentar que se aceptan. Además, el recorte antes de comprobar acepta un `\n` final (`" motivo suficiente\n"`); fijar la conducta con una fila.

## Estado de los hallazgos de la primera revisión (P120-02 a P120-16) tras estos commits

| Id | Estado | Por qué |
|---|---|---|
| P120-01 | **Media** (era Alta) | Ver arriba; sucesor P120S-01 |
| P120-02, 03, 04, 05 | Abiertos | Los commits no tocan esas ramas |
| P120-06 | Parcial | Cerrado el kid repetido y el almacén ilegible (`ProveedorLlavesFirma.cs:122-128,157-158`; prueba `LlaveFirmaTokensTests.cs:334-363`); sigue abierto que una excepción distinta de `CryptographicException` (`UnauthorizedAccessException`, `NotSupportedException`) escape sin el 4740 |
| P120-07 | Abierto | `LlaveMemoria.Liberada` sigue sin leerse |
| P120-08 | Parcial | Se agregó la prueba de caracteres de control; faltan los bordes de 10 y 200 y el recorte antes de contar |
| P120-09 | Parcial | El mensaje ya distingue la falta de privilegios y la rama «quedó exportable» tiene prueba (en memoria); el evento de aceptación sigue quedando sin llave si `Crear` falla |
| P120-10, 11 | Abiertos | Sin cambios |
| P120-12 | Parcial | La fecha futura está cubierta (`LlaveFirmaTokensTests.cs:366-377`); faltan 30/31 días, nombres mal formados y `OpcionesLlavesFirma.Desde` |
| P120-13 a 16 | Abiertos | Sin cambios |

## Texto de comentario para el PR #120

```
Revisión de pruebas de 974128e5 y 8bacc925 (QA de C, solo lectura; no se compiló ni se corrió nada). Dictamen: Aprobado con observaciones, sin Altas. Informe: GPOS-NG-Equipos/traspasos/C/2026-10-20-revision-pruebas-pr120-seguridad.md
P120-01 baja de Alta a Media. Abrir sigue el patrón de LlaveSitio (misma propiedad «Security Descr», mismas reglas de ACE, falla cerrada; dueño más estricto: solo Administradores) pero no lanza: expone ProblemaSeguridad y falla ProveedorLlavesFirma (condición 7). La regla pura (LlaveFirmaTokensTests.cs:300) y el arranque con 4740 (:334) tienen pruebas que fallarían sin el control.
Lo que falta (P120S-01, Media): ninguna prueba que corra sin administrador ejercita LlaveFirmaTokens.Windows.cs:187 ni la relectura/borrado de Crear (:237-254); el ensayo D6 (:383) hace return si no hay admin o TPM y aparece como aprobado. Propongo una costura internal (comprobar siempre) para probarlo con el Software KSP del usuario. Pasa a Baja con esa prueba o con el resultado registrado del ensayo D6.
- P120S-02: la condición 7 solo se prueba con la llave activa. P120S-03: ramas de ProblemaSeguridad sin prueba (DACL nula, denegación, ACE no admitida, dueño SYSTEM).
- P120S-04: NTE_PERM/E_ACCESSDENIED→UnauthorizedAccessException y el borrado de Crear se prueban solo contra el doble.
- Bajas: ensayos con return en vez de Skip (P120S-05); --cuenta acepta cualquier NT SERVICE\* (P120S-06); IsControl no cubre U+2028/U+202E (P120S-07).
```

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica sobre las pruebas; la decisión es de B y del propietario). P120-01 baja a Media.
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-revision-pruebas-pr120-seguridad.md`
- Supuestos: nada compilado ni ejecutado; que el Platform Crypto Provider exponga `Security Descr` en la máquina es *inferido* y no verificado; la afirmación de que la API no está conectada a `ProveedorLlavesFirma` viene del comentario de la clase (`ProveedorLlavesFirma.cs:44-45`).
- Decisiones candidatas a ADR: Ninguna (P120S-06 es una decisión de B/seguridad dentro de BP3 8.2).
- Entregas a otros agentes: desarrollador (B) → P120S-01 a P120S-07 y las abiertas de la tabla; auditor-seguridad → opinar sobre P120S-03 (dueño SYSTEM) y P120S-06; B → registrar el resultado del ensayo D6 y publicar el comentario en el PR.
- Próximo paso recomendado: B agrega la costura y las dos pruebas de P120S-01 (o registra el ensayo D6) para cerrar P120-01.
