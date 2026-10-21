```
Para: A        De: B        Fecha: 2026-10-20
Tipo: Encargo (tareas ya) y respuesta a los planos del instalador y de ADR-90
Prioridad: Media
Repositorio y rama: GPOS-NG-Equipos `traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md` (sin confirmar por el propietario)
Estado: Abierto
```

# Tareas de A según la recomendación de B

El propietario pidió el 2026-10-20 asignar estas tareas a A. Las respuestas de B a los planos están en `traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md` (léalo completo; las firmas F-1, F-5 y F-6 **aún no están dadas**).

## Ya (no dependen de ninguna firma)
1. **PR del emisor** (`GSF.EmisorLicencias` con el submódulo al commit del #103). Desbloquea la unión del #103, que ya aceptó B.
2. **PR-1a de ADR-90** (RT-01 en `GPOS.Comun/Red`, **sin proyecto nuevo**) con los EventId **4743 a 4752**. Criterios y orden en el documento de B.
3. **Hoja de licencia a la v2.14** con lo firmado el 2026-10-20: ceremonia aplazada, firma Básica con TPM en las entregas 1 y 2, suplente Gilberto De La Cruz y fecha de compra de DL-12 «tras la segunda entrega» (aviso `2026-10-20-reconfirma-tpm-ceremonia-aplazada`).
4. **Correcciones del plano que pide B** (documento de B, secciones de hallazgos): HB-01 y H-4 (la raíz protegida la crea el MSI de la API primero; `CarpetaAnillo` no debe crear el padre con ACL heredada), renombres a `*.Windows.cs`, «sin modo» solo sin Estricto y `IpNodos` siempre escrito (4743 si falta en «servidor de sitio»), y la lista de privilegios de `NT SERVICE\GPOS.Api` (los fija A; devops de B los mide).
5. **R-1 de RSVB-04** (0,02 dp), si sobra tiempo.

## Cuando B o el propietario respondan
- **PR-3** antes del 2026-11-09 y **PR-2** después.
- **PR-1b** (`GPOS.Comun.Servidor`) y **O-1/O-3**: tras la firma de **F-1** (excepción de proyectos nuevos, cinco proyectos).
- **PR-4** (4 líneas en el `Program.cs` de la API, zona de DB-7): tras el N-1 de B y la firma de **F-5**; hasta entonces **no se toca** el `Program.cs`.
- **N-10 en detalle (modo híbrido), Q-4 y Q-5:** no se firman ahora; la revisión del auditor va antes (B-6).
- **VS-2 / ADR-77 (N-11 a N-15)** y **tanda 3 de ADR-78:** sin cambios (prueba D4 y entrega 2).

## EventId (respuesta de B, sin firma)
4743-4752 ADR-90 (A) · 4753-4766 acción previa y actualizador (A) · 4767-4779 `GPOS.Instalacion` de B · 4780-4789 verbo `tls` y su tarea (A) · 4790-4799 reserva de DB-7. Se abandona 5130-5149 (choca con 5130-5133 y 5140-5143 ya usados).

## No son de A
T4-01, T4-05, T1-7 y T2-0 (B) y la guarda DF-05 de ADR-91 (C).
