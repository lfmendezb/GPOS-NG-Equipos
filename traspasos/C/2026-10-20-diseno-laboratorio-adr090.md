# Diseño del laboratorio de ADR-90: Name Constraints en .NET, OpenSSL y navegadores, CA fijada y renovación sin reinicio

- **Fecha:** 2026-10-20 · **Versión:** 3 · **Autor:** arquitecto-software del equipo C (OSHIN-LEGION), por encargo de B (`avisos/B-a-C/2026-10-20-pausa-levantada-para-C.md`, punto 2).
- **Tipo:** solo diseño. No se programó, compiló ni ejecutó nada, y no se tocó ninguna base de datos.
- **Estado:** corregido según la [revisión del auditor-seguridad](2026-10-20-revision-seguridad-laboratorio-adr090.md) («Aprobado con observaciones»; en adelante **REV-LAB**).
  - **Corregidos:** LS-01 a LS-07, LS-09 y LS-17, que eran obligatorios.
  - **Incorporados por recomendación:** LS-08, LS-11 y LS-15.
  - **Pasan a «Entregas»:** LS-05 (solo su parte de redacción de RT-10), LS-10, LS-12, LS-13, LS-14 y LS-16.
  - **Versión 3:**
    - corrige LS-18 a LS-22 de la «Verificación de la versión 2» de REV-LAB;
    - suma las precisiones de B (`avisos/B-a-C/2026-10-20-conforme-cola-de-c.md`): PT-02 explícito, la CA sucesora con certificado cruzado (PT-04, bloque S nuevo) y las pruebas de arquitectura de los valores HTTP por omisión (sección 14);
    - se alinea con el blueprint de A (`traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md`, en adelante **BP-A**). Las contradicciones con BP-A van en la sección 11 (C-A1 a C-A5).

  La sección 13 traza cada LS, de LS-01 a LS-22. **Firmado por el propietario el 2026-10-20 («todo según recomendación»):** Q-LAB-01 (a), Q-LAB-02 (a) y Q-LAB-03 (a), con el subconjunto en memoria de N-L en la fase 1.
- **Base leída:**
  - `origin/master` `45a9ab75`: ADR-90, hoja de PT-01 a PT-10, REV y ADR-129;
  - `origin/feature/modelo-ng` `b8f166db`: código.

  Leí con `git show` y `git grep`, sin *checkout*.
- **Marcas:** [V] = verificado en el código o en el texto citado. [I] = inferido: comportamiento de CryptoAPI, OpenSSL, Java, Chromium, NSS, Apple o .NET no comprobado en esta sesión. Para eso existe el laboratorio.

---

## 1. Objetivo, alcance y trazabilidad

**Objetivo.** Demostrar con evidencia, en máquinas virtuales:
1. que los verificadores que usará GPOS NG aplican las restricciones que firma ADR-90;
2. que un cliente con la CA fijada no acepta ninguna otra raíz ni otra ancla con la misma llave;
3. que el certificado del servidor se renueva sin reiniciar y sin caída, también con puestos de reloj atrasado.

Cada resultado esperado se comprueba antes de construir lo que depende de él.

**Alcance:**

| Bloque | Qué prueba | Casos | Fase |
|---|---|---|---|
| N | `X509Chain` de .NET 10 en Windows con Name Constraints críticas: DNS e IP en /32 y /128, CN vacío, SAN fuera de las restricciones, coincidencia por sufijo, `pathLen`, intermedia laxa, EKU de la hoja, otros tipos de nombre, extensiones críticas, mayúsculas, punto final e IDN, PT-01 | LAB-01 a LAB-23b, LAB-71 a LAB-79 | 1 (oráculo, sin código del producto) |
| F | CA fijada exclusiva (`CustomRootTrust`), ancla con el mismo SPKI, regla de alta del ancla, sin descargas, revocación, CA de otro sitio o del sistema, comprobación del SAN, EKU de la CA, modo sin CA fijada | LAB-24 a LAB-31b, LAB-80a a LAB-80c, LAB-81, LAB-85 | 1 |<NL>| S | **CA sucesora con certificado cruzado de la vigente (PT-04)**, con el EKU de LS-13 como dependencia de Q-LAB-01 | LAB-87 a LAB-90 | 1 (oráculo); el recorrido de punta a punta, en la fase 2 |
| N-L | Lo mismo en **Linux** (ADR-129): .NET 10 sobre OpenSSL, más el oráculo de la línea de órdenes `openssl verify`. **Bloque declarado** | LAB-01-L … y LAB-91 a LAB-99 | Subconjunto en memoria en la fase 1 (Q-LAB-03 (a)); el resto, con el tramo Linux |
| V | Conformidad del producto: lo que emite el verbo `tls` y los validadores de A (estación y MAUI en Windows), el alta del ancla y la bajada de modo | LAB-32 a LAB-36, LAB-35b, LAB-35c, LAB-84, LAB-86 | 2 (después de que A construya) |
| R | **Vencimiento y renovación sin reinicio (PT-02)**: huella vigente en el registro, refresco de 5 min del selector de BP-A, reloj de la VM adelantado pasado el vencimiento (PT-10, H-11) | LAB-37 a LAB-48, LAB-37b, LAB-38b, LAB-41b | 2 (después de A y B) |
| R-L | Renovación en Linux: **pendiente**, porque no existe el equivalente del registro de PT-02 | — | Con el tramo Linux |
| B | Edge, Chrome, Firefox (≥ 120) y Firefox ESR con la raíz del sitio en `LocalMachine\Root` | LAB-49 a LAB-62, LAB-83 | 1 |
| M | Android e iOS: **solo se declaran** | LAB-63 a LAB-70 | 3 (fase móvil, RT-10) |

**Fuera de alcance** (otros casos de QA que este documento no diseña, aunque consumen parte de las 0,35 sp; ver la sección 9):
- perfiles de red y cortafuegos (RT-06, O-5);
- latencia del TPM;
- PT-05 y PT-06;
- el recorrido de punta a punta de la **rotación** (QR con la sucesora, ruta de solo lectura con la cadena, aviso al cambiar de emisor), que espera el contrato de PT-04. La **validación del certificado cruzado** sí entra, en el bloque S, con las reglas de LS-13 (sección 11, entrega al Arquitecto Maestro):
  - la sucesora y el cruzado llevan NC y EKU iguales o más estrechos;
  - el cruzado nunca va en la cadena del saludo;
  - con `pathLen = 0`, el cliente lo valida aparte.

**Trazabilidad:**

| Origen | Exigencia | Casos |
|---|---|---|
| PT-07 (H-04) | NC críticas con `dNSName` de los FQDN del sitio e `iPAddress` en /32 y /128, o exclusión de `0.0.0.0/0` y `::/0`; `pathLen = 0`; CN vacío o igual a un nombre del SAN. Laboratorio ampliado a `X509Chain`. Comprobación del SAN en los clientes | Bloques N y N-L, LAB-28, LAB-32 a LAB-34 |
| PT-03 (RT-08, RT-10) | Con la CA fijada, **solo** esa CA, sin descargas ni almacén del sistema; nunca las dos cosas | LAB-23b a LAB-27b, LAB-29, LAB-29b, LAB-35 a LAB-36, LAB-80a a LAB-80c, LAB-81, LAB-84 a LAB-86 |
| PT-02 (RT-04, RT-05) | Huella en `HKLM\SOFTWARE\GPOS NG\Servidor` (`HuellaApi` y `HuellaWeb`, BP-A 4.1), refresco de 5 min, conservar el anterior, evento crítico, orden emitir → lectura → comprobar → publicar, reloj adelantado | LAB-37 a LAB-48 y sus variantes b |<NL>| PT-04 (RT-04, RT-10 punto 6) y LS-13 | La sucesora solo se acepta con un certificado cruzado firmado por la vigente, con NC y EKU iguales o más estrechos; máximo dos CA fijadas | LAB-87 a LAB-90 |
| PT-10, H-11 | 90 días; renovación cuando faltan 30; avisos a 20, 10 y 3 días; tarea diaria y al iniciar; más de 20 días en `comprobar-servidor` | LAB-38b, LAB-44, LAB-45, LAB-48 |
| PT-01 (RT-05) | La Web llama a la API por el nombre del sitio con `ConnectCallback` a *loopback*; sin `localhost` en el SAN de la API | LAB-22, LAB-32 |
| RT-02 | CA propia por sitio con NC críticas | Bloques N y B, LAB-32 |
| RT-04 | Sin CRL ni OCSP; renovación automática sin reinicio | LAB-27, LAB-27b, bloque R |
| RT-08 | Navegadores con la raíz en `LocalMachine\Root`; las estaciones fijan la CA | Bloque B, LAB-35 a LAB-35c |
| RT-10 | MAUI con CA fijada; prohibiciones del punto 5; certificado público del cliente (punto 3); móviles más tarde | LAB-28, LAB-36, LAB-81, bloque M |
| ADR-129 (A1, A2) | Las garantías rigen igual en Linux o la función se bloquea allí | Bloques N-L y R-L |
| H-04 (REV) y REV-LAB | Codificación y aplicación real de las NC | Bloques N, N-L y B |

---

## 2. Lo que hay hoy en el código (verificado contra `origin/feature/modelo-ng` `b8f166db`)

| Id | Hallazgo | Evidencia | Efecto en el laboratorio |
|---|---|---|---|
| F-01 | [V] La estación acepta **todo** certificado que valide el almacén del sistema, antes de mirar el SPKI (ya conocido: V-1 y H-03). Severidad Media, como H-03 | `src/GPOS.AgenteImpresion/Estacion/ClienteDispositivo.cs:67` | LAB-35 lo detecta mientras A no aplique PT-03 |
| F-02 | [V] Si el único error es la cadena y el SPKI de la **hoja** está fijado, la estación acepta una hoja vencida, aún no vigente, sin `serverAuth` o de una raíz desconocida.<br>Consecuencias: una renovación fallida no se nota en las estaciones, y una llave de servidor robada sirve **para siempre** ante ellas, lo que anula H-11. La corrección es de A (LS-10, sección 11) | `ClienteDispositivo.cs:68-69`; el SPKI de la hoja en `:72-73` y `:81` | LAB-35b y LAB-45 lo ponen de manifiesto. Severidad Baja (no hay clientes) |
| F-03 | [V] No existe nada de lo que prueban los bloques V y R:<br>- ni verbo `tls`;<br>- ni `UseHttps(`, `ListenAnyIP` o `ServerCertificate*` en la API o en la Web;<br>- ni `NameConstraints`, `X509Chain`, `CustomRootTrust`, `CertificateChainPolicy` o `MatchesHostname` en `src`.<br>Sí aparece `app.UseHttpsRedirection()` | `git ls-tree src/GPOS.Migracion` (sin `tls`); `src/GPOS.Web/Program.cs:109` | Las fases 2 y 3 esperan la construcción de A y de B |
| F-04 | [V] MAUI usa el `HttpClient` de la fábrica, sin manejador propio. La URL vive en `Preferences`, con `http://` por omisión, también en Release (ya conocido: H-03 y H-09) | `GPOS.UI.MAUI/MauiProgram.cs:19-23`; `GPOS.UI.MAUI/Servicios/ConfiguracionApi.cs:6-12` | LAB-36 depende de que A lo cambie |
| F-05 | [V] Precedentes reutilizables:<br>- el rechazo de `Kestrel:Endpoints` y la comprobación de las direcciones enlazadas;<br>- `HuellaCertificado.Sha256`;<br>- el `ConnectCallback` de la API, que abre una **canalización con nombre** comprobando su dueño. Es precedente de la técnica, no del TCP a *loopback* de PT-01.<br>`PrivadaEnTpm` solo reconoce llaves RSA | `src/GPOS.Reportes.Api/Endpoints/ServiciosReportes.cs:83-84` y `:154-180`; `src/GPOS.Criptografia/Anillo/CifradorAnillo.cs:31`; `src/GPOS.Api/Endpoints/ReenvioReportes.cs:267-276`; `src/GPOS.Core/Infraestructura/Anillo/OrigenCertificadosAnillo.cs:50-56` | Si la llave de la CA es ECDSA en el TPM, el verbo necesita una variante con `ECDsaCng` [I: ADR-90 no fija el algoritmo de la CA] |
| F-06 | [V] Reloj protegido (H-16 v2.1): retroceso tolerado de 5 min y salto máximo de 48 h; la inconsistencia por retroceso persiste tras reiniciar. La hora protegida es el máximo entre el reloj del sistema y el ancla, **así que la licencia por vigencia ve el reloj adelantado** (F-09) | `src/GPOS.Core/Infraestructura/Reloj/RelojProtegido.cs:14`, `:88`, `:91` y `:275`; contrato en `:19-22` y `:77-81` | Bloque R: puntos de control, sin emisión fiscal y sin retrasar el reloj salvo en LAB-46 |
| F-07 | [V] El manejador de la estación recicla las conexiones cada 10 min | `ClienteDispositivo.cs:77` | Compatible con la renovación |
| F-08 | [V] `GPOS.Tests` usa xUnit 2.9.3, sin omisión dinámica, con atributos propios de omisión como precedente. Cada archivo declara su `Esquema` | `tests/GPOS.Tests/GPOS.Tests.csproj:15`; `FactBp2Attribute` (`tests/GPOS.Tests/ModeloNg/ExtraccionBp2Tests.cs:13`), `FactDemoAttribute` (`ImplantacionDemoTests.cs:12`), `FactModoMixtoAttribute` (`Rg14Lote2Tests.cs:18`); `tests/GPOS.Tests/Arquitectura/PruebasNeutralesTests.cs:6-9` y `:47` | Atributo `[FactLaboratorioTls]` y `[Trait("Esquema", "Neutral")]` (sección 7) |
| F-09 | [V] La licencia por vigencia está construida. Con el reloj adelantado a `T0+91` o `T0+95` d, una licencia de laboratorio puede pasar a gracia o a solo consulta [I: depende de sus fechas] | `src/GPOS.Api/Seguridad/ModoLicencia.cs`; `src/GPOS.Core/Sistema/Licencia/EstadosLicencia.cs`; ruta anónima `/api/salud` en `src/GPOS.Api/Program.cs:395` | Licencia de laboratorio vigente hasta al menos `T0+120 d`, con la sonda por `/api/salud` (LS-15, secciones 3 y 6.5) |

### Observaciones de diseño sobre lo firmado

Ninguna cambia la decisión firmada.

- **O-01 · «FQDN exactos» no se puede expresar.**
  - RFC 5280, 4.2.1.10: una restricción `dNSName` admite el nombre **y sus subdominios**. Una llave de CA filtrada puede emitir para `x.srv-c01.<dominio>`, pero no para `xsrv-c01.<dominio>` ni para el dominio padre.
  - La comprobación del SAN con CA fijada lo cierra en MAUI, las estaciones y la Web (LAB-28); en los navegadores queda un residual Bajo.
  - La forma con punto inicial (`.srv-c01…`) **no** se usa: no es portable entre verificadores [I].
  - Va al Arquitecto Maestro como nota de lectura de PT-07.
