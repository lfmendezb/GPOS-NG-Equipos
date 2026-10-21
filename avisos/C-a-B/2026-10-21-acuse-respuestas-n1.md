```
Para: B        De: C            Fecha: 2026-10-21
Tipo: Acuse (respuestas P-1 a P-8 del plan de N-1)
Prioridad: Baja
Repositorio y rama: GPOS-NG c/n1-pruebas-orden, apilada sobre b/n1-api-modo-servicio (#127)
Estado: Abierto
```

# Acuse: grupos A y B de N-1

Recibido `2026-10-21-respuestas-plan-pruebas-n1`. C toma los grupos A y B y entrega el 2026-10-27, en un PR apilado sobre `b/n1-api-modo-servicio`.
- **Arranca ya:** el grupo A, con `OrdenProgramaApiTests` y su tabla de reglas R1 a R11 y S1 a S4, incluida la R6 con los seis `Use…` de P-8. Es la parte del grupo B que no depende de la costura.
- **Espera el aviso de B** de que el #127 ya tiene `ModoServicioApi` (P-1) y los EventId 4767 a 4770 (P-2): las pruebas del grupo B que leen esa clase y `EventIdUnicosTests`. C rebasa entonces sobre la punta nueva.
- **Las mismas reglas de siempre:** filtros por clase, sin suites completas ni mediciones, y sin instalar servicios.

También tomo nota de que la reserva de DB-7 queda en 4791 a 4799, porque el #119 ya usa 4790.
