```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (veredicto de la rama `b/deuda-pr2-p137-p140` @ `8e2d6ef8`) y entregas de las tareas 1, 2 y 3 del aviso `respuesta-dorados-y-tareas-nuevas-2`
Prioridad: Alta
Repositorio y rama: GPOS-NG `b/deuda-pr2-p137-p140`; área común `traspasos/C/`
Estado: Abierto
```

# Veredicto de la deuda de P137/P140 y entregas

## 1. Veredicto por observación
Informe: `traspasos/C/2026-10-22-revision-deuda-p137-p140.md`. Lectura de los 9 commits, **sin compilar ni ejecutar**; las «mutaciones verificadas» y los 885 de B son declaraciones de B que no repetí; mi evidencia son mutaciones mentales.

| Observación | Veredicto | Nota |
|---|---|---|
| P137-01 | **Cubierta** | `_ => null` en la lectura del entorno deja pasar los dos casos a ConModo y fallan 4744 y 4743 |
| P137-02 | **Cubierta** | Las tres mutaciones hacen fallar su prueba; la recarga es síncrona |
| P137-03 | **Cubierta** | Vaciar cualquier `catch` de la vigilancia deja sin detener y salta el timeout |
| P137-04 | **Cubierta** | Quitar `Detener()` de `ComprobarEfectivas` debe fallar los 5 casos (comparten esa línea). El quinto caso (`http://[::]:443`) se infiere cortado por el tope de 120 s de 4 casos × 30 s; **pido que lo corras solo con la mutación (30 s)** para cerrar la duda. No bloquea |
| P137-05 | **Cubierta** | Fallan LocalMachine→CurrentUser, Registry64→Registry32 y otra subclave |
| P140-01 | **Parcial** | Con un certificado de equipo presente caen SHA-1, minúsculas, CurrentUser y «primero sin comparar»; sin certificado la prueba se omite. **Acepto como deuda** y propongo TL-01 en el laboratorio |
| P140-02 | **Parcial** | Cubiertas la rama RSA, el saludo TLS 1.2/1.3 con RSA y la llave que no se abre (simulada). Falta la ACL real y el tipo real de excepción. **Acepto como deuda**; propongo TL-02 (y TL-03 opcional) |
| P140-03 | **Cubierta** | Único cambio de producción: **correcto y mínimo**. El bucle sobrevive a un registro que lanza al escribir 4748/4749; el 4749 queda fuera del `try` (no produce un 4748 falso); la cancelación no se traga (`WaitForNextTickAsync(_parar.Token)` fuera del `try` interno). Verifiqué las líneas 118-135 y 211 en la rama. Pérdida inevitable: con el registro roto, el 4749 se reemplaza por un `LogError` con solo el tipo de la excepción |
| P140-04 | **Cubierta** | La prueba distingue el nombre del servidor por tres vías (NameMismatch con el manejador de producción, SNI capturado, `ConnectCallback` restringido). **`TargetHost` no tiene efecto** (tu hallazgo nuevo): ninguna prueba razonable lo detecta; **retiro una frase de mi P140-04** que decía que cambiarlo rompe el camino feliz. Hay dos afirmaciones sobre un valor sin uso (`ClienteApiLocalTests.cs:166`, `EscuchaWebModoTests.cs:184`); recomiendo a A quitarlo o comentarlo |

**Hallazgos nuevos: 9, todos Bajos; ninguno bloquea unir #137, #139 y #140.** Los relevantes: P140b-01 `LogError` sin EventId (decisión de A); P140b-03 la llave simulada borra la llave en vez de negar acceso; P140b-04 `TargetHost` sin efecto; P137b-01 la prueba de P137-01 depende del entorno de quien la corre; P140b-02 una espera que da una seguridad que no tiene.

**Regresiones:** ninguna relevante. Solo P140-01 toca el almacén real (en solo lectura) y su resultado depende de la PC.

**Preguntas para B:** ¿cuáles son las 3 pruebas omitidas? ¿P140-01 corrió o se omitió en tu PC?

### Casos nuevos de laboratorio (en una VM sin SQL)
- **TL-01:** almacén real tras el verbo `tls`; exige «1 aprobada, 0 omitidas» y probar huella inexistente, en minúsculas y SHA-1.
- **TL-02:** quitar a la cuenta virtual del servicio la lectura de la llave; debe salir 4747 «la cuenta del servicio no puede abrir la llave privada»; registrar el tipo real de la excepción; con ECDSA y RSA y en caliente (4748 en ≤ 5 min).
- **TL-03 (opcional):** renovación real, 4749 en ≤ 5 min y Web con el certificado nuevo en ≤ 10 min.

## 2. Tareas 1, 2 y 3 del aviso `respuesta-dorados-y-tareas-nuevas-2`
- **Tarea 1 (29-oct, adelantada):** `traspasos/C/2026-10-22-verificacion-codigo-hechos-tt.md`. Un cliente inhabilitado **no se valida** para cobrar (`CobrosService.cs:78`), para recibir notas (`:343`) ni para devoluciones (`Ventas.cs:431`; la ruta POS toma el cliente de la factura). **Hallazgo previo:** ninguna ruta del código pone `cat.Cliente.Inhabilitado = 1` (solo SQL directo). `GENERICO` no tiene bandera ni regla (`CodigoContado` no se usa): se elimina si ninguna caja lo usa. `PuenteMae` copia nombre, RNC en dígitos, teléfonos, dirección y catálogos de cliente y suplidor, sin `Inhabilitado`. El suplidor inhabilitado no recibe notas ni pagos, pero sí solicitud de pago, aplicación de saldo a favor y devolución de compra (sin validar).
- **Tarea 2 (5-nov, adelantada):** `traspasos/C/2026-10-22-inventario-reportes-identificacion-tercero.md`. 22 salidas. **Fuga de mayor prioridad:** el reporte `EF-CAJA-CHICA` (`ReportesSemilla.cs:304`) muestra el RNC completo de la tabla base y elude el enmascarado de `rpt.CajaChica`. M-5 se confirma (R sale completo en 5 vistas `rpt`). No enmascarar: 606, 607, comprobantes impresos y de retención.
- **Tarea 3 (9-nov, adelantada):** `traspasos/C/2026-10-22-plan-prueba-arquitectura-campos-personales-titular.md`. 4 clases, ~31 casos, 27 mutaciones, ~2,55 dp. Hallazgos sobre la lista del especialista H-A1..H-A5 y 10 preguntas. Depende de la firma de la forma del JSON y de P1, P2 y P9.

## 3. Pendiente de C
Guarda de los dorados (G-1..G-6): en implementación; aviso al terminar. Tarea 4 (revisión de la DDL rev. 3 de D1): espero tu aviso. Revisión de los PR de D1: espero tu aviso.

Respuesta requerida: tus respuestas a las preguntas del veredicto; si aceptas la deuda de P140-01/02 para el laboratorio.
