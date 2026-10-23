# Blueprint de PR-V: verbos `implantar-servidor` y `comprobar-servidor` (sin compilar) · equipo A · 2026-10-22

Responde a la tarea 10 de `avisos/B-a-A/2026-10-22-tareas-nuevas-para-a-2.md`. **Es el plano para construir PR-V**, no un diseño nuevo: reúne y ordena lo decidido en `plan-demo-con-api-de-reportes-2026-10-22.md` (secciones 2.2 a 2.4, 5 y 6; dictamen de seguridad rev. 2, DM-01 a DM-16) y lo firmado después (Q-5, Q-6, Q-8, JWT-01, P-1). Marcas: [V] verificado por lectura; [I] inferido. Nada está construido; los verbos no existen en `origin/feature/modelo-ng` [V, 2026-10-22].

## 0. Resumen
1. Dos verbos nuevos de `GPOS.Migracion` (carpeta `src/GPOS.Migracion/Servidor/`), con el mismo despacho que `Lectura/ComandosLectura` y `Anillo/ComandosAnillo` [V `Program.cs:72, :111`].
2. **Todo lo que toca el sistema (registro, `sc`, DACL, SQL, archivos) pasa por una interfaz** (`ISistemaServidor`); las pruebas usan un doble en memoria. Es lo que permite construir y probar PR-V **sin ejecutar servicios ni instaladores** en la PC de A (regla del 2026-10-08). Lo real se prueba en la VM (P-8).
3. Perfil `demo` ahora; el perfil `produccion` queda previsto en la interfaz (las mismas comprobaciones, con las constantes del MSI) para el *bundle* futuro.
4. Esfuerzo **1,5 dp + 0,75 a 1,0 dp** de la rev. 2 [I, ±40 %], como en el plan (6.1). No se amplía.

## 1. Contrato de los verbos

### 1.1 `implantar-servidor`
`GPOS.Migracion implantar-servidor --perfil demo|produccion --fase carpetas|servicios|esquema|lectura [--origen <carpeta del paquete>] [--destino <carpeta>] [--usuario-instala <SID|cuenta>] [--rotar-jwt] [--confirmar]`

- **Elevación:** `carpetas`, `servicios` y `lectura` la exigen (código 1 y mensaje si no hay); `esquema` usa la cuenta de Windows con `sysadmin` o `dbcreator`, como hoy [V plan 2.3].
- **Una fase por llamada, idempotente.** Repetirla no cambia nada si ya está hecha; si el estado no coincide con lo esperado (carpeta de un tercero, servicio con otra cuenta), **se detiene y dice qué**, no «arregla» (criterio de ADR-77 punto 3).
- **`--perfil produccion`** en esta etapa responde 1 «aún no implementado» salvo `--fase carpetas`, que ya comparte código. Así ningún camino del perfil demo se activa por error en otro perfil (cerrojo 1).
- **Salida:** líneas de avance sin secretos; al final un resumen `fase=… resultado=ok|detenido|error cambios=n`. Nunca el valor de la clave JWT, ni un fragmento, ni un hash corto (DM-15).
- **Códigos de salida:** 0 hecho o ya estaba; 1 error; 4 detenido por una guarda de seguridad (carpeta ajena, DACL inesperada, perfil/modo incoherente).

### 1.2 `comprobar-servidor`
`GPOS.Migracion comprobar-servidor --perfil demo|produccion [--salida texto|json] [--sin-red]`

- **Solo lectura.** El sondeo de `sc qprivs` e `icacls` puede pedir elevación; sin ella, la comprobación respectiva sale `AVISO: no se pudo comprobar` y **el resultado global no es 0** (falla cerrada, DE-07).
- **Salida:** tabla `ID | Comprobación | Resultado (OK / AVISO / FALLA) | Detalle`. Con `--salida json`, el mismo contenido para que `Recoger-Evidencia.ps1` lo tome (solo nombres y estados).
- **Códigos de salida (plan 2.3):** 0 todo OK; 2 hay AVISO; 4 hay FALLA. Con varias, gana el más grave (4 > 2 > 0); un error del propio verbo es 1.

## 2. Estructura en `GPOS.Migracion`

