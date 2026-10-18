```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Decisión del propietario
Prioridad: Normal
Repositorio y rama: GPOS-NG b/verticales-diseno (ced7cef)
Estado: Abierto
```

# Edición de SQL Server a elección del cliente; con Express, archivado por períodos (después del corte)

Al revisar la capacidad de la central de Duty Free (tres tiendas con nodo y 10 años de retención), el propietario decidió el 2026-10-08:

1. **La edición de SQL Server de la central (Standard o Express) la elige el cliente.**
2. **Si el cliente usa Express, GPOS NG implementa un mecanismo de archivado por períodos, y los períodos los elige el cliente.** El objetivo es no llegar al límite de 10 GB.

**Ubicación en el plan (decisión del propietario): después del corte de la entrega 1.** Ningún cliente se acerca a los 10 GB en los primeros años. El arquitecto-datos de B estimó que una central en Express se llena entre el año 6 y el 20, según el volumen (inferido).

**Para A, que lleva el motor (ADR-54) y el modelo de datos:**
- Es una **capacidad general del producto**, no solo de Duty Free. Es candidata a ADR o a precisión de ADR-54. Pedimos ubicarla en el plan posterior al corte.
- **Archivar no borra.** Con la retención de 10 años (MD-61), los períodos cerrados pasan a otra base que se sigue consultando.
- **Al diseñarlo hay que resolver:**
  - cómo se consultan y reportan los períodos archivados (API de reportes y vistas `rpt`, ADR-109);
  - los archivos fiscales presentados (ADR-111);
  - el respaldo de las bases de archivo con la herramienta de respaldos (MD-54);
  - los nodos (retención local de 90 días);
  - no archivar un período abierto ni un período de inventario sin cerrar (ADR-69).
- **Hasta entonces,** nada del corte depende de esto. Conviene solamente no cerrarle el paso: por ejemplo, que las vistas y los reportes reciban el período como filtro, cosa que la ola 5 ya exige.

Registro de la decisión: `docs/decisiones/2026-10-08-respuestas-propietario-duty-free.md`, rama `b/verticales-diseno` (`ced7cef`).
