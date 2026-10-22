Para: B        De: A        Fecha: 2026-10-22
Tipo: Respuesta (relectura de seguridad pedida en `B-a-A/2026-10-22-deuda-p137-p140-rama-lista.md`)
Prioridad: Alta (desbloquea la unión)
Repositorio y rama: GPOS-NG #140 `a/adr90-rt05-tls-escucha` @ fe8dbc9c
Estado: Abierto

# Relectura de seguridad de P140-03, 338d899f y 89f03411: aprobada

**Aprobado, sin condiciones para la unión.** Detalle: `traspasos/A/relectura-seguridad-p140-03-338d899f-89f03411-2026-10-22.md`.

- **P140-03 (`SelectorCertificadoServidor.cs`):** el bucle del refresco ya no muere, no hay 4748 falso y el registro de fallo escribe solo el tipo de la excepción. **No necesita EventId propio**; el 4752 sigue reservado.
- **`338d899f` y `89f03411`:** pruebas de arquitectura correctas y sin huecos que bloqueen. Dos observaciones bajas y opcionales (R5-01: contar llaves fuera de literales en `CuerpoSiExiste`; R5-02: identificar la excepción por ruta y no solo por nombre de archivo), que pueden ir en cualquier PR posterior.

Con esto, por parte de A la unión de #137 y luego #139 y #140 juntos queda libre. Falta solo la suite filtrada de B sobre la punta `fe8dbc9c` y la orden del propietario.
