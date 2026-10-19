# Decisiones de B sobre los hallazgos pendientes de seguridad (#79 y #81), 2026-10-18

B decide en la pausa del propietario (hasta el miércoles 21). Fuentes: `traspasos/C/revision-seguridad-longitudes-columnas-2026-10-18.md` (#79) y `traspasos/C/revision-seguridad-t2b-archivo-instalacion-2026-10-18.md` (#81). Todos son de severidad Baja.

| Hallazgo | Decisión | Cuándo y quién |
|---|---|---|
| **LC-03** La clave de la caché de `LongitudesColumnas` es la cadena completa con la contraseña | **Aplicar**: clave `DataSource + InitialCatalog + UserID` normalizada con `SqlConnectionStringBuilder` (incluye el usuario porque `INFORMATION_SCHEMA` depende de los permisos). Es preexistente, pero con la rotación de DL-22 se acumula una entrada por credencial | En el siguiente PR de C sobre `LongitudesColumnas`, junto con LC-04; < 0,5 día |
| **LC-04** Esquema vacío por falta de permisos de metadatos queda en la caché y la guarda no valida | **Aplicar antes de aplicar el privilegio mínimo de RG-14 en cualquier instalación real**: si `columnas.Count == 0`, no guardar en la caché y registrar un aviso | Con LC-03; condición de PUB-06 |
| **LC-05** `Limpiar()` frente a una lectura en curso puede dejar un esquema anterior | **Aceptar por ahora** (ventana estrecha, la abre una acción del administrador, falla cerrada si la columna se ensanchó). Contador de generación en el siguiente endurecimiento | Después del corte |
| **T2B-S04** Sin rastro de los cambios en caliente del archivo de instalación | **Aplicar**: `ChangeToken.OnChange` que registre los nombres de las claves ignoradas o cambiadas, sin valores (≈ 1 h) | Con S05, en el cierre de T2 (C) |
| **T2B-S05** Carrera en la recarga (se publica `Data` antes de quitar las claves) | **Aplicar**: construir el diccionario filtrado y publicarlo de una vez | Con S04 |
| **T2B-S07** Ejemplo `ventas@empresa.com` (dominio de un tercero) | **Hecho**: cambiado a `ventas@example.com` (`2635ec8d`; importación y guarda, 162/0). Ampliar `ValoresDeTercerosTests` a direcciones de correo de ejemplo queda con S04 y S05 | Hecho el 2026-10-18 |
| **Comprobación de la DACL del archivo de instalación** | **Aplazar** hasta que ADR-77 esté en el núcleo (el instalador crea `config\` con DACL protegida); mientras tanto sigue la condición de la revisión: el archivo solo se acepta con la lista de claves permitidas | **Condición de PUB-06** |

C sigue en pausa hasta el miércoles 21; estos encargos se le asignan entonces (LC-03, LC-04, S04, S05 y la ampliación de la guarda, unos 0,3 sp en total).
