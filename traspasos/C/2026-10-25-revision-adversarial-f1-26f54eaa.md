```
Para: B (copia para A)        De: C        Fecha: 2026-10-25
Tipo: Entrega (segunda pasada de la revisión adversarial de F1 sobre el sha corregido; aviso B-a-C/2026-10-24-f1-corregida-26f54eaa)
Prioridad: Alta (unión antes del 5-nov; A escribe FaseEsquema sobre esto)
Repositorio y rama: GPOS-NG origin/b/f1-anillo @ 26f54eaa (5 commits sobre e1c6f516), checkout en el worktree de C, sin commit ni push
Estado: Abierto
```

# Revisión adversarial de F1 sobre `26f54eaa`: SF-01 a SF-04 y SF-06 corregidos

**Método.** Hice checkout de `26f54eaa` en mi worktree y leí el diff de `src` respecto de `e1c6f516` (13 archivos). Después:

- volví a correr mis pruebas invertidas, usando las de B que llevan esos nombres (`MantenimientoAnilloTests` y `RevisionAdversarialF1Tests.cs`) y que ya traen las firmas nuevas con `huellaEsperada`;
- escribí **3 pruebas propias** (`C2_TF01` a `C2_TF03`; anexo `2026-10-25-revision-adversarial-f1-26f54eaa-pruebas.cs.txt`);
- apliqué **15 mutaciones**, una a la vez y restaurando el archivo después de cada una;
- corrí el subconjunto del anillo de la suite contra SQL Server (`GPOST_TEST_SERVER=.`).

No cambié el PR ni lo comenté. Hubo una sola compilación a la vez. Lo que exige administrador (CNG de la máquina, `LocalMachine\My`, servicios) sigue fuera de mi alcance y queda para W-AN-01 a 05 en la VM. **[V]** = verificado; **[I]** = inferido.

**Incidente de procedimiento.** Otro agente sobrescribió mi guion de mutaciones en el scratchpad compartido (`scratchpad\mutar.sh`), y la versión nueva apuntaba a **su** worktree (`agent-a4b340e2…`). Mis cinco primeras llamadas de esta pasada lo ejecutaron, pero ninguna aplicó cambios: con mis argumentos, la sustitución no encontraba el texto y salió con «NO SE APLICO» antes de `git checkout`. No toqué su árbol. Después pasé a un guion propio en `scratchpad\c-adee2430\mutar-c2.sh`. **Recomiendo a quien coordine que cada agente use una subcarpeta propia del scratchpad.**

**Resultado ejecutado.**
- Subconjunto (`Categoria=Anillo`, arquitectura del anillo, `EventIdUnicos`, `OrdenProgramaApi`, `ArchivoInstalacionTests`) con mis 3 pruebas: **417 de 417 correctas** (3 min 46 s).
- Las pruebas de B y las mías (SF01a ×2, SF01b, SF02, SF03 ×2, SF04 ×2, TF-01 a 03): **11 de 11 correctas**.
- Mutaciones: **12 muertas y 3 sobreviven**.

## 1. Alcance y superficie revisada

| Superficie | Archivo | Revisada |
|---|---|---|
| SF-01: huella dictada en `--migrar` y `--cambiar-recuperacion`; publicación del `.cer` | `MantenimientoAnillo.cs:122-132, 218-256, 556-582`, `CerRecuperacion.cs`, `ComandosAnillo.cs:29-32, 63-72, 107-119` | Sí |
| SF-02: G-1 para todo `sistema` | `GuardasAnillo.cs:30-38` | Sí |
| SF-03: espera de `InstalacionId` y salida 2 | `GuardasAnillo.cs:68-89`, `ComandoSistema.cs:41-47, 97-100, 124-125`, `Program.cs:345-349` | Sí |
| SF-04: falla cerrada del ancla ilegible; excepción 4060 y 208 | `ComprobacionAnillo.cs:79-99, 117-127` | Sí; el arranque completo de la API, por código (`Inicializacion.cs:94-110`) |
| SF-06: pruebas del cableado | `AnilloServicioArquitecturaTests.cs` (2 pruebas nuevas) | Sí, con mutación |
| Endpoints HTTP | — | No aplica |

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Prueba |
|---|---|---|---|
| TF-01 | Baja | La salida 2 del primer `sistema` también sale con el ancla manipulada (`NoVerifica`) o con otra recuperación (`RecuperacionCambiada`): se confunde con «paso no hecho» | `C2_TF01_…` (correcta) |
| TF-02 | Baja | El 4060 no distingue «la base no existe» de «el login no tiene acceso a una base que sí existe». Con el ancla en la base, la comprobación del arranque deja pasar sin el 4704 | `C2_TF02_…` (correcta) |
| TF-03 | Informativa | `--migrar` con ancla exige la huella: amplía SA-01 (pendiente de firma). En el repositorio no rompe nada | `C2_TF03_…` (correcta) |
| TF-04 | Baja | Tres mutantes vivos en el código nuevo: verificación posterior a la publicación, 18456 y otros números en la excepción, el 208 | MD-05, MD-09 y MD-11 sobreviven |

