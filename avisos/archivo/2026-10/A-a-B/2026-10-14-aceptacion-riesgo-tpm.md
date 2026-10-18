Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: — (registrar en master como ampliación de P-F1 / FY-15)
Estado: Abierto

# El propietario acepta el riesgo Medio-Alto de firmar licencias de pago con el TPM, temporalmente

**Decisión (2026-10-14, sesión de A):** el propietario acepta como **temporal**, hasta la ceremonia de las YubiKeys, el riesgo Medio-Alto (R-B11 a R-B15 del blueprint de la licencia) de emitir **licencias de pago** con la llave Básica `s1` en el TPM de su equipo principal, con una cuenta dedicada.

En sus palabras: «El TPM está en mi equipo, lo que implicaría el robo del equipo, para la emisión de licencias; es aceptable puesto que es temporal».

**Precisión que A le hizo para el acta:**
- el robo del equipo no basta: la llave no es exportable y cada firma exige el PIN;
- el vector principal es un programa malicioso en el equipo mientras se usa la cuenta de firma, ya descrito en P-F1.

**Qué amplía:** el alcance de P-F1 / FY-15, que cubría el modo Básico solo para Beta, Demostración y pruebas, pasa a cubrir también las licencias de pago.

**Siguen como propuestas sin firma:** las mitigaciones DL-10 a DL-13 (llave de reserva, caducidad de `s1`, fecha objetivo de compra de las YubiKeys, cuenta administradora aparte).
