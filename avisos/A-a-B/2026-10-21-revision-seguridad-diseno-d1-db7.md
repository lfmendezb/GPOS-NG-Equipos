```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Entrega (tarea 3: revisión de seguridad del diseño de D1 de DB-7, T1-1 a T1-4)
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/A/revision-seguridad-diseno-d1-db7-2026-10-21.md`
Estado: Abierto
```

# Revisión de seguridad del diseño de D1 de DB-7

**Aprobado con observaciones** (recomendación técnica; solo lectura, sobre la revisión 2 de los documentos de datos). Sin hallazgos Críticos ni Altos; 5 Medios y 10 Bajos. La sección 6 del informe reparte las condiciones por PR. Esfuerzo total ~1,8 dp (±50 %).

**Medios (condiciones para unir):**
- **D1-01 (T1-3):** las rutas `/api/admin/miembros*` y las del SUPER nacen con la autorización global antes del corte. Pedimos 503 `ACCESOS_NO_CONVERTIDOS` sin la marca `Accesos.Modelo`, precondición del verbo (membresías vacías) y la etiqueta `db7-antes-del-corte` antes de T1-1.
- **D1-02 (T1-4):** una base convertida en D1 recibe la marca sin sellos ni padrón v2; en D3 no hay forma de sellarla sin legitimar en masa (ADR-83). Marca distinta en D1 (`MEMBRESIA.v1-sin-sello`) y modo de D3 que complete los sellos, o que en D1 el verbo corra solo en pruebas.
- **D1-03 (T1-4):** `--instalacion-demo` depende de una bandera; sin guarda convierte en dato legítimo el sobreacceso de hoy. Rechazarlo con licencia Producción o Beta y mostrar vista previa por empresa.
- **D1-04 (T1-2):** `VersionPrivilegios` no sube por regla de la base; un solo escritor más prueba de arquitectura.
- **D1-05 (T1-2):** fijar «sin fila = sin acceso» en Q1 y pruebas de empresa inexistente (cualquier nivel) y del SUPER con empresa inexistente o inhabilitada.

Si no se cumplen: T1-4 sin D1-02 y D1-03 queda **Rechazado**; T1-3 sin D1-01 solo es aceptable si no se publica ningún DEMO desde `feature/modelo-ng` a partir de T1-3. Dos candidatas a ADR: marca de conversión sin sello (D1-02) y sin modo DEMO con licencia Producción/Beta (D1-03). Supuesto no leído: ADR-35 (D1-05).

Revisaremos cada PR de D1 en 5 días hábiles desde su aviso (T1-1 el 2-3 de noviembre).

Respuesta requerida: acuse de que incorporan las condiciones al plan antes del 2026-11-02.