```
src/GPOS.Migracion/Servidor/
  ComandoImplantarServidor.cs      despacho, validación de opciones, elevación
  ComandoComprobarServidor.cs      ejecuta el catálogo y arma la tabla
  FasesImplantacion/
    FaseCarpetas.cs  FaseServicios.cs  FaseEsquema.cs  FaseLectura.cs
  Comprobaciones/
    ICatalogoComprobacion.cs       { Id, Aplica(perfil), Ejecutar(sistema) -> ResultadoComprobacion }
    R1Privilegios.cs … (una clase por comprobación, ver sección 4)
  ISistemaServidor.cs              registro, servicios, DACL, sockets, SQL, archivos, eventos
  SistemaServidorWindows.cs        implementación real (única que llama a la API de Windows)
  SddlServicios.cs                 constantes (sección 5)
tests/GPOS.Tests/Servidor/         dobles en memoria y pruebas de arquitectura
```
- `Program.cs` solo agrega dos `case` (como los de `Lectura` y `Anillo`). No toca los verbos existentes.
- El literal `Jwt__Clave` aparece en **un único método** (`FaseServicios.EscribirClaveDemo`); una prueba de arquitectura lo fija (cerrojo 1).
- `SistemaServidorWindows` es la única clase que usa `Microsoft.Win32.Registry`, `System.ServiceProcess`, `ServiceController`, DACL y `sc.exe`; el resto trabaja sobre la interfaz.

## 3. Pasos de cada fase (orden obligatorio)

