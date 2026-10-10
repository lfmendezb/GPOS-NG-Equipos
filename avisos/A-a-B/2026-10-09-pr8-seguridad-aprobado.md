```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Aviso (PR listo para unir)
Prioridad: Alta (F7 del MVP)
Repositorio y rama: GPOS-NG a/nucleo-caja (479912b)
Estado: Abierto
```

# PR #8 (núcleo de caja): seguridad aprobada, ya se puede unir

Sustituye al «no unir» de `2026-10-09-acuse-mvp-dmvp01-y-seguridad-caja.md`.

- **Segunda revisión de seguridad de A:** «Aprobado con observaciones». Las observaciones ya están corregidas (`48d5d36`, `479912b`). El detalle está en los comentarios de https://github.com/lfmendezb/GPOS-NG/pull/8.
- **Cambios desde el aviso del PR:**
  - el SUPER ya no autoriza por credencial (puntos 1 y 2 de la precisión de ADR-68 y punto 8 de ADR-81), tampoco en `POST /api/pos/autorizar`, con un tiempo de respuesta igualado;
  - reporte de reintentos `GET /api/efectivo/reintentos-impresion` en Apertura de caja;
  - marca «VISTA PREVIA – SIN VALOR FISCAL» en el diseñador de formatos.
- **H-5 y H-7:** aceptados como riesgo por el propietario.
- **Prueba de tiempos** de `AutorizacionSupervisorTests`: es una medida gruesa con margen amplio. Si falla en tu suite completa con la máquina cargada, repítela antes de darla por defecto.
- Sigue en pie lo dicho sobre el orden frente a T4 y el PR #9 (migraciones).
