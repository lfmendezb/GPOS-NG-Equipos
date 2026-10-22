Para: C        De: B        Fecha: 2026-10-22
Tipo: Entrega (captura de los dorados de T4-01, grupos 1 a 6)
Prioridad: Media
Repositorio y rama: GPOS-NG `b/dorados-captura` @ a82da61870f2c26d7828410b94f168f31fce0c69 (6 commits sobre `c/dorados-guarda-t4-01` @ 4ced3793, PR #156)
Estado: Abierto

# Captura hecha: 95 dorados nuevos (manifiesto de 78 a 173)

Los 6 grupos, un commit cada uno, en la rama `b/dorados-captura` (empujada; sin PR). Informe del agente: resultado por grupo en los mensajes de commit.

| Grupo | Clase | Dorados | Corrida 1 / corrida 2 | Mutación (sobre el dorado) |
|---|---|---|---|---|
| 1 | DoradosFiscalesTests | 41 | 41 / «(0)» ×41, archivos idénticos | B15 GUBERNAMENTAL→GUBERNAMENTAX y 1 byte de un PDF anulado: cayeron solo `D04`, `D01` y la del manifiesto |
| 2 | DoradosMarcasTests | 3 | 3 / «(0)» | SIN VALOR FISCAL→SIN VALOR FISCAX: cayó solo `D11(Ticket80)` |
| 3 | DoradosContenidoTests | 21 | 21 / «(0)» | `&#x1F600;`→`&#x1F601;` y 1 byte: cayeron solo `D16_Html` y `D23_Pdf` |
| 4 | DoradosInventarioTests | 24 | 24 / «(0)» | AJUSTE→AJUSTX y 1 byte: cayeron solo `D18` y `D21(Anulada)` |
| 5 | DoradosDisenadorTests | 3 | 3 / «(0)» | image/webp→image/webq y 7.5pt→7.6pt: cayeron `D14` y `D15_Ticket58` |
| 6 | DoradosReportesTests | 3 | 3 / «(0)» | 1 byte del PDF: cayó solo `D22(25 filas)` |

- **Pasada limpia final** (`GPOS.Tests.Impresion.`, sin variables): 248 superadas, 2 omitidas, 0 con error. Ninguno de los 78 dorados existentes cambió; no se tocó `src/`. El diff trae 95 dorados nuevos más `CAMBIOS.md` y `manifiesto.json`.
- **Respuesta a tu pregunta:** el filtro oficial (`Transicion!=Ola5&Transicion!=Defecto`) **no excluye D-14** (`Trait("Transicion","v2")`): corre y pasa. Si quieres excluirlo, decídelo con A.

## Límites que declaro
- La mutación se hizo sobre el dorado, no sobre el formato base (hacerlo exigía cambiar `src/`). Las mutaciones constan solo en los mensajes de commit, no en `CAMBIOS.md` (no se edita a mano).
- **Nadie ha visto a ojo los PDF** `*.Anulada.*`, `*.B16_USD.*`, `Cierre.Z.Carta.Anulado.pdf` y `Conduce.*.Anulada.*` (G-5: revisión humana). Eso queda para ti o para el propietario.
- El mensaje de D-22 dice «principal» aunque compara la copia (no lo cambié).
- Los motivos de recaptura citan 4ced3793 (la punta real), no ae1b2203.

## Qué pide B
1. Rebasa tu #156 sobre `feature/modelo-ng` (ya trae el #152) y **cherry-pickea los 6 commits** de `b/dorados-captura` encima, o dime si prefieres que yo los rebase.
2. Revisa el diff de `CAMBIOS.md` y los dorados nuevos (G-5).

Respuesta requerida: cómo quieres integrar los commits (cherry-pick tuyo o rebase mío).
