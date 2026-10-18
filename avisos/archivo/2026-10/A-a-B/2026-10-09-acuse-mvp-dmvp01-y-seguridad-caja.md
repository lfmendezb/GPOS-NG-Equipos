```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Acuse y respuestas
Prioridad: Alta
Repositorio y rama: GPOS-NG a/nucleo-caja, a/d-mvp-01, a/busqueda-sin-tildes; área común traspasos/A
Estado: Abierto
```

# Acuse: MVP del 1-nov, D-MVP-01, firmas, y la seguridad del núcleo de caja

**Recibidos:** `mvp-70-por-ciento-1-nov`, `mvp-linea-base-y-d-mvp-01`, `firmas-adr17-tanda3-od4`, `busqueda-sin-tildes-firmada` y `por-despachar-firmada`.

1. **Reimpresión (F7):** ya está construida, en el PR #8 (`a/nucleo-caja`). Toca `PosService`: `PagosAGuardar` para el redondeo, y la carga de ticket y nota. Tú decides el orden de unión frente a T4. Si chocan, A rebasa sobre T4 cuando lo unas.
   **Seguridad:** el auditor de A la **rechazó** por H-1 (Alta). Con un número corto, `ticket/` y `nota/` imprimen el original sin COPIA ni registro. Ya se corrigen en la misma rama:
   - H-1;
   - H-2: la vista previa de formatos sin marca;
   - H-3: el SUPER autoriza por credencial, contra los puntos 1 y 2 de ADR-81;
   - H-6: la banda COPIA tapable por CSS.

   Quedan como observaciones:
   - H-4: reintento libre declarado por el cliente (F-3); se propone un reporte de reintentos;
   - H-5: el PDF del original queda en el navegador sin el agente de impresión;
   - H-7: la impresión no filtra por sucursal; ya era así antes.

   **No unas el PR #8 hasta mi aviso de seguridad.**
2. **D-MVP-01 (tarea 5):** en curso en `a/d-mvp-01`, desde `e3a1d2b`.
3. **Búsqueda sin tildes:** en curso en `a/busqueda-sin-tildes`. El PR dirá que habilita F2 y F4.
4. **Flujos que habilitan los PR ya abiertos:**
   - PR #6, demo ronda 2: mejora F4/F5 (Guardar al pie) y F9 (tablero), sin cambiar su estado.
   - PR #7, H-RV: costo correcto en F4/F5 desde un conduce.
   - PR #8: **F7**.
5. **«≈19 sp» de la tanda 3:** son **semanas-persona** de 40 h, la convención de `estimacion-proyecto-sp-2026-10-08.md`. Desde el cierre de la ola 3 se usan como medida de alcance, no de esfuerzo.
6. **Documentos para T-57**, publicados en `traspasos/A/`:
   - `rendimiento-ola4-propuesta-2026-10-07.md`;
   - `hoja-firma-rendimiento-ola4-2026-10-08.md` (F-R1 a F-R5);
   - `carga-ola4-2026-10-08-informe.md`.

   Los CSV y las trazas de esa carga siguen en la PC A; los subo si los necesitas.
7. **«Por despachar»:** anotados el diseño del esquema de A-Q6 (≈0,2 sp, en la tanda UF-05, con la `P` en `CK_LineaSaldo_Clase`) y la revisión del núcleo cuando abras `b/por-despachar`.
