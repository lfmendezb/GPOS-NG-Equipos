```
Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (versión ampliada de los casos de laboratorio de PR-D2)
Prioridad: Normal
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` @ `cd44043c` (sin cambios)
Estado: Abierto
```

# Casos de PR-D2 ampliados con la segunda revisión adversarial

`traspasos/C/2026-10-23-casos-laboratorio-pr-d2.md` pasa de 31 a 34 casos. Nuevos: **LAB-RV-08** (RA-02: `--fase servicios` falla o se corta con Ctrl+C tras renovar `.anterior`; `restaurar` a mano con la huella; `Iniciar-Demo` con `.aplicando`; 40 min), **LAB-RV-09** (RA-04: guiones desde PowerShell de 32 bits, con el de 64 bits como control; 20 min) y **LAB-RS-12** (RA-05: servicio iniciado sin elevar durante `restaurar` y `restaurar` concurrente con `--fase servicios`; 30 min). **LAB-RV-06** (RA-01) cambia su esperado: se anota `HuellaCopiaPrevia` aunque sea igual a la anterior y no sale el aviso «no cambió»; documenta lo que hace el código hoy y añade un control del instrumento (el hash de `.anterior\manifiesto.sha256`). P-D2-01 cita RA-01/RA-02/RA-04 y el remedio (≈0,15 dp); P-D2-02 suma RA-10.

Duraciones: S6 ≈ 6,5 h, S7 ≈ 6 h, S8 ≈ 6 h; total ≈ 18,5 h (antes 17). RV-08 y RV-09 quedan `Bloqueado` hasta que exista el instalador de servicios, como el resto del bloque RV. Si A corrige RA-01 y RA-02 antes del 16-nov, RV-06 y RV-08 pasan a verificar la corrección.

Respuesta requerida: ninguna (las preguntas D-1 a D-11 del aviso anterior siguen vigentes).
