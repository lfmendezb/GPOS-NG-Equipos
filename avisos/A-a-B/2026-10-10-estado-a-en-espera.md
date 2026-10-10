```
Para: B            De: A            Fecha: 2026-10-10
Tipo: Entrega (estado al detenerse)
Prioridad: Normal
Repositorio y rama: GPOS-NG a/h2-ncf-historico (37694341), a/h11-p7-candado (PR #24)
Estado: Abierto
```

# A en espera hasta el miércoles 14 a las 04:00: estado para retomar

**Entregado:**
- **PR #24:** primer PR de la segunda parte de H-11, la base de empresa.

**A medias (subido):**
- **H-2, H-3, H-4, H-7 y la parte de datos de H-6** están en `a/h2-ncf-historico` @ `37694341`. Árbol limpio, compila. **Sin PR.**
  - Incluye las preguntas firmadas:
    - el 607 informa el ITBIS tal cual y solo marca «fuera de plazo», con la migración `20261010185211_H2Formato607FueraPlazo`. El 607 era de A, así que no hubo que pasártelo;
    - se mantiene el 51379;
    - el comentario de «e-CF activo» queda como transitorio hasta ADR-108.
  - El guion acumulado es `gpos-empresa-20261010185211_H2Formato607FueraPlazo.sql`.
  - **Pruebas:**
    - la suite completa, antes del cambio del 607, dio 2.166 aprobadas. Hubo 5 fallas que ya existían en la base y 2 sensibles a la carga, que pasaron al repetirlas;
    - el DEMO real pasa 1/1: 9.604 facturas en 150 s;
    - el subconjunto del cambio del 607 da 98/98;
    - Web 623/623 y MAUI 547/547.
  - **Al retomar:**
    - una corrida completa de `GPOS.Tests` y luego el PR;
    - regenerar las migraciones frente al PR #24, si se une antes;
    - correr `GPOS.EnsayoImplantacion` con QA, porque necesita la API levantada.
- **Nuevo en las pruebas:** `GPOST_TEST_PREFIJO`, opcional, para que las bases temporales de cada agente lleven su prefijo y no se borren las de otro.

**Para después del 14:**
1. Corrida completa y PR de H-2 y H-3.
2. Revisión de seguridad y PDS-06 del PR #24.
3. Segundo PR de H-11: el candado de `GPOS_SYSDATA`.
4. Parte de aplicación de H-6: el motivo del usuario en las pantallas y en `_LOG`.
5. T3-12 y RG-14.

Sin agentes activos. El vigilante queda desarmado hasta el 14.
