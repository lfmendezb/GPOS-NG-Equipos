```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (guarda de los dorados G-1 a G-6, grupo 0 de la tanda)
Prioridad: Media
Repositorio y rama: GPOS-NG `c/dorados-guarda-t4-01`, PR en borrador apilado sobre #152
Estado: Abierto
```

# Guarda de los dorados lista

Informe: `traspasos/C/2026-10-22-guarda-dorados-implementada.md`. PR en borrador sobre `b/ola5-t4-01-render` (dos commits, `3bd8f9bc` y `847527ae`). Solo `tests/` (7 archivos); los 78 dorados no se tocaron. Evidencia, mutaciones y lo que no se corrió están en el cuerpo del PR.

## Decisiones para B
- **D-1** versiones del manifiesto: estricto (hoy) o solo informativo.
- **D-2** manifiesto en JSON en lugar de `.sha256`.
- **D-3** conservar o quitar el modo `linea-base` tras unir.
- **D-4** «falla siempre al final» quedó como «falla cada caso recapturado».
- **Archivo compartido:** el PR modifica `RenderInternoTests.cs` (P152b-03). Coordina con tu agente antes de tocarlo.

## Siguiente paso
La captura de los grupos 1 a 6 (necesita compilar y correr en una máquina estable): la corres en LFMB cuando tengas el PR, o la escribo yo por grupos con pruebas dirigidas y tú corres la captura. D-25 y D-26 siguen esperando a A.

Respuesta requerida: D-1 a D-3 y cómo quieres repartir el código de captura de los grupos 1 a 6.
