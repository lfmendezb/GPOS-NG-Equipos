```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega (parcial: diseño) | Pregunta
Prioridad: Normal
Repositorio y rama: GPOS-NG c/dm04-autoclose (e7e65fa, desde 42e13b6)
Estado: Abierto
```

# C-4: AUTO_CLOSE OFF obligatorio (DM-04 y DM-03) y guía de memoria de SQL Server

Diseño entregado por el arquitecto de datos de C. **La implementación y la prueba las hace C** con un desarrollador cuando C-1 termine de compilar (un build a la vez).

**Documentos (rama `c/dm04-autoclose`, `e7e65fa`):**
- `docs/datos/2026-10-10-auto-close-off-aprovisionamiento.md`
- `docs/operaciones/2026-10-10-guia-memoria-sql-server.md`

## Lo medido (contra `.\SQLEXPRESS`, con bases `GPOS_TEST_C4_*` ya borradas)
- **Express deja AUTO_CLOSE ON en todo `CREATE DATABASE`**, aunque `model` lo tenga en OFF. Ningún punto del código lo apaga: ni `FijarOpcionesAsync`, ni el `EnsureCreatedAsync` de `GPOS_SYSDATA`, ni el `CrearBaseAsync` heredado.
- **Primera conexión con la base cerrada:** 404 ms en una base vacía y 4 a 6 s en el DEMO de 80 MB.
- **DM-03:** con la base cerrada, la intercalación se lee como NULL. Además del aviso falso de `ActualizarAsync`, el mismo fallo está en **`CrearAsync:69`**, donde un NULL provocaría un cambio de intercalación innecesario con `SINGLE_USER WITH ROLLBACK IMMEDIATE`.
- **`ALTER DATABASE … SET AUTO_CLOSE OFF WITH NO_WAIT`:**
  - va fuera de toda transacción, porque dentro da el error 226;
  - **no hace falta `ROLLBACK IMMEDIATE` ni detener la API**: tardó 25 ms con otra sesión activa;
  - exige ALTER sobre la base: con `db_ddladmin` falla (5011) y con `db_owner` funciona.

## Propuesta
- **Opciones de toda base de GPOS NG** (empresa, sucursal y `GPOS_SYSDATA`): AUTO_CLOSE OFF, AUTO_SHRINK OFF y PAGE_VERIFY CHECKSUM. Se fijan en un lote idempotente que en la prueba devolvió 7 y luego 0.
- **Ayudante nuevo `src/GPOS.Core/Infraestructura/Motor/OpcionesBase.cs`.** Lo llaman:
  - `FijarOpcionesAsync` (cubre `crear` y `actualizar`);
  - `EsquemaEmpresa.CrearBaseAsync`;
  - `EsquemaSistema.AsegurarOpcionesAsync` (`GPOS_SYSDATA`, al iniciar la API).
- **DM-03:** fijar las opciones **antes** de leer la intercalación y leerla conectado a la propia base. Si aun así sale NULL, el aviso dice «no se pudo leer».
- **`verificar` informa AutoClose** sin cambiar el código de salida (DM-02 queda aparte).
- **Esfuerzo:** 0,5 sp, con 8 casos de prueba especificados en la clase `OpcionesBaseTests`.
- **Instalaciones existentes:** las bases de empresa se corrigen en el próximo `actualizar` y `GPOS_SYSDATA` en el próximo arranque de la API. Tarda milisegundos y no toca datos.
- **RG-14:** la fila «Identidad de migración» del modelo H0 dice `db_ddladmin`, pero el código ya necesita `db_owner` y `CREATE ANY DATABASE`. Hay que corregirla (auditor).

## Guía de memoria (`min` / `max`, en MB)
| Perfil | `min` | `max` |
|---|---|---|
| Express, 4 GB (todo en uno) | 256 | 1.024 |
| Express, 8 GB | 512 | 2.048 |
| Nodo de sucursal, 4 / 8 GB | 256 / 512 | 1.024 / 2.048 |
| Standard, 8 GB, con API y Web | 1.024 | 4.608 |
| Standard, 8 GB, solo SQL | 1.024 | 6.144 |
| Standard, 4 GB (no se recomienda) | 512 | 1.536 |

- Las instancias ajenas, como BarTender, llevan un tope de 512 MB, solo con autorización del cliente.
- La guía incluye los comandos `sp_configure` y las consultas de verificación.

## Decisiones para el propietario (C las pide; B decide cómo llevarlas a la firma)
- **D-C4-01:** registrar la regla como **precisión de ADR-54, punto 3** (recomendado; RCSI y FULL tampoco tienen ADR propio), o como ADR nuevo del rango de C (130-159).
- **D-C4-02:** si la API no puede corregir `GPOS_SYSDATA` por permisos, arranca igual y deja un aviso en el log (recomendado).
- **D-C4-03:** incluir AUTO_SHRINK OFF y PAGE_VERIFY CHECKSUM en el mismo cambio (recomendado).
- **D-MEM-01 a 03:**
  - adoptar los valores de la guía;
  - hoy los aplica el técnico; más adelante, el instalador de servidor;
  - el tope de BarTender, solo con autorización del cliente.

Sin la firma, C construye según la recomendación en la rama `c/dm04-autoclose` y no une nada.

## Otros
- **C-1:** el DEMO de `demo/2026-10-10` nacerá con AUTO_CLOSE ON. Se le pasó a C-1 la línea de mitigación para el guion de instalación.
- **Para devops:** `GPOS_SYSDATA` está en recuperación SIMPLE; conviene revisarlo con MD-54 (fuera de este encargo).
