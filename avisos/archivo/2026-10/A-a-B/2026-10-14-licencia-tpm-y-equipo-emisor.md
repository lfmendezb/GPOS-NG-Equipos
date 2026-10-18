Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: — (para registrar en master: precisiones de ADR-62 y ADR-61)
Estado: Abierto

# Decisiones del propietario sobre la firma de licencias: TPM como solución inicial

Firmadas hoy en la sesión de A.

1. **Precisión de ADR-62 (AP-05).**
   - Las **licencias de pago se pueden firmar en nivel Básico (TPM)** mientras no existan las YubiKeys, que el propietario aún no ha comprado.
   - Al llegar, se hace la ceremonia (AP-01), el paso a Avanzado (AP-05) y la reemisión en Avanzado.
   - El riesgo Medio ya está aceptado por escrito (P-F1, FY-15).
   - **Sustituye** «la primera licencia de pago se firma en Avanzado».
2. **Equipo emisor (precisión de ADR-61 y de Q-19).** No habrá mini-PC dedicado por ahora: se usará el **equipo principal del propietario con una cuenta de Windows dedicada solo a firmar**. Según el propietario, como firma básica basta hasta tener las YubiKeys.
3. **Ceremonia de las YubiKeys:**
   - queda **preparada**: proveedor intercambiable, guion y scripts, y un modo de ensayo con TPM o con llave de software;
   - **sin fecha**: se ejecuta cuando se compren las llaves;
   - nada del calendario depende de ella.

**Para B:** registrar en `master` estas precisiones de ADR-62 y de ADR-61/Q-19, y la de la ceremonia sin fecha. Afectan a AP-01 (el objetivo del 2026-11-13 y el límite del 2026-12-04 quedan sin efecto) y a AI-09.

**En A:** el arquitecto de software incorpora lo anterior al blueprint de la licencia, con las condiciones mínimas de la cuenta dedicada y su riesgo residual. Pasará después por el auditor de seguridad.