- **O-02 · Sitio sin nombre DNS.** Una CA sin ningún subárbol `dNSName` no limita los nombres DNS.
  - El verbo lo rechaza (LAB-33).
  - `comprobar-servidor` comprueba que la CA instalada tiene al menos un subárbol `dNSName` y uno `iPAddress` (permitido, o excluido `/0`).
  - Entrega a A y a B.
- **O-03 · Arranque sin certificado anterior.**
  - El registro guarda también `HuellaAnterior`, que pasa **las mismas validaciones** que la vigente (LAB-41).
  - Orden de escritura: primero `HuellaAnterior`, después `Huella`. Una interrupción entre las dos no deja ninguna huella apuntando a un certificado sin validar.
  - Al arrancar, se usa la vigente; si no sirve, la anterior; si ninguna sirve, el servicio se detiene con un evento crítico.
  - Contrato de PT-02 para A (LAB-42).
- **O-04 · La Web hacia la API.**
  - Propuesta de este diseño: la Web valida a la API con P-FIJADA y la CA del sitio, que lee de `%ProgramData%\GPOS NG\Servidor\tls\`. Esa carpeta solo la escriben Administradores y SYSTEM (H-12), y su integridad es la de ese ACL.
  - **BP-A (5.2) decide otra cosa:** `ClienteApiLocal` valida con el almacén del sistema, sin devolución de llamada propia, y exige la CA en `LocalMachine\Root` del servidor (su riesgo R-11, Bajo). El laboratorio prueba el diseño de BP-A (LAB-22) y deja la diferencia a A (C-A1, sección 11).
  - En Linux (ADR-129, C8), el equivalente es la raíz pública en `/etc/gpos-ng/`, con dueño root y modo 0644 [I].
  - Con un «certificado del cliente», la Web usa el modo sin CA fijada (sección 4).
- **O-05 · EKU en la CA (Q-LAB-01).** Las Name Constraints solo limitan **nombres**. Con la llave de la CA filtrada se podrían firmar:
  - código (Authenticode);
  - correo S/MIME (`rfc822Name` no está restringido);
  - certificados de cliente,

  todos válidos para los puestos que tienen la CA en `LocalMachine\Root`. LAB-30 y LAB-30b miden ese riesgo.
- **O-06 · Revocación con el «certificado del cliente» (Q-LAB-02).**
- **O-07 · `NotBefore` y el reloj de los puestos (LS-06).** Con hojas de 90 días se cambia de certificado cada 60 días. Si `NotBefore` es la hora exacta de emisión, un puesto con el reloj atrasado unos minutos rechaza la hoja nueva en cuanto se publica.
  - Contrato del verbo: `NotBefore` = emisión − 1 h. `NotAfter` sigue a 90 días de la emisión, así que la vida útil no se alarga.
  - Lo prueban LAB-20b, LAB-32 y LAB-38b.
- **O-08 · Origen del ancla (LS-03).** El QR y el alta manual traen el **SPKI** de la CA, pero `CustomTrustStore` necesita el **certificado**. Si el cliente tomara del saludo una raíz con ese SPKI, quien tenga la llave de la CA podría presentar una raíz autofirmada con la misma llave, **sin NC ni EKU**. La regla está en la sección 4 y la prueban LAB-80a a LAB-80c.
- **O-09 · Modo sin CA fijada (LS-05).** Con un certificado público o de dominio, la condición 4 rompe certificados legítimos con comodín o con varios SAN, y no aporta seguridad (una CA pública no tiene NC). La regla está en la sección 4 y la prueba LAB-81. Si el comodín se considera un cambio de RT-10 punto 5, va al Arquitecto Maestro (sección 11).
- **O-10 · Alta del ancla (LS-20).** Quien tenga la llave de la CA puede servir, durante el alta, una autofirmada con el mismo SPKI y NC amplias, y quedar fijada. Además, si el código de emparejamiento viaja por la conexión todavía sin validar, un atacante en la red se lo lleva. Las reglas están en la sección 4.1 y las prueban LAB-84 y LAB-85.
- **O-11 · Bajada de modo (LS-21).** Si un alta manual sin huella activara el modo público, MAUI pasaría a confiar en todo el almacén del sistema ante un servidor con CA propia. La regla está en la sección 4.2 y la prueba LAB-86.

### 2.1 Alineación con el blueprint de A (BP-A)

El laboratorio usa los nombres y contratos de BP-A:
- **Registro** `HKLM\SOFTWARE\GPOS NG\Servidor` (vista de 64 bits): `ModoRed`, `PuertoApi`, `PuertoWeb`, `NombresServidor`, `HuellaApi`, `HuellaWeb` e `IpNodos`. Las huellas son el SHA-256 del DER, en 64 caracteres hexadecimales en mayúsculas (BP-A 4.1).
- **Selector:** `SelectorCertificadoServidor`, con `TlsHandshakeCallbackOptions` y `SslStreamCertificateContext` y un refresco con `PeriodicTimer` de 5 min sobre `TimeProvider`, fuera del saludo (BP-A 5.2).
- **Puntos de inyección para el laboratorio:** `IFuenteConfiguracionRed`, `IAlmacenCertificadosServidor` y `TimeProvider`, más la sobrecarga interna `ClienteApiLocal.CrearManejador(red, raizPruebas)`.
- **Eventos** (BP-A 5.5):
  - 4747 `TlsCertificadoNoDisponible`;
  - 4748 `TlsCertificadoNuevoNoUsable`;
  - 4749 `TlsCertificadoCambiado`;
  - 4743 a 4746, de configuración y escucha.

  Los avisos a 20, 10 y 3 días son de la tarea de B (origen de N-8).
- **Web → API:** `ClienteApiLocal`, con `https://<NombresServidor[0]>:<PuertoApi>` y `ConnectCallback` a `127.0.0.1` y, si falla, a `::1`.
- **Linux:** BP-A devuelve `SinModo` en Linux (4.2), así que R-L espera la fuente Linux de A.

Las diferencias se resuelven en la sección 11 (C-A1 a C-A5).

---

## 3. Entorno del laboratorio

**Dónde corre:**
- En un anfitrión Hyper-V que designe el coordinador de B.
- **Nunca** en la PC del propietario ni en OSHIN-LEGION.
- Licencias: USD 0, con las imágenes de evaluación de Windows Server (180 días) y de Windows 11 Enterprise (90 días) [I: plazos públicos, no revisados en esta sesión] y con Ubuntu, que es libre.

| VM | Sistema | Papel | Software |
|---|---|---|---|
| `VM-SRV` | Windows Server 2025 (compilación 26100), generación 2, **vTPM**, grupo de trabajo | Servidor de sitio | Runtime de ASP.NET Core 10.0 con el parche del producto (10.0.12 o posterior [V], `tests/GPOS.Tests/GPOS.Tests.csproj`); SQL Server 2022 Express; en la fase 2, el paquete único de B |
| `VM-PUESTO` | Windows 11 24H2 o posterior, grupo de trabajo | Puesto y cliente | Edge, Chrome, Firefox estable (≥ 120) y Firefox ESR; runtime de .NET 10; en la fase 2, el agente de impresión y MAUI en Windows |
| `VM-LNX` | **Ubuntu Server 24.04 LTS** (la única distribución de ADR-129, bloque I), x64 | Cliente Linux: la Web hacia la API y la estación | Runtime de .NET 10 y la OpenSSL de la distribución (serie 3.0 [I]); sin interfaz gráfica |

**Red:**
- Conmutador **interno** `GPOS-LAB`, sin salida a Internet durante los casos. La salida solo se habilita para preparar las VM y se retira antes del punto de control base.
- Direcciones de `VM-SRV`: `192.168.50.10/24`, con la secundaria `.11`, y `fd00:50::10/64`. `VM-PUESTO`: `.20`. `VM-LNX`: `.30`.
- Nombres en `hosts`, sin servidor DNS:
  - del sitio: `srv-c01.gposlab.test`, `gpos-c01.gposlab.test` y `srv-c02.gposlab.test`;
  - nombres trampa: `xsrv-c01.gposlab.test`, `a.srv-c01.gposlab.test` y `www.banco-prueba.test`;
  - nombres del modo público (LAB-81): `srv.cliente-prueba.test`, `fsrv.cliente-prueba.test`, `cliente-prueba.test`, `a.b.cliente-prueba.test` y `x.test`.
- `.test` está reservado por RFC 6761. No se usa `.local` (PT-03).

**Bases:** solo en la fase 2, en `VM-SRV`: `GPOS_SYSDATA` y la empresa `GPOS_LAB_TLS`, creadas con `GPOS.Migracion`. No se emiten documentos fiscales (F-06).

**Licencia de laboratorio (LS-15):** vigente hasta al menos `T0+120 d`. Un 403 de licencia durante el bloque R se registra como evento ajeno al TLS y no cuenta como error de la sonda (sección 6.5).

**Reloj (bloque R):**
1. En el anfitrión, desactivar la sincronización de hora de `VM-SRV` y de `VM-PUESTO`, seleccionando el servicio de integración por su Id con `Get-VMIntegrationService`. En un anfitrión en español el nombre está traducido [I].
2. En las VM, dejar `w32time` detenido y deshabilitado.
3. Mover el reloj con `Set-Date` en una consola elevada.
4. Volver atrás solo restaurando un punto de control, salvo en LAB-46.
5. Puntos de control en `T0`, `T0+50 d` y `T0+61 d`.
6. Si el RTC virtual reajusta la hora al arrancar [I], los servicios se dejan en inicio manual y la tarea «al iniciar» se lanza con `schtasks /run`.

**CA y certificados de prueba (oráculo):**
- Los genera el arnés **en la VM**, con `CertificateRequest`, y la extensión NC se escribe con `AsnWriter`.
- El oráculo **no** reutiliza el código del verbo `tls`.
- Algoritmo: ECDSA P-256 con SHA-256 (A5 de ADR-64).
- Todo certificado lleva el marcador `O=GPOS-LAB-TLS`. Las hojas de sujeto vacío lo llevan en una extensión privada **no crítica**; si fuera crítica, todas fallarían como en LAB-75. Además, el generador registra la lista de huellas que crea, y la limpieza puede usar esa lista.
- **Llaves de las CA:** efímeras. Se destruyen después de emitir, salvo las del bloque B, que se guardan como CNG no exportables en `VM-SRV`.
- **Llaves de las hojas** que sirve `VM-SRV`: persistentes y no exportables en el proveedor de software.
- Nunca se escribe un PFX ni una llave a disco, y no hay contraseñas (ADR-44).
- Solo la parte pública de las CA viaja a `VM-PUESTO` y a `VM-LNX`.

**Evidencia común:**
- CAPI2 activado (`Microsoft-Windows-CAPI2/Operational`) en las VM Windows;
- versión exacta de Windows (con la UBR), de .NET, de OpenSSL (`openssl version -a`) y de cada navegador.

---

## 4. Política de validación que se somete a prueba

El laboratorio prueba esta política, que se propone como contrato del **validador único** de A, compartido por MAUI, la estación y la Web (LS-16, entrega a A). Rige igual en Windows y en Linux.

### 4.1 Con la CA fijada (P-FIJADA)

**Ancla (LS-03):**
1. **Al emparejar**, el cliente obtiene el **DER** de la CA, por el QR o por una ruta de solo lectura, y comprueba que el SHA-256 de su SPKI coincide con el del QR o con el del alta manual (PT-08).
2. **Valida el perfil del ancla (LS-20):**
   - los subárboles permitidos de la NC son **exactamente** los nombres de la lista del sitio que trae el QR (DNS e IP), más la exclusión de `0.0.0.0/0` y `::/0` si no hay IP; ni uno más;
   - ninguna extensión crítica desconocida;
   - extensión NC crítica, con al menos un `dNSName`;
   - `pathLen = 0`;
   - autofirma válida;
   - vigencia;
   - EKU, si se firma Q-LAB-01.
3. **Guarda el DER** junto a la URL en el almacén seguro (PT-03).
4. **Nunca** toma un ancla del saludo.
5. **Orden del alta (LS-20):** la ruta de la CA se consulta por una conexión todavía sin validar, y por ella **no viaja ninguna credencial**. El código de emparejamiento de la estación y el inicio de sesión de MAUI solo se envían después de guardar el ancla, por una conexión **nueva** validada con P-FIJADA.
6. Opcional (contrato de A): el QR lleva también el SHA-256 del **DER** de la CA, además del SPKI. El alta manual (PT-08, solo SPKI) depende de la regla de los subárboles exactos.

El formato del QR y de la ruta es contrato de A (SD-10 v2; sección 11).

**Construcción de la cadena (LS-02):**
- `SslStream` recibe `SslClientAuthenticationOptions.CertificateChainPolicy` con esta política, para que su cálculo no use el almacén [I, LAB-23b].
- Además, en la devolución de llamada, el validador construye **su propia** cadena a partir de la hoja, con una política **nueva en cada conexión**:

| Ajuste | Valor | Por qué |
|---|---|---|
| `TrustMode` y `CustomTrustStore` | `X509ChainTrustMode.CustomRootTrust` con los DER guardados (vigente y, si existe, sucesora; máximo dos, PT-04). **Siempre juntos**: con `TrustMode = System`, .NET ignora `CustomTrustStore` [I] | PT-03 |
| `ExtraStore` | Realmente vacío, en la política propia del validador. **No basta como barrera:** `SslStream` agrega al `ExtraStore` los certificados que envía el servidor [I]. La barrera real es `pathLen = 0` más la regla de longitud | LS-02 |
| Longitud | `ChainElements.Count == 2` (hoja → CA fijada), hasta que PT-04 defina el caso del certificado cruzado | LS-02 |
| `DisableCertificateDownloads` | `true` | PT-03; evita AIA hacia URL no confiables |
| `RevocationMode` | `NoCheck` | RT-04: no hay CRL ni OCSP. `Online` u `Offline` darían `RevocationStatusUnknown`, que obligaría a usar `Ignore*` |
| `VerificationFlags` | `NoFlag` | Ningún `Ignore*`: `IgnoreInvalidName` anula las NC. Tampoco `AllowUnknownCertificateAuthority`. Con `NoFlag`, también `HasNotSupportedNameConstraint` y `HasNotDefinedNameConstraint` hacen fallar la cadena (falla cerrada) |
| `ApplicationPolicy` | `serverAuth` (1.3.6.1.5.5.7.3.1). Necesario, pero no suficiente: ver la condición 5 | — |
| `VerificationTime` | Por omisión, la hora local. **Nunca** se fija con datos del servidor | — |

