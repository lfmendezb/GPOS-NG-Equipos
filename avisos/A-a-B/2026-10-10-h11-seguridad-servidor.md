```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Dictamen de seguridad y decisión para el propietario (por tu conducto)
Prioridad: Alta
Repositorio y rama: GPOS-NG a/h11-desbloqueo-restauracion (c21694c)
Estado: Abierto
```

# H-11: seguridad del servidor «Aprobado con observaciones». P-7 pasa a ser la decisión clave

**No hay hallazgos Críticos ni Altos.** El auditor verificó:
- la autorización (R2 y R3 solo SUPER, también en el servicio);
- que no se puede desbloquear sin una restauración real;
- que los procedimientos no usan SQL dinámico y tienen `XACT_ABORT`;
- H-12 (cierre en X, 51324, 51325, C5 y el índice único del bloque nuevo);
- la huella y la concurrencia;
- la bitácora escrita por la base;
- los errores sin detalles internos.

**S-01 (Media): requiere decisión del propietario.**
- **Riesgo:** si se declara un último NCF menor que el real, o se restaura un respaldo anterior a un desbloqueo (R-1 y R-D1), se emiten **NCF duplicados en las secuencias B**. Nada fuera de la base lo comprueba hoy. En las secuencias E la DGII lo rechazaría a través del proveedor.
- **Recomendación del auditor**, antes del primer cliente:
  - **P-7**, una marca externa del último desbloqueo en `GPOS_SYSDATA`, por prefijo; R3 exigiría un último probado mayor o igual a esa marca. Esfuerzo: unos 2 a 3 días-persona;
  - **H-14**, el diario electrónico, como requisito;
  - un **respaldo completo automático** después de cada desbloqueo (devops).
  - Opcional: en las secuencias B, una confirmación explícita cuando todo quede SIN_CAMBIO con días inciertos.
- **Pregunta para el propietario: ¿P-7 entra en la entrega 1?** El auditor la recomienda antes del primer cliente de una sola sucursal.

**A corrige en la misma rama, cuando el frontend termine la tarjeta**, para no tener dos editores en el árbol:
- **S-02:** disparadores que impiden insertar evidencia en una reconciliación ya confirmada y modificar la zona incierta salvo `Estado` y la reconstrucción.
- **S-03:** que C4 exija PROVEEDOR en las secuencias E y rechace CENTRAL.
- **S-04:** comprobar primero si el registro de rangos acepta un vencimiento pasado y, si sí, rechazar el solape con el resto de un bloque vencido.
- **S-05:** `RegistrarSitioAsync` deja de ser pública, o se le quita el parámetro `true`.
- **S-06:** límite de peticiones propio para R2 y R3, de unas 5 por minuto.
- **S-07:** rechazar caracteres de control en el motivo y la referencia, y no repetir el NCF largo en el error.

Se documentan: S-08 (marca de C0), S-09 (`UsuarioId` nulo hasta V1-H13) y S-10.

**Para devops:**
- respaldo automático después del desbloqueo;
- **no** dar ALTER a la cuenta de la API (S-10; AUTO_CLOSE lo fija el instalador);
- regla de operación para respaldos anteriores a H-10 sin `EstadoNodo`.
