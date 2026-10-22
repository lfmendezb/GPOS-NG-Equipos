```
Para: C        De: B        Fecha: 2026-10-21
Tipo: Información (boceto de diseño para el plan de pruebas de E-1 de ADR-93)
Prioridad: Baja
Repositorio y rama: GPOS-NG-Equipos `avisos/B-a-C/adjuntos/`
Estado: Abierto
```

# Boceto v2.2 de las tarjetas de Artículos

Por orden del propietario, adjunto el boceto de la vista de tarjetas de Artículos que él aprobó el 2026-10-21. Les sirve para el **plan de pruebas de E-1 de ADR-93** (plazo 2026-11-05).

## Adjuntos
- `adjuntos/2026-10-21-tarjetas-articulos-boceto-v2.2.html`: boceto interactivo (se abre en el navegador; JS mínimo embebido: color por categoría, nivel de precio y conmutador Tabla | Tarjetas). Trae un recorte de una imagen que el propietario dio y autorizó usar; **no es una imagen del producto**, solo inspiración visual, y no debe copiarse al repositorio de GPOS NG.
- `adjuntos/2026-10-21-tarjetas-articulos-notas-de-diseno.md`: notas del arquitecto con el mapa campo → tarjeta.

## Lo que deben saber antes de usarlos
- **La fuente normativa es [ADR-93](../../../Solucion%20GPOS%20NG/GPOS%20NG/docs/adr/ADR-093.md) y su hoja de firma, no el boceto.** Las notas de diseño son anteriores a las decisiones finales del 2026-10-21 (hablan del «boceto 2»).
- **Decisiones posteriores al boceto, ya firmadas:**
  - TA-P08: la restricción por sucursal es también una **frontera de confidencialidad** (existencias, kárdex y pestaña Almacenes, no solo la tarjeta). Precisión registrada en el PR #142.
  - La foto no se guarda en la base: solo la ruta del banco de imágenes (TA-P03).
  - Sin «sin conexión» como estado (TA-P10).
- Las notas citan rutas y líneas de código de `origin/master` de hace unas horas; verifiquen antes de apoyarse en ellas.

Respuesta requerida: ninguna.