**Criterio de aceptación de una conexión.** Se acepta solo si se cumplen **todas** las condiciones:
1. `sslPolicyErrors == None` y la cadena propia construye con `ChainStatus` **vacío**.
   - No se acepta ninguna marca, tampoco `PartialChain`, y no hay reintentos.
   - Si una hoja buena da una marca, se cambia el perfil de la hoja, no la política.
2. La raíz de la cadena es **idéntica por DER**, o por su SHA-256, a una de las CA guardadas.
3. `MatchesHostname(host, allowWildcards: false, allowCommonName: false)` sobre el host **ya normalizado** (condición 4, regla d).
4. **Nombres del SAN (LS-09).** El SAN existe y **todos** sus nombres están en la lista del sitio que trae el QR. Un «nombre» se define así:
   - a. Solo cuentan `dNSName` e `iPAddress`. Cualquier otro tipo en el SAN (`URI`, `rfc822Name`, `otherName`, `directoryName`, etc.) → rechazo.
   - b. **DNS:** solo ASCII; se compara con `OrdinalIgnoreCase`. Una etiqueta no ASCII (U-label), un punto final o un comodín en el SAN → rechazo. Las A-label (`xn--…`) se comparan como texto ASCII.
   - c. **IP:** se compara por octetos. Una IPv4 mapeada en IPv6 → rechazo.
   - d. **Host de la URL:** una URL con punto final se **rechaza** al darla de alta; la URL se guarda sin punto final (falla cerrada). Así `TargetHost`, que `SocketsHttpHandler` toma de la URI, y `MatchesHostname` ven siempre el mismo nombre (LS-22).

   El origen y la actualización de la lista del sitio se tratan en LS-14 (sección 11).
5. **EKU explícito de la hoja:** la hoja **tiene** la extensión EKU, que contiene `serverAuth` y **no** contiene `anyExtendedKeyUsage`. CryptoAPI trata una hoja sin EKU como válida para todo [I].

### 4.2 Sin CA fijada (certificado público o de dominio del cliente, RT-10 punto 3) (LS-05)

- `TrustMode = System`. **Nunca** se combina con P-FIJADA (PT-03).
- Condición 1 con `RevocationMode` según Q-LAB-02.
- Condición 3 con comodín admitido **solo** como etiqueta izquierda completa (RFC 6125) y sin CN: `MatchesHostname(host, allowWildcards: true, allowCommonName: false)`, más reglas propias (LS-21): sin comodines parciales (`f*.dominio`); el comodín cubre exactamente una etiqueta, ni el apex ni dos niveles; detrás del `*` hay al menos dos etiquetas (`*.a.b`; `*.test` se rechaza), porque `MatchesHostname` no consulta la lista de sufijos públicos [I]; y un host que es una IP nunca casa con un comodín.
- Condiciones 4 b-d solo sobre el host de la URL. **Sin** la lista del sitio: un certificado público lleva el nombre del sitio y no tiene NC que compensar.
- Condición 5 igual que con CA fijada.
- Descargas (AIA): **pendiente de LS-12** (entrega a A y B). La versión 1 de este diseño decía `false`; el auditor recomienda desactivarlas y que el paquete compruebe que el servidor envía la cadena completa. LAB-31b se ejecuta con lo que se decida.
- **Quién fija el modo (LS-21):** solo el QR o una opción explícita «certificado del cliente», visible para el técnico y registrada. Un alta manual **sin huella** nunca activa el modo público; ante un servidor con CA propia, se rechaza (LAB-86).
- Lo que pide la redacción de RT-10 punto 5 sobre el comodín y la bajada de modo va al Arquitecto Maestro (sección 11).

### 4.3 Prueba de arquitectura

En lugar de crecer una lista de patrones, LS-16 (entrega a A) propone:
- un único validador donde se permiten `X509Chain`, `X509ChainPolicy`, `SslPolicyErrors`, las devoluciones de llamada de validación y `X509VerificationFlags`;
- prohibir esos tipos en el resto del código de los clientes;
- exigir los literales `NoFlag` y `CustomRootTrust` en la rama fijada.

---

## 5. Perfiles de prueba

Valores comunes: ECDSA P-256 con SHA-256 y marcador `O=GPOS-LAB-TLS`. Hojas de 90 días; `NotBefore` = emisión − 1 h en las hojas **y en las CA** (LS-22); EKU `serverAuth`, KU `digitalSignature`, sin CDP ni AIA, salvo que se diga otra cosa. CA con `basicConstraints` crítica (`pathLen = 0`), KU `keyCertSign` y `cRLSign`, SKI y AKI.

**Autoridades:**

| Id | Descripción | NC (críticas) |
|---|---|---|
| CA-A | CA del sitio C01 | Permitidos: `dNSName` `srv-c01.gposlab.test` y `gpos-c01.gposlab.test`; `iPAddress` `192.168.50.10/32` y `fd00:50::10/128` |
| CA-A0 | CA del sitio C01 sin IP | Mismos `dNSName`; **excluidos** `0.0.0.0/0` y `::/0` |
| CA-U | CA de «un equipo» | `localhost`, `127.0.0.1/32` y `::1/128` |
| CA-B | CA de otro sitio (C02) | `srv-c02.gposlab.test` |
| CA-I | Impostora: mismo sujeto y mismas NC que CA-A, otra llave | Igual que CA-A |
| CA-I2 | Impostora con el mismo sujeto **y el mismo SKI** que CA-A, otra llave | Igual que CA-A |
| CA-SPKI | Autofirmada con **la misma llave**, el mismo sujeto y el mismo SKI que CA-A, sin NC ni EKU (simula la llave filtrada, LS-03) | Ninguna |
| CA-SPKI-AMPLIA | Autofirmada con la misma llave que CA-A y NC **amplias** (LS-20) | Permitidos: `dNSName` `test`; `iPAddress` `0.0.0.0/0` |
| CA-A2 y X-A2 | Sucesora de CA-A (otra llave) y su **certificado cruzado**: sujeto y llave de CA-A2, emitido y firmado por CA-A, con `basicConstraints` de CA (bloque S) | Iguales a CA-A |
| CA-A2E | CA-A2 con un EKU distinto del de la vigente (o sin EKU), con su cruzado (bloque S, Q-LAB-01) | Iguales a CA-A |
| X-A2-AMPLIO / X-A2-ESTRECHO | Cruzados con NC más amplias que CA-A (por ejemplo, `gposlab.test`) o más estrechas (solo `srv-c01…`) | Según el nombre |
| X-A2-I | «Cruzado» de CA-A2 firmado por CA-I (otra llave) | Iguales a CA-A |
| CA-A-VENC / CA-A-FUT | CA-A vencida, o con `NotBefore` futuro | Igual que CA-A |
| CA-A2 | Sucesora con **el mismo DN** que CA-A y otra llave | Igual que CA-A |
| CA-S | «Raíz del sistema» (corporativa o de un tercero), en `LocalMachine\Root` | Ninguna |
| CA-X | Control sin NC ni EKU | Ninguna |
| CA-AE | CA-A con EKU `serverAuth` (Q-LAB-01) | Igual que CA-A |
| CA-CRIT | CA-A con una extensión crítica desconocida | Igual que CA-A |
| CA-N1 | Raíz con NC `srv-c01…` y `pathLen = 1` | `srv-c01.gposlab.test` |
| Sub-N | Intermedia de CA-N1, **sin NC** o con NC que permiten `www.banco-prueba.test` | Laxa |
| Sub-A | Intermedia de CA-A (viola `pathLen = 0`) | — |
| CA-X1 y Sub-X | Control: raíz sin `pathLen` ni NC, con su intermedia | Ninguna |
| Sub-AIA | Intermedia de CA-X1 que **no se entrega** a nadie y solo es alcanzable por AIA | — |

**Hojas.** Las emite CA-A salvo indicación.

| Id | Sujeto | SAN | Particularidad |
|---|---|---|---|
| H-DNS | vacío | `srv-c01.gposlab.test` (crítico) | Perfil propuesto para el verbo |
| H-CN | `CN=srv-c01.gposlab.test` | `srv-c01…` | — |
| H-IP | vacío | `srv-c01…`, `192.168.50.10` y `fd00:50::10` | — |
| H-FUERA | vacío | `www.banco-prueba.test` | — |
| H-MEZCLA | vacío | `srv-c01…` y `www.banco-prueba.test` | — |
| H-SUFIJO / H-PADRE / H-SUB | vacío | `xsrv-c01…` / `gposlab.test` / `a.srv-c01…` | — |
| H-COMODIN | vacío | `*.gposlab.test` | — |
| H-IPFUERA / H-IPMAP | vacío | `192.168.50.11` / `::ffff:192.168.50.10` | — |
| H-SINSAN | `CN=srv-c01…` | — | — |
| H-CNDIST | `CN=www.banco-prueba.test` | `srv-c01…` | — |
| H-SANNC | vacío | `srv-c01…` (no crítico) | — |
| H-CLI | vacío | `srv-c01…` | EKU solo `clientAuth` |
| H-SINEKU / H-ANYEKU | vacío | `srv-c01…` | Sin la extensión EKU / EKU `anyExtendedKeyUsage` |
| H-URI / H-MAILSAN / H-UPN | vacío | `srv-c01…` más `URI https://www.banco-prueba.test/`, `rfc822Name` de prueba u `otherName` UPN | — |
| H-CRIT | vacío | `srv-c01…` | Extensión crítica desconocida |
| H-MAYUS | vacío | `SRV-C01.GPOSLAB.TEST` | — |
| H-PUNTO / H-ULABEL / H-ALABEL | vacío | `srv-c01.gposlab.test.` / U-label en `IA5String` / A-label `xn--…` del sitio, con NC equivalentes | — |
| H-VENC / H-FUT | vacío | `srv-c01…` | Fuera de vigencia (H-FUT, a días vista) |
| H-AHORA | vacío | `srv-c01…` | `NotBefore` = ahora, **sin** el margen de 1 h |
| H-AIA | vacío | `srv-c01…` | AIA `caIssuers` y CDP hacia `http://192.168.50.10:8080/` |
| H-AIAINT | vacío | `srv-c01…` | La emite **Sub-AIA**, con AIA hacia el escucha |
| H-API | vacío | `srv-c01…` sin `localhost` | Certificado de la API (PT-01) |
| H-PATH | vacío | `srv-c01…` | La emite Sub-A |
| H-LAXA | vacío | `www.banco-prueba.test` | La emite Sub-N |
| H-CODE-NC | vacío | `srv-c01…` | EKU `codeSigning`; emitida por CA-A, por CA-AE y, como control, por CA-X |
| H-MAIL | vacío | `srv-c01…` más `rfc822Name` de prueba | EKU `emailProtection`; emitida por CA-A y por CA-AE |
| H-PUB-COMODIN / H-PUB-3SAN | vacío | `*.cliente-prueba.test` / tres nombres de `cliente-prueba.test` | Las emite CA-S |
| H-PUB-PARCIAL / H-PUB-TLD | vacío | `f*.cliente-prueba.test` / `*.test` | Las emite CA-S (LS-21) |
| H-A2 | vacío | `srv-c01…` | La emite CA-A2 |

---

## 6. Matriz de casos

**Evidencia por caso** (bloques N, N-L, F y V): un JSON con el caso, la plataforma, las versiones de SO, .NET y OpenSSL, `Build`, el `ChainStatus` de cada elemento, las huellas de la cadena, `sslPolicyErrors` y la decisión del validador. En Windows se añade el extracto de CAPI2 y en Linux la salida de `openssl verify`.

**Criterio general:**
- Un caso aprueba si coincide con lo esperado.
- Los **informativos** aprueban si quedan registrados.
- Si un cliente de GPOS NG acepta algo que debía rechazar, el hallazgo es **Alto** y bloquea RT-08 y RT-10.

### 6.1 Bloque N · `X509Chain` en Windows (fase 1; P-FIJADA y validador del oráculo salvo indicación)

