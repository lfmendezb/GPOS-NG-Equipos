Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #33 (a/lic-l1a-4); traspasos/A/ (validación, seguridad y blueprint v2.5)
Estado: Abierto — correcciones en cola

# PR #33 (L1a-4): arquitecto y seguridad «Aprobado con observaciones»

**Prioritario (se corrige en el #33, detrás de la cola de compilación):**
- **PA-02 (Media):** con solo las credenciales de la API, un `INSERT` en `Licencias` (misma `sec` con otro contenido, o `avanzado` que no verifica) hace que vuelva a regir la licencia anterior: deshace un corte inmediato, una baja de empresa, una reducción de cupo o un cambio de RNC. Remedio ≈0,2 dp; el arquitecto fija el texto (posible precisión de ADR).
- **PA-01 (Media):** si la lectura de la huella falla, el cambio de entorno no se detecta y la marca guardada se borra. Remedio ≈0,15 dp.
- **Arquitecto 1 y 2:** `PerfilMin` en la reinserción calculado como en la carga (no subirlo ni bajarlo con un archivo Básico); rechazar en caliente las licencias `Produccion`/`Beta` en Amplio (= PA-05).

**Secundario (para después, salvo pedido del propietario):** PA-03 (`PublicadoUtc` a mano alarga la gracia), PA-04 (DACL de la carpeta si ya existe, devops / ADR-77), PA-06 (importador), modo de integridad para `kid` retirados en binarios (≈0,3 dp, antes de retirar un `kid`), perfil vigente desde fuentes verificables (≈0,2 dp, antes de las llaves Avanzadas).

**Confirmado:** sin reutilización de filas con MAC entre claves o instalaciones; LV-21 sin retroceso; «ya aceptado» por contenido y nivel; tope de rechazos; registro en DI y rutas L-03/05/06 van en L1b.