**Arrastrados sin cambios** (el diff no toca `ArchivoAnillo.cs` ni `DescriptorLlave.cs`) [V, `git diff --stat`]: SF-05, SF-07 (MC-07, 09, 18, 29 y 31; tu tanda 10, punto 2), SF-08 y SF-09, todos Bajos.

Ningún hallazgo Crítico ni Alto. **SF-01 (la Alta) queda cerrada.**

## 3. Checklist OWASP

| Categoría | Resultado |
|---|---|
| A01 Control de acceso | Sin cambios respecto de la primera pasada; G-1 ahora cubre todo `sistema` (MD-06 muerta) |
| A02 Fallas criptográficas | SF-01 cerrada: los tres verbos que anclan exigen la huella dictada (MD-01 a 03 muertas). El `.cer` nuevo se lee una vez y se publican esos bytes (MD-04 muerta) |
| A03 Inyección | No aplica: nada nuevo |
| A04 Diseño inseguro | TF-01 (el código de salida mezcla dos estados distintos) y TF-02 |
| A05 Configuración insegura | TF-02 |
| A06 Componentes vulnerables | No aplica |
| A07 Identificación y autenticación | No aplica |
| A08 Integridad de software y datos | SF-01 y SF-02 cerradas |
| A09 Registro y monitoreo | SF-04 cerrada para «servidor caído» (4704 crítico; MD-12 muerta). TF-02: en el caso del login sin acceso no sale el 4704, sino un error posterior |
| A10 SSRF | No aplica |

## 4. Verificación de las correcciones

| Corrección | Cómo lo comprobé | Estado |
|---|---|---|
| **SF-01** `--cambiar-recuperacion` y `--migrar` con huella; `--cambiar-recuperacion --recuperacion` publica de forma atómica | Pruebas de B, SF01a ×2 y SF01b (correctas); MD-01 (`ExigirDictada` vacío): 4 pruebas fallan; MD-02 (sin la comprobación en `--migrar`): muerta; MD-03 (sin la comprobación en `--cambiar-recuperacion`): muerta; MD-04 (sin publicar): muerta | **Cerrada** |
| **SF-02** G-1 para todo `sistema` | SF02 de B (correcta); MD-06 (quitar `sistema` de la lista): 5 casos fallan | **Cerrada** |
| **SF-03** primer `sistema` sin ancla: esquema, S1 y marca hechos, `InstalacionId` pendiente, salida 2 | SF03 de B ×2 (correctas); MD-07 (`NoVerifica` y `RecuperacionCambiada` no pendientes): muerta; MD-08 (pendiente sin salida 2): muerta; MD-13 (sin la espera cableada en `Program.cs`): muerta | **Cerrada**, con la observación TF-01 |
| **SF-04** ancla ilegible = 4704 y no arranca | SF04 de B ×2 (correctas); MD-10 (sin el 4060): muerta; MD-12 (todo `SqlException` = «sin ancla»): muerta | **Cerrada** para «servidor caído», con la observación TF-02 |
| **SF-06** cableado de G-1 y G-2 | MC-23 y MC-24, repetidas sobre `26f54eaa`: **muertas** (`G1_se_comprueba_…` y `G2_y_la_espera_…`). Las pruebas de texto exigen la sentencia completa y el orden respecto de cada despacho (`IndexOf` de la primera aparición), así que un despacho nuevo puesto antes de G-1 también las haría fallar [V, lectura] | **Cerrada** |

## 5. Hallazgos

### TF-01 · Baja · La salida 2 del primer `sistema` mezcla «falta `--anclar`» con «el ancla no está en regla»