| Id | Entrada | Resultado esperado | Criterio |
|---|---|---|---|
| LAB-01 | CA-A + H-DNS | `ChainStatus` vacío, 2 elementos, validador acepta | Exacto |
| LAB-02 | CA-A + H-CN | Válida. Si Windows marca algo [I], el verbo emite el sujeto vacío; la política **no** se relaja | Resultado registrado y perfil del verbo fijado |
| LAB-03 | CA-A + H-IP | Válida | Exacto |
| LAB-04 | CA-A + H-FUERA | Rechazo con marca de NC (`HasNotPermittedNameConstraint` [I]) | `Build = false` y marca de NC |
| LAB-05 | **Control:** CA-X + H-FUERA | Cadena válida | Si LAB-04 y LAB-05 rechazan los dos, LAB-04 no demuestra nada |
| LAB-06 | CA-A + H-MEZCLA | Rechazo | Como LAB-04 |
| LAB-07 | CA-A + H-SUFIJO | Rechazo (comparación por etiquetas) | Como LAB-04 |
| LAB-08 | CA-A + H-PADRE | Rechazo | Como LAB-04 |
| LAB-09 | CA-A + H-SUB | **Informativo:** RFC 5280 lo permite (O-01); el validador rechaza (LAB-28) | Registrado |
| LAB-10 | CA-A + H-COMODIN | Rechazo | Como LAB-04 |
| LAB-11 | CA-A + H-IPFUERA | Rechazo | Como LAB-04 |
| LAB-12 | CA-A + H-IPMAP | Rechazo: 16 octetos no casan con una restricción de 8 [I]; el validador rechaza por la regla 4c | Rechazo del validador; la cadena, registrada |
| LAB-13 | CA-A0 + H-IP (IPv4 e IPv6 por separado) | Rechazo con `HasExcludedNameConstraint` [I] | Como LAB-04; si sale `HasNotSupportedNameConstraint`, ver la sección 8, punto 5 |
| LAB-14 | **Control:** CA-A0 + H-DNS | Válida | Exacto |
| LAB-15 | CA-A + H-SINSAN | Registrar `X509Chain` y `SslStream` por sí solos. El validador rechaza | Rechazo del validador |
| LAB-16 | CA-A + H-CNDIST | **Informativo** para la cadena. El validador no mira el CN | Registrado |
| LAB-17 | CA-A + H-SANNC | **Informativo** | Registrado |
| LAB-18 | **(a) Oráculo:** `X509Chain` con CA-A fijada y Sub-A en el `ExtraStore` de una cadena de prueba (no la del validador) → H-PATH. **(b) Validador:** un Kestrel de prueba envía Sub-A en el saludo. **Control:** CA-X1 → Sub-X → hoja, con Sub-X en `ExtraStore` | (a) `Build = false` con `InvalidBasicConstraints` en **cualquier** elemento [I]. (b) `sslPolicyErrors = RemoteCertificateChainErrors` [I]; la cadena propia del validador da `PartialChain`, porque no ve Sub-A; el validador rechaza. Control: válida | (a) exige la marca de `pathLen`, y ahí no vale `PartialChain`. (b) basta con el rechazo y los estados registrados (LS-19) |
| LAB-19 | CA-A + H-CLI | Rechazo por EKU | `Build = false` y validador rechaza |
| LAB-20 | CA-A + H-VENC; CA-A + H-FUT | Rechazo `NotTimeValid` | `Build = false` |
| LAB-20b | **LS-06:** reloj del cliente 10 min por detrás (`VerificationTime` simulado solo en la prueba del oráculo). CA-A + H-AHORA; CA-A + H-DNS (con el margen de −1 h) | H-AHORA: rechazo `NotTimeValid`; H-DNS: válida | Exacto. Justifica el margen de O-07 |
| LAB-21 | CA-U + hoja {`localhost`, `127.0.0.1`, `::1`}; CA-U + H-DNS | Válida la primera; rechazo la segunda | Exacto |
| LAB-22 | PT-01 con el diseño de BP-A (5.2). **Fase 1 (oráculo):** Kestrel de prueba en *loopback* con H-API; cliente con `ConnectCallback` TCP a `127.0.0.1` (y `::1` si falla), URL `https://srv-c01.gposlab.test:<PuertoApi>` y CA-A en `LocalMachine\Root` de la VM. **Fase 2:** `ClienteApiLocal.CrearManejador(red)`. Después, URL `https://localhost:<PuertoApi>` y un destino distinto de `DireccionApi` | Conecta, y el SNI recibido es `srv-c01.gposlab.test`. Con `localhost`, rechazo por nombre. Con otro destino, «destino no permitido» (BP-A) | Exacto. Compartido con RT-05. La variante con P-FIJADA (O-04) solo si A la adopta (C-A1) |
| LAB-23a | **En memoria:** `SslStream` con `CertificateChainPolicy` = P-FIJADA ante H-DNS | La devolución de llamada recibe `None` | Exacto |
| LAB-23b | **Solo en la VM (LS-01):** CA-S **instalada** en `LocalMachine\Root`, con una hoja de CA-S para `srv-c01`. (a) control con `TrustMode = System`; (b) P-FIJADA con {CA-A} | (a) `None`; (b) `RemoteCertificateChainErrors` | Las dos. Demuestra que `SslStream` no usa el almacén |
| LAB-71 | **Intermedia laxa (N-A):** `X509Chain` del oráculo con CA-N1 fijada y Sub-N en `ExtraStore` → H-LAXA. **Control:** CA-X1 → Sub-X (en `ExtraStore`) → hoja `www.banco-prueba.test` | `Build = false` con una marca de NC, **no** `PartialChain`; el control es válido. El validador, además, rechaza por longitud | Exacto (LS-19). Sirve también para el punto 2 de la sección 8 |
| LAB-72 | **Mismo SKI (N-B):** CA-I2 + su hoja, con P-FIJADA {CA-A} | Rechazo, por firma o por `PartialChain` si CryptoAPI descarta al candidato [I] | Rechazo (LS-22). Demuestra que el emisor no se elige solo por el identificador |
| LAB-73 | **EKU de la hoja (N-C):** CA-A + H-SINEKU; CA-A + H-ANYEKU | La cadena puede aceptarlas [I]; **el validador rechaza** (condición 5) | Rechazo del validador |
| LAB-74 | **Otros tipos de nombre (N-D):** CA-A + H-URI, H-MAILSAN y H-UPN | Cadena registrada; **el validador rechaza** (regla 4a) | Rechazo del validador |
| LAB-75 | **Extensión crítica desconocida (N-E):** CA-A + H-CRIT; CA-CRIT + H-DNS | H-CRIT: rechazo (`HasNotSupportedCriticalExtension` [I]). CA-CRIT en la cadena: **informativo**, porque CryptoAPI puede no revisar las extensiones críticas del ancla [I]; la regla de alta la rechaza (LAB-85) | H-CRIT: `Build = false`. CA-CRIT: registrado |
| LAB-76 | **IPv4 mapeada contra exclusiones (N-F):** CA-A0 + H-IPMAP | Rechazo | Rechazo del validador; la cadena, registrada |
| LAB-77 | **Mayúsculas (N-G):** CA-A + H-MAYUS, con la URL en minúsculas | Válida en la cadena y en el validador | Exacto |
| LAB-78 | **Punto final e IDN (N-H):** alta con la URL `https://srv-c01.gposlab.test.:p`; CA-A + H-PUNTO; H-ULABEL; H-ALABEL con NC en A-label | La URL con punto final se **rechaza** al darla de alta (falla cerrada; LS-22). H-PUNTO y H-ULABEL: el validador rechaza. H-ALABEL: válida | Exacto |
| LAB-79 | **CA fijada vencida o futura (N-I):** CA-A-VENC y CA-A-FUT en `CustomTrustStore`, con una hoja vigente de cada una | Rechazo `NotTimeValid` en el elemento de la CA | `Build = false` |

### 6.2 Bloque F · CA fijada que excluye el almacén del sistema (fase 1)

LAB-23b, LAB-24 a LAB-26, LAB-30, LAB-30b, LAB-31, LAB-31b y LAB-81 tocan almacenes de máquina y corren **solo en la VM**, cada uno en **su propio proceso** (LS-11).

| Id | Entrada | Resultado esperado | Evidencia | Criterio |
|---|---|---|---|---|
| LAB-24 | CA-S en `LocalMachine\Root` y una hoja de CA-S para `srv-c01`. (a) `TrustMode = System`; (b) P-FIJADA {CA-A} | (a) válida; (b) rechazo (`UntrustedRoot` o `PartialChain`; el validador rechaza las dos) | JSON y CAPI2 | (b) rechazo con (a) válida |
| LAB-25 | CA-B en `LocalMachine\Root` y una hoja de CA-B para `srv-c02`; P-FIJADA {CA-A} | Rechazo | JSON | Rechazo |
| LAB-26 | CA-I en `LocalMachine\Root` y una hoja de CA-I para `srv-c01`; P-FIJADA {CA-A} | Rechazo (firma y AKI) | JSON con SKI y AKI | Rechazo |
| LAB-27 | CA-A + H-AIA, con un escucha HTTP en `192.168.50.10:8080` | Válida en menos de 1 s, con **cero** peticiones al escucha y sin recuperaciones en CAPI2 | Registro del escucha, CAPI2 y tiempo | Las tres condiciones. Prueba `NoCheck`, no las descargas (ver LAB-27b) |
| LAB-27b | **Descarga necesaria (LS-08):** H-AIAINT, con CA-X1 fijada y Sub-AIA solo alcanzable por AIA | `PartialChain` y **cero** peticiones al escucha | Escucha y CAPI2 | Las dos. Prueba `DisableCertificateDownloads` |
| LAB-28 | Defensa con CA fijada: H-SUB y una hoja con SAN {`gpos-c01…`} cuando el QR solo trae `srv-c01…` | El validador rechaza las dos | Decisión del validador | Rechazo |
| LAB-29 | Dos CA fijadas, CA-A y una sucesora con otro DN: hojas de cada una y de CA-B | Válidas las dos primeras; rechazo la tercera | JSON | Exacto |
| LAB-29b | **Rotación con el mismo DN (LS-08):** {CA-A, CA-A2} fijadas, con hojas de cada una | Cada hoja construye contra su CA (por SKI y AKI y por firma) | JSON | Exacto |
| LAB-30 | **Firma de código (LS-07):** script de prueba firmado con H-CODE-NC emitida por CA-A, por CA-AE y por CA-X, las tres CA en `LocalMachine\Root`; `Get-AuthenticodeSignature` | CA-X: `Valid` (el control prueba que el montaje funciona). CA-A: `Valid` [I], lo que **demuestra el riesgo** de O-05. CA-AE: no válido | Salida del cmdlet | **Solo** si CA-A da `Valid` y CA-AE no, Q-LAB-01 (a) queda demostrada. Si CA-A da no válido, el resultado es no concluyente y se analiza la causa en CAPI2 |
| LAB-30b | **S/MIME (LS-07), informativo:** H-MAIL emitida por CA-A y por CA-AE; `certutil -verify` con la política de aplicación `1.3.6.1.5.5.7.3.4` (correo), porque sin ella no se comprueba ese uso [I] (LS-22) | CA-A: aceptada para correo [I]; CA-AE: rechazada | Salida de `certutil` | Registrado |
| LAB-31 | Modo sin CA fijada (O-06): hoja de CA-S con CDP inalcanzable, `TrustMode = System`, `RevocationMode` según Q-LAB-02 | Con (a) `NoCheck`: válida sin esperas. Con (c) `Online`: rechazo tras el tiempo de espera | JSON y tiempo | Según la opción firmada |
| LAB-31b | **Modo sin CA fijada con la intermedia enviada por el servidor (LS-12):** hoja de una intermedia de CA-S que el servidor envía en el saludo, con descargas según la resolución de LS-12 | Válida sin recuperaciones por red [I] | Escucha y CAPI2 | Se ejecuta con la regla que fijen A y B |
| LAB-80a | **Ataque de LS-03 (LS-18):** H-FUERA y una hoja con SAN `a.srv-c01…` (fuera de la lista), firmadas con la llave de CA-A. Un Kestrel de prueba las sirve con CA-SPKI en el saludo; el cliente tiene guardado el DER de CA-A | **Rechazo**: NC de CA-A en la cadena propia, o condición 4 | Decisión del validador y estados | Rechazo |
| LAB-80b | **Control:** la misma H-FUERA verificada en el oráculo con CA-SPKI como ancla (`CustomTrustStore` {CA-SPKI}) | La cadena se **acepta**: muestra lo que se evita al fijar el DER y no solo el SPKI | JSON | Aceptada |
| LAB-80c | H-DNS servida con CA-SPKI en el saludo | **Se acepta**: el saludo no cambia el ancla y un certificado de más no rompe una hoja legítima | Decisión del validador | Aceptada |
| LAB-81 | **Modo sin CA fijada (LS-05, LS-21):** CA-S en `LocalMachine\Root`. Positivos: H-PUB-COMODIN por `https://srv.cliente-prueba.test`; H-PUB-3SAN. Negativos: H-PUB-PARCIAL por `fsrv.cliente-prueba.test`; H-PUB-COMODIN por el apex `cliente-prueba.test` y por `a.b.cliente-prueba.test`; H-PUB-TLD por `x.test`; H-PUB-COMODIN por `https://192.168.50.10`. Y el modo con CA fijada ante H-COMODIN de CA-A | Positivos: aceptados. Negativos: rechazados (comodín parcial, apex, dos niveles, menos de dos etiquetas tras el `*`, host IP). Modo fijado: rechazo | JSON | Exacto |
| LAB-85 | **Regla de alta del ancla (LS-20), en el oráculo:** el QR trae el SPKI de CA-A y la lista {`srv-c01…`, `gpos-c01…`, `192.168.50.10`, `fd00:50::10`}. Se ofrece en el alta: CA-SPKI-AMPLIA; CA-SPKI; CA-CRIT; CA-A0 con una lista que trae IP; y CA-A | Rechazo de las cuatro primeras (subárboles distintos de la lista, sin NC o extensión crítica desconocida); CA-A aceptada. Con el SHA-256 del DER en el QR, CA-SPKI-AMPLIA también falla por la huella | Decisión de la regla de alta | Exacto |

### 6.2b Bloque S · CA sucesora con certificado cruzado de la vigente (PT-04, LS-13)

Regla que se prueba (oráculo; el contrato definitivo de PT-04 es del Arquitecto Maestro y de A, sección 11). El cliente acepta la sucesora CA-A2 como segunda CA fijada **solo** si se cumplen todas estas condiciones:
1. el cruzado X-A2 valida contra el DER guardado de CA-A, con una política propia (`CustomRootTrust` {CA-A}, `NoFlag`, sin descargas);
2. el SPKI de X-A2 es igual al de CA-A2;
3. CA-A2 se autofirma bien y pasa la regla de alta (sección 4.1): NC iguales a la lista del sitio o más estrechas, ninguna extensión crítica desconocida y `pathLen = 0`;
4. el EKU de CA-A2 y de X-A2 es igual o más estrecho que el de CA-A, si se firma Q-LAB-01 (a);
5. no hay ya dos CA fijadas.

El cruzado **nunca** se acepta en la cadena del saludo.

| Id | Entrada | Resultado esperado | Evidencia | Criterio |
|---|---|---|---|---|
| LAB-87 | CA-A fijada; se presenta CA-A2 con X-A2 (NC iguales). Después, H-A2 | CA-A2 aceptada como segunda fijada; H-A2 válida contra CA-A2 (2 elementos) | JSON | Exacto |
| LAB-87b | Lo mismo con X-A2-ESTRECHO y la sucesora con NC más estrechas | Aceptada | JSON | Exacto |
| LAB-87c | Sucesora y cruzado con el **mismo DN** que CA-A (cruzado autoemitido, RFC 5280, 6.1.4) | Aceptada. Si CryptoAPI confunde la construcción por el DN repetido [I], se registra y va a la entrega de LS-13 | JSON y CAPI2 | Exacto o registrado |
| LAB-88 | X-A2-AMPLIO, o una sucesora sin NC | Rechazo | Decisión de la regla | Rechazo |
| LAB-88b | **Dependiente de Q-LAB-01:** con CA-AE vigente, CA-A2E sin EKU o con un EKU más amplio; y una sucesora con `serverAuth` | Con (a) firmada: rechazo de las dos primeras y aceptación de la tercera. Sin (a): informativo | Decisión de la regla | Según la firma |
| LAB-89 | X-A2-I (firmado por otra llave); una sucesora sin cruzado entregada por la conexión ya validada (H-05); un cruzado cuyo SPKI no coincide con la sucesora | Rechazo de los tres | Decisión de la regla | Rechazo |
| LAB-90 | Con dos CA ya fijadas, una tercera con un cruzado válido. Y un Kestrel de prueba que envía X-A2 en el saludo junto a H-A2, **antes** de aceptar CA-A2 | La tercera se rechaza (máximo dos). La conexión se rechaza: el saludo no aporta anclas y la cadena no tiene 2 elementos | Decisión del validador | Rechazo |

Los resultados de este bloque son **provisionales** hasta que se fije el contrato de PT-04 (formato del cruzado y ruta de la cadena). El recorrido de punta a punta, en la fase 2, es la «rotación» de la sección 1.

### 6.3 Bloque N-L · Linux (ADR-129): declarado; su ejecución depende de Q-LAB-03