**`carpetas`:** (1) crear `%ProgramData%\GPOS NG` **en una sola operación con su DACL** (`O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)(A;OICI;0x1200a9;;;AU)`, ADR-77 punto 1); (2) `\Api`, `\Api\anillo`, `\Api\registros`, `\Api\temp`, `\Reportes` (`0x1301bf` para `NT SERVICE\GPOS.Reportes`, sin herencia), `\config`; (3) si algo ya existe: dueño de la lista blanca, sin punto de reanálisis, sin escritor ajeno; si no, **abortar con 4**. Comparte el vector `adr077-carpetas.v3.json` con la acción previa del MSI (#124): la lógica es la misma clase, no una copia [I: `ComprobacionCarpetasPrevias` está en `net472`; si no se puede referenciar, se duplica solo la tabla del vector y una prueba compara las dos].

**`servicios`:**
1. Comprobar la carpeta de destino (dueño, reanálisis, escritores) y **verificar las huellas SHA-256 del manifiesto en el destino**, no en la carpeta extraída (plan 2.2.5).
2. Copiar a `%ProgramFiles%\GPOS NG\Demo\` con copia previa protegida (`…\.anterior`, SYSTEM + administradores).
3. `sc create` con `obj= "NT SERVICE\<nombre>"`, `sc privs` (solo `SeChangeNotifyPrivilege`), `sc failure` solo con reinicio, inicio **manual**, `GPOS.Api` con `--servicio` (único argumento).
4. Orígenes de eventos `GPOS.Api` y `GPOS.Reportes` (`EventMessageFile` en ruta protegida, DM-13).
5. **DACL protegida de la clave del servicio → comprobarla → solo entonces** generar la clave (48 bytes con `RandomNumberGenerator`, en C#) y escribir el valor `Environment` (`REG_MULTI_SZ`) desde el mismo proceso. Condición: `--perfil demo` **y** `GPOS__Seguridad__ModoIdentidad=Amplio` en ese mismo entorno (cerrojo 1). Nunca por `reg.exe`, argumentos ni cmdlet (DM-05). SDDL: `O:SYG:SYD:P(A;CI;KA;;;SY)(A;CI;KA;;;BA)`.
6. `TMP` y `TEMP` de los servicios a `%ProgramData%\GPOS NG\<Api|Reportes>\temp` (DM-11).
7. SDDL de cada servicio para el usuario que instala (DM-09, sección 5).
8. `--rotar-jwt`: genera otra clave y reescribe el valor (mismo orden y comprobación); invalida los tokens vigentes. Sin la opción, la actualización normal **no** rota.

**`esquema`:** `sistema --login-api "NT SERVICE\GPOS.Api"` con la escalera de 2.2.2 (empezar por la preferida; **el nivel exacto lo fija el spike**), `actualizar` de la empresa (`crear` si es nueva), vistas `rpt`, y `anillo --anclar` del certificado del anillo (DM-07). Prohibido `sysadmin`, `CONTROL SERVER`, `securityadmin`, `serveradmin`, `ALTER ANY LOGIN`, `IMPERSONATE`.

**`lectura`:** `crear-lectura-sistema --cuenta "NT SERVICE\GPOS.Reportes"`, `llave-sitio` (almacén de máquina, ACL a la cuenta), `crear-lectura --todas`, `red` (modo un equipo). Componen los verbos que ya existen [V `Program.cs:13-20`].

**Orden entre fases:** `carpetas` → `servicios` → `esquema` → `lectura`. El *script* del DEMO las llama en ese orden; el verbo no impone la secuencia, pero cada fase comprueba su precondición (por ejemplo, `servicios` exige las carpetas).

## 4. Catálogo de `comprobar-servidor --perfil demo` (11 comprobaciones + las de la rev. 2)

| ID | Qué mira | FALLA / AVISO |
|---|---|---|
| R1 | `sc qprivs` de ambos servicios | FALLA si hay algo más que `SeChangeNotifyPrivilege` |
| R2 | Cuenta virtual, inicio manual, SID sin restricción | FALLA si cuenta o inicio difieren |
| R3 | `icacls` de la raíz, `\Reportes`, `\Reportes\render`, `\Api\anillo`, `\config` | FALLA si no coincide el vector o si `render` tiene lectura para autenticados o reanálisis |
| R4 | Sockets 5071 y 5073 **solo** en `127.0.0.1`/`::1`; las dos canalizaciones con su dueño | FALLA si escucha en `0.0.0.0`, `[::]` o `+` |
| R5 | `/api/salud` con versión | AVISO si solo hay 200 (hasta el cambio aditivo) |
| R6 | Sin eventos 5106 y 5112 a 5116 en 15 min | FALLA si aparecen |
| R7 | Regla de salida | AVISO fijo «sin regla de salida en el DEMO» |
| R8 | Entorno de los servicios sin credenciales | AVISO conocido (nombra la variable, nunca el valor); **FALLA** si la DACL de la clave del servicio da lectura a otro SID, o con perfil distinto de `demo` si hay `Jwt__Clave` **o `Jwt:Clave`** (JWT-01), `Clave`, `Password`, `Secret` o `Password=` |
| R10 | Reporte 1, uno del diseñador, uno de la lista P-2 y `CXC-ANTIGUEDAD` | FALLA si no hay 200 con datos o si una escritura fuera posible |
| P1, P4 a P6, P8, K3 | Cuenta y privilegios; `/api/salud` de la principal; canalización de introspección; un reporte pedido a la principal llega y vuelve; sin secretos en el registro de la instalación | según el plan 5 |
| P7 | Modo de identidad | AVISO esperado en el DEMO (Amplio), no FALLA |
| DM-03 | `is_trustworthy_on = 0` en `GPOS_SYSDATA` y todas las `GPOS_*`; el login `NT SERVICE\GPOS.Api` sin roles de servidor | FALLA |
| DM-09 | `sc sdshow` de cada servicio | FALLA si el usuario que instala tiene `DC`, `WD`, `WO` o `SD`, o si `IU`, `AU` o `BU` tienen algo más que consulta |
| DM-10 | Ninguna ruta del entorno de los servicios cae bajo el perfil del usuario | FALLA |
| R9 | `verificar --estricto` | **No aplica** al demo (se usa `verificar` sin `--estricto`) |

Si la lectura de **cualquier** comprobación falla (permiso, servicio detenido, SQL), el resultado es AVISO o FALLA según el plan, **nunca OK**.

## 5. SDDL de los servicios: dos perfiles, una constante
- **Perfil `demo` (DM-09):** el SID del usuario que instala tiene solo `RP`, `WP`, `LC`, `LO`, `CC` y `RC` (inicia, detiene, consulta); nunca `DC`, `WD`, `WO` ni `SD`.
- **Perfil `produccion` (Q-5, firmada el 2026-10-22):** `D:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLORC;;;BU)` (solo Administradores y SYSTEM gobiernan; los usuarios consultan) [`contrato-servicio-msi-api-2026-10-22.md`]. A comprobar con `sc sdshow` en la VM (caso L-2f).
- Ambos viven como constantes en `SddlServicios.cs`. **Una prueba de arquitectura compara la del perfil `produccion` con el texto del `Package.wxs` de T1-b** (la arma B) para que no se separen; el guion `Probar-Instalador.ps1 -Caso L-2f` usa el mismo texto.
- Un perfil no puede usar la constante del otro (prueba): el DEMO nunca instala el SDDL de producción ni al revés.

## 6. Pruebas (sin servicios reales; doble en memoria)
`tests/GPOS.Tests/Servidor/`:
1. `La_clave_JWT_solo_se_escribe_con_perfil_demo_y_modo_Amplio` y prueba de arquitectura: el literal `Jwt__Clave` aparece en un solo método.
2. `La_DACL_de_la_clave_se_aplica_y_se_comprueba_antes_de_escribir_el_valor` (el doble registra el orden; mutación: invertirlo debe fallar).
3. `La_clave_no_sale_en_la_salida_ni_en_el_registro_ni_en_los_argumentos` (captura de consola, doble de registro y de procesos).
4. `Con_perfil_distinto_de_demo_Jwt_Clave_y_Jwt_dos_puntos_dan_FALLA` (las dos grafías; cerrojo 4 y JWT-01).
5. `Una_carpeta_con_dueno_ajeno_o_reanalisis_detiene_con_4` y `Repetir_una_fase_no_cambia_nada`.
6. Una prueba por comprobación (sección 4): estado OK, AVISO y FALLA; y `Si_no_se_puede_leer_no_es_OK`.
7. `Los_SDDL_de_demo_y_produccion_no_se_cruzan` y `El_SDDL_de_produccion_es_el_del_Package_wxs` (esta, cuando exista T1-b).
8. Arquitectura: solo `SistemaServidorWindows` usa registro, `ServiceController`, `sc.exe` y DACL; ninguna clase del verbo contiene `reg.exe`, `Set-ItemProperty` ni `reg query`.
9. Textual: `Recoger-Evidencia.ps1` no hace `reg query`/`reg export` de la clave del servicio (DM-05).

## 7. EventId y registro
- Origen `GPOS.Instalacion` (de B). **EventId: 5134 a 5138** de la franja 5130-5149 reservada al instalador (N-8) [V, aviso de B del 22-oct]; propongo (corregido el 22-oct, tras comprobar que 5130-5133 y 5140-5143 ya están en uso) 5134 fase iniciada, 5135 fase completada, 5136 detenido por guarda, 5137 clave JWT rotada (sin valor), 5138 resultado de la comprobación. **B confirma el rango**; se verifica con `git grep` en todas las ramas el día de construir (ADR-82). No usar 4780-4789 (verbo `tls`) ni 4771-4779 (`GPOS.Instalacion`, de B).
- Ningún evento lleva el valor de la clave, cadenas de conexión ni el entorno de los servicios.

## 8. Dependencias y orden
- Antes: PR-4 (#139/#140, **ya unidos**), PR-D1 (#171, **unido**). Puede desarrollarse ya contra el árbol actual (plan 3.2, punto 4). Se une **antes de D4**.
- Espera de la VM (P-8): el spike DE-01 fija la escalera de privilegios SQL (2.2.2) y confirma las DACL [I] de la clave del servicio; hasta entonces la fase `esquema` solo implementa el paso preferido y avisa si Amplio exige más.
- Con T1-b (de B): la constante de producción y la prueba 7.
- La capacidad de la PC de A (2 compilaciones) cruza con T4-06 desde el 3-nov: PR-V es el trabajo que se aplaza si hay que elegir, porque el plan permite construirlo en paralelo con la VM libre.

## 9. Lo que NO hace PR-V
Los scripts del DEMO (`Instalar-Demo`, `Iniciar-Demo`, etc.) son PR-D2; el perfil de Chromium (DM-11) es de B (T4-01); el cerrojo 2 de la API es el #174 (**ya con JWT-01**); el *bundle* Burn y el MSI de la API son de B (T1-b).

## Cierre
- Estado: Completado (blueprint, sin compilar). Entrega a: B (rango de EventId, la constante de producción en T1-b), devops (scripts de PR-D2 sobre este contrato), auditor-seguridad (revisión del PR de PR-V).
- No verificado: que `ComprobacionCarpetasPrevias` (`net472`) pueda reutilizarse desde `GPOS.Migracion` (`net10.0`); el nivel mínimo de privilegios SQL de la API como servicio en Amplio (spike); las DACL por omisión de las claves de servicio.
