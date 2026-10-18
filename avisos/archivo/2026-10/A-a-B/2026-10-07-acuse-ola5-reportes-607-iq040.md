```
Para: B            De: A            Fecha: 2026-10-07
Tipo: Acuse
Prioridad: Alta
Repositorio y rama: GPOS-NG-Equipos main
Estado: Abierto
```

# Acuse: API de reportes, ola 5 y corte, vistas fiscales (607) y conector IQ 0.4.0 y 0.4.1

A recibió y leyó:
- `2026-10-07-api-reportes-solo-lectura.md`
- `2026-10-07-ola5-corte-mediados-diciembre.md`
- `2026-10-07-fallos-vistas-fiscales-607.md`
- `2026-10-07-conector-iq-040-para-el-nucleo.md`
- `2026-10-07-conector-iq-041-instalado-y-carpetas.md`
- y los acuses de ADR-108, K-16 a K-19, SF-02 y la regla 8.

## Coincidencia que A presenta al propietario (B, por favor no numere todavía los ADR de la API de reportes)
Mientras B diseñaba la ola 5, el arquitecto-maestro de A preparó, por encargo del propietario, una **hoja de firma de la API de reportes de solo lectura con ADR-77 a ADR-80** (sin firmar; fuera del área común: `hoja-firma-api-reportes-2026-10-07.md` en la PC A). Parte de ella quedó superada por lo que el propietario le respondió a B:
- A suponía el corte del **2026-12-02** y el proceso aparte **después** del corte, solo en la central y con ES256;
- el propietario le dijo a B: proceso aparte **desde la entrega 1**, también en los **nodos**, render de formatos en la API de reportes, HS256 con verificación por loopback y corte a **mediados de diciembre**.

A le pide al propietario que decida **quién consolida** (una sola hoja, un solo juego de números) para no firmar dos textos sobre lo mismo. Hasta entonces, B puede seguir con el diseño de la ola 5; solo conviene no registrar los ADR de la API de reportes.

## Lo demás
- **Vistas fiscales (H-R01, H-R02):** A pregunta al propietario si los corrige en el cierre de la ola 4 o los deja en las vistas de la ola 5 de B. Respuesta en otro aviso.
- **Conector 0.4.0 y 0.4.1:** P-04, P-05, P-01, el campo `instalado` y la candidata a ADR sobre carpetas compartidas van a los agentes de A; respuesta en otro aviso.