- **Plataforma:** `VM-LNX`, con Ubuntu Server 24.04 LTS, .NET 10 y la OpenSSL de la distribución (serie 3.0 [I]).
- **Cuándo (Q-LAB-03 (a)):**
  - en la **fase 1**, solo el subconjunto en memoria: LAB-01-L a LAB-23a-L, LAB-28-L, LAB-71-L a LAB-80c-L y LAB-85-L, con el mismo oráculo y la misma `dotnet test`, en una VM sin escritorio. Así A conoce el comportamiento de OpenSSL antes de fijar el validador único;
  - con el **tramo Linux**: LAB-24-L a LAB-26-L (almacén de la distribución), LAB-91 a LAB-99 (línea de órdenes) y R-L.
- **Alcance:**
  - la Web hacia la API y la estación en modo servicio, que son los validadores del producto en Linux (ADR-129, A1);
  - el bloque B no aplica, porque los navegadores no cambian.
- **Lo que hereda:** el mismo oráculo, que se ejecuta en la VM Linux, y el mismo JSON, con la plataforma registrada.
- **Guarda de VM:** `systemd-detect-virt` más el marcador `/etc/gpos-ng/laboratorio-tls/id` (dueño root, 0644), igual al de la variable de entorno de la sesión, y el nombre de la VM en la lista admitida (LS-11).
- **Casos con .NET en Linux (sufijo `-L`):**
  - LAB-01-L a LAB-23a-L, LAB-28-L, LAB-71-L a LAB-80c-L y LAB-85-L;
  - LAB-24-L a LAB-26-L, con CA-S, CA-B y CA-I en el almacén del sistema de la distribución, instaladas con `update-ca-certificates` solo en la VM.
- **Resultados esperados:**
  - **Los mismos que en Windows para el validador:** toda diferencia del validador entre plataformas es un hallazgo.
  - Las marcas de `ChainStatus` pueden diferir, porque .NET traduce los errores de OpenSSL [I]. Se registran.
  - En LAB-24-L a LAB-26-L, `CustomRootTrust` no consulta el almacén de la distribución [I].

**Oráculo OpenSSL (línea de órdenes, en `VM-LNX`).** Fija qué hace la biblioteca que usa .NET en Linux, sin .NET de por medio. Se ejecuta `openssl verify -x509_strict -purpose sslserver -CAfile <ca> [-untrusted <inter>] [-verify_hostname <h> | -verify_ip <ip>] <hoja>`. Los códigos son los de OpenSSL 3 [I sobre el número exacto de cada uno].

| Id | Entrada | Esperado [I] |
|---|---|---|
| LAB-91 | CA-A + H-DNS, con `-verify_hostname srv-c01.gposlab.test` | `OK` |
| LAB-92 | CA-A + H-FUERA; **control** con CA-X + H-FUERA | `X509_V_ERR_PERMITTED_VIOLATION`; el control da `OK`. OpenSSL aplica las NC de toda la cadena, también las del ancla [I] |
| LAB-93 | CA-A + H-SUFIJO, H-PADRE y H-MEZCLA | `X509_V_ERR_PERMITTED_VIOLATION` |
| LAB-94 | CA-A + H-IPFUERA, con `-verify_ip 192.168.50.11`; CA-A0 + H-IP | `X509_V_ERR_PERMITTED_VIOLATION`; `X509_V_ERR_EXCLUDED_VIOLATION` |
| LAB-95 | CA-A + H-SINSAN, con `-verify_hostname srv-c01…` | Se registra. OpenSSL compara el CN con las NC de `dNSName` cuando falta el SAN [I] y puede aceptar el nombre por el CN. El validador lo rechaza igual (condiciones 3 y 4) |
| LAB-96 | CA-A → Sub-A → H-PATH, con `-untrusted`; CA-N1 → Sub-N → H-LAXA | `X509_V_ERR_PATH_LENGTH_EXCEEDED`; `X509_V_ERR_PERMITTED_VIOLATION` |
| LAB-97 | CA-A + H-CLI, H-VENC, H-FUT y H-CRIT | `X509_V_ERR_INVALID_PURPOSE`, `X509_V_ERR_CERT_HAS_EXPIRED`, `X509_V_ERR_CERT_NOT_YET_VALID` y `X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION` |
| LAB-98 | CA-A + H-SINEKU, con `-purpose sslserver` | **Informativo:** OpenSSL acepta una hoja sin EKU para `sslserver` [I]; el validador la rechaza (condición 5) |
| LAB-99 | Hoja de CA-I con `-CAfile` CA-A; H-FUERA con `-CAfile` CA-SPKI | `X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY` o `X509_V_ERR_CERT_SIGNATURE_FAILURE`; la segunda da `OK` (**informativo**: muestra por qué se fija el DER y no solo el SPKI; LS-22) |

**Bloque R-L, pendiente.** En Linux no existe `HKLM`, y ADR-129 (C15) deja delante de la Web «nginx o Kestrel con HTTPS». El equivalente de PT-02 (dónde vive la huella vigente, quién lo escribe y cómo se recarga sin reiniciar) lo diseña A con el tramo Linux [I]. Cuando exista, R-L repite LAB-37 a LAB-48 con ese mecanismo.

### 6.4 Bloque V · Conformidad del producto (fase 2)

| Id | Entrada | Resultado esperado | Evidencia | Criterio |
|---|---|---|---|---|
| LAB-32 | `GPOS.Migracion tls --crear-ca --emitir` en `VM-SRV`, en «servidor de sitio» con DNS e IP y sin IP, y en «un equipo» | La CA y las hojas se leen con `AsnReader` y con `certutil -dump`. Deben salir:<br>- NC **crítica** con los DNS de `NOMBRES_SERVIDOR`, IP en 8 y 32 octetos con máscara completa, o excluidos `/0`;<br>- `pathLen = 0`;<br>- `NotBefore` = emisión − 1 h **también en la CA** (LS-22);<br>- hoja ECDSA P-256 con SHA-256, 90 días, **`NotBefore` = emisión − 1 h** (O-07) y EKU `serverAuth`;<br>- sujeto vacío con SAN crítico, o CN ∈ SAN según LAB-02;<br>- sin CDP ni AIA;<br>- sin `localhost` en la API de «servidor de sitio» | Volcados | Cada campo igual al perfil |
| LAB-33 | El verbo con entradas inválidas: sin ningún nombre DNS (O-02), una subred `/24` en lugar de una IP, un `.local`, un comodín, mayúsculas, punto final y nombres no ASCII (regla 4 de LS-09) | Salida distinta de 0, sin CA y con mensaje claro. Las mayúsculas se normalizan a minúsculas; el resto, rechazo | Salida y almacén | Todas como se espera |
| LAB-34 | Repetir el bloque N y LAB-24 a LAB-29b, LAB-80a a LAB-80c, LAB-81, LAB-85 y el bloque S con el **validador único de A** y, donde aplica, con la CA y las hojas del verbo | Los mismos resultados que el oráculo | JSON | Ninguna diferencia |
| LAB-35 | Estación de punta a punta en `VM-PUESTO`: emparejar por QR, operar y después servir una hoja de CA-S, que está en `LocalMachine\Root` | Rechazo y motivo registrado (PT-03). Hoy aceptaría (F-01) | Registro del agente | Rechazo |
| LAB-35b | **Respaldo heredado (LS-08, LS-10):** la estación nueva ante una hoja cuyo SPKI de hoja estaba fijado en el formato anterior, pero emitida por CA-S o vencida | Rechazo: el camino «SPKI de la hoja» ya no existe | Registro del agente | Rechazo |
| LAB-35c | **Cambio de modo (LS-08):** el servidor pasa de la CA propia a un certificado del cliente | La estación y MAUI rechazan hasta que se vuelve a emparejar (falla cerrada) | Registros | Rechazo |
| LAB-36 | MAUI en Windows: alta manual con 32 caracteres hexadecimales (PT-08) y por QR. Después, el servidor con una hoja de CA-B | Rechazo. La URL y la CA quedan **juntas** en el almacén seguro (DPAPI), no en `Preferences` | Registro de la aplicación; del almacén **solo** la presencia y una huella, nunca su contenido (LS-11) | Las dos condiciones |
| LAB-84 | **Alta contra un impostor (LS-20):** `VM-PUESTO` resuelve `srv-c01…` hacia una VM que sirve CA-I (o CA-SPKI-AMPLIA) y la ruta de la CA, y registra todo lo que recibe. Se dan de alta la estación (QR) y MAUI (QR y manual) | El cliente rechaza la CA. El impostor **no recibe** el código de emparejamiento, ni el secreto, ni credenciales de inicio de sesión: solo la petición de la ruta de la CA. Contra el servidor legítimo, el código viaja por una conexión **nueva** y ya validada | Registro del impostor (redactado) y del cliente | Las tres condiciones |
| LAB-86 | **Bajada de modo (LS-21):** MAUI, alta manual con la URL y **sin huella**, contra el servidor con CA propia (CA-A está en `LocalMachine\Root` de `VM-PUESTO` por el bloque B) | Rechazo: el alta manual sin huella no activa el modo público. El modo público solo se activa desde el QR o la opción explícita «certificado del cliente», que queda registrada | Registro de la aplicación | Rechazo |

### 6.5 Bloque R · Renovación sin reinicio (fase 2)

**Sonda.** Desde `VM-PUESTO`, cada 5 s:
- abre una conexión TLS **nueva** sin reanudar la sesión (`AllowTlsResume = false` [I]);
- llama a la ruta **anónima** `/api/salud` (F-09) y a una ruta operativa.

Registra la huella, `NotAfter` y el resultado. Un 403 de licencia en la ruta operativa se registra **aparte**, como ajeno al TLS, y no cuenta como error (LS-15).

Además se registran:
- el PID de los servicios cada minuto;
- los eventos del origen de N-8;
- el volcado de `HKLM\SOFTWARE\GPOS NG\Servidor`.

| Id | Entrada | Resultado esperado | Criterio |
|---|---|---|---|
| LAB-37 | Estado inicial | `HuellaApi` y `HuellaWeb` (BP-A 4.1) presentes. Un usuario estándar no puede escribir la clave; Administradores y SYSTEM sí. La sonda ve el certificado A | Exacto |
| LAB-37b | **LS-08:** la cuenta `NT SERVICE\GPOS.Api` (y la de la Web) intenta escribir la clave | Denegado | Exacto |
| LAB-38 | Renovación forzada con el verbo | Orden emitir → lectura → comprobar → publicar. Evento 4749 (`TlsCertificadoCambiado`). Certificado B servido en **5 min 30 s o menos** (refresco de 5 min de BP-A), **PID sin cambio**, **cero errores TLS** y A conservado | Todas |
| LAB-38b | **LS-06:** como LAB-38, con `VM-PUESTO` 10 min por detrás del servidor | Cero errores en la sonda y en la estación | Exacto |
| LAB-39 | Huella de un certificado cuya llave la cuenta del servicio no puede leer | Sigue con el anterior; evento 4748 (`TlsCertificadoNuevoNoUsable`) como mucho una vez por huella en cada refresco; sin caída | Exacto |
| LAB-40 | Huella inexistente o ilegible | Igual que LAB-39 | Exacto |
| LAB-41 | Huella de un certificado que se puede abrir pero está vencido, aún no vigente o sin `serverAuth` (criterios de BP-A 5.2); y otro **sin los nombres del sitio** | Los tres primeros: no se adopta, con 4748 (BP-A). El de los nombres: BP-A **no** lo comprueba hoy, así que se adoptaría (C-A3). Resultado esperado: el que fije A | Igual al contrato |
| LAB-41b | **LS-08:** huella de una hoja válida de CA-S presente en `LocalMachine\My` | Recomendado: el selector no la adopta en el modo con CA propia. BP-A no comprueba el emisor hoy (C-A3) | Igual al contrato |
| LAB-42 | Reinicio del servicio con la huella vigente rota | Según BP-A: evento 4747 y no arranca (falla cerrada). Según la propuesta O-03 (C-A2): arranca con `HuellaAnterior` si es válida y, si no, 4747 | Igual al contrato que fije A |
| LAB-43 | Fallo inyectado en el verbo: (a) cuenta del servicio inexistente; (b) escritura de la clave denegada a SYSTEM con una entrada de control de acceso temporal | Salida distinta de 0 y evento; la huella publicada **no cambia**; el servicio sigue con A | Todas |
| LAB-44 | **Reloj adelantado, camino feliz:** `T0` → `T0+61 d` y reinicio del equipo → `T0+91 d` | La tarea renueva. En `T0+91 d`, la Web, la API, la estación y la sonda siguen sin errores TLS y con el PID sin cambio desde la renovación. `comprobar-servidor`, en verde | Todas |
| LAB-45 | **Reloj adelantado, camino de fallo:** tarea deshabilitada; `T0+70`, `+80`, `+87` y `+91` | Avisos a 20, 10 y 3 días. `comprobar-servidor` en rojo por debajo de 20 días. En `T0+91`, todos los clientes rechazan (hoy la estación aceptaría: F-02). Evento crítico. Al habilitar la tarea, se recupera sin reiniciar en 5 min 30 s o menos | Todas |
| LAB-46 | Reloj hacia atrás sin restaurar el punto de control, y otra huella publicada | La nueva se toma en 5 min 30 s o menos: el `PeriodicTimer` de BP-A cuenta intervalos, no la hora del sistema [I]. La inconsistencia del reloj protegido es esperada (F-06). Se restaura el punto de control al terminar | Exacto |
| LAB-47 | Circuito de Blazor abierto durante la renovación | Sigue vivo; al recargar ve B | Sin desconexión forzada |
| LAB-48 | Apagado en `T0+50` y arranque en `T0+95` (A vencido) | Sin intervención, en **10 min o menos** desde el arranque, el servicio sirve B | Recuperación automática |

### 6.6 Bloque B · Navegadores con la raíz en `LocalMachine\Root` (fase 1)

**Montaje:**
- Las CA (CA-A, CA-A0, CA-X, CA-AE y, en el propio equipo, CA-U) se instalan con el guion del arnés, **solo** en `LocalMachine\Root`, desde una consola elevada.
- `VM-SRV` sirve cada caso en un puerto propio (una vinculación de HTTP.sys por puerto) y con un nombre propio en `hosts`.
- Cada caso se abre en un perfil o ventana privada nuevo, y **nunca** se acepta una excepción.

**Evidencia:** captura, código de error, visor de certificados, versión exacta del navegador y, en Firefox, `security.enterprise_roots.enabled`.

**Navegadores:** Edge, Chrome y Firefox estables ejecutan **todo** el bloque. No se recorta Edge (LS-08): es el navegador por omisión de los puestos, y su almacén y su política difieren de los de Chrome [I]. Firefox ESR ejecuta LAB-49 a LAB-58 y LAB-83 (rebaja aceptada por el auditor).