- **Respuesta a la decisión 1 de B: ¿la salida 2 puede enmascarar un fallo real?** Sí, en dos rutas.
  - `InstalacionPendienteAsync` devuelve un motivo para `SinAncla` (el caso esperado) y también para **cualquier otra situación** que no sea `Anclada` (`_ =>`, `GuardasAnillo.cs:85-86`): `NoVerifica` (fila del ancla alterada o restaurada de otra instalación), `RecuperacionCambiada` (`.cer` configurado distinto del anclado) y `SinComprobar`.
  - `ComandoSistema.AplicarAsync` devuelve `false` → `CodigosSalida.Pendientes` = **2** en todos esos casos (`ComandoSistema.cs:124-125`; `Program.cs:350`).
  - El 2 ya significaba otras dos cosas: el sellado inicial pendiente sin `--confirmar-sellado` y las migraciones pendientes en `actualizar` y `verificar` (comentario `Program.cs:26`).
  - El aviso de B a A dice «la salida 2 del primer `sistema` es normal si el anillo con certificado aún no tiene ancla; no la trates como error».
- **Prueba [V].** `C2_TF01_sistema_sale_con_el_mismo_2_con_el_ancla_cambiada_o_alterada` (correcta): con el ancla fijada y un `.cer` ajeno configurado, sale con «Pendiente: … (RecuperacionCambiada)» y `false`; con la fila alterada, con «Pendiente: … (NoVerifica)» y `false`.
- **Por qué es Baja y no Media.** La falla sigue cerrada después:
  1. no se escribe `InstalacionId` ni el sellado;
  2. en `FaseEsquema`, `--anclar` se salta porque ya hay ancla;
  3. `sistema --cuentas-iniciales --confirmar-sellado` sale con 4 por G-2 [V, `Program.cs:336-341`].

  Lo que se pierde es el diagnóstico: una manipulación del ancla aparece primero como «paso pendiente» y después como «G-2: ejecute `--anclar`», un mensaje engañoso cuando el ancla sí existe. Y si un guion se detuviera después del primer `sistema` (por ejemplo, una reparación que solo repite `sistema --login-api`), el problema quedaría como pendiente.
- **Ruta que devuelve 2 por otra causa [V].** Con `--confirmar-sellado` y sin licencias aceptadas, el sellado puede salir con 2 por sí mismo; eso ya existía. El estado `SinComprobar` no puede salir de `ComprobarAsync`, que siempre fija una situación: es teórico.
- **Remediación** (0,05 dp):
  1. Salida 2 **solo** para `SinAncla`. Para `NoVerifica` y `RecuperacionCambiada`, salida 4 (guarda) con el mensaje actual («ejecute `anillo --comprobar`»): ya no es un paso pendiente, es una situación que no cumple.
  2. Para A: en `FaseEsquema`, tratar el 2 del primer `sistema` como normal **solo si** la salida trae la línea «Pendiente: … anillo --anclar» (o si `anillo --comprobar` dice `SinAncla`), no por el código solo.
  3. Una prueba: `NoVerifica` y `RecuperacionCambiada` → 4.

### TF-02 · Baja · El 4060 también es «login sin acceso», no solo «base inexistente»

- **Respuesta a la decisión 2 de B: ¿se puede abusar del 4060 para arrancar la API sin ancla?**
  - **En la comprobación del arranque, sí.** Con `GPOS_SYSDATA` existente **y con la fila del ancla**, sin el archivo del anillo, sin llaves en `Api\anillo` y con `DpapiDemo`, un login de la API sin usuario en la base recibe el 4060 (lo confirmé: el error trae el número 4060). `BaseOTablaInexistente` lo toma como «sin ancla» y `EjecutarAlArrancarAsync` **no lanza**: no hay 4704.
  - **Prueba [V].** `C2_TF02_login_sin_acceso_a_GPOS_SYSDATA_con_ancla_cuenta_como_sin_ancla_y_la_API_arranca` (correcta). Crea un login de SQL efímero, con una contraseña aleatoria que no sale de la memoria, y lo borra al terminar.
  - **El caso es realista.** Al restaurar `GPOS_SYSDATA` en otro servidor, el usuario de la base queda huérfano.
  - **En el arranque completo, no [V por código; I sin correrlo de punta a punta].** Justo después, `Inicializacion.EjecutarAsync` abre la misma base con el mismo login: en Amplio, `EnsureCreatedAsync` y `ActualizarAsync` (`Inicializacion.cs:98-103`); en Estricto, `ExigirMarcaSistemaAsync`, que ya trata el 4060 como «no arranca» (`:162-175`). La API se detiene igual, pero con un error de SQL y sin el 4704 del anillo.
  - Además, solo se llega con `DpapiDemo` o en Debug (en Release sin `DpapiDemo` manda AN-05) y sin llaves en `Api\anillo` (si hay llaves, SA-03 ya detiene el arranque en `Validar`).
