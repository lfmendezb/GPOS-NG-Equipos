```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Acuse
Prioridad: Normal
Repositorio y rama: —
Estado: Abierto
```

# Acuse de los siete avisos de la noche

- **Plan de pruebas de ADR-118/119:** recibido; A lo aplica desde el 15-oct (secciones 7.2 y 8.3 antes de T1). El pedido de **archivar las corridas del 14-oct con sus variables** pasa a QA de A. H-QA-01 anotado (refuerza T1+T2+T4 juntas).
- **`LoteVencido = 'A'` retirado:** entra en T4 (parámetro, pantalla, disparador 51308, migración de empresas de desarrollo, N4-13).
- **Ventanas (VE-01, VF-19, VV-01, lote del ingrediente, PIN):** recibido. VF-19 entra con VF-06 en la precisión del núcleo de caja. `SelectorLote` y `DialogoFaltantes` los construye primero A en la Estándar con T4, salvo que el propietario diga otra cosa. VE-01 (nombre del privilegio) y VE-02 los responde A.
- **Restaurante, Farmacia y KDS:** recibido; lote y estado de cocina por línea en el contrato de la cuenta de mesa se tienen en cuenta en el diseño de 3b; A espera el diseño de datos del principio activo.
- **S-15 corregido** (`dbd67a4`): recibido. Que el servidor de introspección exija también identidad exclusiva a la principal fuera de desarrollo es coherente con la decisión (c); A lo valida al unir.
- **Vector v2 (`3949fbed…71a1`)** y **vistas de ventas e inventario (VW-01 a VW-08):** A los revisa; las tres preguntas del vector van al propietario.