| Id | Entrada | Esperado en todos | Criterio |
|---|---|---|---|
| LAB-49 | CA-A + H-DNS | Carga sin aviso | Exacto |
| LAB-50 | CA-A + H-IP, por IPv4 y por IPv6 | Carga sin aviso | Exacto |
| LAB-51 | CA-A + H-FUERA | Error de NC (Chromium: `NET::ERR_CERT_NAME_CONSTRAINT_VIOLATION` u otro error de certificado [I]; Firefox: `SEC_ERROR_CERT_NOT_IN_NAME_SPACE` [I]) | Error, con LAB-52 cargando |
| LAB-52 | **Control:** CA-X + H-FUERA | Carga | Si no carga, LAB-51 no demuestra nada |
| LAB-53 | CA-A + H-SUFIJO | Error | Error |
| LAB-54 | CA-A + H-SUB | **Informativo** (O-01) | Registrado |
| LAB-55 | CA-A + H-IPFUERA, por `.11` | Error | Error |
| LAB-56 | CA-A0 + H-IP, por la IP | Error | Error |
| LAB-57 | CA-A + H-SINSAN | Error, sin recurrir al CN [I] | Error |
| LAB-58 | CA-A → Sub-A → H-PATH | Error | Error |
| LAB-83 | **B-MEZCLA (LS-08):** CA-A + H-MEZCLA, entrando por `srv-c01…` | Error: se comprueban **todos** los nombres, no solo el pedido | Error |
| LAB-59 | En el propio equipo: CA-U + hoja {`localhost`, `127.0.0.1`, `::1`}; CA-U + H-DNS | Cargan las dos primeras direcciones; error en la tercera | Exacto |
| LAB-60 | Firefox: la CA aparece como importada del sistema; con `security.enterprise_roots.enabled = false`, LAB-49 da emisor desconocido | Exacto | Confirma de dónde toma Firefox la confianza |
| LAB-61 | CA-A retirada de `LocalMachine\Root`, y LAB-49 repetido | Emisor desconocido | Exacto |
| LAB-62 | CA-AE + H-DNS y CA-AE + H-IP | Cargan sin aviso | Exacto. Si un navegador rechaza, Q-LAB-01 (a) no es viable |

### 6.7 Bloque M · Android e iOS (fase móvil; solo declarado)

**Lo que aporta este diseño:**
- el oráculo;
- la política de la sección 4;
- los resultados esperados del validador;
- el formato de evidencia.

**Lo que falta:**
- el ejecutor en el dispositivo (hoy `tests/GPOS.UI.MAUI.Tests` es `net10.0` sin plataforma [V], `GPOS.UI.MAUI.Tests.csproj:3`);
- los dispositivos o emuladores.

**Versiones:** los mínimos del proyecto, API 24 de Android e iOS 15 [V] (`GPOS.UI.MAUI/GPOS.UI.MAUI.csproj:20-22`), más las vigentes en la fecha del laboratorio.

| Id | Qué se probará |
|---|---|
| LAB-63 | Android: qué manejador usa `HttpClient` y si `CustomRootTrust` funciona con él [I] |
| LAB-64 | Android: si se aplican las NC del ancla (casos equivalentes a LAB-01, 04, 05, 07, 11, 13, 15, 18, 71 y 80). Con Java PKIX probablemente **no** se aplican [I]. Por eso se incluye la **variante de dos niveles** (sección 8, punto 2), y la condición 4 pasa a ser el control que sostiene la seguridad |
| LAB-65 | iOS: lo mismo con `SecTrust` y anclas propias [I] |
| LAB-66 | iOS: App Transport Security con el perfil, sin excepciones |
| LAB-67 | Android: sin `<certificates src="user"/>` ni `cleartextTrafficPermitted`; una CA de usuario no valida |
| LAB-68 | La URL y el DER de las CA juntos en Keystore o Keychain (PT-03, LS-03) |
| LAB-69 | QR con el DER o el SPKI de la CA, los nombres del sitio y la sucesora; alta manual con 128 bits |
| LAB-70 | Renovación del servidor con el móvil conectado, sin volver a emparejar |

---

## 7. Arnés: dónde vive, quién lo construye y cómo queda fuera de la suite oficial

**Sin proyectos nuevos.**

### 7.1 Pruebas en `tests/GPOS.Tests/Laboratorio/Tls/`

**Archivos:**
- `PkiLaboratorio.cs`: el oráculo, con su escritor propio de NC con `AsnWriter`;
- `NameConstraintsLaboratorioTests.cs`: bloques N y N-L;
- `CaFijadaLaboratorioTests.cs`: bloque F;
- `ConformidadVerboLaboratorioTests.cs`: fase 2.

**Reglas de las pruebas:**
- Cada archivo lleva `[Trait("Esquema", "Neutral")]` y `[Trait("Categoria", "LaboratorioTls")]`.
- **Exclusión de la suite oficial:** `[FactLaboratorioTls]`, derivado de `FactAttribute`, como los precedentes `FactBp2Attribute`, `FactDemoAttribute` y `FactModoMixtoAttribute` (F-08). Asigna `Skip` si `GPOS_LAB_TLS` no vale `1`. El filtro oficial **no cambia**.

**Guardas para los casos que tocan almacenes, `hosts`, HTTP.sys o el reloj (LS-11):**
1. `GPOS_LAB_TLS_VM=1`.
2. **Marcador** creado solo por `Preparar-Vm.ps1`: en Windows `HKLM\SOFTWARE\GPOS NG\LaboratorioTls\Id` y en Linux `/etc/gpos-ng/laboratorio-tls/id`. Debe ser igual a la variable `GPOS_LAB_TLS_ID` de la sesión.
3. El nombre del equipo, en la lista de VM admitidas del guion.
4. Comprobación de virtualización: `Win32_ComputerSystem` en Windows y `systemd-detect-virt` en Linux.

Si falla cualquiera, la prueba **falla sin tocar nada**.

**Más reglas:**
- **Solo almacenes de máquina**, desde una consola elevada (o `sudo` en Linux). **Nunca** `CurrentUser\Root`, que abre un diálogo de Windows.
- **Un proceso por caso** en los que modifican almacenes: CryptoAPI guarda en caché las cadenas del motor por omisión [I].
- **Ejecución:** `dotnet test tests/GPOS.Tests --filter "Categoria=LaboratorioTls"`, **solo en las VM**.

### 7.2 Guiones en `tests/laboratorio-adr090/`

Es una carpeta **nueva sin proyecto**. Hay precedentes de carpetas de guiones `.ps1` sin proyecto, como `instalador/Demo/scripts/`. `tests/GPOS.EnsayoImplantacion` sí es un proyecto y no sirve de precedente (LS-17).

- `Preparar-Anfitrion.ps1`: comprueba el nombre del anfitrión contra la lista y, si no coincide, se detiene. **Nunca se ejecuta en la PC del propietario.**
- `Preparar-Vm.ps1` y su equivalente `preparar-vm.sh` para `VM-LNX`: marcador, CAPI2, `w32time` y `hosts`.
- `Servir-CasosNavegador.ps1`.
- `Adelantar-Reloj.ps1`: comprueba el nombre de la VM.
- `Sondear-Certificado.ps1`.
- `Recoger-Evidencia.ps1`.
- `limpiar-laboratorio.sh` (`VM-LNX`, LS-22): retira de `/usr/local/share/ca-certificates/` lo que lleve el marcador o figure en la lista de huellas, vuelve a ejecutar `update-ca-certificates` y termina con la restauración del punto de control.
- `Limpiar-Laboratorio.ps1`: retira todo lo que lleve `O=GPOS-LAB-TLS` de `LocalMachine\Root`, `\CA` y `\My`; las vinculaciones de HTTP.sys; las entradas de `hosts`; y la caché de URL de CryptoAPI (`certutil -urlcache * delete`).
- La prueba comprueba el estado limpio **antes** de empezar. Al final de cada fase se restaura el punto de control base, que es la limpieza definitiva.

**Redacción de la evidencia (LS-11).** `Recoger-Evidencia.ps1` no copia:
- códigos de emparejamiento ni el `Secreto` de la estación;
- tokens `disp+jwt`;
- cadenas de conexión;
- el contenido del almacén DPAPI (solo su presencia y una huella).

Al terminar, se revocan los dispositivos del laboratorio.

**Repositorio (LS-11).** B añade a `.gitignore`:
- `*.p12`, `*.key` y `*.pem`, salvo que el proyecto ya los use;
- `tests/laboratorio-adr090/salida/`.

Hoy solo está `*.pfx`, según REV-LAB. La evidencia en bruto **no** va al repositorio `GPOS NG`.

### 7.3 Informe

- **Informe:** `docs/calidad/AAAA-MM-DD-laboratorio-adr090.md`, en `master`.
- **Evidencia en bruto:** ya redactada, en el área común (`GPOS-NG-Equipos`, en la carpeta que fije B).

### 7.4 Quién construye

Respeta el reparto de ADR-90 y §6 de la hoja de PT. **C no construye.** Lo confirma el coordinador de B.

| Pieza | Equipo y agente |
|---|---|
| Oráculo, bloques N, N-L, F y S, conformidad (LAB-32 y LAB-34) y guardas dentro de las pruebas (LS-11, puntos 2 y 4) | **A**, qa (independiente del desarrollador del verbo) |
| VM Windows y `VM-LNX`, anfitrión, marcadores, limpieza, reloj, evidencia, redacción y `.gitignore` (LS-11, puntos 1, 3 y 5 a 7) | **B**, devops |
| Ejecución de las fases 1 y 2 | qa de A con devops de B |
| Revisión de la evidencia | auditor-seguridad |

### 7.5 Promoción a la suite oficial (R-1, para el coordinador de B)

Al cerrar la fase 1, se promueven solo los casos **en memoria y de resultado exacto**, con la plataforma registrada:

LAB-01, 03 a 08, 10, 11, 14, 18 (a), 19 a 21, 23a, 28, 29, 29b, 71, 72, 73, 74, 75 (solo H-CRIT), 77, 79, 80b, 85 y, cuando se fije el contrato de PT-04, 87 a 90 en su parte de oráculo. LAB-80a y LAB-80c necesitan un Kestrel de prueba en *loopback*, igual que LAB-22, y se promueven si caben en el tiempo de la suite.

**No** se promueven:
- LAB-23b y los casos que tocan almacenes;
- los informativos.

Costo inferido: de 2 a 4 s de suite.

**Orden recomendado:**
1. Fase 1 en Windows **antes** de que A escriba el verbo `tls` y el validador. Fija el perfil de la hoja, la codificación de `/0` y la viabilidad de Q-LAB-01.
2. Fase 2 con el paquete único.
3. N-L: el subconjunto en memoria ya en la fase 1; el resto con el tramo Linux (Q-LAB-03).
4. Fase 3 con la fase móvil.

---

## 8. Riesgos y qué hacer si algo no aplica las restricciones

| Riesgo | Prob. / impacto | Mitigación | Residual |
|---|---|---|---|
| `X509Chain` en Windows no aplica las NC del ancla con `CustomRootTrust` | **Media [I] hasta LAB-04 y LAB-05** (como la hoja) / Medio | Punto 1 | Bajo |
| OpenSSL en Linux no las aplica o recurre al CN | Media [I] / Medio | Punto 1 y LAB-91 a LAB-95 | Bajo |
| Un navegador no aplica las NC de una raíz local | Media [I] / Medio | Punto 3 (previsto en ADR-90) | Medio, documentado |
| Un puesto con el reloj atrasado rechaza cada renovación | Media sin O-07 / Medio | `NotBefore` − 1 h y LAB-38b | Bajo |
| Un ancla con el mismo SPKI y sin NC anula las defensas | Baja / Medio | Regla del ancla por DER y regla de alta con subárboles exactos (sección 4.1); LAB-80a a LAB-80c y LAB-85 | Bajo |
| El código de emparejamiento viaja por la conexión del alta sin validar | Baja / Medio | Orden del alta (sección 4.1, punto 5) y LAB-84 | Bajo |
| El contrato de PT-04 cambia y deja obsoleto el bloque S | Media / Bajo | Resultados del bloque S marcados como provisionales; entrega de LS-13 | Bajo |
| Windows marca un perfil de hoja bueno (LAB-02) | Media [I] / Bajo | Sujeto vacío | Ninguno |
| El salto de reloj rompe la VM o la licencia contamina la sonda | Media / Bajo | Puntos de control, licencia hasta `T0+120 d`, `/api/salud` y 403 registrado aparte | Bajo |
| La sonda reanuda la sesión TLS | Media [I] / Bajo | `AllowTlsResume = false` y un proceso nuevo por sonda como control | Bajo |
| El laboratorio corre en una PC no autorizada o deja raíces instaladas | Baja / Alto | Cuatro guardas, limpieza por marcador y restauración del punto de control (sección 7) | Bajo |
| La fase 2 se retrasa | Alta / Bajo | La fase 1 aporta valor sola | — |

**Qué hacer si algo no aplica las restricciones:**
1. **.NET (Windows u OpenSSL) no aplica las NC en el ancla.** Las condiciones 4 y 5 y la regla del ancla por DER sostienen el control en MAUI, las estaciones y la Web: son más estrictas que las NC. Se informa al auditor y no hace falta cambiar el ADR.
2. **Solo se aplican en intermedias** (o en Android, LAB-64). Variante de dos niveles:
   - raíz con NC y `pathLen = 1`;
   - intermedia con NC y `pathLen = 0`.

   LAB-71 ya mide si las NC de la raíz se aplican por debajo de una intermedia. Si hace falta, el Arquitecto Maestro prepara una precisión de RT-02 y PT-07 para firma (de 0,03 a 0,05 sp en el verbo, más 0,02 sp de laboratorio [I]).
3. **Un navegador no las aplica.** Se documenta (ADR-90). Mitigaciones:
   - Q-LAB-01;
   - recomendar la CA de dominio del cliente.
4. **Firefox no lee `LocalMachine\Root`.** Alternativa: la directiva empresarial `ImportEnterpriseRoots` desde el MSI del agente [I]. Decide A en su momento.
5. **Windows no admite la exclusión `/0`.** Se permite una sola dirección imposible (`0.0.0.0/32` y `::/128`) [I]. Es una precisión menor de PT-07 para el Arquitecto Maestro.
6. **El EKU en la CA rompe algún verificador (LAB-62).** Q-LAB-01 (a) se descarta antes de construir.

---

## 9. Esfuerzo y exceso sobre ADR-90

1 sp = 5 días-persona, de USD 1.500 a 2.000 por sp. Cifras inferidas, ±30 %.

