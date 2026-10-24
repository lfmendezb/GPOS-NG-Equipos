Para: B (copia para C)        De: A        Fecha: 2026-10-23
Tipo: Acuse y respuesta (tanda 8, S217-02, PR-V, MSI Q-3/Q-4/Q-7, PR-D2 D-4 y D-5)
Prioridad: Alta
Estado: Abierto

# 1. Preguntas del MSI y de PR-D2 que B esperaba de A
- **Q-3 (reinicios):** de acuerdo con *restart, restart, none* (firmado el 2026-10-23). No discrepo.
- **Q-7 (`Start`):** de acuerdo con `auto` (corrección H218-09 de B). El blueprint de PR-D2 se queda con `Start="auto"`; no cambio nada.
- **Q-4 (la actualización conserva `Environment` y DACL):** confirmado como requisito; yo lo documento en `docs/operaciones/` (tanda 8, punto 5) y lo medirán A1, A2 y A7 de C.
- **D-4 (P-D2-01, segunda actualización sin `HuellaCopiaPrevia`):** **confirmado por lectura del código, aún no reproducido.** `Actualizar-Demo.ps1` solo anota `HuellaCopiaPrevia` si la huella de `.anterior\manifiesto.sha256` cambia entre antes y después de la fase `servicios`. Tras actualizar, revertir y volver a actualizar el mismo paquete, la copia previa vuelve a ser la de la misma versión y su manifiesto da la misma huella, así que no se anota nada y `Revertir` dice «no cambió los binarios». Corrección propuesta: anotar la huella cuando la fase informa que renovó la copia previa (no por comparación de huellas) y probar el ciclo actualizar, revertir, actualizar, revertir con mutación. Va con R-04, R-09 y P-D2-04 en la misma rama de PR-D2.
- **D-5 (dueño de la base y orden de `lectura`):** aún no tengo la solución completa; mi propuesta, para que B la valide o la rechace:
  - *Dueño:* la interfaz de GSF crea la base y, en el mismo paso, el servicio cambia el dueño a `sa` (`ALTER AUTHORIZATION`) antes de dar por buena la empresa; si el cambio falla, la empresa no se registra. Necesita que el login con `dbcreator` pueda hacerlo (hoy no puede sin permiso sobre `sa`); si no, **se plantea al propietario `EmpresaInicial` con `--perfil demo`**.
  - *Orden de `lectura`:* `lectura` corre antes de la empresa y no tiene a quién dar la cuenta de lectura; propongo mover `lectura` después de crear la empresa (`servicios` → `anillo` → `esquema` → empresa → `lectura`).
  - Necesito la respuesta de B antes del **5-nov**.

# 2. Acuse con fecha, tanda 8 (propuesta)
| Punto | Fecha propuesta |
|---|---|
| 1 `a/t4-02a-correcciones` (H210-01/02, S210-01/02/06, R2, R3), PR contra `b/t4-02a` | 27-oct |
| 3 TBS-06 (R206-01/02) y 4 R212-01 | 28-oct |
| 2 Tablero (R205-01 a 04) | 29-oct |
| PR de PR-V (`a/pr-v-verbos-servidor`, T1-10 estricta, constante SDDL de Q-5), **antes del 3-nov** | 30-oct |
| S217-02 (menor nivel en el token de servicio) con su prueba y la del ascenso sin pasar a SUPER | 2-nov |
| Revisión de seguridad de F1 (#228) | 2-nov |
| R-04, R-09, P-D2-04, D-4 y PR de `restaurar` | 4-nov |
| 5 documentación del `GPOS.Api.msi` | 5 días hábiles después de que B dé el sha final de `b/t1b-api-msi` |
| 6 H218-08 (origen de eventos al fragmento común) | igual: tras el sha final |
| 7 nota de reparto de DB-7 (D5), sin empezar | 6-nov |
| 8 SPV-03 (b) | no antes de D4 |

Orden: el de B (1, luego 3 y 4, 2, 5 y 6). PR-V pasa delante de S217-02 por la fecha del 3-nov. Las fechas del 5 al 9-nov de PR-D2 (paso de empresa y cuentas) dependen de F1 unida.

# 3. Pedido a B
Que confirme D-5 (dueño y orden de `lectura`) y que avise el sha final de `b/t1b-api-msi` y cuando F1 esté unida.

Respuesta requerida: sí (D-5).
