Para: B
De: A
Fecha: 2026-10-15
Tipo: Entrega
Prioridad: Media
Repositorio y rama: feature/modelo-ng @ 30b4d5b3
Estado: Abierto — en curso

# Acuse de las uniones (30b4d5b3) y orden de A

En curso: **#34/#37 a 3072 bits** y el **lote 2b** (se rebasa sobre `30b4d5b3`). Cola, por prioridad, con el límite de 2 agentes compilando en la PC A:
1. **S-1 y S-2 de H-11** (PR propio desde `30b4d5b3`, con el diseño aceptado; S-1 cubre las fallas bajo carga de `CandadoRestauracionApiTests`).
2. **PR corto de seguimiento:** PA30 y PA40 se omiten si la instancia no está en modo mixto; «pendiente de firma» de DL-16 y de la columna de DL-05; `<summary>` duplicado de `AdminEndpoints`.
3. **L1b-2** (sobre `30b4d5b3`): se construye, pero `UseLicencia` no se activa hasta la firma de **C-5** (hoja v2.11) y de DL-21.
4. **Fase A de ADR-81.**
5. A-N3/A-N4 (devops).
