```
Para: C (conocimiento de A)        De: B            Fecha: 2026-10-17
Tipo: Aviso
Prioridad: Normal
Repositorio y rama: GPOS-NG b/prep-27oct @ d67f5a33; #66 c/b9-afinidad @ e5e63f41 (aplicado sin confirmar en los árboles de medición)
Estado: Abierto
```

# T6: quinta tanda esta noche, con la afinidad del #66

El propietario decidió la salida 1 para T-28: diagnosticar el modo lento y corregir 8.2 (6) en la misma tanda.

## Hecho
- **8.2 (6):** `FORCESEEK` en los dos accesos a `ventas.VentaLineaImpuesto` de la comprobación de impuestos (CA-12) de `TR_Documento_Emision`, dentro de `Uf05ForceSeek` (`b/prep-27oct` `d67f5a33`, en GitHub).
  - El guion idempotente se regeneró: solo cambian esas 2 líneas.
  - Emisión, migraciones, 3b, planes y Mvp: 141 correctas, 0 fallidas, 4 omitidas.
- **El #66** se aplicó sin confirmar en los dos árboles de medición:
  - base `GPOS-B-carga`, `e80f4654`;
  - candidato `GPOS-B-prep27`, `d67f5a33`.
  - Aplica limpio en los dos. `AfinidadCargaTests`: 35/35 en cada lado.
  - En LFMB, el Express tiene 8 planificadores (CPU 0 a 7), así que `auto` deja al cliente en las CPU 8 a 15.
  - **No se une todavía:** se une en el orden firmado, después de leer la tanda.

## Quinta tanda (`Solucion GPOS NG\Medicion-T6-r5.ps1`, inicio a las 20:00)
1. **Control:** T-28 sin afinidad, una corrida por lado.
2. **Cinco rondas** de T-28 con `GPOST_B9_AFINIDAD=auto`, base y candidato intercalados.
3. **Una ronda** de T-57 y N6-02 con la afinidad.

- **Durante cada corrida,** `Muestras-Pagelatch.ps1` toma cada 500 ms:
  - las tareas en espera por tipo (PAGELATCH, LCK_M, WRITELOG, SOS);
  - la página de cada PAGELATCH, traducida en vivo a objeto e índice (`fn_PageResCracker` + `dm_db_page_info`).
- **Salidas:** `GPOS-B-prep27\TestResults\T6-r5-*`. Duración estimada: 6 a 7 h.
- **No se usa `dotnet-counters`:** no está instalado, y las líneas GRUPO del #66 dan la CPU por venta.
- **Si el equipo pasa a batería, el guion se detiene solo.** Al publicar este aviso, LFMB estaba en batería (87 %).

## Pedido a C
Ninguno por ahora. B publica el resultado en `traspasos/B/2026-10-16-t6-segunda-tanda.md`.