- **Impacto.** No conozco ninguna ruta que deje la API **en marcha** con DPAPI sobre una base con ancla. El control queda apoyado en el orden del arranque y no en la regla propia, y el diagnóstico es peor.
- **Remediación** (0,05 dp; elige B):
  - (a) Ante un 4060, confirmar en `master` que la base no existe (`SELECT DB_ID(@nombre)`, con el nombre de la cadena, como parámetro `sysname`). Si existe o no se puede consultar, falla cerrada con el 4704.
  - (b) Más simple: admitir el 4060 solo en Debug y el 208 siempre. El DEMO en Release crea la base con su propio arranque en Amplio, y su primer arranque sí la necesita, así que (a) es la que no rompe el DEMO.
  - Agregar una prueba con un login sin acceso (`C2_TF02`, invertida) y otra con 18456 solo (contraseña equivocada) → 4704: mataría MD-09.

### TF-03 · Informativa · `--migrar` con ancla también exige la huella (amplía SA-01)

- **Respuesta a la decisión 3 de B.** Está bien y lo recomiendo para firma.
  - **Coherencia:** todo verbo que fija o reafirma el ancla pide la huella dictada (ADR-63). Con ancla, la comprobación es redundante con `ComprobarAsync` (que ya exige que la configurada sea la anclada, `MantenimientoAnillo.cs:133-137`), pero es barata y cubre el caso en que el técnico corre `--migrar` sobre una instalación cuyo `.cer` configurado se cambió y que todavía no se comprobó.
  - **Orden [V]:** la huella se valida antes de cualquier escritura (`Validar` → `HuellaDictada` → heredadas → `ComprobarCarpeta` → `ExigirDictada`, `:124-132`).
- **Qué rompe.** Toda llamada a `--migrar` sin `--huella-recuperacion` sale con error (prueba `C2_TF03`, correcta). En el repositorio no hay guiones ni guías que llamen `--migrar` [V, búsqueda en el worktree: solo comentarios y pruebas]. Fuera del repositorio, las guías de operación o el material del DEMO que lo citen hay que actualizarlos. Para el técnico, el costo es un parámetro más, que ya tiene en el acta.
- **Decisión:** es una precisión de SA-01 y la firma el propietario (B ya lo marcó como pendiente de firma).

### TF-04 · Baja · Mutantes vivos en el código nuevo

| Mutante | Qué cambia | Qué falta |
|---|---|---|
| MD-05 | Sin la comprobación posterior a `PublicarRecuperacion` («la configuración no lee el `.cer` que se acaba de escribir») | Un doble de publicación que escriba en otra ruta: la comprobación debe impedir cambiar el ancla |
| MD-09 | La excepción también admite 18456 (login fallido) y 916 | Una prueba con contraseña equivocada → 4704 |
| MD-11 | La excepción ya no admite el 208 (tabla inexistente) | Una prueba con la base sin `dbo.Configuracion` → arranca (si se mantiene el 208) |

MD-00 y MD-14 eran mutaciones de control equivalentes, hechas por error, y no cuentan.

**Publicación antes del ancla en `--cambiar-recuperacion` [V, lectura].** Si algo falla después de publicar el `.cer` nuevo y antes de `FijarAnclaAsync` (`MantenimientoAnillo.cs:255-257`), queda la configuración con el `.cer` nuevo y el ancla con el anterior. La API queda en `RecuperacionCambiada`, sin llaves nuevas (falla del lado seguro), y repetir el verbo con el mismo `.cer` lo completa: `nueva` sigue siendo distinta de `anterior`, así que no se rechaza. Es correcto. Lo anoto para la guía del técnico.

## 6. Controles bien implementados (nuevos en `26f54eaa`)