| Tarea | Fase | sp |
|---|---|---|
| VM Windows, vTPM, red, reloj, puntos de control, guardas y limpieza (LS-11) | 1 | 0,05 |
| Oráculo ampliado (unos 45 perfiles, LS-07 y LS-08) y atributo de omisión | 1 | 0,06 |
| Bloques N y F en Windows (unos 55 casos, casi todos en memoria), con LAB-80a a LAB-80c, LAB-81 ampliado y LAB-85 (LS-18 a LS-21) | 1 | 0,07 |
| Bloque S (PT-04, unos 8 casos en el oráculo) | 1 | 0,01 |
| Bloque B (15 casos en Edge, Chrome y Firefox completos, más ESR parcial) | 1 | 0,06 |
| Informe parcial de la fase 1 | 1 | 0,02 |
| Bloque V (LAB-32 a LAB-36 y variantes) | 2 | 0,03 |
| Bloque R (15 casos y dos recorridos de reloj) | 2 | 0,08 |
| Informe final y revisión del auditor | 2 | 0,03 |
| **Subtotal Windows (este diseño)** | | **0,41 sp (de 0,29 a 0,53)** |
| Bloque N-L, subconjunto en memoria (Q-LAB-03 (a)) | 1 | 0,01 |
| Bloque N-L, resto: LAB-24-L a LAB-26-L y LAB-91 a LAB-99 (LS-04) | Tramo Linux | 0,02 |
| Bloque R-L | Tramo Linux | Sin estimar: depende del diseño de A |

**Exceso declarado:**
- **Presupuesto de ADR-90:** 0,35 sp de laboratorio, más 0,02 a 0,05 sp de PT-07 (hoja). Ese laboratorio también incluye casos que este documento **no** diseña: perfiles de red, cortafuegos, TPM, PT-05 y PT-06, que estimo en 0,08 a 0,12 sp [I].
- **Laboratorio completo, con Windows y el subconjunto en memoria de N-L** (Q-LAB-03 (a)): 0,41 + 0,01 + 0,08 a 0,12 = **0,50 a 0,54 sp**.
  - Sobre las 0,35 sp de ADR-90: **0,15 a 0,19 sp de exceso** (de USD 225 a 380). Sin el subconjunto de N-L: de 0,14 a 0,18 sp (de USD 210 a 360).
  - Sobre las 0,37 a 0,40 sp que suman ADR-90 y PT-07: de 0,10 a 0,17 sp de exceso.
- **Con N-L completo ahora (opción (b)):** 0,02 sp más (exceso de 0,17 a 0,21 sp sobre las 0,35).
- **Coincidencia con el auditor:** REV-LAB estimó de 0,45 a 0,51 sp para la versión 2. La versión 3 suma unas 0,03 sp por LS-18 a LS-21, el bloque S que pidió B y el subconjunto de N-L. Las pruebas de arquitectura de la sección 14 las construye A en sus PR y no cargan al laboratorio (unas 0,02 sp de A [I]).
- **Por qué no cabe:** el exceso viene de lo que el auditor mostró que faltaba: casos de ataque (LS-08), guardas y limpieza (LS-11), controles que eviten aprobados sin prueba (LS-01, LS-02 y LS-07) y Linux (LS-04).
- **Rebajas que no debilitan:** Firefox ESR solo en los casos de NC, ya aplicada (unas 0,01 sp).
- **Rebajas que no recomiendo:**
  - recortar Edge;
  - un solo recorrido de reloj, porque pierde LAB-45, la prueba de que un vencimiento sin renovar se detecta y se recupera;
  - quitar los controles negativos.
- **Licencias e infraestructura:** USD 0.

Como el exceso supera el presupuesto firmado, va a firma: **Q-LAB-03**.

---

## 10. Preguntas para la firma del propietario

### Q-LAB-01 · EKU `serverAuth` en la CA del sitio (O-05, con LS-07 y LS-13)

**Firmado el 2026-10-20: (a).** Los casos «según la firma» (LAB-30, LAB-62 y LAB-88b) se leen con (a).

**Problema.** Las Name Constraints impiden que una llave filtrada suplante sitios de Internet. Pero la CA está en `LocalMachine\Root` de cada puesto **para todos los usos**, y las NC no limitan:
- la firma de código, que no lleva nombres DNS;
- el correo S/MIME, porque `rfc822Name` no está restringido.

LAB-30 lo mide con una hoja **dentro** de las NC y con un control (CA-X), para que un rechazo por las NC no se confunda con la ausencia de riesgo. LAB-30b lo mide para el correo.

**Opciones:**
- **(a, recomendada)** El verbo pone en la CA el EKU con solo `serverAuth`.
  - **Base:** con las NC, es lo que la política de raíces de Mozilla y los BR del CA/Browser Forum llaman CA «técnicamente restringida» [I]. Windows, Chromium y Mozilla aplican el EKU de la CA como límite de lo que emite [I].
  - **Comprobación previa:** LAB-30 y LAB-62 confirman antes de construir que la opción es viable y que el EKU es la causa del rechazo.
  - **Costo:** unas 0,01 sp en el verbo.
  - **Consecuencias que se aceptan con (a)** (LS-13):
    1. La sucesora y su certificado cruzado (PT-04) deben llevar un EKU **igual o más estrecho**, además de las NC. Si no, las hojas de la sucesora fallan en Windows [I]. El texto de PT-04 lo prepara el Arquitecto Maestro. LAB-88b (bloque S) lo prueba.
    2. El cruzado nunca va en la cadena del saludo: con `pathLen = 0` la violaría. El cliente lo valida aparte, como ya dice PT-04.
    3. La CA del sitio **nunca** podrá emitir certificados de cliente, por ejemplo para un TLS mutuo futuro de las estaciones. Hoy nada lo prevé: ADR-53 autentica el nodo con la llave del TPM.
    4. Android (Java PKIX) probablemente ignora el EKU del ancla [I]. No hace daño.
  - **Qué rompe:** nada construido.
- **(b)** Restringir los usos de la raíz al instalarla en cada puesto (propiedad del certificado en el almacén).
  - Solo cubre Windows.
  - Unas 0,03 sp en el MSI del agente y el verbo [I].
- **(c)** Aceptar el residual: con la llave de la CA, alguien firmaría código o correo que esos puestos tendrían por válidos. El residual es Medio con la CA en software (H-13) y Bajo con TPM.

[ ] (a) · [ ] (b) · [ ] (c) · [ ] Otra: ______

### Q-LAB-02 · Revocación con el «certificado del cliente» (sin CA fijada; O-06)

**Firmado el 2026-10-20: (a) `NoCheck`**, con el residual de la CA de dominio declarado aparte.

**Problema.** PT-03 manda usar el almacén del sistema, pero no dice si se comprueba la revocación.

**Opciones:**
- **(a, recomendada)** `NoCheck`, como con la CA propia (RT-04).
  - Funciona sin Internet y **nunca** se combina con ninguna marca `Ignore*`.
  - **El residual depende del tipo de CA** (precisión de REV-LAB):
    - **CA pública:** un certificado revocado por robo de su llave se sigue aceptando hasta su vencimiento, que es de 200 días como máximo hoy y de 100 días desde marzo de 2027 (SC-081 [I]);
    - **CA de dominio del cliente (AD CS):** las vigencias suelen ser de 1 a 2 años [I], así que el residual es **mayor**;
    - en los dos casos, el atacante necesita estar en la red local o en la VPN (R-VPN-1).
  - **Mitigación sin costo:** `comprobar-servidor` avisa si el certificado del cliente dura más de 200 días, para que el técnico pida al cliente vigencias cortas en su CA de dominio.
- **(b)** `Online` aceptando el estado «desconocido».
  - Exige `IgnoreEndRevocationUnknown`, que la prueba de arquitectura prohíbe.
  - Un atacante en la red bloquea la consulta.
- **(c)** `Online` estricto. Si la red local no alcanza la CRL o el OCSP, MAUI y las estaciones dejan de conectar.
- **(d, descartada)** `Online` con falla abierta en código propio (rechazar solo `Revoked`).
  - No exige `Ignore*`.
  - Un atacante en la red bloquea la consulta.
  - Cuando no se alcanza la CRL, cada conexión nueva espera el tiempo de recuperación [I].

[ ] (a) · [ ] (b) · [ ] (c) · [ ] Otra: ______

### Q-LAB-03 · Presupuesto del laboratorio y momento del bloque Linux

**Firmado el 2026-10-20: (a).** Se aprueba el exceso (laboratorio de 0,50 a 0,54 sp). El subconjunto en memoria de N-L corre en la fase 1 y el resto, con el tramo Linux de ADR-129.

**Problema.** El laboratorio completo pasa las 0,35 sp de ADR-90 en **0,15 a 0,19 sp** con Windows y el subconjunto en memoria de Linux (de USD 225 a 380), y en 0,17 a 0,21 sp si todo el bloque Linux corre ahora (sección 9).

**Opciones:**
- **(a, recomendada)** Aprobar el exceso de Windows (fases 1 y 2) y **ejecutar ya, en la fase 1, el subconjunto en memoria de N-L** (unas 0,01 sp, matiz de REV-LAB, V.5). El resto de N-L (almacén de la distribución y línea de órdenes, 0,02 sp) y R-L se hacen con el tramo Linux de ADR-129, cargados a ese tramo, **antes** de habilitar un servidor o una estación Linux para un cliente.
  - Mientras tanto, la validación TLS en Linux queda bloqueada, como manda ADR-129, A2.
  - Base: el código Linux se construye después del corte, así que hoy no hay validador Linux que probar contra el producto.
- **(b)** Aprobar el exceso y ejecutar todo N-L ahora, en la fase 1 (+0,02 sp sobre (a)).
  - Ventaja: la línea de órdenes de OpenSSL y el almacén de la distribución también se conocen antes del validador. (a) ya cubre lo esencial: el comportamiento de .NET sobre OpenSSL.
  - Costo: una VM más que mantener desde ya.
- **(c)** Mantener las 0,35 sp: quitar el recorrido de fallo del reloj (LAB-45) y la mitad del bloque B, y dejar Linux para otro presupuesto.
  - **No recomendada:** se pierde la prueba de que un vencimiento sin renovar se detecta y se recupera (el riesgo Alto de H-02) y el control de los navegadores.

[ ] (a) · [ ] (b) · [ ] (c) · [ ] Otra: ______

---

## 11. Entregas

Puntos que **no** se resuelven en este diseño. Cada uno va a su responsable.

| LS u observación | Para | Qué necesita |
|---|---|---|
| **LS-05** (parte de redacción) | **Arquitecto Maestro** | Decidir si el comodín en la etiqueta izquierda, en el modo sin CA fijada (sección 4.2), cambia RT-10 punto 5 («aceptar errores de nombre»). Si es así, preparar la nota de lectura o la precisión para firma. El diseño ya aplica la regla técnica y la prueba (LAB-81) |
| **LS-13** | **Arquitecto Maestro** | En el texto de PT-04: la sucesora y el cruzado llevan NC **y EKU** iguales o más estrechos; el cruzado nunca va en la cadena del saludo; validación aparte con `pathLen = 0`; caso del cruzado autoemitido (mismo DN, RFC 5280, 6.1.4). Q-LAB-01 (a) lo declara como consecuencia |
| **LS-14** | **Arquitecto Maestro** (y A) | Nota de lectura en ADR-90:<br>- un cambio de nombre o de IP del SAN es una **rotación de CA**, porque las NC quedan fijas por 10 años (corrige «reemisión con el verbo», ADR-090.md:181);<br>- recomendar nombres DNS estables y evitar IP en el SAN.<br>Para A: la lista del sitio solo llega por el QR, el alta manual o firmada por la CA; al emparejar se comprueba que está contenida en los subárboles de la CA fijada |
| O-01 | Arquitecto Maestro | Nota de lectura de PT-07 sobre los subdominios. No usar la forma con punto inicial |
| Sección 8, puntos 2 y 5 | Arquitecto Maestro | Precisiones condicionales, solo si el laboratorio las exige |
| **LS-10** | **A**, desarrollador-backend | Al aplicar PT-03, eliminar el camino «el SPKI de la hoja fijado prevalece sobre los errores de cadena» (`ClienteDispositivo.cs:68-69`), sin conservarlo como respaldo de transición. Las estaciones se vuelven a emparejar. Lo comprueba LAB-35b |
| **LS-12** | **A** (Kestrel) y **B** (paquete) | Descargas en el modo sin CA fijada. Recomendación del auditor:<br>- desactivarlas;<br>- que el paquete compruebe al importar el certificado del cliente que las intermedias están en `LocalMachine\CA`;<br>- que Kestrel envíe la cadena completa (`SslStreamCertificateContext`).<br>LAB-31b se ejecuta con lo que se decida |
| **LS-16** | **A**, arquitecto-software | Validador **único** como único lugar de las API de validación TLS; la prueba de arquitectura prohíbe esas API fuera de él y exige `NoFlag` y `CustomRootTrust` en la rama fijada |
| LS-03 y LS-09 (contratos) | A, arquitecto-software | SD-10 v2: DER de la CA en el QR o por una ruta de solo lectura, y su validación de perfil; reglas de normalización de nombres de la sección 4.1. El diseño ya las fija como política de prueba |
| O-02 y O-03, `NotBefore` (O-07) | A, arquitecto-software y desarrollador-backend; B (`comprobar-servidor`) | Verbo: al menos un DNS y `NotBefore` − 1 h. Selector: `HuellaAnterior`, su orden de escritura y la regla de arranque. `comprobar-servidor`: subárboles `dNSName` e `iPAddress` presentes en la CA |
| F-05 | A, desarrollador-backend | Variante ECDSA de `PrivadaEnTpm` si la CA es ECDSA |
| R-L | A, arquitecto-software (tramo Linux) | El equivalente de PT-02 en Linux, con nginx o Kestrel (ADR-129, C15). BP-A devuelve `SinModo` en Linux (4.2) |
| **LS-20** | **A**, arquitecto-software (SD-10 v2) | Al dar de alta el ancla: subárboles permitidos **exactamente** iguales a la lista del sitio del QR (más la exclusión de `/0` si no hay IP, y el EKU si se firma Q-LAB-01) y ninguna extensión crítica desconocida. Opcional: el SHA-256 del DER en el QR. Orden: ninguna credencial por la conexión sin validar; el código de emparejamiento (`ClienteDispositivo.cs:130`) y el inicio de sesión de MAUI, solo por una conexión nueva con P-FIJADA. Lo prueban LAB-84 y LAB-85 |
| **LS-21** | **A** (reglas) y **Arquitecto Maestro** (con LS-05) | A: en el modo público, sin comodines parciales, una sola etiqueta, al menos dos etiquetas tras el `*` y nunca con un host IP; el modo lo fija solo el QR o la opción explícita «certificado del cliente», nunca un alta manual sin huella. Maestro: si la bajada de modo y el comodín cambian RT-10 puntos 4 y 5, preparar la nota o la precisión. Lo prueban LAB-81 y LAB-86 |
| **C-A1** · Web → API | **A**, arquitecto-software | BP-A (5.2) valida a la API con el almacén del sistema, sin validador propio (su R-11). Este diseño proponía P-FIJADA (O-04), porque PT-03 pide exclusividad allí donde hay CA fijada. Hay que decidir: (a) mantener BP-A y aceptar R-11 (el laboratorio prueba LAB-22 así), o (b) usar la sobrecarga con la CA del sitio también en producción, dentro del validador único (LS-16). El laboratorio no depende de la elección |
| **C-A2** · arranque | **A**, arquitecto-software | BP-A: sin certificado utilizable al arrancar, 4747 y no arranca; no hay `HuellaAnterior`. Este diseño (O-03, apoyado por REV-LAB) propone `HuellaAnterior`, escrita antes que `HuellaApi` o `HuellaWeb`. El resultado esperado de LAB-42 depende de lo que fije A |
| **C-A3** · criterios del selector | **A**, arquitecto-software | BP-A (5.2) no comprueba ni el **emisor** (la CA del sitio, o el certificado del cliente registrado) ni que el SAN sea `NombresServidor`. Una huella publicada por error o con malicia hacia un certificado de otra raíz presente en `LocalMachine\My` se adoptaría (LAB-41 y LAB-41b). Propuesta: añadir esas dos comprobaciones a «utilizable» |
| **C-A4** · proyecto nuevo | **A** y **Arquitecto Maestro** | BP-A crea `GPOS.Comun.Servidor`. `CLAUDE.md` solo admite como proyectos nuevos `GPOS.Migracion` y las excepciones listadas, y este no está entre ellas. Necesita la decisión del propietario antes de unir. No afecta al laboratorio |
| **C-A5** · prueba de arquitectura | **A**, arquitecto-software | La prueba de BP-A (PR-2) mira solo `src/GPOS.Web` y `src/GPOS.Comun.Servidor`. Conviene extenderla a `GPOS.UI.MAUI` y `src/GPOS.AgenteImpresion` con el validador único (LS-16) y los casos de la sección 14 |
| Precisiones de B | Coordinador de B | (1) PT-02: bloque R, explícito (LAB-37 a LAB-48); PT-04: bloque S nuevo (LAB-87 a LAB-90), con el EKU de LS-13 dependiente de Q-LAB-01 (LAB-88b). (2) Pruebas de arquitectura de los valores HTTP por omisión: sección 14 |
| LS-04 (VM) y LS-11 | B, devops | `VM-LNX`, guardas, marcadores, limpieza, redacción de la evidencia y `.gitignore` |
| LS-15 | B, devops | Licencia de laboratorio vigente hasta `T0+120 d` |
| R-1 y el reparto de 7.4 | Coordinador de B | Confirmar el reparto y la promoción de casos a la suite |
| Revisión | auditor-seguridad | Verificar que la versión 3 atiende LS-18 a LS-22; después, la evidencia de cada fase |
| Registro | documentador-técnico | Estado del laboratorio en `estado.json` de ADR-90 cuando se ejecute |

