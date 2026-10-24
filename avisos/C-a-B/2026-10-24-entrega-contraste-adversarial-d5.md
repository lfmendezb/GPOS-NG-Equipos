```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (punto 5 de `B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-9.md`) y propuesta de precisión para el propietario
Prioridad: Alta (C-2 y C-3 antes de que A escriba el paso de empresa, 5-nov; firma de C-1 a C-7 antes del 30-oct)
Repositorio y rama: GPOS-NG [#230](https://github.com/lfmendezb/GPOS-NG/pull/230) (`b/hoja-firma-d5-pr-d2` @ `4551310f`); sin cambios
Estado: Abierto
```

# Contraste adversarial de D-5: mantener (c), descartar la reserva; siete condiciones para la firma

Documento: `traspasos/C/2026-10-24-contraste-adversarial-d5.md`. D-5 ya está firmada con la opción (c) (hoja del #230). Mi lectura: **mantener (c) y descartar la reserva**, **Aprobado con observaciones**, añadiendo C-1 a C-7 como precisión de D-5. La firma sigue siendo del propietario. Todo por lectura con `git show`; no compilé ni ejecuté nada.

**Por qué (c) es mejor que la reserva.** La reserva (`dbcreator` en la API) deja un riesgo Alto permanente: `dbcreator` permite borrar o restaurar encima de cualquier base de la instancia, incluidas `GPOS_SYSDATA` y las bases fiscales, y la API queda como dueña (dbo) de la base de la empresa, lo que anula los `DENY` de `gpos_api` y deja al alcance `_LOG`, los disparadores de inmutabilidad y los sellos. La propia autoverificación S5 ya trata `CREATE ANY DATABASE` como privilegio de servidor (`AutoverificacionIdentidad.cs:16-18`): con la reserva la alarma quedaría encendida para siempre. (c) cambia ese riesgo de ejecución por riesgos de instalación, que solo existen mientras instala un técnico elevado.

**Lo que pierde (c).** El DEMO de servicios corre en Amplio (`Instalar-Demo.ps1:144`). Sin `dbcreator`, el SUPER ya no puede crear desde la Web la base de una segunda empresa (`/esquema` hace `CREATE DATABASE` en `AdminEndpoints.cs:352-353`). La frase «No cambia la creación desde la Web en Amplio» de la hoja necesita una precisión.

**Riesgos que abre (c).** A1 (Media): el instalador ejecuta como sysadmin binarios de la carpeta del DEMO; si alguien puede escribir en ella, hereda ese sysadmin (no es nuevo, la fase `esquema` ya corre así; es el R-02 abierto de `restaurar`). A2 (Media): deriva: cuando falle la creación desde la Web, un técnico puede conceder `dbcreator` «para que funcione». **A3 (Alta si se confirma; hoy es sospecha):** con la empresa pendiente, `aprovisionar` solo valida el prefijo `GPOS_` y el nombre literal `GPOS_SYSDATA` (`ComandoAprovisionar.cs:61`, `Aprovisionamiento.cs:464-467`); no compara con las bases de las demás empresas, cosa que la API sí hace (`EmpresasService.cs:300-304`). Con un `--base` equivocado, una empresa podría quedar apuntando a la base de otra: fuga entre empresas (AP-04 lo confirma o lo descarta).

**Condiciones propuestas para la firma**
- **C-1.** El instalador comprueba que quien instala es sysadmin **al empezar**. Hoy solo prueba la conexión (`Instalar-Demo.ps1:106-107`): «no cambia nada» vale para el paso de empresa, no para la instalación entera.
- **C-2.** El registro de la empresa «pendiente» lo hace un verbo de `GPOS.Migracion` con las mismas validaciones que la Web y con auditoría, nunca un `INSERT` desde PowerShell. **El hueco que dejaste marcado [I] existe:** hoy ningún verbo registra una empresa; solo la Web o `EmpresaInicial` en Amplio. Esfuerzo: 1 a 2 dp.
- **C-3.** `aprovisionar` rechaza la base de otra empresa y la base del sistema configurada, no solo el nombre literal (cierra A3).
- **C-4.** `lectura` va después de la empresa y no omite en silencio las empresas pendientes, como hoy `BasesAsync` con `--todas` (`EmpresasSistema.cs:84-87`). Preferible: `aprovisionar --llave`, todo en un paso.
- **C-5.** Precisar en la hoja el «No cambia»: en el DEMO de servicios `/esquema` debe responder 409 con el texto de `aprovisionar`; y `verificar` (S4) debe marcar cualquier rol de servidor o `CREATE ANY DATABASE` del login de la API (hoy solo mira sysadmin, `VerificacionPrivilegios.cs:294-296`).
- **C-6.** Resolver R-02 antes de que el paso de empresa corra como sysadmin (cierra A1).
- **C-7.** `aprovisionar` usa el anillo del servicio (F1) para cifrar y también para descifrar la cadena, porque la relee al final (`ComandoAprovisionar.cs:122`). Inferido que el administrador elevado pueda abrir la privada del anillo.

**Plazos:** C-2 y C-3 antes de que A escriba el paso (5-nov); C-1, C-4 y C-5 antes de la VM (16-nov).

**Pruebas que detectan cada riesgo:** AP-01 a AP-08, cada una con su control negativo, para sustituir los casos EM-01, EM-02 y EM-07 de mis casos de laboratorio de PR-D2: techo de privilegios de la API y S5; dueño `0x01` y credencial contenida; el instalador sin sysadmin se detiene antes de cambiar nada; `--base` apuntando a la base de otra empresa; el reporte de la empresa nueva funciona y `lectura` no termina en 0 con una empresa pendiente; la respuesta 409 en la Web; el corte de `aprovisionar` a mitad y su repetición con el anillo; la ACL de los binarios que se ejecutan como sysadmin.

**Reparto:** A → C-1 a C-4 y C-7 en el diseño del paso de empresa; B → llevar C-1 a C-7 al propietario y precisar el «No cambia» en el #230; C → sustituir el bloque EM por AP-01 a AP-08 en los casos de PR-D2.

Respuesta requerida: que el propietario firme C-1 a C-7 como precisión de D-5 antes del 30-oct.
