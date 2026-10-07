---
name: cierre-numeracion-nuevo-equipo
description: "La revisión independiente con Fable 5.1 de la numeración configurable se hará en el nuevo equipo del propietario, no en LAPTOP-DUMQQ5QK"
metadata:
  node_type: memory
  type: project
  originSessionId: f996b5de-a7ff-414c-a94d-a243315ed78c
  modified: 2026-10-03T16:37:15.257Z
---

Decisión del propietario del 2026-10-02: la revisión independiente con Fable 5.1 de la rama `feature/numeracion-configurable` se hará **en el nuevo equipo**.

El propietario copiará todo a mano, sin push a GitHub. Las llaves de Data Protection (DPAPI) no se trasladan: allá hay que volver a escribir las cadenas de las empresas y la clave SMTP.

**Why:** el propietario termina las pruebas en este equipo y luego se muda.

**Actualización del 2026-10-02:** el propietario aplazó a la siguiente fase:
- la impresión en papel, pasos 45 a 49 (aquí solo tiene impresoras virtuales);
- MAUI, pasos 50 a 52;
- la prueba manual del lienzo (zoom y selección múltiple).

En este equipo solo repite el paso 10, con la marca `GPOS.Esquema`, y después se pasa a la revisión con Fable.

**How to apply:**
- En este equipo: correcciones de PC-4 (C-1 a C-7), unirlas a la rama y repetir los pasos pendientes (29–31, 42, 45–52).
- No lanzar la revisión con Fable aquí.
- La unión a master va después de esa revisión y con la firma del propietario.

**Actualización del 2026-10-03 (equipo nuevo, DevLab00, SQL Server 2025):**
- El propietario firmó P1, P2 y la corrección de CP187, que van en la rama antes de Fable.
- Los documentos `docs/datos/2026-10-03-diagnostico-cp141-cp187-sql2025.md` y `docs/decisiones/2026-10-03-decision-estrategia-acceso-datos.md` quedan **fuera de la rama y fuera de la carpeta del repositorio** hasta que termine la revisión de Fable. Así Fable revisa sin conocer nuestras conclusiones.
- Después se le muestran a Fable para comparar y se confirman en un solo commit de documentación.
- P1, P2 y CP187 quedaron confirmados en `9f790f1`, con la suite en verde y QA aprobado. La rama queda lista para Fable.
- Los documentos están en `OneDrive\Documentos\Agentes\pendientes-post-fable\docs\...`.
- Las pruebas en este equipo necesitan la variable `GPOST_TEST_SERVER=.`.
- Pendientes de baja severidad para después: P3, H-1 y H-2 (claves de texto sin largo en las listas con `Contains`).
- La revisión con Fable terminó el 2026-10-03. Informes y consolidado en `OneDrive\Documentos\Agentes\revision-fable\`.
- El lote bloqueante RG-01 a RG-03 está en `b3c59aa`, con la suite en verde (1.131/0/4).
- El propietario dio la **PC-4 por cerrada** el 2026-10-03, con lo aplazado.
- Antes de unir: RG-10, RG-21 y la corrección de la lista de PC-4 (pasos 12, 17 y 20).
- La unión a master se hace por pull request con `gh`, ya instalado y con sesión de lfmendezb. El repositorio GitHub `lfmendezb/GPOS-NG` es privado.
- **Decisiones del propietario sobre la revisión con Fable (2026-10-03):**
  - Firmó el consolidado: "Aprobado con observaciones".
  - RG-04 y RG-05: ver [[no-generar-comprobante-permiso-bitacora]].
  - RG-30: ver [[titulos-menu-mayusculas]].
  - **RG-25, opción A:** botón "Sincronizar el espejo" (E12) en la pantalla de Diagnóstico, solo para el SUPER y con `DialogoMotivo`. Se recomendó además escribir el procedimiento de reversión en `docs/operaciones/`. Va antes de publicar.
  - **RG-19 aprobado:** precisar ADR-46 ("impide activar el modo por sucursal con ese código", no "asignar el código") y ADR-45 (la excepción del cambio de subserie, residuo QA2-02, y `inv_Articulos` como último nivel en orden ordinal, de RG-03). También va en la regla de CLAUDE.md.
  - Sigue abierto RG-14 (privilegio mínimo; el propietario se inclina por un usuario de Windows exclusivo, y se le explicó la separación entre cuenta de operación y cuenta de esquema).
- **UNIDA A MASTER el 2026-10-03** con la firma del propietario: PR lfmendezb/GPOS-NG#1, merge commit `7bcda19`, etiqueta `numeracion-v1`.
  - El master local (carpeta `GPOS NG`) está al día.
  - La rama `feature/numeracion-configurable` se conserva; el propietario decidirá más adelante si la borra.
  - Lo que sigue es el bloque "antes de publicar" (CLAUDE.md y §7 del consolidado) y luego la siguiente fase.
- Padrón RNC en GPOS_SYSDATA: cargado el 2026-10-03, 791.383 contribuyentes en 16 s. Antes había fallado por falta de memoria de SQL Server; se resolvió con min 1 GB y max 3 GB.

Relacionado: [[clasificacion-empresas-pendiente]].
