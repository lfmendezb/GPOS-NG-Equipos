```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Entrega (diseño) y preguntas para ti, C y el propietario
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-p7-candado (desde e7f1f96)
Estado: Abierto
```

# Segunda parte de H-11: blueprint listo; división del trabajo con C para que la confirmes

**Blueprint:** `traspasos/A/blueprint-h11-p7-candado-2026-10-10.md`, del arquitecto-software de A. Lo verificó contra el código y contra el blueprint v2 de C (`929f44e`).

**Diseño en breve:**
- **CR-01:**
  - un solo middleware `ModoCandadoRestauracion` para los dos candados, que rechaza por omisión toda escritura sin marca (`PermitidaConCandado(Sistema|Empresa)` o `SoloConsulta`). Va entre `UseVersionEsquemaEmpresa` y `UseGuardaSitio`;
  - una prueba de inventario de rutas;
  - en la base de empresa se conservan 51330 y se agrega el disparador 51391 sobre `doc.Documento`;
  - los trabajos en segundo plano consultan el mismo estado.
- **El candado de empresa es el estado `RESTAURADA` de H-11**, que libera R3. Mientras `GPOS_SYSDATA` tenga candado, R3 se rechaza con 409 `LIBERAR_SISTEMA_PRIMERO` (orden firmado).
- **P-7:**
  - la marca va en una tabla de solo inserción en `GPOS_SYSDATA`, con clave empresa + nodo + prefijo, y se escribe **después** de confirmar R3;
  - si no se puede leer, R3 no procede;
  - se recompone al liberar `GPOS_SYSDATA` (P-81A-12) y al arrancar.
- **Respaldo posterior:** lo hace la API, en segundo plano, con un respaldo `COPY_ONLY` de la base de empresa y de `GPOS_SYSDATA`, igual que `RespaldoService`. Si falla, se reintenta con R4. **Devops** pone el permiso de respaldo, la retención, la copia fuera del equipo y la alerta.
- **P-3:** regla C9 y bloqueo de chequeras, en el orden firmado.
- **Tus ajustes al unir:**
  - `PD01`: aprobado;
  - `SeparacionTokensTests` con el 429: con observación Baja. Proponemos aceptar el 429 solo en las rutas que tienen límite, y agregar una prueba aparte con los límites apagados (0,02 sp, dentro de este PR).

**División del trabajo con C (PC-1).** Confírmala antes de que A construya; pásasela a C.
- **A construye:**
  - el middleware, las marcas y el inventario de rutas, que sirven a los dos candados;
  - la detección de los candados de empresa y de sistema (15 s);
  - del bloque B de C: la tabla, la vista y el procedimiento de liberación sin cambios, y la reconciliación **sin** los pasos del factor;
  - la tabla `BitacoraSeguridad` del bloque A;
  - las rutas de consulta y liberación del sistema (200 con la recomposición);
  - la regla P-81A-11 en el inicio de sesión;
  - la marca P-7 y su recomposición;
  - la pantalla del sistema sin el factor.
- **C agrega después:**
  - la reconciliación completa (sello, último paso y códigos revividos);
  - el segundo factor y la autenticación reciente en la liberación y en R3;
  - la purga y el servicio de la bitácora;
  - lo del factor en las pantallas.

  **Su tanda T5b baja de unas 0,9 sp a unas 0,35 sp.**
- **Errores:** A usa 52008 y 52009; C conserva 52001 a 52007 y 52010 a 52019.
- **Orden de unión:** este PR primero, después C rebasa, y después H-2 de A.

**Preguntas, con su opción por omisión:**
- **PC-1:** la división de arriba. *Recomendado: sí.* **A no empieza a construir la parte de `GPOS_SYSDATA` hasta tu respuesta.**
- **PC-2:** con la base de empresa bloqueada, ¿el SUPER puede dar de alta secuencias NCF (solo altas)? Sin eso no se puede desbloquear cuando la marca supera el rango de la base. *Recomendado: sí.*
- **PC-3:** el respaldo posterior lo hace la API, no Backup Tool. *Recomendado.*
- **PC-4:** con candado se puede imprimir y reimprimir. *Recomendado: sí.*
- **PC-5:** ¿un PR o dos? Dos serían 2a (unas 1,85 sp: el candado de empresa, P-7 y P-3) y 2b (unas 0,55 sp: la parte de `GPOS_SYSDATA`). *Recomendado: un PR,* salvo que quieras el 2a antes.
- **PC-6:** el candado de una empresa bloquea también lo que esa sesión escriba en `GPOS_SYSDATA`. *Recomendado: sí.*

**Esfuerzo:** unas 2,4 sp con PC-1 (±40 %, inferido). **La fecha del PR se mueve:** unos 2,5 a 3 días hábiles, unos 2 más que un PR solo con P-7.

**Riesgo para la guía de devops (R-10, inferido):** copiar los archivos de la base o revertir una instantánea de la máquina virtual no cambia el fork, así que esa restauración no se detecta.

**Mientras tanto,** A avanza con el diseño de datos (migración `H11CandadoChequeras` y las tablas de `GPOS_SYSDATA`), que no choca con C. H-2 y H-3 siguen en diseño en paralelo.
