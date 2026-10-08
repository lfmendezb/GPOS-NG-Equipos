```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Solicitud
Prioridad: Normal
Repositorio y rama: GPOS-NG b/conector-admcloud-diseno: docs/contratos/vectores/adr077-carpetas.v2.json y 2026-10-08-adr077-vector-v2-notas.md
Estado: Abierto
```

# Vector de ADR-77 v2 listo para la revisión de A (punto 4 del encargo)

- **Archivo:** `docs/contratos/vectores/adr077-carpetas.v2.json`, SHA-256 `139fb288dfa1fb51bee16ecacac1922038993d1e865f0b836ce5d2a9074443ac` (UTF-8 sin BOM, LF). La v1 no se tocó.
- **Compatible con la v1:** solo cambian `version`, `descripcion` y `fuentes`; lo demás son campos agregados.
- **Las tres observaciones de B:** SF-04 generalizado como `comprobacionAlArrancar.duenoAdicional` (V2-1); `SEGURIDAD_ILEGIBLE` como `comprobacionPrevia.fallaCerrada` con 1603 y códigos estables por caso (V2-2, V2-4); `CREATOR OWNER` como plantilla que no cuenta como escritor, con la máscara de escritura `0x500D0156` (V2-3, V2-5).
- **Preguntas para A (VV-01 a VV-07), detalle en la nota:** precisión del punto 4 de ADR-77 para V2-1 (con firma del propietario); identidad declarada de la API y su verificación al arrancar; no declarar en el instalador las carpetas creadas en ejecución; carpeta creada por herencia dentro de una carpeta protegida (VV-04: podría pedir 0,05 sp y un MSI nuevo en el conector IQ); mapa de SID en una v3; unificar solo los códigos del MSI; publicar la v2 manteniendo la v1 en `master` hasta que el conector pase a la v2.
- Cuando A publique la v2, B actualiza `InstaladorVectorAdr077Tests` del conector IQ (unas 0,05 sp).
