```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Decisión del propietario (para registrar en master)
Prioridad: Alta
Repositorio y rama: GPOS-NG master (registro, lo hace el coordinador)
Estado: Abierto
```

# Ciclo de vida de los tokens: CS-1 a CS-13 firmadas

El propietario firmó el 2026-10-09, **según la recomendación**, la hoja CS-1 a CS-13 de `traspasos/A/propuesta-cambio-clave-sesiones-2026-10-09.md`. Con eso cierra la condición de la aceptación de H-3 y H-4.

**Qué queda decidido:**
- **Sello de seguridad** por cuenta en el token y en los comprobantes (CS-1).
- **Solo vale el último token** de la sesión (CS-2).
- **Una sola operación para invalidar credenciales** (CS-4).
- **Bloqueo por intentos** al cambiar la clave, con cierre de la sesión (CS-5), y un cupo propio de 10 por minuto (CS-6).
- **La propia clave** solo se cambia con la clave actual (CS-7, cierra R-1).
- **Inhabilitar la cuenta o bajar a un ADMIN a USER** renueva el sello (CS-8, cierra R-3).
- **Sesión:** 120 min de inactividad (CS-9) y un tope absoluto de 12 h (CS-10).
- **Entrega 2:** el sello viaja con las credenciales replicadas (CS-11, en principio).
- **Tokens sin `sid` o sin `sst`:** dejan de aceptarse (CS-12, cierra R-4).
- **Caché del estado de sesión:** 15 s, y 0 s con la versión 1 de ADR-36 (CS-3).

**Calendario (CS-13):** se construye con la fase A de ADR-81, unas 2,3 sp. Si ADR-81 se retrasa, se adelantan CS-1, CS-5 y CS-7, unas 0,9 sp.

**Para B:**
- registrar en `master` las precisiones de ADR-36 y del estándar 3.6 (CS-1, CS-2, CS-9, CS-10) y de la cláusula 6 de ADR-53 (CS-11);
- agendar la construcción;
- A puede construirla como apoyo si se la encargas.

R-2, el comprobante 409 vivo hasta 5 min, queda cubierto por CS-1.
