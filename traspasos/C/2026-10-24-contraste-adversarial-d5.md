Para: B (copia para A y el propietario)        De: C        Fecha: 2026-10-24
Tipo: Contraste adversarial (tanda 9, punto 5): D-5 de PR-D2, opción (c) firmada, frente a la reserva `EmpresaInicial` con `--perfil demo`
Estado: Completado. No bloquea firmas: D-5 (c) ya está firmada (hoja en `origin/b/hoja-firma-d5-pr-d2` @ `4551310f`, PR #230)
Fuentes, solo con `git show`: `origin/feature/modelo-ng` (código), `origin/a/pr-d2-manifiesto` (`Instalar-Demo.ps1`) y `origin/b/f1-anillo`. [V] = verificado leyendo el código; [I] = inferido; [S] = sospecha que hay que confirmar en la VM.

## 1. Qué pierde cada opción y qué ataque deja abierto

| | (c) `aprovisionar` con el sysadmin del instalador (firmada) | Reserva: `EmpresaInicial` y `dbcreator` en la API |
|---|---|---|
| **Qué se pierde** | En el DEMO de servicios (que corre en Amplio, `Instalar-Demo.ps1:144`), el SUPER ya no puede crear la base de una segunda empresa desde la Web. `POST /empresas/{c}/esquema` hace `CREATE DATABASE` (`AdminEndpoints.cs:352-353`) y la API no tiene el permiso. La escalera del paso 4 y el bloque EM de mis casos quedan sin ejercitar. | La base nace con el login de la API como dueño (dbo) y con la cadena integrada del servicio, no con la credencial contenida, hasta que alguien corra `aprovisionar` [V: `Inicializacion.cs:141-146`, `EmpresasService.cs:399-402`]. La autoverificación S5 marca `Servidor = 1` mientras exista `CREATE ANY DATABASE` (`AutoverificacionIdentidad.cs:16-18`), así que la instalación vive con la alarma encendida o se acostumbra a ignorarla. |
| **Ataque que abre** | (A1) Quien consiga ejecutar código en la carpeta del DEMO hereda un sysadmin de SQL, porque el instalador ejecuta binarios de esa carpeta. No es un riesgo nuevo: la fase `esquema` ya corre con esa identidad. Es el R-02 abierto de `restaurar`. (A2) La deriva: el día que un técnico vea fallar la creación desde la Web, concede `dbcreator` «para que funcione». (A3) [S] El camino «pendiente» de `aprovisionar` valida solo el prefijo `GPOS_` y el nombre literal `GPOS_SYSDATA` (`ComandoAprovisionar.cs:61`, `Aprovisionamiento.cs:464-467`). No compara con las bases de las demás empresas, cosa que la API sí hace con `MotivoBaseNoPermitida` (`EmpresasService.cs:300-304`). Con un `--base` equivocado, la empresa X recibiría la base de la empresa Y y su credencial contenida: es una fuga entre empresas. | Si alguien compromete la API (inyección o ejecución de código en el proceso), `dbcreator` le permite **borrar o restaurar encima de cualquier base** de la instancia, incluidas `GPOS_SYSDATA` y las bases fiscales. Además, ser dbo en la base de la empresa invalida los `DENY` de `gpos_api`, así que podría alterar `_LOG`, los disparadores de inmutabilidad y los sellos. Esto se acerca al techo de sysadmin que RG-14 quiere evitar. |
| **Gravedad del peor caso** | A3 es **Alta** si se confirma (aislamiento entre empresas); A1 y A2 son **Medias**. | **Alta**, de forma permanente mientras la API tenga `dbcreator`. |

**Lectura:** (c) cambia un riesgo Alto que queda **en ejecución**, al alcance de cualquier compromiso de la API, por riesgos que solo existen **en la instalación** y que un técnico elevado comete o evita. La firma es correcta. Pero la hoja deja cinco huecos sin cerrar (sección 3).

## 2. Qué prueba detecta cada riesgo (para la VM; sustituyen a EM-01, EM-02 y EM-07)

| Id | Prueba | Detecta |
|---|---|---|
| AP-01 | Tras instalar: `IS_SRVROLEMEMBER('dbcreator', <login de la API>) = 0`, ningún rol de servidor, y S5 con `Servidor = 0` en el tablero. **Control negativo:** conceder `dbcreator`, comprobar que S5 pasa a 1 y que `verificar --estricto` da hallazgo; luego retirarlo. | Deriva A2 y reserva |
| AP-02 | `SUSER_SNAME(owner_sid)` de `GPOS_DEMO` es el login de `owner_sid 0x01`; la cadena guardada usa la credencial contenida `gpos_app_*`, no la integrada. | El dueño y la credencial de D-5 |
| AP-03 | Quien instala **no** es sysadmin: el instalador se detiene **antes de 1b**. Antes y después se toma una instantánea de servicios, logins, bases y `%ProgramData%\GPOS NG`, y deben coincidir. | La condición C-1 |
| AP-04 | `aprovisionar --empresa X --base <base de otra empresa>` y `--base <nombre personalizado de la base del sistema>`: se rechaza y no cambia nada. | A3 |
| AP-05 | Reporte de `DEMO` por la API de reportes: 200. Hay usuario `gpos_rpt*` en la base. **Control negativo:** con la empresa todavía pendiente, `lectura` **no** puede terminar en 0. | El orden de fases y la omisión silenciosa |
| AP-06 | En el DEMO de servicios, el SUPER registra una segunda empresa: queda «Pendiente de aprovisionar» y `/esquema` responde 409 con el texto de `aprovisionar`, no 500 ni el error crudo 262. No se crea ninguna base. | La pérdida de (c) bien gestionada |
| AP-07 | Se corta `aprovisionar` tras crear la base (cuando la VM se apaga) y se repite: termina `AL_DIA` o `APROVISIONADA`, sin rotar dos veces (PA-39). La API abre la empresa con el anillo del servicio y `anillo --comprobar` da 0. | Atomicidad y anillo (C-7) |
| AP-08 | Revisión de la ACL: los binarios que el instalador ejecuta como sysadmin solo los pueden escribir Administradores y SYSTEM, desde el origen hasta la ejecución. | A1 |

## 3. Condiciones que conviene añadir a la firma (precisión de D-5; las decide el propietario)

1. **C-1. Comprobar sysadmin antes de empezar, no en el paso de empresa.** `aprovisionar` lo comprueba antes de tocar nada (`ComandoAprovisionar.cs:73-81`). Pero en el instalador, para cuando llega ese paso, `servicios`, `anillo` y `esquema` ya cambiaron el equipo. Hoy la comprobación previa solo prueba la conexión (`Instalar-Demo.ps1:106-107`). Por eso la frase «el paso se detiene y no cambia nada» es cierta para el paso, pero no para la instalación. Costo: unas 2 h.
2. **C-2. El registro «pendiente» lo hace un verbo de `GPOS.Migracion`, nunca un `INSERT` desde PowerShell.** [V] Hoy no hay ningún verbo que registre una empresa: solo la Web (`EmpresasService.cs:217-223`) o `EmpresaInicial` en Amplio. El verbo debe aplicar las mismas validaciones que `GuardarAsync`/`MotivoBaseNoPermitida` y dejar auditoría. Esto confirma el hueco [I] de B: existe. Costo: 1 a 2 días-persona.
3. **C-3. `aprovisionar` (con `--base` o sin él) rechaza la base de otra empresa y la base del sistema configurada,** no solo el literal `GPOS_SYSDATA` (A3, AP-04). Si AP-04 confirma la sospecha, es un hallazgo Alto. Costo: unas 0,5 días-persona más la prueba.
4. **C-4. `lectura` va después de la empresa y no salta en silencio a las empresas pendientes.** `BasesAsync` las omite con `--todas` (`EmpresasSistema.cs:84-87`). La alternativa preferible es `aprovisionar --llave` en un solo paso.
5. **C-5. Precisar el «No cambia» de la hoja.** En el DEMO de servicios (Amplio sin `dbcreator`), la Web registra la empresa, pero no crea su base: la base la crea `aprovisionar`. AP-06 debe dar 409 con ese texto. Además, `verificar` (S4, `VerificacionPrivilegios.cs:294-296`, que hoy solo mira sysadmin) debe marcar cualquier rol de servidor o `CREATE ANY DATABASE` del login de la API, para que la deriva A2 se vea en la comprobación del técnico y no solo en S5 informativo.
6. **C-6. Resolver R-02 de `restaurar` antes de que el paso de empresa corra como sysadmin** (A1, AP-08).
7. **C-7. `aprovisionar` usa la configuración del anillo del servicio (F1).** Debe cifrar con ese anillo y también descifrar la cadena, porque relee y descifra al final (`ComandoAprovisionar.cs:122`). [I] La privada del anillo de F1 tiene que abrirse con el administrador elevado (`PrepararAnillo.cs:254-255`). Si no abre, el comando termina en ERROR después de haberlo hecho todo, y el anillo equivocado deja la empresa ilegible para la API. Lo cubre AP-07.

## 4. Controles bien implementados (verificados)
- `aprovisionar` exige sysadmin en las dos instancias antes de cambiar nada (`ComandoAprovisionar.cs:73-81`).
- Deja el dueño `0x01`, aunque `sa` se haya renombrado (`:100-101`).
- No rota en la segunda ejecución.
- Termina con S4 y no escribe secretos en el Visor de eventos (`:24-26`, `:129-134`).
- La identidad no admite `sa` ni `gsf` (`Program.cs:60-63`).
- S5 ya detecta `CREATE ANY DATABASE`.

## 5. Recomendación
**Mantener (c) y descartar la reserva.** Es **Aprobado con observaciones**, con las condiciones C-1 a C-7 como precisión de D-5. C-2 y C-3 deben estar resueltas antes de que A escriba el paso (5-nov). C-1, C-4 y C-5 deben estar antes de la VM (16-nov). Es una recomendación técnica: la firma es del propietario. La reserva solo sería aceptable con `dbcreator` retirado **en el mismo guion**, inmediatamente después de crear la base, y con `aprovisionar` a continuación. Es decir, sería (c) con un paso de más y una ventana de exposición: no aporta nada.

### Cierre
- Estado: Completado (lectura: Aprobado con observaciones para D-5 (c))
- Artefactos: `traspasos/C/2026-10-24-contraste-adversarial-d5.md`
- Supuestos: DEMO de servicios en Amplio (`Instalar-Demo.ps1:144`); la ACL de la privada del anillo de F1 [I]; A3 es una sospecha [S] hasta AP-04.
- Decisiones candidatas a ADR: ninguna (es una precisión de D-5 en su hoja).
- Entregas a otros agentes: A → C-1 a C-4 y C-7 en el diseño del paso de empresa (tarea 3 de la tanda 9); B → llevar C-1 a C-7 al propietario y anotar la precisión de «No cambia» (C-5) en la hoja del #230; C (yo) → sustituir el bloque EM de `2026-10-23-casos-laboratorio-pr-d2.md` por AP-01 a AP-08.
- Próximo paso recomendado: que el propietario firme C-1 a C-7 como precisión de D-5 antes del 30-oct.
