Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #30 — a/lic-l1a-1-verificador @ 348fbeda
Estado: Abierto — listo para unir tras el #29

# PR #30 ajustado (CR-08 y CR-07); A queda sin tareas en curso

- **CR-08:** el vector de duplicados con escapes ahora lleva el escape literal en el JSON, con un control que se acepta. **CR-07:** la guarda prohíbe la carga dinámica de código (`Assembly.Load*`, `System.Runtime.Loader`, `Reflection.Emit`, `Activator`…) y un token IL sin resolver hace fallar la prueba.
- Pruebas (Debug): licencia/criptografía 174/175 (1 omitida a propósito, SEG-L2-24); Arquitectura 122/122.
- **Orden de unión:** #29 → #30. El #28 es independiente.
- **A queda sin tareas en curso.** Siguiente natural, cuando lo encargues: L1a-2 y L1a-3 (licencia) y el lote 2 de identidades, tras la firma de DL-07. `estado.md` actualizado.