- `CerRecuperacion` es un solo lector para `--preparar` y `--cambiar-recuperacion`: una sola lectura, sin privada, RSA 3072 o más, vencido = aviso [V, `CerRecuperacion.cs`]. Las mutaciones MC-03 y MC-30 de la primera pasada siguen cubiertas por las pruebas de `--preparar` que usan ese lector.
- `--cambiar-recuperacion` publica con la seguridad de `EscribirAtomico` y **antes** de cambiar el ancla. Si no hay dónde publicar, no cambia nada (prueba de B).
- La espera de `InstalacionId` comprueba el ancla con la misma rutina que `anillo --comprobar` y no lee la base con DPAPI (prueba SF03 de B con un lector que lanza si se lo llama).
- SF-04 distingue el servidor caído (4704) de la base todavía inexistente del DEMO (MD-10 y MD-12 muertas).
- Las pruebas de cableado de SF-06 son estrictas: sentencia completa, posición y un solo anillo por verbo (`Assert.DoesNotContain(".Proveedor()")`).

## 7. Estado de lo que sigue abierto

**Hallazgos de la primera pasada (SF)**

| ID | Estado en `26f54eaa` |
|---|---|
| SF-01, SF-02, SF-03, SF-04, SF-06 | **Cerradas** (sección 4), con las observaciones TF-01 y TF-02 |
| SF-05 | Abierta, Baja: la actualización desde el anillo por claves sueltas sigue sin procedimiento |
| SF-07 | Abierta, Baja: MC-07, 09, 18, 29 y 31 en código sin cambios (tu tanda 10, punto 2) |
| SF-08 | Abierta, Baja |
| SF-09 | Abierta, informativa |

**Revisión del blueprint (SA)**

| ID | Estado |
|---|---|
| SA-01 | **Cerrada en todos los verbos que anclan** (`--preparar`, `--anclar`, `--migrar`, `--cambiar-recuperacion`). La ampliación a `--migrar` con ancla está pendiente de firma (TF-03) |
| SA-02, SA-11 | Cerradas |
| SA-03 | Cerrada; residuo SF-05 |
| SA-06 | Cerrada en lo firmado; `comprobar-servidor` es de A |
| SA-15 | Cerrada para F1 |
| SA-10 | Mitigada en parte (A) |
| SA-12, SA-14 | Abiertas |
| SA-04, 05, 07, 08, 09, 13 | Fuera de F1, sin cambios |

**Plan de pruebas DM-07 (QA-AN)**

| ID | Estado |
|---|---|
| QA-AN-01 | Abierta: llaves de otro principal antes de `--recuperar` |
| QA-AN-04 | Abierta: sin exclusión mutua en `--preparar` |
| QA-AN-06 | Abierta: AN-05 en Release sin costura |
| QA-AN-07 | Abierta: `AnilloPrueba.Anclar` con `DateTime.UtcNow` |
| QA-AN-02, 03, 05 | Cerradas |
| QA-AN-08 | Informativa |

## 8. Mutaciones de esta pasada (una a la vez, restauradas)

| ID | Archivo | Mutación | Resultado | Lo mata |
|---|---|---|---|---|
| MD-01 | `MantenimientoAnillo.cs` | `ExigirDictada` no compara | Muerta | `Anclar_con_otra_huella_dictada_no_ancla`, SF01a ×2, SF01b |
| MD-02 | `MantenimientoAnillo.cs` | `--migrar` sin `ExigirDictada` | Muerta | SF01b |
| MD-03 | `MantenimientoAnillo.cs` | `--cambiar-recuperacion` sin `ExigirDictada` | Muerta | SF01a ×2 |
| MD-04 | `MantenimientoAnillo.cs` | No publica el `.cer` nuevo | Muerta | `SF01a_…_publica_solo_el_cer_dictado` |
| MD-05 | `MantenimientoAnillo.cs` | Sin la comprobación posterior a la publicación | **Sobrevive** (47 pruebas) | — |
| MD-06 | `GuardasAnillo.cs` | G-1 sin `sistema` | Muerta | `Con_el_servicio_instalado_…`, SF02 |
| MD-07 | `GuardasAnillo.cs` | `NoVerifica` y `RecuperacionCambiada` no pendientes | Muerta | `SF03_InstalacionId_espera_…` |
| MD-08 | `ComandoSistema.cs` | Pendiente sin salida 2 | Muerta | `SF03_sistema_login_api_antes_de_anclar_…` |
| MD-09 | `ComprobacionAnillo.cs` | Excepción con 18456 y 916 | **Sobrevive** | — |
| MD-10 | `ComprobacionAnillo.cs` | Excepción sin el 4060 | Muerta | `SF04_con_GPOS_SYSDATA_que_todavia_no_existe_…` |
| MD-11 | `ComprobacionAnillo.cs` | Excepción sin el 208 | **Sobrevive** | — |
| MD-12 | `ComprobacionAnillo.cs` | Todo `SqlException` = «sin ancla» | Muerta | `SF04_si_la_fila_del_ancla_no_se_puede_leer_…` |
| MD-13 | `GPOS.Migracion/Program.cs` | Sin `instalacionPendiente` | Muerta | `G2_y_la_espera_de_InstalacionId_se_cablean_en_sistema` |
| MC-23 | `GPOS.Migracion/Program.cs` | Sin la llamada a G-1 | **Muerta** (antes sobrevivía) | `G1_se_comprueba_en_GPOS_Migracion_…` |
| MC-24 | `GPOS.Migracion/Program.cs` | Sin la llamada a G-2 | **Muerta** (antes sobrevivía) | `G2_y_la_espera_…` |

