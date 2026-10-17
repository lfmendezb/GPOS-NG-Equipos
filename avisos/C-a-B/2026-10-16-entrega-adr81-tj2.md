```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-16
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: GPOS-NG c/adr81-fase-a @ bdcf7804 (con push, sin PR hasta T-r)
Estado: Abierto
```

# Fase A de ADR-81: T-j2 (vía a′) construida y revisada; faltan T-n y T-r

## Construido en `c/adr81-fase-a`
**Tandas de la fase A:** T-a a T-m, T-o, T-p y T-q (con P8 en la Web y MAUI) y **T-j2a a T-j2f**.

**Qué es T-j2:** la recuperación del SUPER con una autorización de GSF, que firmaron R-COR, PA-01 a PA-05 y P-TJ2-01 a 05.

**Revisiones de seguridad de T-j2:** tres, todas «Aprobado con observaciones», sin Críticos, Altos ni Medios.
- **Diseño:** `traspasos/C/revision-seguridad-via-a-prima-2026-10-16.md`.
- **Código del servidor:** con la verificación de las correcciones. Están cerrados SEG-TJ2-01 a 06, 08 y 10 (`d59cd1e2` a `bdcf7804`). Informe: `traspasos/C/revision-seguridad-tj2-codigo-2026-10-16.md`.
- **Cliente:** están cerrados SEG-TJ2C-02 y 03. Informe: `traspasos/C/revision-seguridad-tj2-cliente-2026-10-16.md`.
- **Quedan:** solo informativos, y SEG-TJ2C-01. Este último es de UX: si la conexión se corta al confirmar, el SUPER ve «El tiempo terminó» aunque la recuperación se completó.

**Pruebas:**

| Proyecto | Resultado |
|---|---|
| Web | 786/786 |
| MAUI | 611/611 |
| Clases afectadas de GPOS.Tests | En verde. Hubo 3 fallas intermitentes por carga que pasaron al correrlas solas |

## Publicación (PA-05)
La vía (a′) queda **apagada en Release** mientras el recurso de llaves no traiga una llave `aut`.

Publicarla exige un PR con las llaves `aut` de GSF y la constancia del propietario de que se cumplen REQ-E-01 a REQ-E-11.

## Falta
- **T-n:** el sello real con `ISelladoCuenta`. Espera la pieza SL de A.
- **T-r:** la integración, que incluye:
  - la suite oficial completa;
  - PA-14 y PF-12 medidas con la máquina sola;
  - PF-18 con o sin el #49;
  - PF-24 (búsqueda de secretos);
  - la revisión final.

## Para B al unir
- **Marca del esquema de `GPOS_SYSDATA`:** 5. Si está ocupada, asígnale el número siguiente.
- **#45 de A:** marca como Esencial la liberación del candado; no se repite aquí.
- **Prueba PF-44:** monta `UseLicencia` en la propia prueba. Cuando se una el #45, pásala al anfitrión real.
- **DEMO en Release:** exigirá el segundo factor al SUPER (R-25). Hace falta una guía antes de publicarlo.
