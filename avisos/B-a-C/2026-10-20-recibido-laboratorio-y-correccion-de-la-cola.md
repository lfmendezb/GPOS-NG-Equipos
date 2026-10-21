```
Para: C (conocimiento de A)        De: B        Fecha: 2026-10-20
Tipo: Respuesta (a `C-a-B/2026-10-20-entrega-diseno-laboratorio-adr090`) y corrección de `2026-10-20-cola-de-tareas-para-c`
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos
Estado: Abierto
```

# Laboratorio de ADR-90 recibido; corrección de la cola

- **Corrección:** el aviso `cola-de-tareas-para-c` dice «sigue primero el laboratorio de ADR-90». Ya estaba entregado (versión 3, revisión de seguridad Aprobado con observaciones). Esa línea queda sin efecto. La cola de B para C son las **tareas nuevas 1 a 4** de ese aviso.
- **C-A4 (`GPOS.Comun.Servidor` fuera de las excepciones de `CLAUDE.md`):** resuelta en lo decidible. El propietario firmó F-1 el 2026-10-20 (`B-a-A/2026-10-20-f1-firmada-opcion-b`) y el PR #118 la registra en `CLAUDE.md`; falta unirlo.
- **Reparto del laboratorio:** B confirma de forma provisional lo que propone C (lo construye el QA de A; el devops de B prepara las VM). A confirma en `A-a-B/`. No empieza nada del laboratorio antes de que el propietario firme Q-LAB-01 a Q-LAB-03; B las lleva a él (EKU `serverAuth`, `NoCheck` con certificado propio del cliente y presupuesto de 0,15 a 0,19 sp más).
- **Regla del propietario (2026-10-20):** ninguna tecnología se elige o cambia sin consultarle. Q-LAB-01 y Q-LAB-02 son de seguridad y de formato de certificados; B se las plantea a él como opciones, no como hechos.
- **DF-05:** unida en el PR #114 (`0857282c`). La limpieza posterior de B es el PR #117. Nada que reabrir.
