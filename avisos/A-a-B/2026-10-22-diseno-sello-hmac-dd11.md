Para: B        De: A        Fecha: 2026-10-22
Tipo: Entrega (tarea 3: diseño del sello HMAC de DD-11′, sin compilar)
Prioridad: Media
Repositorio y rama: GPOS-NG #178 `b/datos-t4-10` (insumo) y API de reportes

# Diseño del sello HMAC de DD-11′ entregado (antes del 29-oct)

Documento: `traspasos/A/diseno-sello-hmac-dd11-api-reportes-2026-10-22.md`. Adopta tu mensaje canónico (3.2) y lo completa con el contrato de la ruta, los controles, la verificación y las pruebas.

**Lo que cambia para B:**
1. `CifradorAnillo` cifra las llaves del anillo de Data Protection, no guarda secretos sueltos: la llave se guarda protegida por un `IDataProtector` del **anillo propio de la API de reportes**, que hoy no existe (trabajo nuevo, lo cuenta el esfuerzo: 2,2 dp frente a 1 a 1,5 de la hoja).
2. `Huella` pasa de `binary(32)` a **`binary(33)`** (byte `Kid` más HMAC) para rotar la llave. Ajustar el DDL del #178.
3. **Guardar sin transacción abierta durante la llamada HTTP:** fila inerte, pedir el sello, `UPDATE` con guarda `rowversion`. Decidir (arquitecto-software) si el guardado falla cuando no hay API de reportes (recomiendo que falle).
4. La ruta de sellado exige SUPER estricto, `otp`, autenticación de menos de 5 minutos, canalización, sin token de servicio, tope de tamaño y de frecuencia, y evento sin contenido. Confirmar que la introspección v1 devuelve `auth_time`.
5. Pedir ya a T1-1 el evento `FORMATO_RAZOR_SELLADO` en el catálogo cerrado (se construye desde el 2-nov).
6. **EventId:** el #170 conserva 5117 a 5119; T4-10 pasa a **5134 a 5139** (verificar con `git grep` al construir).
7. Nodos: el sello de la central no verifica en la API de reportes de un nodo; recomiendo aceptarlo mientras el Razor sea legado.

Respuesta requerida: B decide los puntos 3 y 7; el resto es insumo.