---

## 12. Supuestos

- Todo lo marcado [I] está sin verificar en esta sesión. En particular:
  - las NC del ancla en CryptoAPI, OpenSSL, Java, Apple, Chromium y NSS;
  - que `SslStream` agregue al `ExtraStore` los certificados del saludo;
  - el trato de la hoja sin EKU;
  - los códigos exactos de OpenSSL;
  - `AllowTlsResume`;
  - el punto final y las IDN en `MatchesHostname`;
  - los plazos de evaluación de Windows.
- Hay un anfitrión Hyper-V fuera de la PC del propietario y de OSHIN-LEGION.
- El reparto de la sección 7.4 lo confirma B.
- No se conocen las fechas de la licencia de laboratorio.
- BP-A es una propuesta sin firmar: los nombres que el laboratorio toma de él (registro, eventos, `ClienteApiLocal`, puntos de inyección) pueden cambiar.
- El contrato de PT-04 no existe todavía: el bloque S usa una regla provisional.

---

## 13. Trazabilidad de la revisión del auditor (LS-nn → dónde se atendió)

| LS | Sev. | Tratamiento | Dónde |
|---|---|---|---|
| LS-01 | Media | Corregido: LAB-23 dividido en 23a (en memoria) y 23b (VM, con CA-S instalada y control); 23b fuera de R-1 | 6.1 (LAB-23a y LAB-23b); 7.5 |
| LS-02 | Media | Corregido: justificación de `ExtraStore`, cadena propia del validador con política nueva por conexión y longitud igual a 2; LAB-18 con Sub-A por `ExtraStore` y por el saludo, y control CA-X1 → Sub-X | 4.1; 6.1 (LAB-18) |
| LS-03 | Media | Corregido: ancla por DER guardado al emparejar, con su perfil validado; condición 2 por DER; nunca del saludo; caso LAB-80 (CA-SPKI), rehecho en la versión 3 (LS-18). Contrato SD-10 v2 entregado a A | O-08; 4.1; 5 (CA-SPKI); 6.2 (LAB-80); 11 |
| LS-04 | Media | Corregido: bloque N-L declarado (.NET en Linux y oráculo OpenSSL, LAB-91 a LAB-99, con [I]); guarda de Linux; R-L pendiente; `VM-LNX` a B; momento según Q-LAB-03 | 1; 3; 6.3; 7.1; 9; 10 (Q-LAB-03); 11 |
| LS-05 | Media | Corregido en el diseño: modo sin CA fijada con comodín solo en la etiqueta izquierda, sin CN y sin la condición 4; caso LAB-81. La redacción de RT-10 punto 5, al Arquitecto Maestro | O-09; 4.2; 6.2 (LAB-81); 11 |
| LS-06 | Media | Corregido: `NotBefore` = emisión − 1 h como contrato del verbo; LAB-20b, LAB-32 y LAB-38b | O-07; 5; 6.1; 6.4; 6.5; 11 |
| LS-07 | Media | Corregido: H-CODE-NC dentro de las NC, con control CA-X; criterio explícito; H-MAIL (LAB-30b); Q-LAB-01 lo cita | 5; 6.2 (LAB-30 y LAB-30b); 10 |
| LS-08 | Baja | Incorporado: LAB-71 a LAB-80, LAB-27b, LAB-29b, LAB-35b, LAB-35c, LAB-37b, LAB-41b y LAB-83 (B-MEZCLA); Edge completo | 5; 6.1, 6.2, 6.4, 6.5 y 6.6; 9 |
| LS-09 | Baja | Corregido: definición de «nombre» (tipos, ASCII, mayúsculas, punto final, IP por octetos, host normalizado antes de `TargetHost`); LAB-33 ampliado; LAB-78 | 4.1 (condición 4); 6.1 (LAB-78); 6.4 (LAB-33) |
| LS-10 | Baja | Entrega a A (desarrollador-backend); F-02 ampliado; LAB-35b lo comprueba | 2 (F-02); 6.4; 11 |
| LS-11 | Baja | Incorporado: guardas con marcador, lista de VM y de anfitriones; solo `LocalMachine`; limpieza por marcador; un proceso por caso; llaves de CA efímeras; `.gitignore`; redacción de la evidencia y revocación de dispositivos | 3; 6.4 (LAB-36); 7.1 y 7.2; 7.4 |
| LS-12 | Baja | Entrega a A y B (no resuelto aquí); LAB-31b declarado con la regla que se fije | 4.2; 6.2 (LAB-31b); 11 |
| LS-13 | Baja | Consecuencias declaradas en Q-LAB-01 (a); texto de PT-04 al Arquitecto Maestro; nota en «Fuera de alcance» | 1; 10 (Q-LAB-01); 11 |
| LS-14 | Baja | Entrega al Arquitecto Maestro y a A (no resuelto aquí) | 4.1 (condición 4, remisión); 11 |
| LS-15 | Baja | Incorporado: licencia hasta `T0+120 d`, sonda por `/api/salud`, 403 de licencia registrado aparte; F-09 nuevo y F-06 completado | 2 (F-06 y F-09); 3; 6.5; 11 |
| LS-16 | Baja | Entrega a A (arquitecto-software); la sección 4.3 remite a la propuesta | 4.3; 11 |
| LS-17 | Baja | Corregido: F-03 (`UseHttpsRedirection`); F-05 (`ConnectCallback` por canalización con nombre); F-06 con la implementación y la licencia; `GPOS.EnsayoImplantacion` es un proyecto; probabilidad «Media [I] hasta LAB-04 y LAB-05» | 2; 7.2; 8 |
| LS-18 | Media | Corregido: LAB-80 rehecho en LAB-80a (hoja fuera de las NC con CA-SPKI en el saludo → rechazo), LAB-80b (control con CA-SPKI como ancla → aceptada) y LAB-80c (H-DNS con CA-SPKI en el saludo → aceptada); R-1 ajustado | 6.2; 7.5; 8 |
| LS-19 | Baja | Corregido: LAB-18 (a) con `ExtraStore` y la marca en cualquier elemento; LAB-18 (b) acepta `PartialChain` en la cadena propia; LAB-71 en el oráculo con `ExtraStore` y una marca de NC, no `PartialChain` | 6.1 |
| LS-20 | Baja | Corregido en el diseño: regla de alta con subárboles exactos y sin extensiones críticas desconocidas; orden del alta sin credenciales en la conexión sin validar; SHA-256 del DER opcional. Casos LAB-84 y LAB-85. Contrato a A | O-10; 4.1; 6.2; 6.4; 11 |
| LS-21 | Baja | Corregido en el diseño: comodín sin parciales, una etiqueta, mínimo dos etiquetas tras el `*`, nunca con un host IP; el modo lo fija solo el QR o la opción explícita. LAB-81 con casos negativos y LAB-86. Reglas a A; redacción al Arquitecto Maestro | O-11; 4.2; 6.2; 6.4; 11 |
| LS-22 | Baja | Corregido: LAB-99 (H-FUERA con CA-SPKI → `OK`, informativo); LAB-72 «rechazo»; LAB-75 con CA-CRIT informativo y rechazo en el alta; LAB-30b con el OID de correo; LAB-78 rechaza el punto final; `NotBefore` − 1 h en la CA (LAB-32); `limpiar-laboratorio.sh`; marcador en extensión no crítica o lista de huellas; nombres de LAB-81 en `hosts` | 3; 4.1; 5; 6.1; 6.2; 6.3; 6.4; 7.2 |
| Precisiones de B y BP-A | — | PT-02 (bloque R) y PT-04 (bloque S nuevo); pruebas de arquitectura de los valores HTTP por omisión (sección 14); nombres y puntos de inyección de BP-A (2.1); contradicciones C-A1 a C-A5 | 1; 2.1; 6.2b; 6.5; 11; 14 |

---

## 14. Pruebas de arquitectura de los valores HTTP por omisión (RT-10, punto 5, y H-09)

Apartado breve, por la precisión (2) de B. No son casos de laboratorio. Son pruebas sobre el texto del código, en `tests/GPOS.Tests/Arquitectura/`, con el estilo de `ValoresPorOmisionDistribuidosTests.cs` [V]. Las construye A con el PR de H-09 y de RT-10, **no antes**: hoy algunas fallarían (se indica cuáles) y romperían la suite oficial.

| Id | Qué comprueba | Hoy |
|---|---|---|
| AR-01 | MAUI: fuera de `#if DEBUG`, `ConfiguracionApi` no tiene ninguna dirección por omisión ni literales `http://` | Fallaría: `GPOS.UI.MAUI/Servicios/ConfiguracionApi.cs:7-12` [V] |
| AR-02 | MAUI: en Release, `ValidacionDireccionApi` exige `https` también hacia *loopback*, y rechaza una URL con punto final (LS-22) | Fallaría en *loopback* (REV, `ValidacionDireccionApi.cs:23-24`) |
| AR-03 | Android: el `AndroidManifest.xml` de Release no lleva `usesCleartextTraffic="true"` ni un `networkSecurityConfig` con `cleartextTrafficPermitted` o `<certificates src="user"/>`. El manifiesto de depuración, que sí lo lleva (`AndroidManifest.Debug.xml:3` [V]), solo se usa con la condición de Debug (`GPOS.UI.MAUI.csproj:26-28` [V]) | Pasaría [I] |
| AR-04 | iOS y Mac Catalyst: `Info.plist` sin `NSAppTransportSecurity` con `NSAllowsArbitraryLoads`, `NSExceptionDomains` ni `NSAllowsLocalNetworking` | Pasaría [I] |
| AR-05 | Web: el `appsettings.json` que se distribuye no trae `Api:Url` con `http://`; con BP-A, la URL sale del registro | Fallaría: `src/GPOS.Web/appsettings.json:14` [V, BP-A] |
| AR-06 | Agente: el MSI no escribe `*` ni orígenes `http://` que no sean locales en `ORIGENES` (`ConfiguracionAgente.Permite` acepta `*`, `src/GPOS.AgenteImpresion/ConfiguracionAgente.cs:29-34` [V]) | Por revisar en las fuentes de WiX [I] |
| AR-07 | Validadores: ningún `DangerousAcceptAnyServerCertificateValidator`, devolución de llamada de validación, `X509VerificationFlags.Ignore*`, `AllowUnknownCertificateAuthority` ni `allowCommonName: true` fuera del validador único (LS-16), en `src/GPOS.Web`, `src/GPOS.Comun.Servidor`, `GPOS.UI.MAUI` y `src/GPOS.AgenteImpresion` (C-A5) | Fallaría por `ClienteDispositivo.cs:80` hasta que exista el validador único [V] |

Costo inferido para A: unas 0,02 sp, dentro de los PR de H-09, RT-08 y RT-10.

---

### Cierre
- Estado: Completado (diseño, versión 3, con LS-01 a LS-22 atendidos o entregados, las precisiones de B y la alineación con BP-A; pendiente de que el auditor-seguridad verifique LS-18 a LS-22 y de la firma de Q-LAB-01 a Q-LAB-03).
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-diseno-laboratorio-adr090.md`.
- Supuestos: los de la sección 12.
- Decisiones candidatas a ADR: ninguna nueva. Q-LAB-01 y Q-LAB-02 serían precisiones de ADR-90 (RT-02 y PT-03); Q-LAB-03 es una decisión de presupuesto; las notas de LS-05, LS-13, LS-14, LS-21 y O-01 son del Arquitecto Maestro; C-A4 (proyecto nuevo de BP-A) necesita la decisión del propietario.
- Entregas a otros agentes: sección 11.
- Próximo paso recomendado: que el auditor-seguridad verifique esta versión y el propietario firme Q-LAB-01 a Q-LAB-03; después, la fase 1 en Windows antes de que A escriba el verbo `tls`.