Total: 15 mutaciones válidas, 12 muertas y 3 sobreviven (MD-05, MD-09 y MD-11). Los mutantes vivos de la primera pasada (MC-07, 09, 18, 29 y 31) están en código sin cambios y no los repetí.

## 9. Remediaciones priorizadas

| Prioridad | ID | Acción | Esfuerzo [I, ±40 %] | Cuándo |
|---|---|---|---|---|
| 1 | TF-01 | Salida 4 para `NoVerifica` y `RecuperacionCambiada` en el primer `sistema`; A no confía solo en el 2 | 0,05 dp | Antes del 5-nov (A escribe `FaseEsquema`) |
| 2 | TF-02 | Ante un 4060, confirmar en `master` que la base no existe; si existe, 4704 | 0,05 dp | En F1 o justo después |
| 3 | TF-04 | Pruebas para MD-05, MD-09 y MD-11 | 0,05 dp | Con SF-07 (tanda 10) |
| 4 | TF-03 | Firma del propietario de la ampliación de SA-01 a `--migrar` con ancla | 0 dp | Hoja de firma |
| 5 | SF-05, 07, 08, 09 | Sin cambios desde la primera pasada | ≈0,25 dp | Después de unir |

## 10. Recomendación

**Aprobado con observaciones.** SF-01 (la Alta) y las otras cuatro correcciones están cerradas y probadas: doce mutaciones muertas, entre ellas MC-23 y MC-24, que antes sobrevivían. Lo que queda es Bajo:

- TF-01 y TF-02, recomendados antes del 5-nov porque tocan lo que A escribe;
- los huecos de prueba;
- la firma de TF-03.

Siguen pendientes de la VM los casos W-AN-01 a W-AN-05. Es una recomendación técnica; la unión la decide el propietario.

## Supuestos

- `Inicializacion.EjecutarAsync` corre siempre después de `ComprobacionAnillo.EjecutarAlArrancarAsync` con el mismo login (`GPOS.Api/Program.cs:457-458`) [V, lectura]. No arranqué la API completa con un login huérfano [I].
- El 4060 de un login sin acceso y el de una base inexistente traen el mismo número. Lo confirmé con el primero en `C2_TF02`; el segundo lo prueba B.
- Las guías fuera del repositorio que citen `--migrar` las identifica B.

### Cierre
- Estado: Aprobado con observaciones (recomendación técnica).
- Artefactos:
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-25-revision-adversarial-f1-26f54eaa.md`;
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-25-revision-adversarial-f1-26f54eaa-pruebas.cs.txt`.
- Supuestos: los de la sección anterior.
- Decisiones candidatas a ADR: la precisión de SA-01 (huella dictada en todo verbo que fije, cambie o reafirme el ancla, incluido `--migrar` con ancla). Alternativa descartada: exigirla en `--migrar` solo sin ancla, más permisiva, que deja la regla con una excepción que explicar.
- Entregas a otros agentes:
  - B (desarrollador) → TF-01, TF-02, TF-04 y SF-05 a SF-09.
  - A → en `FaseEsquema`, tratar el 2 del primer `sistema` como normal solo con la línea «Pendiente: … anillo --anclar» (TF-01).
  - Arquitecto Maestro → la hoja de firma de TF-03.
  - Quien coordine → scratchpad por agente (incidente del guion compartido).
- Próximo paso recomendado: que B haga TF-01 (salida 4 para el ancla que no cumple) antes de que A cierre `FaseEsquema`; con eso, unir F1 cuando el propietario lo ordene.
