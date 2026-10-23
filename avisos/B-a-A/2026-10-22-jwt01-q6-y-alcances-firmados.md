Para: A        De: B        Fecha: 2026-10-22
Tipo: Aviso (autorización y firmas del propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG
Estado: Abierto

# JWT-01 autorizado, Q-6 firmada y alcances de M-168-2 y de la cédula en rpt

El propietario respondió en el chat el 2026-10-22:

- **JWT-01 (#174): APROBADO.** Sube al #174 tu corrección de la grafía `Jwt:Clave`. Conviene unir el #174 antes del 2-nov; avísame cuando esté empujado.
- **Q-6 (VM): aprobada según la recomendación.** La primera ventana después del 11-13, en `VM-SRV` de LFMB; el guion en `tests/laboratorio-adr090/invitado/` (lo escribes tú en T1-c con `Recoger-Evidencia.ps1`); B opera la VM [lectura de B]. El spike del modo Amplio, en otra ventana de la misma VM, por bloques.
- **M-168-2, lecturas:** el alcance del ADMIN restringido cubre `GET /api/admin/usuarios` (solo cuentas restringidas de su empresa y sucursal) y la escritura de `/api/admin/pos/usuarios`. `politicas/efectiva` se evalúa aparte. Afecta a tu `Usuarios.razor` (tarea 7) y a tu revisión del #168.
- **Q-TI-9, alcance:** la cédula completa en `rpt` solo en documentos con comprobante fiscal (`rpt.VentaDocumento`, `rpt.ConsultaFactura`, cuando es el `RncReceptor`); cotizaciones, consumo sin comprobante y catálogos siguen enmascarados por la letra.

Registro: PR de la rama `b/hoja-firma-alcances-q6`. También abrí los PR de seguimiento: #182 (`estado.json` de #137, #139, #140 y #171) y #183 (DAT-D1, R3-01 a R3-03; confirma el desvío de `Accesos.ConversionId`).

Respuesta requerida: aviso cuando el JWT-01 esté en el #174; confirmar el desvío de #183.
